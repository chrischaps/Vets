-- Tilemap Rendering System
-- Supports Wang tilesets (corner-based autotiling) and standard tilesets
-- Loads tileset images and metadata for rendering tile-based levels

local json = require("libraries.json")

local Tilemap = {}
Tilemap.__index = Tilemap

-- Debug mode flag
Tilemap.debug_wang_tiles = false

-- Load a tileset from disk
-- @param tileset_path (string): Path to tileset directory (e.g., "assets/graphics/tilesets/rooftop")
-- @return tileset instance or nil, error
function Tilemap.load(tileset_path)
    local tileset = setmetatable({}, Tilemap)

    -- Load metadata
    local metadata_path = tileset_path .. "/metadata.json"
    local metadata_contents = love.filesystem.read(metadata_path)
    if not metadata_contents then
        return nil, string.format("Failed to load metadata from %s", metadata_path)
    end

    local metadata = json.decode(metadata_contents)
    if not metadata then
        return nil, string.format("Failed to parse JSON from %s", metadata_path)
    end

    tileset.metadata = metadata
    tileset.tile_size = metadata.tile_size or {width = 16, height = 16}
    tileset.tileset_path = tileset_path

    -- Load tileset image
    local image_path = tileset_path .. "/tileset.png"
    local success, image = pcall(love.graphics.newImage, image_path)
    if not success then
        return nil, string.format("Failed to load tileset image from %s: %s", image_path, image)
    end

    tileset.image = image
    tileset.image_width = image:getWidth()
    tileset.image_height = image:getHeight()

    -- Create quads for each tile (for fast rendering)
    tileset.quads = {}
    tileset.tiles_by_id = {}

    if metadata.tileset_data and metadata.tileset_data.tiles then
        for _, tile in ipairs(metadata.tileset_data.tiles) do
            local bbox = tile.bounding_box
            local quad = love.graphics.newQuad(
                bbox.x, bbox.y,
                bbox.width, bbox.height,
                tileset.image_width, tileset.image_height
            )
            tileset.quads[tile.id] = quad
            tileset.tiles_by_id[tile.id] = tile
        end

        print(string.format("[Tilemap] Loaded %d tiles from %s", #metadata.tileset_data.tiles, tileset_path))
    end

    -- Check if this is a Wang tileset (has corner data)
    tileset.is_wang = false
    if metadata.tileset_data and metadata.tileset_data.tiles and #metadata.tileset_data.tiles > 0 then
        local first_tile = metadata.tileset_data.tiles[1]
        if first_tile.corners then
            tileset.is_wang = true
            tileset:buildWangLookupTable()
        end
    end

    return tileset
end

-- Build lookup table for Wang tilesets
-- Maps corner patterns to tile IDs for O(1) lookup
function Tilemap:buildWangLookupTable()
    self.wang_lookup = {}

    for _, tile in ipairs(self.metadata.tileset_data.tiles) do
        if tile.corners then
            -- Create lookup key from corner pattern
            -- Format: "NW_NE_SW_SE" where each value is terrain type
            local key = string.format("%s_%s_%s_%s",
                tile.corners.NW,
                tile.corners.NE,
                tile.corners.SW,
                tile.corners.SE
            )
            self.wang_lookup[key] = tile.id
        end
    end

    print(string.format("[Tilemap] Built Wang lookup table with %d patterns",
        table.count(self.wang_lookup or {})))
end

-- Get tile ID for a Wang tileset based on corner terrains
-- @param nw, ne, sw, se (string): Terrain types for each corner
-- @return tile_id (string) or nil
function Tilemap:getWangTileId(nw, ne, sw, se)
    if not self.is_wang or not self.wang_lookup then
        return nil
    end

    local key = string.format("%s_%s_%s_%s", nw, ne, sw, se)
    return self.wang_lookup[key]
end

-- Draw a single tile at world position
-- @param tile_id (string): Tile ID from metadata
-- @param world_x, world_y (number): World coordinates to draw tile
-- @param camera_x, camera_y (number): Camera offset (optional)
function Tilemap:drawTile(tile_id, world_x, world_y, camera_x, camera_y)
    local quad = self.quads[tile_id]
    if not quad then
        return
    end

    camera_x = camera_x or 0
    camera_y = camera_y or 0

    love.graphics.draw(
        self.image,
        quad,
        world_x - camera_x,
        world_y - camera_y
    )
end

-- Draw a Wang tilemap layer from terrain grid
-- @param terrain_grid (table): 2D array where [y][x] = terrain type ("lower" or "upper")
-- @param offset_x, offset_y (number): World offset for the tilemap
-- @param camera_x, camera_y (number): Camera offset
function Tilemap:drawWangLayer(terrain_grid, offset_x, offset_y, camera_x, camera_y)
    if not self.is_wang then
        print("[Tilemap] Warning: drawWangLayer called on non-Wang tileset")
        return
    end

    offset_x = offset_x or 0
    offset_y = offset_y or 0
    camera_x = camera_x or 0
    camera_y = camera_y or 0

    local tile_w = self.tile_size.width
    local tile_h = self.tile_size.height

    -- Iterate through each cell in the terrain grid
    -- For a vertex grid of size [height][width], there are [height-1][width-1] cells
    local grid_height = #terrain_grid
    local grid_width = terrain_grid[1] and #terrain_grid[1] or 0

    for y = 1, math.max(0, grid_height - 1) do
        for x = 1, math.max(0, grid_width - 1) do
            -- Sample terrain at the 4 corners of this cell
            -- In Wang tiling, corners are shared between adjacent cells
            -- Corner positions: (x, y) is NW, (x+1, y) is NE, (x, y+1) is SW, (x+1, y+1) is SE
            local nw = self:sampleTerrain(terrain_grid, x, y)
            local ne = self:sampleTerrain(terrain_grid, x + 1, y)
            local sw = self:sampleTerrain(terrain_grid, x, y + 1)
            local se = self:sampleTerrain(terrain_grid, x + 1, y + 1)

            -- Get matching tile ID for this corner pattern
            local tile_id = self:getWangTileId(nw, ne, sw, se)

            if tile_id then
                -- Calculate world position for this tile
                local world_x = offset_x + (x - 1) * tile_w
                local world_y = offset_y + (y - 1) * tile_h

                self:drawTile(tile_id, world_x, world_y, camera_x, camera_y)

                -- Draw debug label if enabled
                if Tilemap.debug_wang_tiles then
                    local label = self:getWangDebugLabel(nw, ne, sw, se)
                    local screen_x = world_x - camera_x
                    local screen_y = world_y - camera_y

                    -- Draw semi-transparent background for text
                    love.graphics.setColor(0, 0, 0, 0.6)
                    love.graphics.rectangle("fill", screen_x, screen_y, tile_w, 8)

                    -- Draw label text (larger scale for single-char labels)
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print(label, screen_x + 4, screen_y + 1, 0, 0.8, 0.8)
                    love.graphics.setColor(1, 1, 1, 1) -- Reset color
                end
            end
        end
    end
end

-- Sample terrain value from grid with bounds checking
-- @param grid (table): 2D terrain grid
-- @param x, y (number): Grid coordinates (1-indexed)
-- @return terrain type (string) or "lower" if out of bounds
function Tilemap:sampleTerrain(grid, x, y)
    -- Out of bounds defaults to "lower" terrain
    if y < 1 or y > #grid then
        return "lower"
    end
    if x < 1 or x > #grid[y] then
        return "lower"
    end

    return grid[y][x] or "lower"
end

-- Generate a short debug label for a Wang tile based on corner pattern
-- @param nw, ne, sw, se (string): Corner terrain types
-- @return label (string): Short descriptive label
function Tilemap:getWangDebugLabel(nw, ne, sw, se)
    -- Convert corner pattern to a short label
    -- U = upper, L = lower
    local pattern = string.format("%s%s%s%s",
        nw == "upper" and "U" or "L",
        ne == "upper" and "U" or "L",
        sw == "upper" and "U" or "L",
        se == "upper" and "U" or "L"
    )

    -- Map common patterns to single-character labels
    local labels = {
        ["LLLL"] = ".",        -- All lower = air/background
        ["UUUU"] = "#",        -- All upper = solid platform
        ["UULL"] = "T",        -- Top edge
        ["LLUU"] = "B",        -- Bottom edge (shouldn't appear in sidescroller)
        ["ULUL"] = "L",        -- Left edge
        ["LULU"] = "R",        -- Right edge
        ["ULLL"] = "1",        -- Top-left corner (outer)
        ["LULL"] = "2",        -- Top-right corner (outer)
        ["LLUL"] = "3",        -- Bottom-left corner (outer)
        ["LLLU"] = "4",        -- Bottom-right corner (outer)
        ["LUUL"] = "5",        -- Top-left corner (inner)
        ["ULUL"] = "6",        -- Top-right corner (inner)
        ["UUUL"] = "7",        -- Bottom-left corner (inner)
        ["UULU"] = "8",        -- Bottom-right corner (inner)
    }

    return labels[pattern] or pattern
end

-- Helper function to count table entries (since # doesn't work for non-array tables)
function table.count(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

return Tilemap
