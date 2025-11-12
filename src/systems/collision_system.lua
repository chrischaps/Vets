-- collision_system.lua
-- Collision detection and response system using bump.lua

local bump = require("libraries.bump")

local CollisionSystem = {}
CollisionSystem.__index = CollisionSystem

-- Collision layers (bit flags for filtering)
CollisionSystem.LAYER = {
    PLAYER = 1,
    TERRAIN = 2,
    HAZARD = 4,
    DELIVERY_ZONE = 8,
    POWERUP = 16,
    TRIGGER = 32
}

-- Collision response types
CollisionSystem.RESPONSE = {
    SLIDE = "slide",   -- Slides along surfaces (walls, floors)
    CROSS = "cross",   -- Passes through but detects collision (triggers)
    TOUCH = "touch",   -- Detects collision but doesn't move (sensors)
    BOUNCE = "bounce"  -- Bounces off (future use)
}

-- Create a new collision system
function CollisionSystem.new(cell_size)
    local self = setmetatable({}, CollisionSystem)

    -- Initialize bump world with specified cell size (default 16px)
    self.world = bump.newWorld(cell_size or 16)

    -- Track entities in the world
    self.entities = {}

    -- Collision filter callback
    self.filter = function(item, other)
        -- Get collision layers for both items
        local item_layer = item.collision and item.collision.layer or 0
        local item_mask = item.collision and item.collision.mask or 0
        local other_layer = other.collision and other.collision.layer or 0
        local other_mask = other.collision and other.collision.mask or 0

        -- Check if items should collide based on layer/mask
        -- Item collides with other if: (item_mask & other_layer) != 0
        -- Using bit library (LuaJIT/LÖVE compatibility)
        local item_collides = bit.band(item_mask, other_layer) ~= 0
        local other_collides = bit.band(other_mask, item_layer) ~= 0

        if not (item_collides or other_collides) then
            return nil  -- No collision
        end

        -- Determine collision response type
        -- Default to slide for terrain collisions
        if other_layer == CollisionSystem.LAYER.TERRAIN then
            return CollisionSystem.RESPONSE.SLIDE
        elseif other_layer == CollisionSystem.LAYER.TRIGGER or
               other_layer == CollisionSystem.LAYER.DELIVERY_ZONE then
            return CollisionSystem.RESPONSE.CROSS
        elseif other_layer == CollisionSystem.LAYER.POWERUP then
            return CollisionSystem.RESPONSE.CROSS
        else
            return CollisionSystem.RESPONSE.SLIDE
        end
    end

    return self
end

-- Add an entity to the collision world
function CollisionSystem:add(entity, x, y, w, h)
    if not entity then
        error("CollisionSystem:add - entity is nil")
    end

    -- Add to bump world
    self.world:add(entity, x, y, w, h)

    -- Track entity
    self.entities[entity] = true
end

-- Remove an entity from the collision world
function CollisionSystem:remove(entity)
    if not entity then return end

    -- Remove from bump world
    if self.world:hasItem(entity) then
        self.world:remove(entity)
    end

    -- Stop tracking entity
    self.entities[entity] = nil
end

-- Update an entity's position in the collision world
function CollisionSystem:update(entity, x, y, w, h)
    if not entity or not self.world:hasItem(entity) then
        return x, y, {}, 0
    end

    -- Move entity in bump world with collision detection
    local actual_x, actual_y, cols, len = self.world:move(
        entity,
        x,
        y,
        self.filter
    )

    return actual_x, actual_y, cols, len
end

-- Check for collisions at a position without moving
function CollisionSystem:check(entity, x, y, w, h)
    if not entity or not self.world:hasItem(entity) then
        return x, y, {}, 0
    end

    local actual_x, actual_y, cols, len = self.world:check(
        entity,
        x,
        y,
        self.filter
    )

    return actual_x, actual_y, cols, len
end

-- Query for entities in a rectangular area
function CollisionSystem:queryRect(x, y, w, h, filter)
    local items, len = self.world:queryRect(x, y, w, h, filter)
    return items, len
end

-- Query for entities at a point
function CollisionSystem:queryPoint(x, y, filter)
    local items, len = self.world:queryPoint(x, y, filter)
    return items, len
end

-- Get entity bounds from bump world
function CollisionSystem:getBounds(entity)
    if not entity or not self.world:hasItem(entity) then
        return nil, nil, nil, nil
    end

    return self.world:getRect(entity)
end

-- Check if entity exists in collision world
function CollisionSystem:hasEntity(entity)
    return self.world:hasItem(entity)
end

-- Debug: Draw collision boundaries
function CollisionSystem:debugDraw()
    love.graphics.setColor(0, 1, 0, 0.3)

    -- Draw all collision rectangles
    for entity, _ in pairs(self.entities) do
        if self.world:hasItem(entity) then
            local x, y, w, h = self.world:getRect(entity)
            love.graphics.rectangle("line", x, y, w, h)
        end
    end
end

return CollisionSystem
