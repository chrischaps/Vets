-- platform.lua
-- Static platform entity for collision testing

local Entity = require("src.entities.entity")
local Transform = require("src.components.transform")
local Collision = require("src.components.collision")

local Platform = {}
Platform.__index = Platform

-- Create a new platform entity
function Platform.new(x, y, width, height)
    local self = setmetatable({}, Platform)

    -- Create base entity
    self.entity = Entity.new("platform")

    -- Add Transform component
    self.transform = Transform.new(x, y)
    self.entity:addComponent("transform", self.transform)

    -- Add Collision component
    self.collision = Collision.new(width, height, Collision.SHAPE.AABB)
    self.collision:setLayer(Collision.LAYER.TERRAIN)
    self.collision:setMask(Collision.LAYER.NONE)  -- Platforms don't move, so no mask needed
    self.entity:addComponent("collision", self.collision)

    -- Store dimensions for easy access
    self.width = width
    self.height = height

    -- Visual representation
    self.color = {0.3, 0.3, 0.4}  -- Gray color for platforms

    return self
end

-- Draw platform
function Platform:draw()
    local x = self.transform.x
    local y = self.transform.y
    local w = self.width
    local h = self.height

    -- Draw platform as colored rectangle
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Draw border
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", x, y, w, h)
end

-- Get entity
function Platform:getEntity()
    return self.entity
end

return Platform
