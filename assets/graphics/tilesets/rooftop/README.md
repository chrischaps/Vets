# Rooftop Tileset

Top-down Wang tileset for rooftop terrain in Courier Cat.

## Specifications

- **Tile Size:** 16×16 pixels
- **Total Tiles:** 16 tiles in 4×4 grid
- **Format:** Wang tileset (corner-based autotiling)
- **Style:** Single color outline, basic shading, medium detail
- **View:** High top-down perspective

## Description

- **Lower Terrain:** Dark slate rooftop tiles with subtle texture
- **Upper Terrain:** Brick parapet wall edge with weathered mortar
- **Transition:** Crumbling edge where roof meets wall (0.5 transition size)

## Files

- `tileset.png` - 64×64px sprite sheet containing 16 tiles
- `metadata.json` - Tile data with Wang corner types and bounding boxes

## Usage

This is a Wang tileset designed for corner-based autotiling:

1. Create a terrain grid with vertices (0=lower/roof, 1=upper/wall)
2. For each map cell, sample 4 corner values (NW, NE, SW, SE)
3. Match the corner pattern to a tile in metadata.json
4. Extract tile from sprite sheet using bounding box coordinates

### Wang Corners

Each tile has 4 corners (NW, NE, SW, SE) with terrain types:
- `"lower"` - Dark slate rooftop
- `"upper"` - Brick parapet wall

### Metadata Structure

```json
{
  "format": "tileset15",
  "tiles": [
    {
      "id": "13",
      "corners": {"NE": "upper", "NW": "upper", "SE": "upper", "SW": "lower"},
      "bounding_box": {"x": 0, "y": 0, "width": 16, "height": 16}
    }
    // ... 15 more tiles
  ]
}
```

## Collision Properties

- **Rooftop tiles (lower):** Solid, walkable
- **Wall tiles (upper):** Solid, wall-slideable
- **Transition tiles:** Solid, walkable with edge collision

## Base Tile IDs

For creating connected/chained tilesets:
- Lower (rooftop): `00fbb26d-2fe8-4473-84ac-fceefebd94d0`
- Upper (wall): `e57e85e5-6b17-4329-8e53-2d3f414f7d44`

## Generated

- **Tool:** PixelLab MCP
- **Tileset ID:** `70095e58-3243-47f6-8941-03150a5189e4`
- **Date:** November 2025
