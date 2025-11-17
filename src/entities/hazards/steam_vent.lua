-- steam_vent.lua
-- Steam vent hazard that periodically pushes the player upward

local Entity = require("src.entities.entity")
local Transform = require("src.components.transform")
local Collision = require("src.components.collision")

local SteamVent = {}
SteamVent.__index = SteamVent

-- Vent states
SteamVent.STATE = {
    COOLDOWN = "cooldown",  -- Inactive, no visual effect
    WARNING = "warning",    -- Red glow before steam
    ACTIVE = "active"       -- Steam puff, applying upward force
}

-- Create a new steam vent
function SteamVent.new(x, y, width, height)
    local self = setmetatable({}, SteamVent)

    -- Create base entity
    self.entity = Entity.new("steam_vent")

    -- Add Transform component (center-based positioning)
    self.transform = Transform.new(x, y)
    self.entity:addComponent("transform", self.transform)

    -- Add Collision component (trigger, non-solid)
    self.collision = Collision.new(width or 16, height or 16, Collision.SHAPE.AABB)
    self.collision:setLayer(Collision.LAYER.HAZARD)
    self.collision:setMask(Collision.LAYER.PLAYER)  -- Only interact with player
    self.collision:setTrigger(true)  -- Non-solid, players can pass through
    self.entity:addComponent("collision", self.collision)

    -- Store dimensions for easy access
    self.width = width or 16
    self.height = height or 16

    -- State machine
    self.state = SteamVent.STATE.COOLDOWN
    self.state_timer = 0

    -- Timing configuration (from JIRA spec)
    self.cooldown_duration = 1.5  -- seconds
    self.warning_duration = 0.5   -- seconds (red glow)
    self.active_duration = 1.0    -- seconds (steam puff)

    -- Force configuration
    self.upward_force = 300  -- pixels/second (applied to player velocity)

    -- Visual effects
    self.warning_color = {1, 0.2, 0.2}  -- Red warning glow
    self.steam_color = {0.9, 0.9, 1}    -- Light blue steam
    self.vent_color = {0.3, 0.3, 0.35}  -- Dark gray vent base

    -- Warning glow animation
    self.glow_intensity = 0  -- 0-1 range
    self.glow_pulse_speed = 8  -- Pulses per second during warning

    -- Steam particles
    self.steam_particles = {}  -- Array of active steam particles
    self.steam_spawn_rate = 0.05  -- Spawn particle every 0.05 seconds
    self.steam_spawn_timer = 0
    self.steam_particle_lifetime = 0.8  -- seconds

    return self
end

-- Update steam vent state machine and effects
function SteamVent:update(dt)
    -- Update state timer
    self.state_timer = self.state_timer + dt

    -- State machine transitions
    if self.state == SteamVent.STATE.COOLDOWN then
        if self.state_timer >= self.cooldown_duration then
            self:transitionToWarning()
        end
        self.glow_intensity = 0

    elseif self.state == SteamVent.STATE.WARNING then
        if self.state_timer >= self.warning_duration then
            self:transitionToActive()
        end
        -- Pulse warning glow
        local pulse_phase = self.state_timer * self.glow_pulse_speed * math.pi * 2
        self.glow_intensity = (math.sin(pulse_phase) + 1) / 2  -- Range: 0-1

    elseif self.state == SteamVent.STATE.ACTIVE then
        if self.state_timer >= self.active_duration then
            self:transitionToCooldown()
        end
        self.glow_intensity = 0

        -- Spawn steam particles
        self.steam_spawn_timer = self.steam_spawn_timer + dt
        if self.steam_spawn_timer >= self.steam_spawn_rate then
            self.steam_spawn_timer = 0
            self:spawnSteamParticle()
        end
    end

    -- Update steam particles
    for i = #self.steam_particles, 1, -1 do
        local particle = self.steam_particles[i]
        particle.timer = particle.timer + dt

        -- Move particle upward with some horizontal drift
        particle.x = particle.x + (particle.vx * dt)
        particle.y = particle.y + (particle.vy * dt)

        -- Fade out and expand
        particle.alpha = 1 - (particle.timer / particle.lifetime)
        particle.size = particle.initial_size * (1 + particle.timer / particle.lifetime)

        -- Remove expired particles
        if particle.timer >= particle.lifetime then
            table.remove(self.steam_particles, i)
        end
    end
end

-- Transition to WARNING state
function SteamVent:transitionToWarning()
    self.state = SteamVent.STATE.WARNING
    self.state_timer = 0
    print(string.format("[SteamVent] Vent at (%.1f, %.1f) entering WARNING state",
        self.transform.x, self.transform.y))
end

