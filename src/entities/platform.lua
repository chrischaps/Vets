-- platform.lua
-- Static platform entity for collision testing

local Entity = require("src.entities.entity")
local Transform = require("src.components.transform")
local Collision = require("src.components.collision")

local Platform = {}
Platform.__index = Platform

-- Class-level window sprites (shared by all platforms)
Platform.window_sprites = nil

-- Load window sprites (called once)
function Platform.loadWindowSprites()
    if not Platform.window_sprites then
        Platform.window_sprites = {
            dark = love.graphics.newImage("assets/graphics/props/window_dark.png"),
            lit = love.graphics.newImage("assets/graphics/props/window_lit.png")
        }
        Platform.window_sprites.dark:setFilter("nearest", "nearest")
        Platform.window_sprites.lit:setFilter("nearest", "nearest")
        print("[Platform] Loaded window sprites")
    end
end

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

    -- Load window sprites if not already loaded
    Platform.loadWindowSprites()

    -- Generate procedural windows
    self:generateWindows()

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
    -- Grid width: number of vertex columns needed to span platform width
    -- For N tiles, we need N+1 vertices (vertices at tile corners)
    local num_tiles_horizontal = math.ceil(self.width / tile_w)
    local grid_width = num_tiles_horizontal + 1  -- No padding - use out-of-bounds sampling

    -- Grid height: 1 row for platform top + rows extending down to fill collision box
    -- Calculate rows needed to span the full height of the platform collision box
    local rows_below = math.ceil(self.height / tile_h)
    local grid_height = 1 + rows_below

    -- Create terrain grid (vertex-based for Wang tiling)
    -- No padding - rely on out-of-bounds sampling for edge context
    self.terrain_grid = {}
    for row = 1, grid_height do
        self.terrain_grid[row] = {}
        for col = 1, grid_width do
            if row == 1 then
                -- First row: all platform surface (upper)
                self.terrain_grid[row][col] = "upper"
            else
                -- Rows below: air/facade (lower)
                self.terrain_grid[row][col] = "lower"
            end
        end
    end

    -- Store grid dimensions for reference
    self.grid_width = grid_width
    self.grid_height = grid_height
end

-- Generate procedural windows on platform facade
function Platform:generateWindows()
    self.windows = {}

    -- Only generate windows if platform is wide and tall enough
    local min_width = 32
    local min_height = 16
    if self.width < min_width or self.height < min_height then
        return
    end

    -- Use platform position as seed for consistent random generation
    local seed = math.floor(self.transform.x) + math.floor(self.transform.y) * 1000
    math.randomseed(seed)

    -- Window spacing and size
    local window_spacing_x = 20  -- Horizontal spacing between windows
    local window_spacing_y = 36  -- Vertical spacing between window rows
    local first_row_offset = 24  -- First row offset from platform top

    -- Generate multiple rows of windows going down the facade
    local y_pos = first_row_offset
    while y_pos < self.height - 8 do
        -- Generate windows across the platform width for this row
        local x_pos = 8 --window_spacing_x / 2
        while x_pos < self.width - 20 do
            -- Randomly choose lit or dark window (30% chance of lit)
            local is_lit = math.random() < 0.3

            table.insert(self.windows, {
                x = x_pos,
                y = y_pos,
                lit = is_lit
            })

            x_pos = x_pos + window_spacing_x
        end

        y_pos = y_pos + window_spacing_y
    end

    -- Restore random seed
    math.randomseed(os.time())
end

-- Draw platform
function Platform:draw()
    local x = self.transform.x
    local y = self.transform.y
    local w = self.width
    local h = self.height

    -- Reset color
    love.graphics.setColor(1, 1, 1)

    -- Debug: Print first platform draw position when F2 is held
    if love.keyboard.isDown("f2") and self.width == 160 then  -- Ground platform
        print(string.format("[Platform] Ground at: (%.1f, %.1f) size: %dx%d", x, y, w, h))
    end

    -- If tileset is available, use Wang tiling
    if self.tileset and self.tileset.is_wang and self.terrain_grid then
        -- Draw using Wang tileset
        -- Offset upward by half tile height so rooftop surface aligns with collision box top
        local tile_w = self.tileset.tile_size and self.tileset.tile_size.width or 16
        local tile_h = self.tileset.tile_size and self.tileset.tile_size.height or 16
        self.tileset:drawWangLayer(self.terrain_grid, x, y - tile_h/2, 0, 0)
    else
        -- Fallback: Draw platform as colored rectangle
        love.graphics.setColor(self.color)
        love.graphics.rectangle("fill", x, y, w, h)

        -- Draw border
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.rectangle("line", x, y, w, h)
    end

    -- Draw windows if available
    if Platform.window_sprites and self.windows then
        love.graphics.setColor(1, 1, 1, 1)
        for _, window in ipairs(self.windows) do
            local sprite = window.lit and Platform.window_sprites.lit or Platform.window_sprites.dark
            love.graphics.draw(sprite, x + window.x, y + window.y)
        end
    end

end

-- Get entity
function Platform:getEntity()
    return self.entity
end

return Platform
