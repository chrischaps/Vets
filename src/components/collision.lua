-- collision.lua
-- Collision component for entity collision detection

local Collision = {}
Collision.__index = Collision

-- Collision shape types
Collision.SHAPE = {
    AABB = "aabb",      -- Axis-Aligned Bounding Box (rectangle)
    CIRCLE = "circle",  -- Circle
    POINT = "point"     -- Point (for triggers, pickups, etc.)
}

-- Collision layers (bit flags)
Collision.LAYER = {
    NONE = 0,
    PLAYER = 1,
    TERRAIN = 2,
    HAZARD = 4,
    DELIVERY_ZONE = 8,
    POWERUP = 16,
    TRIGGER = 32,
    ALL = 255
}

-- Create a new Collision component
function Collision.new(width, height, shape_type)
    local self = setmetatable({}, Collision)

    -- Shape type
    self.shape = shape_type or Collision.SHAPE.AABB

    -- Dimensions
    if self.shape == Collision.SHAPE.AABB then
        self.width = width or 16
        self.height = height or 16
    elseif self.shape == Collision.SHAPE.CIRCLE then
        self.radius = width or 8  -- Use width parameter as radius
    else  -- POINT
        self.width = 1
        self.height = 1
    end

    -- Offset from entity position (for fine-tuning hitbox)
    self.offset_x = 0
    self.offset_y = 0

    -- Collision layer (what layer this entity is on)
    self.layer = Collision.LAYER.NONE

    -- Collision mask (what layers this entity collides with)
    self.mask = Collision.LAYER.ALL

    -- Is this a trigger (doesn't block movement, only detects overlaps)?
    self.is_trigger = false

    -- Is this a solid (blocks movement)?
    self.is_solid = true

    -- Reference to owner entity (set by Entity:addComponent)
    self.owner = nil

    return self
end

-- Set collision layer
function Collision:setLayer(layer)
    self.layer = layer
end

-- Set collision mask (what layers to collide with)
function Collision:setMask(mask)
    self.mask = mask
end

-- Check if this collision component collides with a specific layer
function Collision:collidesWithLayer(layer)
    return (bit.band(self.mask, layer)) ~= 0
end

-- Set as trigger (no solid collision, only overlap detection)
function Collision:setTrigger(is_trigger)
    self.is_trigger = is_trigger
    self.is_solid = not is_trigger
end

-- Set offset from entity position
function Collision:setOffset(offset_x, offset_y)
    self.offset_x = offset_x
    self.offset_y = offset_y
end

-- Get collision bounds (for AABB)
function Collision:getBounds(entity_x, entity_y)
    if self.shape == Collision.SHAPE.AABB then
        local x = (entity_x or 0) + self.offset_x
        local y = (entity_y or 0) + self.offset_y
        return x, y, self.width, self.height
    elseif self.shape == Collision.SHAPE.CIRCLE then
        local x = (entity_x or 0) + self.offset_x
        local y = (entity_y or 0) + self.offset_y
        return x, y, self.radius
    else  -- POINT
        local x = (entity_x or 0) + self.offset_x
        local y = (entity_y or 0) + self.offset_y
        return x, y, 1, 1
    end
end

return Collision
