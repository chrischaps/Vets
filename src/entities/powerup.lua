-- powerup.lua
-- Base power-up entity system that handles collection, effects, and lifecycle

local Entity = require("src.entities.entity")
local Transform = require("src.components.transform")
local Collision = require("src.components.collision")

local PowerUp = {}
PowerUp.__index = PowerUp

-- PowerUp lifecycle states
PowerUp.STATE = {
    IDLE = "idle",          -- Floating/bobbing, waiting to be collected
    COLLECTED = "collected", -- Just collected, transitioning to active
    ACTIVE = "active",      -- Effect applied to player
    EXPIRED = "expired",    -- Effect duration complete
    RESPAWN = "respawn"     -- (Optional) Waiting to respawn
}

-- Create a new power-up
-- @param x: X position
-- @param y: Y position
-- @param powerup_type: Type identifier (e.g., "coffee", "speedboost")
-- @param duration: Effect duration in seconds (default: 15)
-- @param effect_callback: Function(player, powerup) called when collected
-- @param remove_callback: Function(player, powerup) called when expired (optional)
function PowerUp.new(x, y, powerup_type, duration, effect_callback, remove_callback)
    local self = setmetatable({}, PowerUp)

    -- Create base entity
    self.entity = Entity.new("powerup_" .. (powerup_type or "generic"))

    -- Add Transform component (center-based positioning)
    self.transform = Transform.new(x, y)
    self.entity:addComponent("transform", self.transform)

    -- Store dimensions (default 12×12 pixels)
    self.width = 12
    self.height = 12

    -- Add Collision component (trigger, non-solid)
    self.collision = Collision.new(self.width, self.height, Collision.SHAPE.AABB)
    self.collision:setLayer(Collision.LAYER.POWERUP or Collision.LAYER.HAZARD)  -- Use POWERUP layer if available
    self.collision:setMask(Collision.LAYER.PLAYER)  -- Only interact with player
    self.collision:setTrigger(true)  -- Non-solid, players can pass through
    self.entity:addComponent("collision", self.collision)

    -- Power-up configuration
    self.type = powerup_type or "generic"
    self.duration = duration or 15  -- Default 15 seconds
    self.effect_data = {}  -- Type-specific data (extendable)

    -- Lifecycle state
    self.state = PowerUp.STATE.IDLE
    self.collected = false
    self.effect_timer = 0  -- Time remaining for active effect

    -- Callbacks
    self.effect_callback = effect_callback  -- Called when collected
    self.remove_callback = remove_callback  -- Called when effect expires

    -- Collection detection
    self.collection_cooldown = 0  -- Prevent rapid re-collection
    self.player_reference = nil  -- Reference to player who collected this

    -- Floating/bobbing animation
    self.bob_time = 0  -- Time accumulator for animation
    self.bob_amplitude = 3  -- How far it bobs (pixels)
    self.bob_speed = 2  -- How fast it bobs
    self.visual_offset_y = 0  -- Current Y offset from bobbing

    -- Glow/aura effect
    self.glow_time = 0  -- Time accumulator for glow animation
    self.glow_intensity = 0  -- Current glow intensity (0-1)
    self.glow_pulse_speed = 3  -- Pulses per second
    self.glow_color = {1, 1, 0.5}  -- Yellow glow (can be customized per type)

    -- Visual configuration (can be overridden by specific power-up types)
    self.base_color = {0.9, 0.8, 0.3}  -- Base power-up color
    self.collected_scale = 1  -- Visual scale (shrinks when collected)

    -- Respawn configuration (optional)
    self.can_respawn = false
    self.respawn_delay = 30  -- Seconds before respawn
    self.respawn_timer = 0

    return self
end

-- Update power-up state and animations
function PowerUp:update(dt)
    -- Update entity
    self.entity:update(dt)

    -- Update state machine
    if self.state == PowerUp.STATE.IDLE then
        self:updateIdle(dt)

    elseif self.state == PowerUp.STATE.COLLECTED then
        self:updateCollected(dt)

    elseif self.state == PowerUp.STATE.ACTIVE then
        self:updateActive(dt)

    elseif self.state == PowerUp.STATE.EXPIRED then
        self:updateExpired(dt)

    elseif self.state == PowerUp.STATE.RESPAWN then
        self:updateRespawn(dt)
    end

    -- Update collection cooldown
    if self.collection_cooldown > 0 then
        self.collection_cooldown = self.collection_cooldown - dt
    end
end

-- Update IDLE state: floating animation and glow
function PowerUp:updateIdle(dt)
    -- Update bobbing animation
    self.bob_time = self.bob_time + dt
    self.visual_offset_y = math.sin(self.bob_time * self.bob_speed) * self.bob_amplitude

    -- Update glow animation
    self.glow_time = self.glow_time + dt
    local pulse_phase = self.glow_time * self.glow_pulse_speed * math.pi * 2
    self.glow_intensity = (math.sin(pulse_phase) + 1) / 2  -- Range: 0-1
end

-- Update COLLECTED state: transition animation (shrink/fade)
function PowerUp:updateCollected(dt)
    -- Shrink the power-up
    self.collected_scale = self.collected_scale - dt * 3  -- Shrink in ~0.3 seconds

    if self.collected_scale <= 0 then
        -- Transition to ACTIVE state
        self.state = PowerUp.STATE.ACTIVE
        self.effect_timer = self.duration
        print(string.format("[PowerUp] %s effect active for %.1fs", self.type, self.duration))
    end
