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
local MoonTimer = require("src.ui.moon_timer")
local Constants = require("src.core.constants")

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

    -- Cleanup (future: destroy entities, clear collision system, etc.)
    self.player = nil
    self.platforms = nil
    self.delivery_zones = nil
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

    -- Initialize moon timer UI
    self.moon_timer = MoonTimer.new(self.timer, 280, 20)

    -- Initialize scoring system
    self.scoring = Scoring.new()

    print("[GameState] Systems initialized")
end

-- Load level data for specified night
-- TODO: Load from JSON/Tiled map files in future
-- For now, use hardcoded level from main.lua
function GameState:loadLevel(night_number)
    print("[GameState] Loading level for Night " .. night_number)

    -- Initialize entity arrays
    self.platforms = {}
    self.delivery_zones = {}

    -- Create test level (from main.lua)
    -- Ground platform
    local ground = Platform.new(10, 150, 160, 30)
    table.insert(self.platforms, ground)
    self.collision_system:add(ground, 10, 150, 160, 30)

    -- Elevated platforms
    local p1 = Platform.new(40, 120, 50, 8)
    table.insert(self.platforms, p1)
    self.collision_system:add(p1, 40, 120, 50, 8)

    local p2 = Platform.new(122, 110, 45, 8)
    table.insert(self.platforms, p2)
    self.collision_system:add(p2, 122, 110, 45, 8)

    local p3 = Platform.new(215, 95, 40, 8)
    table.insert(self.platforms, p3)
    self.collision_system:add(p3, 215, 95, 40, 8)

    local p4 = Platform.new(40, 70, 50, 8)
    table.insert(self.platforms, p4)
    self.collision_system:add(p4, 40, 70, 50, 8)

    -- Walls
    local wall_left = Platform.new(5, 30, 8, 90)
    table.insert(self.platforms, wall_left)
    self.collision_system:add(wall_left, 5, 30, 8, 90)

    local wall_right = Platform.new(307, 30, 8, 90)
    table.insert(self.platforms, wall_right)
    self.collision_system:add(wall_right, 307, 30, 8, 90)

    local p5 = Platform.new(120, 50, 45, 8)
    table.insert(self.platforms, p5)
    self.collision_system:add(p5, 120, 50, 45, 8)

    local p6 = Platform.new(180, 35, 40, 8)
    table.insert(self.platforms, p6)
    self.collision_system:add(p6, 180, 35, 40, 8)

    -- Wall-jump combo test area
    local combo_wall_left = Platform.new(250, 20, 8, 120)
    table.insert(self.platforms, combo_wall_left)
    self.collision_system:add(combo_wall_left, 250, 20, 8, 120)

    local combo_wall_right = Platform.new(302, 20, 8, 120)
    table.insert(self.platforms, combo_wall_right)
    self.collision_system:add(combo_wall_right, 302, 20, 8, 120)

    local combo_floor = Platform.new(250, 142, 60, 8)
    table.insert(self.platforms, combo_floor)
    self.collision_system:add(combo_floor, 250, 142, 60, 8)

    -- Create delivery zones
    table.insert(self.delivery_zones, DeliveryZone.new(280, 130, self.collision_system))
    table.insert(self.delivery_zones, DeliveryZone.new(280, 105, self.collision_system))
    table.insert(self.delivery_zones, DeliveryZone.new(280, 80, self.collision_system))
    table.insert(self.delivery_zones, DeliveryZone.new(280, 55, self.collision_system))
    table.insert(self.delivery_zones, DeliveryZone.new(280, 30, self.collision_system))

    -- Create player at spawn point (center of screen)
    local spawn_x = 160
    local spawn_y = 100
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

    -- Initialize camera and set target to player
    self.camera = CameraSystem.new(self.player.transform.x, self.player.transform.y)
    self.camera:setTarget(self.player)
    self.camera:setSmoothing(0.1)

    print("[GameState] Level loaded:")
    print("  - Platforms: " .. #self.platforms)
    print("  - Delivery zones: " .. #self.delivery_zones)
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
    end

    -- Update moon timer visual
    if self.moon_timer then
        self.moon_timer:update(dt)
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

    -- Draw moon timer UI
    if self.moon_timer then
        self.moon_timer:draw()
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

return GameState
