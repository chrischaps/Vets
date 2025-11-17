-- wall.lua
-- Climbable wall entity for wall-sliding and wall-jumping

local Entity = require("src.entities.entity")
local Transform = require("src.components.transform")
local Collision = require("src.components.collision")

local Wall = {}
Wall.__index = Wall

-- Create a new wall entity
-- @param x, y: Position
-- @param width, height: Dimensions
-- @param tileset: Optional Tilemap tileset for rendering (if nil, uses gray rectangles)
function Wall.new(x, y, width, height, tileset)
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
    self.color = {0.2, 0.25, 0.3}  -- Dark gray-blue color for walls (fallback)

    -- Tileset for rendering
    self.tileset = tileset

    -- Generate terrain grid if tileset is provided
    if self.tileset and self.tileset.is_wang then
        self:generateTerrainGrid()
    end

    return self
end

-- Generate terrain grid for Wang tiling
-- Creates a grid filled with wall (upper) terrain
function Wall:generateTerrainGrid()
    if not self.tileset or not self.tileset.tile_size then
        return
    end

    local tile_w = self.tileset.tile_size.width
    local tile_h = self.tileset.tile_size.height

    -- Calculate grid dimensions with padding for Wang tiling coverage
    -- Add 1 extra column to ensure full visual coverage (prevents gaps on edges)
    local grid_width = math.ceil(self.width / tile_w) + 1
    -- For Wang tiling, we need vertices (N+1) not tiles (N)
    -- Example: 64px wall / 16px tiles = 4 tiles, requiring 5 vertices
    local grid_height = math.ceil(self.height / tile_h) + 1

    -- Create terrain grid filled with brick facade (lower terrain)
    -- Walls are vertical surfaces, so they use "lower" (brick facade) not "upper" (rooftop)
    self.terrain_grid = {}
    for row = 1, grid_height do
        self.terrain_grid[row] = {}
        for col = 1, grid_width do
            -- All wall vertices use "lower" (brick facade) terrain
            self.terrain_grid[row][col] = "lower"
        end
    end

    -- Store grid dimensions for reference
    self.grid_width = grid_width
    self.grid_height = grid_height
end

-- Draw wall
function Wall:draw()
    local x = self.transform.x
    local y = self.transform.y
    local w = self.width
    local h = self.height

    -- If tileset is available, use Wang tiling
    if self.tileset and self.tileset.is_wang and self.terrain_grid then
        -- Draw using Wang tileset at the wall's position
        self.tileset:drawWangLayer(self.terrain_grid, x, y, 0, 0)
    else
        -- Fallback: Draw wall as colored rectangle
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", x, y, w, h)

        -- Draw border
        love.graphics.setColor(0.3, 0.35, 0.4)
        love.graphics.rectangle("line", x, y, w, h)
    end

    -- Debug info when F2 is held
    if love.keyboard.isDown("f2") then
        love.graphics.setColor(1, 1, 0)  -- Yellow text
        love.graphics.print(
            string.format("W:%s", self.wall_type),
            x + 2,
            y + 2
        )
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Get entity
function Wall:getEntity()
    return self.entity
end

return Wall
