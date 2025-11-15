-- coffee.lua
-- Coffee power-up that increases player run speed by 50% for 15 seconds

local PowerUp = require("src.entities.powerup")

local Coffee = {}
Coffee.__index = Coffee

-- Create a new coffee power-up
-- @param x: X position
-- @param y: Y position
-- @param respawn_enabled: Whether power-up should respawn after use (optional, default: false)
function Coffee.new(x, y, respawn_enabled)
    -- Coffee power-up configuration
    local DURATION = 15  -- 15 second duration
    local SPEED_MULTIPLIER = 1.5  -- 50% speed boost (120 → 180)

    -- Effect callback: Apply speed boost when collected
    local function applySpeedBoost(player, powerup)
        -- Store original run speed
        powerup.effect_data.original_run_speed = player.physics.max_velocity_x

        -- Apply 50% speed boost
        player.physics.max_velocity_x = player.physics.max_velocity_x * SPEED_MULTIPLIER

        -- Change player color to indicate coffee effect (brownish tint)
        powerup.effect_data.original_color = {player.color[1], player.color[2], player.color[3]}
        player.color = {0.6, 0.4, 0.2}  -- Brown/coffee color tint

        print(string.format("[Coffee] Speed boost applied! Run speed: %.1f → %.1f px/s",
            powerup.effect_data.original_run_speed, player.physics.max_velocity_x))
    end

    -- Remove callback: Revert speed boost when expired
    local function removeSpeedBoost(player, powerup)
        -- Restore original run speed
        if powerup.effect_data.original_run_speed then
            player.physics.max_velocity_x = powerup.effect_data.original_run_speed

            print(string.format("[Coffee] Speed boost expired. Run speed restored to %.1f px/s",
                player.physics.max_velocity_x))
        end

        -- Restore original player color
        if powerup.effect_data.original_color then
            player.color = powerup.effect_data.original_color
        end
    end

    -- Create base PowerUp with coffee configuration
    local self = PowerUp.new(x, y, "coffee", DURATION, applySpeedBoost, removeSpeedBoost)

    -- Override visuals for coffee aesthetic
    self.base_color = {0.4, 0.25, 0.15}  -- Dark brown (coffee)
    self.glow_color = {0.8, 0.6, 0.3}  -- Warm cream glow

    -- Increase size slightly (coffee cup is bigger than generic power-up)
    self.width = 14
    self.height = 14

    -- Coffee-specific visual data for rendering
    self.coffee_data = {
        cup_color = {0.9, 0.85, 0.75},  -- Light cream (cup)
        coffee_color = {0.3, 0.15, 0.1},  -- Dark coffee liquid
        steam_particles = {}  -- Array of steam particles {x, y, alpha, age}
    }

    -- Steam particle system
    self.steam_spawn_timer = 0
    self.steam_spawn_rate = 0.15  -- Spawn steam particle every 0.15 seconds

    -- Respawn configuration
    if respawn_enabled then
        self.can_respawn = true
        self.respawn_delay = 30  -- 30 second respawn
    end

    -- Override update to add steam particles
    local original_update = self.update
    function self:update(dt)
        -- Call original update
        original_update(self, dt)

        -- Only spawn steam when in IDLE state
        if self.state == PowerUp.STATE.IDLE then
            self.steam_spawn_timer = self.steam_spawn_timer + dt

            -- Spawn new steam particles
            if self.steam_spawn_timer >= self.steam_spawn_rate then
                self.steam_spawn_timer = 0

                -- Create steam particle
                table.insert(self.coffee_data.steam_particles, {
                    x = self.transform.x + math.random(-2, 2),  -- Random horizontal offset
                    y = self.transform.y - self.height / 2,  -- Start at top of cup
                    alpha = 0.8,  -- Start fairly opaque
                    age = 0,  -- Age in seconds
                    velocity_y = -15,  -- Rise speed (pixels per second)
                    velocity_x = math.random(-5, 5)  -- Slight horizontal drift
                })
            end

            -- Update steam particles
            for i = #self.coffee_data.steam_particles, 1, -1 do
                local particle = self.coffee_data.steam_particles[i]

                particle.age = particle.age + dt
                particle.y = particle.y + particle.velocity_y * dt
                particle.x = particle.x + particle.velocity_x * dt
                particle.alpha = particle.alpha - dt * 0.8  -- Fade out over ~1 second

                -- Remove particle if faded out or too old
                if particle.alpha <= 0 or particle.age > 1.5 then
                    table.remove(self.coffee_data.steam_particles, i)
                end
            end
        end
    end

    -- Override draw to render coffee cup with steam
    local original_draw = self.draw
    function self:draw()
        local x = self.transform.x
        local y = self.transform.y + self.visual_offset_y

        -- Only draw in IDLE and COLLECTED states
        if self.state == PowerUp.STATE.IDLE or self.state == PowerUp.STATE.COLLECTED then
            -- Draw glow/aura (outer ring)
            if self.state == PowerUp.STATE.IDLE then
                love.graphics.setColor(
                    self.glow_color[1],
                    self.glow_color[2],
                    self.glow_color[3],
                    self.glow_intensity * 0.4
                )
                local glow_expand = 3 + self.glow_intensity * 2
                love.graphics.circle(
                    "fill",
                    x,
                    y,
                    (self.width / 2) * self.collected_scale + glow_expand
                )
            end

            -- Draw coffee cup base (circle for cup body)
            love.graphics.setColor(self.coffee_data.cup_color)
            love.graphics.circle(
                "fill",
                x,
                y,
                (self.width / 2) * self.collected_scale
            )

            -- Draw coffee liquid inside cup (smaller dark circle)
            love.graphics.setColor(self.coffee_data.coffee_color)
            love.graphics.circle(
                "fill",
                x,
                y + 1,  -- Slightly below center
                (self.width / 3) * self.collected_scale
            )

            -- Draw cup handle (small arc on the right side)
            if self.state == PowerUp.STATE.IDLE then
                love.graphics.setColor(self.coffee_data.cup_color)
                love.graphics.setLineWidth(1)
                love.graphics.arc(
                    "line",
                    "open",
                    x + (self.width / 2) - 1,
                    y,
                    3 * self.collected_scale,
                    -math.pi / 2,
                    math.pi / 2
                )
            end

            -- Draw steam particles (only in IDLE state)
            if self.state == PowerUp.STATE.IDLE then
                for _, particle in ipairs(self.coffee_data.steam_particles) do
                    love.graphics.setColor(0.9, 0.9, 0.9, particle.alpha * 0.5)
                    love.graphics.circle("fill", particle.x, particle.y, 1.5)
                end
            end

            -- Draw inner highlight on cup
            love.graphics.setColor(1, 1, 1, 0.6 * self.collected_scale)
            love.graphics.circle(
                "fill",
                x - 2,
                y - 2,
                (self.width / 4) * self.collected_scale
            )
        end

        -- Debug: Draw collision box (if F2 is held)
        if love.keyboard.isDown("f2") then
            love.graphics.setColor(0, 1, 0, 0.3)
            love.graphics.rectangle(
                "line",
                x - self.width / 2,
                y - self.height / 2,
                self.width,
                self.height
            )

            -- Draw state text
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(
                "Coffee " .. self.state .. " (" .. string.format("%.1f", self.effect_timer) .. "s)",
                x - self.width / 2,
                y - self.height / 2 - 10
            )
        end
    end

    return self
end

return Coffee
