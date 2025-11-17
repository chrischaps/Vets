# Wang Tiling System - Implementation Guide

**Version:** 1.0
**Last Updated:** November 17, 2025
**Game:** Courier Cat
**System:** Tilemap Rendering (src/systems/tilemap.lua)

---

## Table of Contents

1. [Overview](#1-overview)
2. [What is Wang Tiling?](#2-what-is-wang-tiling)
3. [Implementation Architecture](#3-implementation-architecture)
4. [How It Works](#4-how-it-works)
5. [Data Structures](#5-data-structures)
6. [Rendering Pipeline](#6-rendering-pipeline)
7. [Usage Examples](#7-usage-examples)
8. [Debugging](#8-debugging)
9. [Performance Considerations](#9-performance-considerations)
10. [Common Patterns](#10-common-patterns)

---

## 1. Overview

The Wang tiling system in Courier Cat provides seamless autotiling for platformer levels. It uses **corner-based pattern matching** to automatically select the correct tile based on neighboring terrain, eliminating the need for manual tile placement.

**Key Features:**
- Automatic edge and corner detection
- Seamless terrain transitions
- O(1) tile lookup via hash table
- Support for sidescroller and top-down tilesets
- Debug visualization mode

**Use Cases:**
- Rooftop platforms with proper edges and corners
- Wall tiles with smooth transitions
- Any tile-based terrain requiring autotiling

---

## 2. What is Wang Tiling?

Wang tiles (named after mathematician Hao Wang) are a set of square tiles with labeled edges or corners that tile a plane when matching rules are satisfied.

### Corner-Based Wang Tiling

Our implementation uses **corner-based** Wang tiling, where each tile is defined by its four corner values:

```
    NW --- NE          (x,y) --- (x+1,y)
     |     |             |          |
     |     |             |          |
    SW --- SE        (x,y+1) - (x+1,y+1)
```

**Corner Values:**
- `upper`: Solid platform terrain
- `lower`: Air/background

**How It Works:**
1. Define a **vertex grid** where each vertex represents terrain type
2. Each **cell** (tile) is defined by its 4 corner vertices
3. Select the appropriate tile based on the corner pattern

---

## 3. Implementation Architecture

### System Components

```
┌─────────────────────────────────────────┐
│         Tilemap System                  │
│  (src/systems/tilemap.lua)              │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
┌──────▼─────┐   ┌──────▼────────┐
│  Tileset   │   │ Terrain Grid  │
│  Metadata  │   │  (Vertex)     │
└──────┬─────┘   └──────┬────────┘
       │                │
       └────────┬───────┘
                │
         ┌──────▼──────┐
         │ Wang Lookup │
         │   Table     │
         └──────┬──────┘
                │
         ┌──────▼──────┐
         │ Tile Quads  │
         │  (Render)   │
         └─────────────┘
```

### File Structure

```
assets/graphics/tilesets/rooftop/
├── metadata.json       # Tile definitions with corner patterns
├── tileset.png        # Combined tileset image
└── README.md          # Optional documentation
```

---

## 4. How It Works

### Step 1: Vertex Grid Definition

A terrain is defined as a 2D vertex grid where each vertex has a terrain type:

```lua
-- Example: 4x3 vertex grid (creates 3x2 cells)
terrain_grid = {
    {"lower", "lower", "lower", "lower"},  -- y=1
    {"upper", "upper", "upper", "upper"},  -- y=2
    {"upper", "upper", "upper", "upper"},  -- y=3
}
```

**Key Concept:** A grid with `height` rows and `width` columns of vertices creates `(height-1) × (width-1)` cells/tiles.

### Step 2: Corner Sampling

For each cell, we sample terrain at its 4 corners:

```lua
-- Cell at (x=1, y=1)
local nw = terrain_grid[1][1]   -- "lower"
local ne = terrain_grid[1][2]   -- "lower"
local sw = terrain_grid[2][1]   -- "upper"
local se = terrain_grid[2][2]   -- "upper"

-- This creates a "top edge" pattern: lower_lower_upper_upper
```

### Step 3: Tile Lookup

Convert corner pattern to a lookup key:

```lua
local key = string.format("%s_%s_%s_%s", nw, ne, sw, se)
-- Result: "lower_lower_upper_upper"

local tile_id = wang_lookup[key]
-- Returns tile ID for top edge tile
```

### Step 4: Rendering

Draw the selected tile at the cell's world position:

```lua
local world_x = offset_x + (x - 1) * tile_width
local world_y = offset_y + (y - 1) * tile_height

tilemap:drawTile(tile_id, world_x, world_y, camera_x, camera_y)
```

---

## 5. Data Structures

### Tileset Metadata Format

```json
{
    "tile_size": {
        "width": 16,
        "height": 16
    },
    "tileset_data": {
        "tiles": [
            {
                "id": "tile_0_LLLL",
                "bounding_box": {
                    "x": 0,
                    "y": 0,
                    "width": 16,
                    "height": 16
                },
                "corners": {
                    "NW": "lower",
                    "NE": "lower",
                    "SW": "lower",
                    "SE": "lower"
                }
            },
            {
                "id": "tile_1_UUUU",
                "bounding_box": {
                    "x": 16,
                    "y": 0,
                    "width": 16,
                    "height": 16
                },
                "corners": {
                    "NW": "upper",
                    "NE": "upper",
                    "SW": "upper",
                    "SE": "upper"
                }
            }
        ]
    }
}
```

### Terrain Grid Format

```lua
-- Lua 2D array (1-indexed)
-- Rows are Y coordinates, columns are X coordinates
terrain_grid = {
    {terrain, terrain, terrain, ...},  -- y=1
    {terrain, terrain, terrain, ...},  -- y=2
    {terrain, terrain, terrain, ...},  -- y=3
    ...
}

-- where terrain is "upper" or "lower"
```

### Wang Lookup Table

```lua
-- Built at tileset load time
wang_lookup = {
    ["lower_lower_lower_lower"] = "tile_0_LLLL",  -- All air
    ["upper_upper_upper_upper"] = "tile_1_UUUU",  -- All solid
    ["upper_upper_lower_lower"] = "tile_2_UULL",  -- Top edge
    ["lower_upper_lower_lower"] = "tile_3_LULL",  -- Top-right corner
    -- ... all 16 possible combinations
}
```

---

## 6. Rendering Pipeline

### Loading Phase

```lua
-- 1. Load tileset from disk
local tileset = Tilemap.load("assets/graphics/tilesets/rooftop")

-- 2. Metadata is parsed and Wang lookup table is built
-- tileset.wang_lookup contains all corner patterns
```

### Render Phase

```lua
-- 1. Define terrain grid (typically from level data)
local terrain_grid = {
    {"lower", "lower", "lower", "lower"},
    {"upper", "upper", "upper", "upper"},
    {"upper", "upper", "upper", "upper"},
}

-- 2. Render the Wang layer
tileset:drawWangLayer(
    terrain_grid,
    offset_x,     -- World X offset
    offset_y,     -- World Y offset
    camera_x,     -- Camera X position
    camera_y      -- Camera Y position
)
```

### Internal Rendering Loop

```lua
function Tilemap:drawWangLayer(terrain_grid, offset_x, offset_y, camera_x, camera_y)
    local grid_height = #terrain_grid
    local grid_width = #terrain_grid[1]

    -- Iterate cells (height-1 × width-1)
    for y = 1, grid_height - 1 do
        for x = 1, grid_width - 1 do
            -- Sample 4 corners
            local nw = terrain_grid[y][x]
            local ne = terrain_grid[y][x + 1]
            local sw = terrain_grid[y + 1][x]
            local se = terrain_grid[y + 1][x + 1]

            -- Get tile ID
            local tile_id = self:getWangTileId(nw, ne, sw, se)

            -- Calculate world position
            local world_x = offset_x + (x - 1) * tile_width
            local world_y = offset_y + (y - 1) * tile_height

            -- Draw tile
            self:drawTile(tile_id, world_x, world_y, camera_x, camera_y)
        end
    end
end
```

---

## 7. Usage Examples

### Example 1: Simple Platform

```lua
-- Load tileset
local rooftop_tileset = Tilemap.load("assets/graphics/tilesets/rooftop")

-- Define a simple 3-tile-wide platform
local terrain = {
    {"lower", "lower", "lower", "lower"},  -- Air above
    {"upper", "upper", "upper", "upper"},  -- Platform top
    {"upper", "upper", "upper", "upper"},  -- Platform bottom
}

-- Render at world position (100, 100)
function love.draw()
    rooftop_tileset:drawWangLayer(terrain, 100, 100, camera.x, camera.y)
end
```

**Result:** Renders a 3-tile wide platform with proper top edges.

### Example 2: Platform with Corners

```lua
-- Create an L-shaped platform
local terrain = {
    {"lower", "lower", "lower", "lower", "lower"},
    {"lower", "upper", "upper", "upper", "lower"},
    {"lower", "upper", "upper", "upper", "lower"},
    {"lower", "lower", "lower", "upper", "lower"},
}
```

**Result:** Automatically generates:
- Top edges where platform meets air
- Corners at terrain transitions
- Interior solid tiles

### Example 3: Multiple Layers

```lua
-- Layer platforms and walls separately
function love.draw()
    -- Draw platform layer
    platform_tileset:drawWangLayer(platform_grid, 0, 0, camera.x, camera.y)

    -- Draw wall layer (rendered on top)
    wall_tileset:drawWangLayer(wall_grid, 0, 0, camera.x, camera.y)
end
```

---

## 8. Debugging

### Enable Debug Mode

```lua
-- In your code before rendering
Tilemap.debug_wang_tiles = true
```

### Debug Labels

When debug mode is enabled, each tile displays a label indicating its corner pattern:

```
Single-Character Labels:
. = LLLL (all air)
# = UUUU (all solid)
T = UULL (top edge)
L = ULUL (left edge)
R = LULU (right edge)
1 = ULLL (top-left outer corner)
2 = LULL (top-right outer corner)
etc.
```

### Debug Visualization

```lua
-- The debug label appears in the top-left of each tile
-- Black semi-transparent background
-- White text showing corner pattern
```

### Common Debug Scenarios

**All tiles showing ".":**
- Grid is all "lower" terrain
- Check that your grid has "upper" values

**Missing tiles (gaps in rendering):**
- Missing corner pattern in tileset
- Check metadata.json has all 16 combinations

**Tiles offset incorrectly:**
- Check offset_x, offset_y values
- Verify tile_size matches metadata

---

## 9. Performance Considerations

### Optimization Strategies

**1. Lookup Table (O(1) Tile Selection)**
```lua
-- Fast hash table lookup instead of linear search
tile_id = wang_lookup[key]  -- O(1)
```

**2. Quad Caching**
```lua
-- Quads created once at load time
self.quads[tile_id] = love.graphics.newQuad(...)
```

**3. Render Culling (TODO)**
```lua
-- Only render tiles visible in camera view
if tile_x > camera_left and tile_x < camera_right then
    tilemap:drawTile(...)
end
```

**4. Batch Rendering (TODO)**
```lua
-- Use SpriteBatch for static tilesbatch = love.graphics.newSpriteBatch(tileset.image, 1000)
for each tile:
    batch:add(quad, x, y)
batch:flush()
love.graphics.draw(batch)
```

### Performance Metrics

**Current Implementation:**
- Tileset load time: ~10-20ms
- Render time (100 tiles): ~1-2ms
- Memory usage: ~1MB per tileset

**Target Performance:**
- 60 FPS with 500+ tiles on screen
- < 5ms per frame for tilemap rendering

---

## 10. Common Patterns

### 16 Wang Tile Combinations

For 2-terrain Wang tiling (upper/lower), there are exactly **2^4 = 16** possible corner combinations:

```
ID  Pattern  NW NE SW SE  Description
--  -------  -- -- -- --  -----------
0   LLLL     L  L  L  L   Air (all sides)
1   LLLH     L  L  L  H   Bottom-right outer corner
2   LLHL     L  L  H  L   Bottom-left outer corner
3   LLHH     L  L  H  H   Bottom edge
4   LHLL     L  H  L  L   Top-right outer corner
5   LHLH     L  H  L  H   Right edge
6   LHHL     L  H  H  L   Top-right inner corner
7   LHHH     L  H  H  H   Bottom-right inner corner
8   HLLL     H  L  L  L   Top-left outer corner
9   HLLH     H  L  L  H   Top-left inner corner
10  HLHL     H  L  H  L   Left edge
11  HLHH     H  L  H  H   Bottom-left inner corner
12  HHLL     H  H  L  L   Top edge
13  HHLH     H  H  L  H   Top-right inner corner (alt)
14  HHHL     H  H  H  L   Top-left inner corner (alt)
15  HHHH     H  H  H  H   Solid (all sides)

Legend: L=lower, H=upper (or "high")
```

### Visual Pattern Guide

```
Air/Background (LLLL):
  ....
  ....

Solid Center (HHHH):
  ####
  ####

Top Edge (HHLL):
  ####
  ....

Top-Left Outer Corner (HLLL):
  #...
  ....

Top-Right Outer Corner (LHLL):
  ...#
  ....

Top-Left Inner Corner (HLLH):
  #..#
  ....

Top-Right Inner Corner (LHLH):
  ...#
  ...#
```

### Tileset Requirements

**Minimum Required Tiles:**
- 16 tiles (one for each combination)

**Recommended Tileset:**
- 16 base tiles
- Optional: Variations for visual diversity
- Optional: Animated tiles (not yet implemented)

---

## Appendix: Code Reference

### Key Functions

**Loading:**
- `Tilemap.load(tileset_path)` - Load tileset from disk
- `Tilemap:buildWangLookupTable()` - Build pattern lookup table

**Rendering:**
- `Tilemap:drawWangLayer(grid, x, y, cam_x, cam_y)` - Render Wang layer
- `Tilemap:drawTile(tile_id, x, y, cam_x, cam_y)` - Draw single tile

**Utilities:**
- `Tilemap:getWangTileId(nw, ne, sw, se)` - Get tile ID from corners
- `Tilemap:sampleTerrain(grid, x, y)` - Sample terrain with bounds check
- `Tilemap:getWangDebugLabel(nw, ne, sw, se)` - Generate debug label

### File Locations

```
src/systems/tilemap.lua          # Main tilemap system
assets/graphics/tilesets/*/      # Tileset directories
  metadata.json                  # Tile definitions
  tileset.png                    # Combined tile image
```

---

## Future Enhancements

1. **Batch Rendering** - Use SpriteBatch for static tiles
2. **Animated Tiles** - Support for animated corner patterns
3. **3+ Terrain Types** - Extend beyond upper/lower
4. **Tile Variants** - Multiple tiles per pattern for visual variety
5. **Procedural Generation** - Generate tilesets from parameters
6. **Editor Integration** - Visual tileset editor

---

**End of Wang Tiling Implementation Guide**

*For questions or issues, refer to src/systems/tilemap.lua or contact the development team.*