end

-- Update ACTIVE state: track effect duration
function PowerUp:updateActive(dt)
    -- Countdown effect timer
    self.effect_timer = self.effect_timer - dt

    if self.effect_timer <= 0 then
        -- Effect expired
        self:transitionToExpired()
    end
end

-- Update EXPIRED state: cleanup and optional respawn
function PowerUp:updateExpired(dt)
    -- If respawn is enabled, transition to respawn state
    if self.can_respawn then
        self.state = PowerUp.STATE.RESPAWN
        self.respawn_timer = self.respawn_delay
        print(string.format("[PowerUp] %s will respawn in %.1fs", self.type, self.respawn_delay))
    end
    -- Otherwise, power-up should be removed by external system
end

-- Update RESPAWN state: wait for respawn delay
function PowerUp:updateRespawn(dt)
    self.respawn_timer = self.respawn_timer - dt

    if self.respawn_timer <= 0 then
        -- Respawn the power-up
        self:reset()
        print(string.format("[PowerUp] %s respawned", self.type))
    end
end

-- Check if player collides with power-up and trigger collection
-- Returns true if collected
function PowerUp:checkPlayerContact(player_x, player_y, player_width, player_height)
    -- Only check collection in IDLE state
    if self.state ~= PowerUp.STATE.IDLE then
        return false
    end

    -- Check if cooldown is active
    if self.collection_cooldown > 0 then
        return false
    end

    -- Calculate player bounding box
    local player_left = player_x - player_width / 2
    local player_right = player_x + player_width / 2
    local player_top = player_y - player_height / 2
    local player_bottom = player_y + player_height / 2

    -- Calculate power-up bounding box (with current bob offset)
    local powerup_left = self.transform.x - self.width / 2
    local powerup_right = self.transform.x + self.width / 2
    local powerup_top = self.transform.y + self.visual_offset_y - self.height / 2
    local powerup_bottom = self.transform.y + self.visual_offset_y + self.height / 2

    -- Check for AABB overlap
    local overlaps = player_right > powerup_left and
                     player_left < powerup_right and
                     player_bottom > powerup_top and
                     player_top < powerup_bottom

    return overlaps
end

-- Collect the power-up and apply effect to player
function PowerUp:collect(player)
    if self.state ~= PowerUp.STATE.IDLE then
        return false
    end

    -- Store player reference
    self.player_reference = player

    -- Transition to COLLECTED state
    self.state = PowerUp.STATE.COLLECTED
    self.collected = true
    self.collection_cooldown = 0.5  -- Prevent immediate re-collection

    -- Apply effect via callback
    if self.effect_callback then
        self.effect_callback(player, self)
    end

    print(string.format("[PowerUp] Player collected %s power-up!", self.type))
    return true
end

-- Transition to EXPIRED state and remove effect
function PowerUp:transitionToExpired()
    self.state = PowerUp.STATE.EXPIRED
    self.effect_timer = 0

    -- Remove effect via callback
    if self.remove_callback and self.player_reference then
        self.remove_callback(self.player_reference, self)
    end

    print(string.format("[PowerUp] %s effect expired", self.type))
end

-- Reset power-up to IDLE state (for respawn)
function PowerUp:reset()
    self.state = PowerUp.STATE.IDLE
    self.collected = false
    self.effect_timer = 0
    self.collected_scale = 1
    self.collection_cooldown = 0
    self.player_reference = nil
end

-- Draw power-up
function PowerUp:draw()
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

        -- Draw power-up base (circle)
        love.graphics.setColor(self.base_color)
        love.graphics.circle(
            "fill",
            x,
            y,
            (self.width / 2) * self.collected_scale
        )

        -- Draw inner highlight
        love.graphics.setColor(1, 1, 1, 0.6 * self.collected_scale)
        love.graphics.circle(
            "fill",
            x - 2,
            y - 2,
            (self.width / 4) * self.collected_scale
        )

        -- Draw type icon (placeholder - simple letter)
        if self.state == PowerUp.STATE.IDLE then
            love.graphics.setColor(0.2, 0.2, 0.3, 0.8)
            love.graphics.print(
                string.sub(self.type, 1, 1):upper(),
                x - 3,
                y - 4
            )
        end
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
            self.state .. " (" .. string.format("%.1f", self.effect_timer) .. "s)",
            x - self.width / 2,
            y - self.height / 2 - 10
        )
    end
end

-- Get entity
function PowerUp:getEntity()
    return self.entity
end

-- Check if power-up is active (effect is currently applied)
function PowerUp:isActive()
    return self.state == PowerUp.STATE.ACTIVE
end

-- Get remaining effect time
function PowerUp:getTimeRemaining()
    return self.effect_timer
end

-- Destroy power-up
function PowerUp:destroy()
    -- Remove effect if still active
    if self.state == PowerUp.STATE.ACTIVE and self.remove_callback and self.player_reference then
        self.remove_callback(self.player_reference, self)
    end

    self.player_reference = nil
    self.entity:destroy()
end

return PowerUp
