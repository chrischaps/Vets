-- game_state.lua
-- Main gameplay state for Courier Cat
-- Manages active night/level gameplay with player, platforms, deliveries, and timer

-- Load required systems and entities
local Player = require("src.entities.player")
local Platform = require("src.entities.platform")
local DeliveryZone = require("src.entities.delivery_zone")
local CollisionSystem = require("src.systems.collision_system")
local CameraSystem = require("src.systems.camera")
local Input = require("src.systems.input")
local Timer = require("src.systems.timer")
local Scoring = require("src.systems.scoring")
local HUD = require("src.ui.hud")
local TimerDisplay = require("src.ui.timer_display")
local Constants = require("src.core.constants")
local Level = require("src.systems.level")

local GameState = {}

-- Virtual resolution (shared across states)
local VIRTUAL_WIDTH = 320
local VIRTUAL_HEIGHT = 180

function GameState:enter(night_number, state_manager)
    print("[GameState] Entering game state for Night " .. (night_number or 1))

    -- Store night number (default to 1 if not provided)
    self.night_number = night_number or 1

    -- Store state_manager reference for state transitions (VETS-31)
    self.state_manager = state_manager

    -- Initialize game state flags
    self.paused = false
    self.game_over = false
    self.game_won = false

    -- Initialize systems
    self:initializeSystems()

    -- Load level for specified night
    self:loadLevel(self.night_number)

    -- Track deliveries
    self.total_deliveries = #self.delivery_zones
    self.completed_deliveries = 0

    print("[GameState] Game initialized:")
    print("  - Night: " .. self.night_number)
    print("  - Total deliveries: " .. self.total_deliveries)
    print("  - Timer: " .. self.timer:getFormattedTime())
end

function GameState:exit()
    print("[GameState] Exiting game state")

    -- Unload level and cleanup entities
    if self.level then
        Level.unload(self.level)
        self.level = nil
    end

    -- Cleanup
    self.player = nil
    self.platforms = nil
    self.delivery_zones = nil
    self.hazards = nil
    self.powerups = nil
    self.collision_system = nil
    self.camera = nil
    self.input = nil
    self.timer = nil
    self.moon_timer = nil
    self.scoring = nil
end

-- Initialize all game systems
function GameState:initializeSystems()
    print("[GameState] Initializing systems...")

    -- Initialize input system
    self.input = Input.new()
    self.input:init()

    -- Initialize collision system (16px cell size)
    self.collision_system = CollisionSystem.new(16)

    -- Initialize timer (180 seconds for Night 1)
    -- TODO: Adjust timer based on night number in future
    self.timer = Timer.new(180)

    -- Set up timer expiration callback
    self.timer.on_expire = function()
        self:onTimerExpired()
    end

    -- Initialize HUD framework (VETS-43)
    self.hud = HUD.new()

    -- Initialize moon timer display (VETS-44)
    -- Scaled for native resolution (50% smaller than 4x scaling)
    self.moon_timer = TimerDisplay:new({
        initial_time = 180,
        max_time = 180,
        x = 0,
        y = 0,
        anchor = HUD.ANCHOR.TOP_CENTER,
        max_radius = 60,       -- Smaller moon (2x original)
        min_radius = 8,        -- 4 * 2
        horizon_offset = 120,  -- 60 * 2
        top_offset = 70,       -- Ensure moon isn't cut off (>= max_radius)
        show_digital = false,
        show_horizon = true
    })
    self.hud:addElement(self.moon_timer)

    -- Initialize scoring system
    self.scoring = Scoring.new()

    print("[GameState] Systems initialized")
end