-- Transition to ACTIVE state
function SteamVent:transitionToActive()
    self.state = SteamVent.STATE.ACTIVE
    self.state_timer = 0
    print(string.format("[SteamVent] Vent at (%.1f, %.1f) entering ACTIVE state - steam puff!",
        self.transform.x, self.transform.y))
end

-- Transition to COOLDOWN state
function SteamVent:transitionToCooldown()
    self.state = SteamVent.STATE.COOLDOWN
    self.state_timer = 0
    -- Clear steam particles when transitioning to cooldown
    self.steam_particles = {}
    print(string.format("[SteamVent] Vent at (%.1f, %.1f) entering COOLDOWN state",
        self.transform.x, self.transform.y))
end

-- Spawn a steam particle
function SteamVent:spawnSteamParticle()
    local particle = {
        -- Position (relative to vent center)
        x = (math.random() - 0.5) * self.width * 0.6,  -- Spawn across vent width
        y = -self.height / 2,  -- Start at top of vent

        -- Velocity
        vx = (math.random() - 0.5) * 20,  -- Small horizontal drift
        vy = -60 - math.random() * 20,    -- Upward velocity (60-80 px/s)

        -- Visual properties
        initial_size = 2 + math.random() * 2,  -- 2-4 pixels
        size = 2,
        alpha = 1,

        -- Lifetime
        timer = 0,
        lifetime = self.steam_particle_lifetime
    }
    table.insert(self.steam_particles, particle)
end

-- Check if player is in vent zone and apply upward force
-- Returns true if force was applied
function SteamVent:checkPlayerContact(player_x, player_y, player_physics)
    -- Only apply force during ACTIVE state
    if self.state ~= SteamVent.STATE.ACTIVE then
        return false
    end

    -- Check if player is overlapping with vent AABB
    local vent_left = self.transform.x - self.width / 2
    local vent_right = self.transform.x + self.width / 2
    local vent_top = self.transform.y - self.height / 2
    local vent_bottom = self.transform.y + self.height / 2

    -- Simple AABB overlap check
    if player_x >= vent_left and player_x <= vent_right and
       player_y >= vent_top and player_y <= vent_bottom then
        -- Apply upward force by setting player's upward velocity
        -- This overrides gravity temporarily, creating the "push" effect
        if player_physics then
            player_physics.velocity_y = -self.upward_force
            print(string.format("[SteamVent] Pushing player up with force %.1f", self.upward_force))
            return true
        end
    end

    return false
end

-- Draw steam vent
function SteamVent:draw()
    local x = self.transform.x
    local y = self.transform.y
    local w = self.width
    local h = self.height

    -- Draw vent base (always visible)
    love.graphics.setColor(self.vent_color)
    love.graphics.rectangle("fill", x - w/2, y - h/2, w, h)

    -- Draw vent grate lines
    love.graphics.setColor(0.2, 0.2, 0.25)
    for i = 1, 3 do
        local line_y = y - h/2 + (i * h / 4)
        love.graphics.line(x - w/2, line_y, x + w/2, line_y)
    end

    -- Draw warning glow (during WARNING state)
    if self.state == SteamVent.STATE.WARNING then
        love.graphics.setColor(
            self.warning_color[1],
            self.warning_color[2],
            self.warning_color[3],
            self.glow_intensity * 0.6
        )
        love.graphics.rectangle("fill", x - w/2, y - h/2, w, h)

        -- Draw outer warning glow
        love.graphics.setColor(
            self.warning_color[1],
            self.warning_color[2],
            self.warning_color[3],
            self.glow_intensity * 0.3
        )
        local glow_expand = 4 * self.glow_intensity
        love.graphics.rectangle("fill",
            x - w/2 - glow_expand,
            y - h/2 - glow_expand,
            w + glow_expand * 2,
            h + glow_expand * 2)
    end

    -- Draw steam particles (during ACTIVE state)
    for _, particle in ipairs(self.steam_particles) do
        local particle_x = x + particle.x
        local particle_y = y + particle.y

        love.graphics.setColor(
            self.steam_color[1],
            self.steam_color[2],
            self.steam_color[3],
            particle.alpha * 0.7
        )
        love.graphics.circle("fill", particle_x, particle_y, particle.size)
    end

    -- Debug: Draw collision box (if F2 is held)
    if love.keyboard.isDown("f2") then
        love.graphics.setColor(1, 0, 0, 0.3)
        love.graphics.rectangle("line", x - w/2, y - h/2, w, h)

        -- Draw state text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(self.state, x - w/2, y - h/2 - 10)
    end
end

-- Get entity
function SteamVent:getEntity()
    return self.entity
end

-- Destroy steam vent
function SteamVent:destroy()
    self.steam_particles = {}
    self.entity:destroy()
end

return SteamVent
