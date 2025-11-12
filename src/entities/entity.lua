-- entity.lua
-- Base entity class for the Entity-Component System

local Entity = {}
Entity.__index = Entity

-- Global entity ID counter
local next_entity_id = 1

-- Create a new entity
function Entity.new(entity_type)
    local self = setmetatable({}, Entity)

    -- Unique ID for this entity
    self.id = next_entity_id
    next_entity_id = next_entity_id + 1

    -- Entity type (e.g., "player", "platform", "hazard")
    self.type = entity_type or "entity"

    -- Active state (for object pooling)
    self.active = true

    -- Components table (stores all components attached to this entity)
    self.components = {}

    -- Tags set (for entity queries)
    self.tags = {}

    return self
end

-- Add a component to this entity
function Entity:addComponent(component_name, component)
    self.components[component_name] = component

    -- Set component's owner reference
    if component then
        component.owner = self
    end

    return component
end

-- Get a component by name
function Entity:getComponent(component_name)
    return self.components[component_name]
end

-- Check if entity has a component
function Entity:hasComponent(component_name)
    return self.components[component_name] ~= nil
end

-- Remove a component from this entity
function Entity:removeComponent(component_name)
    local component = self.components[component_name]
    if component then
        component.owner = nil
        self.components[component_name] = nil
    end
    return component
end

-- Add a tag to this entity
function Entity:addTag(tag)
    self.tags[tag] = true
end

-- Remove a tag from this entity
function Entity:removeTag(tag)
    self.tags[tag] = nil
end

-- Check if entity has a tag
function Entity:hasTag(tag)
    return self.tags[tag] == true
end

-- Activate this entity (for object pooling)
function Entity:activate()
    self.active = true
end

-- Deactivate this entity (for object pooling)
function Entity:deactivate()
    self.active = false
end

-- Check if entity is active
function Entity:isActive()
    return self.active
end

-- Update all components (if they have an update method)
function Entity:update(dt)
    if not self.active then return end

    for name, component in pairs(self.components) do
        if component.update then
            component:update(dt)
        end
    end
end

-- Draw all components (if they have a draw method)
function Entity:draw()
    if not self.active then return end

    for name, component in pairs(self.components) do
        if component.draw then
            component:draw()
        end
    end
end

-- Destroy this entity (cleanup)
function Entity:destroy()
    -- Remove all components
    for name, component in pairs(self.components) do
        self:removeComponent(name)
    end

    -- Clear tags
    self.tags = {}

    -- Mark as inactive
    self.active = false
end

return Entity