-- Load level data for specified night
function GameState:loadLevel(night_number)
    print("[GameState] Loading level for Night " .. night_number)

    -- Load level from JSON using Level system (VETS-35, VETS-36)
    local level, err = Level.load(night_number, self.collision_system)
    if not level then
        error("[GameState] Failed to load level: " .. err)
    end

    -- Store level instance and entity arrays
    self.level = level
    self.platforms = level.platforms  -- Already in collision system
    self.delivery_zones = level.delivery_zones
    self.hazards = level.hazards
    self.powerups = level.powerups

    -- Get spawn point from level data
    local spawn = Level.get_spawn_point(level)
    local spawn_x, spawn_y = spawn.x, spawn.y

    -- Create player at level spawn point
    self.player = Player.new(spawn_x, spawn_y, self.collision_system, self.input)

    -- Add player to collision system
    local px = self.player.transform.x - self.player.collision.width / 2
    local py = self.player.transform.y - self.player.collision.height / 2
    self.collision_system:add(self.player, px, py, self.player.collision.width, self.player.collision.height)

    -- Connect player to game systems
    self.player.delivery_zones = self.delivery_zones
    self.player.timer = self.timer
    self.player.moon_timer = self.moon_timer
    self.player.scoring = self.scoring

    -- Update timer with level's time limit (if specified in environment)
    if level.environment and level.environment.time_limit then
        self.timer:reset(level.environment.time_limit)
        print("[GameState] Timer set to " .. level.environment.time_limit .. " seconds from level data")
    end

    -- Initialize camera and set target to player
    self.camera = CameraSystem.new(self.player.transform.x, self.player.transform.y)
    self.camera:setTarget(self.player)
    self.camera:setSmoothing(0.1)

    print("[GameState] Level loaded:")
    print("  - Level: " .. level.name)
    print("  - Platforms: " .. #self.platforms)
    print("  - Delivery zones: " .. #self.delivery_zones)
    print("  - Hazards: " .. #self.hazards)
    print("  - Powerups: " .. #self.powerups)
    print("  - Player spawn: (" .. spawn_x .. ", " .. spawn_y .. ")")
end

-- Update game logic
function GameState:update(dt)
    -- Update input state
    if self.input then
        self.input:update()
    end

    -- Handle pause input
    if self.input and self.input:is_pressed("pause") then
        self:togglePause()
    end

    -- Don't update game logic if paused or game over
    if self.paused or self.game_over or self.game_won then
        return
    end

    -- Update player
    if self.player then
        self.player:update(dt)
    end

    -- Update delivery zones (pass player position for proximity detection)
    if self.player then
        for _, zone in ipairs(self.delivery_zones) do
            zone:update(dt, self.player.transform.x, self.player.transform.y)

            -- Track completed deliveries
            if zone.completed then
                -- Count completed zones (check hasn't been counted yet)
                local count = 0
                for _, z in ipairs(self.delivery_zones) do
                    if z.completed then
                        count = count + 1
                    end
                end
                self.completed_deliveries = count
            end
        end
    end

    -- Update hazards
    if self.player then
        for _, hazard in ipairs(self.hazards) do
            hazard:update(dt)

            -- Check for player contact/interaction
            if hazard.checkPlayerContact then
                -- Steam vents need player position and physics
                if hazard.type == "steam_vent" then
                    hazard:checkPlayerContact(
                        self.player.transform.x,
                        self.player.transform.y,
                        self.player.physics
                    )
                -- Laundry lines need player bounds and dash state
                elseif hazard.type == "laundry_line" then
                    local is_stunned = hazard:checkPlayerContact(
                        self.player.transform.x,
                        self.player.transform.y,
                        self.player.collision.width,
                        self.player.collision.height,
                        self.player.dashing
                    )

                    -- Apply stun to player if hit
                    if is_stunned and self.player.applyStun then
                        self.player:applyStun(hazard.stun_duration)
                    end
                end
            end
        end
    end

    -- Update powerups
    if self.player then
        for _, powerup in ipairs(self.powerups) do
            powerup:update(dt)

            -- Check for player contact/collection
            if powerup.checkPlayerContact then
                local is_touching = powerup:checkPlayerContact(
                    self.player.transform.x,
                    self.player.transform.y,
                    self.player.collision.width,
                    self.player.collision.height
                )

                -- Collect the powerup if touching
                if is_touching and powerup.collect then
                    powerup:collect(self.player)
                end
            end
        end
    end

    -- Update camera (smooth following)
    if self.camera then
        self.camera:update(dt)

        -- Apply player screen shake to camera
        if self.player then
            local shake_x, shake_y = self.player:getScreenShakeOffset()
            self.camera.shake_x = shake_x
            self.camera.shake_y = shake_y
        end
    end

    -- Update timer
    if self.timer then
        self.timer:update(dt)

        -- Sync moon timer display with timer state
        if self.moon_timer then
            self.moon_timer:setTime(self.timer:getTimeRemaining())
        end
    end

    -- Update HUD (includes moon timer visual)
    if self.hud then
        self.hud:update(dt)
    end

    -- Check win condition (all deliveries completed)
    if self.completed_deliveries >= self.total_deliveries then
        self:onWinCondition()
    end
end

-- Draw game rendering
function GameState:draw()
    -- Draw background
    love.graphics.setColor(0.2, 0.2, 0.3)  -- Dark blue-purple background
    love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    -- Apply camera transform
    if self.camera then
        self.camera:attach(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    end

    -- Draw platforms
    for _, platform in ipairs(self.platforms) do
        platform:draw()
    end

    -- Draw delivery zones
    for _, zone in ipairs(self.delivery_zones) do
        zone:draw()
    end

    -- Draw hazards
    for _, hazard in ipairs(self.hazards) do
        hazard:draw()
    end

    -- Draw powerups
    for _, powerup in ipairs(self.powerups) do
        powerup:draw()
    end

    -- Draw player
    if self.player then
        self.player:draw()
    end

    -- Debug: Draw collision boundaries (F1 key)
    if self.collision_system and love.keyboard.isDown("f1") then
        self.collision_system:debugDraw()
    end

    -- Detach camera (UI elements drawn after this won't move with camera)
    if self.camera then
        self.camera:detach()
    end

    -- Draw score display
    if self.scoring then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("Score: %d", self.scoring:getTotal()), 10, 10)
        love.graphics.print(string.format("Deliveries: %d/%d", self.completed_deliveries, self.total_deliveries), 10, 22)

        -- Draw combo display
        local combo_count = self.scoring:getComboCount()
        local combo_multiplier = self.scoring:getComboMultiplier()
        if combo_count > 0 then
            -- Highlight combo text based on multiplier level
            if combo_multiplier >= 5 then
                love.graphics.setColor(1, 0.3, 1)  -- Magenta for max combo (5x)
            elseif combo_multiplier >= 3 then
                love.graphics.setColor(1, 1, 0.3)  -- Yellow for high combo (3-4x)
            else
                love.graphics.setColor(0.3, 1, 1)  -- Cyan for active combo (1-2x)
            end
            love.graphics.print(string.format("COMBO: %dx (%dx multiplier)", combo_count, combo_multiplier), 10, 34)
        end
    end

    -- Draw pause overlay
    if self.paused then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("PAUSED", VIRTUAL_WIDTH / 2 - 20, VIRTUAL_HEIGHT / 2 - 10)
        love.graphics.print("Press P to resume", VIRTUAL_WIDTH / 2 - 40, VIRTUAL_HEIGHT / 2 + 5)
    end

    -- Draw game over overlay
    if self.game_over then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.print("TIME'S UP!", VIRTUAL_WIDTH / 2 - 30, VIRTUAL_HEIGHT / 2 - 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("Final Score: %d", self.scoring:getTotal()), VIRTUAL_WIDTH / 2 - 45, VIRTUAL_HEIGHT / 2)
        love.graphics.print("Press ESC to exit", VIRTUAL_WIDTH / 2 - 45, VIRTUAL_HEIGHT / 2 + 20)
    end

    -- Draw win overlay
    if self.game_won then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
        love.graphics.setColor(0.3, 1, 0.3)
        love.graphics.print("ALL DELIVERIES COMPLETE!", VIRTUAL_WIDTH / 2 - 70, VIRTUAL_HEIGHT / 2 - 30)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("Final Score: %d", self.scoring:getTotal()), VIRTUAL_WIDTH / 2 - 45, VIRTUAL_HEIGHT / 2 - 10)
        love.graphics.print(string.format("Time Remaining: %s", self.timer:getFormattedTime()), VIRTUAL_WIDTH / 2 - 60, VIRTUAL_HEIGHT / 2 + 5)
        love.graphics.print("Press ESC to exit", VIRTUAL_WIDTH / 2 - 45, VIRTUAL_HEIGHT / 2 + 25)
    end
end

-- Toggle pause state
function GameState:togglePause()
    if self.game_over or self.game_won then
        return  -- Can't pause during game over/win
    end

    self.paused = not self.paused

    if self.paused then
        self.timer:pause()
        print("[GameState] Game paused")
    else
        self.timer:resume()
        print("[GameState] Game resumed")
    end
end

-- Called when timer expires
function GameState:onTimerExpired()
    print("[GameState] Timer expired - Game Over!")
    self.game_over = true

    -- Transition to ResultsState with lose condition (VETS-31)
    self:transitionToResults(false)
end

-- Called when all deliveries are completed
function GameState:onWinCondition()
    if self.game_won then
        return  -- Already won
    end

    print("[GameState] All deliveries completed - You Win!")
    self.game_won = true

    -- Stop timer
    self.timer:pause()

    -- Award time bonus and completion bonus
    local time_bonus = self.scoring:calculateTimeBonus(self.timer:getTimeRemaining())
    local completion_bonus = self.scoring:awardCompletionBonus()

    print("[GameState] Time Bonus: +" .. time_bonus .. " points")
    print("[GameState] Completion Bonus: +" .. completion_bonus .. " points")
    print("[GameState] Final Score: " .. self.scoring:getTotal())

    -- Transition to ResultsState with win condition (VETS-31)
    self:transitionToResults(true)
end

-- Transition to ResultsState with completion data (VETS-31)
-- @param success: Boolean indicating win (true) or lose (false)
function GameState:transitionToResults(success)
    -- Prepare results data
    local results_data = {
        success = success,
        night_number = self.night_number,
        score = self.scoring:getTotal(),
        time_remaining = self.timer:getTimeRemaining(),
        deliveries_completed = self.completed_deliveries,
        total_deliveries = self.total_deliveries,
        combo_peak = self.scoring:getComboPeak(),
        state_manager = self.state_manager  -- Pass state_manager reference
    }

    print("[GameState] Transitioning to ResultsState...")
    print("[GameState] Results data:")
    print("  - Success: " .. tostring(results_data.success))
    print("  - Score: " .. results_data.score)
    print("  - Combo Peak: x" .. results_data.combo_peak)

    -- Switch to ResultsState if we have a state_manager reference
    if self.state_manager then
        self.state_manager:switch("results", results_data)
    else
        print("[GameState] Warning: No state_manager reference, cannot transition to results")
    end
end

-- Draw UI at native window resolution (high resolution, sharp)
-- Called separately from draw() to render UI outside the low-res canvas
function GameState:drawUI()
    -- Draw HUD (includes moon timer) at native resolution
    if self.hud then
        self.hud:draw()
    end
end

return GameState
