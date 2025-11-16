-- wall.lua
-- Climbable wall entity for wall-sliding and wall-jumping

local Entity = require("src.entities.entity")
local Transform = require("src.components.transform")
local Collision = require("src.components.collision")

local Wall = {}
Wall.__index = Wall

-- Create a new wall entity
function Wall.new(x, y, width, height)
    local self = setmetatable({}, Wall)

    -- Create base entity
    self.entity = Entity.new("wall")

    -- Add Transform component (top-left positioning like platforms)
    self.transform = Transform.new(x, y)
    self.entity:addComponent("transform", self.transform)

    -- Add Collision component (TERRAIN layer, same as platforms)
    self.collision = Collision.new(width, height, Collision.SHAPE.AABB)
    self.collision:setLayer(Collision.LAYER.TERRAIN)
    self.collision:setMask(Collision.LAYER.NONE)  -- Walls don't move, so no mask needed
    self.entity:addComponent("collision", self.collision)

    -- Store dimensions for easy access
    self.width = width
    self.height = height

    -- Store wall type and properties (set by level loader)
    self.wall_type = "building_wall"  -- Default type
    self.properties = {
        climbable = true,  -- Default: walls are climbable
        friction = 0.8     -- Default friction for wall-sliding
    }

    -- Visual representation (darker color than platforms for distinction)
    self.color = {0.2, 0.25, 0.3}  -- Dark gray-blue color for walls

    return self
end

-- Draw wall
function Wall:draw()
    local x = self.transform.x
    local y = self.transform.y
    local w = self.width
    local h = self.height

    -- Draw wall as colored rectangle
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Draw border
    love.graphics.setColor(0.3, 0.35, 0.4)
    love.graphics.rectangle("line", x, y, w, h)

    -- Debug info when F2 is held
    if love.keyboard.isDown("f2") then
        love.graphics.setColor(1, 1, 0)  -- Yellow text
        love.graphics.print(
            string.format("W:%s", self.wall_type),
            x + 2,
            y + 2
        )
    end
end

-- Get entity
function Wall:getEntity()
    return self.entity
end

return Wall
