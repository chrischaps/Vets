-- platform.lua
-- Static platform entity for collision testing

local Entity = require("src.entities.entity")
local Transform = require("src.components.transform")
local Collision = require("src.components.collision")

local Platform = {}
Platform.__index = Platform

-- Create a new platform entity
-- @param x, y: Position
-- @param width, height: Dimensions
-- @param tileset: Optional Tilemap tileset for rendering (if nil, uses gray rectangles)
function Platform.new(x, y, width, height, tileset)
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
    self.color = {0.3, 0.3, 0.4}  -- Gray color for platforms (fallback)

    -- Tileset for rendering
    self.tileset = tileset

    -- Generate terrain grid if tileset is provided
    if self.tileset and self.tileset.is_wang then
        self:generateTerrainGrid()
    end

    return self
end

-- Generate terrain grid for Wang tiling
-- Creates a grid with rooftop tiles on platform surface and wall tiles extending down
function Platform:generateTerrainGrid()
    if not self.tileset or not self.tileset.tile_size then
        return
    end

    local tile_w = self.tileset.tile_size.width
    local tile_h = self.tileset.tile_size.height

    -- Calculate grid dimensions
    -- Grid width: number of tiles horizontally
    local grid_width = math.ceil(self.width / tile_w)

    -- Grid height: 1 row for platform top + rows extending down to bottom of screen
    -- Virtual resolution is 320x180, so calculate rows needed to reach y=180
    local screen_bottom = 180
    local platform_bottom = self.transform.y + self.height
    local pixels_below = math.max(0, screen_bottom - platform_bottom)
    local rows_below = math.ceil(pixels_below / tile_h) + 2  -- +2 for extra coverage
    local grid_height = 1 + rows_below

    -- Create terrain grid
    self.terrain_grid = {}
    for row = 1, grid_height do
        self.terrain_grid[row] = {}
        for col = 1, grid_width do
            if row == 1 then
                -- First row: rooftop (lower terrain)
                self.terrain_grid[row][col] = "lower"
            else
                -- Rows below: wall/building (upper terrain)
                self.terrain_grid[row][col] = "upper"
            end
        end
    end

    -- Store grid dimensions for reference
    self.grid_width = grid_width
    self.grid_height = grid_height
end

-- Draw platform
function Platform:draw()
    local x = self.transform.x
    local y = self.transform.y
    local w = self.width
    local h = self.height

    -- Debug: Print first platform draw position when F2 is held
    if love.keyboard.isDown("f2") and self.width == 160 then  -- Ground platform
        print(string.format("[Platform] Ground at: (%.1f, %.1f) size: %dx%d", x, y, w, h))
    end

    -- If tileset is available, use Wang tiling
    if self.tileset and self.tileset.is_wang and self.terrain_grid then
        -- Draw using Wang tileset
        -- Offset to align with platform position
        self.tileset:drawWangLayer(self.terrain_grid, x, y, 0, 0)
    else
        -- Fallback: Draw platform as colored rectangle
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", x, y, w, h)

        -- Draw border
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.rectangle("line", x, y, w, h)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

-- Get entity
function Platform:getEntity()
    return self.entity
end

return Platform
