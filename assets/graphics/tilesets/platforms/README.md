# Platform Tileset

Sidescroller platform tileset for 2D platformer gameplay in Courier Cat.

## Specifications

- **Tile Size:** 16×16 pixels
- **Total Tiles:** 16 platform tiles
- **Format:** Edge-based sidescroller tileset
- **Style:** Single color outline, basic shading, medium detail
- **View:** Side perspective (optimized for 2D platformers)
- **Background:** Transparent (suitable for overlaying on backgrounds)

## Description

- **Platform Material:** Wooden platform planks with iron support brackets
- **Surface Layer:** Moss and overgrown vines on platform edges (0.25 transition)
- **Design:** Flat platform surfaces (no slopes) for solid platformer gameplay

## Files

- `tileset.png` - Sprite sheet containing 16 platform tiles
- `metadata.json` - Tile data with edge types and bounding boxes

## Usage

This sidescroller tileset uses edge-based tiling (not corner-based like Wang):

1. Create level layout grid (1=platform, 0=air)
2. For each platform cell, determine edge configuration
3. Select appropriate tile based on neighboring platforms
4. Extract tile using bounding box coordinates from metadata

### Platform Integration

- Designed for horizontal scrolling 2D platformers
- Transparent background allows background layer composition
- Flat surfaces for precise platformer physics
- Compatible with Unity, Godot, GameMaker, LÖVE

## Collision Properties

- **Platform tiles:** Semi-solid (jump-through from below)
- **Top surface:** Solid, walkable
- **Sides/bottom:** Passable
- **Edge moss:** Visual only, no collision impact

## Tile Types

- Center platform tiles (no edges)
- Left edge tiles
- Right edge tiles
- Single-width platform tiles
- Corner pieces for platform ends

## Base Tile ID

For creating connected/chained tilesets:
- Platform base: `90ee401a-7938-4f05-9561-dbbab518c8cf`

## Generated

- **Tool:** PixelLab MCP
- **Tileset ID:** `a3ff6418-0607-4bbe-8506-ed7ea250410b`
- **Date:** November 2025
