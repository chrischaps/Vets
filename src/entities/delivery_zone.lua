-- delivery_zone.lua
-- Delivery zone entity where players deliver letters

local Entity = require("src.entities.entity")
local Transform = require("src.components.transform")
local Collision = require("src.components.collision")

local DeliveryZone = {}
DeliveryZone.__index = DeliveryZone

-- Create a new delivery zone
function DeliveryZone.new(x, y, collision_system)
    local self = setmetatable({}, DeliveryZone)

    -- Store collision system reference
    self.collision_system = collision_system

    -- Create base entity
    self.entity = Entity.new("delivery_zone")

    -- Add Transform component
    self.transform = Transform.new(x or 160, y or 90)
    self.entity:addComponent("transform", self.transform)

    -- Add Collision component (for visual/structural purposes only)
    -- Delivery zones use distance-based detection, not bump.lua collision
    -- This component exists for consistency but doesn't interact with physics
    self.collision = Collision.new(32, 32, Collision.SHAPE.AABB)
    self.collision:setLayer(Collision.LAYER.DELIVERY_ZONE)
    self.collision:setMask(Collision.LAYER.NONE)  -- No collision mask - zones are non-physical
    self.collision:setTrigger(true)  -- Non-solid
    self.entity:addComponent("collision", self.collision)

    -- Animation state
    self.glow_timer = 0  -- Timer for glow pulse animation
    self.glow_cycle_time = 0.8  -- Glow pulse cycle duration (seconds)
    self.base_glow_alpha = 0.6  -- Base glow opacity

    -- Proximity detection
    self.proximity_range = 48  -- Range to brighten when player is near (pixels)
    self.player_nearby = false  -- Is player within proximity range?
    self.player_in_zone = false  -- Is player inside delivery zone?
    self.proximity_brightness = 0  -- Additional brightness from proximity (0-1)

    -- Visual representation
    self.base_color = {1, 0.9, 0.4}  -- Warm yellow/gold color for window glow
    self.glow_color = {1, 1, 0.8}  -- Brighter glow color

    -- Note: Delivery zones are NOT registered with the collision system
    -- They use distance-based detection for proximity and delivery prompts
    -- This prevents them from interfering with player physics

    return self
end

-- Update delivery zone (animation and proximity detection)
function DeliveryZone:update(dt, player_x, player_y)
    -- Update glow pulse animation
    self.glow_timer = self.glow_timer + dt
    if self.glow_timer >= self.glow_cycle_time then
        self.glow_timer = self.glow_timer - self.glow_cycle_time
    end

    -- Calculate proximity to player (if player position provided)
    if player_x and player_y then
        local dx = player_x - self.transform.x
        local dy = player_y - self.transform.y
        local distance = math.sqrt(dx * dx + dy * dy)

        -- Check if player is nearby (within proximity range)
        self.player_nearby = distance <= self.proximity_range

        -- Calculate proximity brightness (inverse of distance, 0-1 range)
        if self.player_nearby then
            -- Smoothly increase brightness as player gets closer
            -- At max range (48px): brightness = 0
            -- At center (0px): brightness = 1
            self.proximity_brightness = 1 - (distance / self.proximity_range)
        else
            self.proximity_brightness = 0
        end

        -- Check if player is in delivery zone (within collision radius)
        -- Using 16px (half of 32px collision box) as the zone radius
        self.player_in_zone = distance <= 16
    end
end

-- Get glow alpha based on animation cycle
function DeliveryZone:getGlowAlpha()
    -- Use sine wave for smooth pulsing animation
    -- Oscillates between base_glow_alpha and 1.0
    local pulse_phase = (self.glow_timer / self.glow_cycle_time) * 2 * math.pi
    local pulse_value = (math.sin(pulse_phase) + 1) / 2  -- Range: 0-1
    local glow_alpha = self.base_glow_alpha + (1 - self.base_glow_alpha) * pulse_value

    -- Add proximity brightness (more noticeable)
    glow_alpha = math.min(1, glow_alpha + self.proximity_brightness * 0.5)

    return glow_alpha
end

-- Get glow radius multiplier based on proximity
function DeliveryZone:getGlowSize()
    -- Glow expands when player is nearby
    return 1 + (self.proximity_brightness * 0.5)  -- Up to 150% size at max proximity
end

-- Check if player should see delivery prompt
function DeliveryZone:shouldShowPrompt()
    return self.player_in_zone
end

-- Draw delivery zone
function DeliveryZone:draw()
    local x = self.transform.x
    local y = self.transform.y
    local radius = self.collision.width / 2  -- Half of collision box width

    -- Get current glow alpha and size
    local glow_alpha = self:getGlowAlpha()
    local glow_size = self:getGlowSize()

    -- Draw outer glow (larger, more transparent) - grows with proximity
    love.graphics.setColor(
        self.glow_color[1],
        self.glow_color[2],
        self.glow_color[3],
        glow_alpha * 0.3
    )
    love.graphics.circle("fill", x, y, radius * 1.5 * glow_size)

    -- Draw inner glow (smaller, more opaque) - grows with proximity
    love.graphics.setColor(
        self.glow_color[1],
        self.glow_color[2],
        self.glow_color[3],
        glow_alpha * 0.6
    )
    love.graphics.circle("fill", x, y, radius * glow_size)

    -- Draw core (always visible)
    love.graphics.setColor(
        self.base_color[1],
        self.base_color[2],
        self.base_color[3],
        1
    )
    love.graphics.circle("fill", x, y, radius * 0.5)

    -- Draw delivery prompt if player is in zone
    if self:shouldShowPrompt() then
        love.graphics.setColor(1, 1, 1, 1)
        -- Draw simple text prompt instead of Unicode character
        love.graphics.print("E", x - 3, y - 24)
    end

    -- Debug: Draw collision box (if F2 is held)
    if love.keyboard.isDown("f2") then
        love.graphics.setColor(0, 1, 0, 0.3)
        love.graphics.rectangle(
            "line",
            x - self.collision.width / 2,
            y - self.collision.height / 2,
            self.collision.width,
            self.collision.height
        )

        -- Draw proximity range
        love.graphics.setColor(0, 0, 1, 0.2)
        love.graphics.circle("line", x, y, self.proximity_range)
    end
end

-- Get entity
function DeliveryZone:getEntity()
    return self.entity
end

-- Cleanup delivery zone
function DeliveryZone:destroy()
    -- Destroy entity (zones are not registered with collision system)
    self.entity:destroy()
end

return DeliveryZone
