-- transform.lua
-- Transform component for entity position, rotation, scale, and rendering order

local Transform = {}
Transform.__index = Transform

-- Create a new Transform component
function Transform.new(x, y, rotation, scale_x, scale_y, z_index)
    local self = setmetatable({}, Transform)

    -- Position in world space
    self.x = x or 0
    self.y = y or 0

    -- Rotation in radians
    self.rotation = rotation or 0

    -- Scale
    self.scale_x = scale_x or 1
    self.scale_y = scale_y or 1

    -- Z-index for rendering order (higher values render on top)
    self.z_index = z_index or 0

    -- Reference to owner entity (set by Entity:addComponent)
    self.owner = nil

    return self
end

-- Set position
function Transform:setPosition(x, y)
    self.x = x
    self.y = y
end

-- Get position
function Transform:getPosition()
    return self.x, self.y
end

-- Translate (move by offset)
function Transform:translate(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end

-- Set rotation (in radians)
function Transform:setRotation(rotation)
    self.rotation = rotation
end

-- Get rotation
function Transform:getRotation()
    return self.rotation
end

-- Rotate by angle (in radians)
function Transform:rotate(angle)
    self.rotation = self.rotation + angle
end

-- Set scale
function Transform:setScale(scale_x, scale_y)
    self.scale_x = scale_x
    self.scale_y = scale_y or scale_x  -- If only one value provided, use it for both
end

-- Get scale
function Transform:getScale()
    return self.scale_x, self.scale_y
end

-- Set z-index
function Transform:setZIndex(z_index)
    self.z_index = z_index
end

-- Get z-index
function Transform:getZIndex()
    return self.z_index
end

return Transform
