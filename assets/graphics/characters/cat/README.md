# Courier Cat Character Sprites

## Overview

Character sprites for the player character "Courier Cat" - a small cat courier delivering letters across rooftops.

**Generated:** 2025-11-16
**Character ID:** ef4db8a3-6ce1-4831-a8a8-9a4d75e718fc
**Tool:** PixelLab MCP

## Specifications

- **Canvas Size:** 48×48px (character approximately 28px tall, 21px wide)
- **View:** High top-down perspective
- **Directions:** 8 (south, south-east, east, north-east, north, north-west, west, south-west)
- **Art Style:**
  - Single color black outline
  - Basic shading
  - Medium detail level
  - Pixel art style

## Character Features

- **Small cat** with courier theme
- **Mail bag** on back
- **Large expressive eyes**
- **Prominent tail** (key feature for idle animations)
- **Warm sunset color palette** featuring purples, oranges, and pinks

## Files

### Rotation Sprites
All sprites are 48×48px PNG files with transparency:

- `rotations/south.png` - Facing down/toward camera
- `rotations/south-east.png` - Diagonal facing
- `rotations/east.png` - Facing right
- `rotations/north-east.png` - Diagonal facing
- `rotations/north.png` - Facing up/away from camera
- `rotations/north-west.png` - Diagonal facing
- `rotations/west.png` - Facing left
- `rotations/south-west.png` - Diagonal facing

### Metadata
- `metadata.json` - Complete character metadata including keypoints for collision detection
- `courier_cat.zip` - Original download archive (can be kept for reference or removed)

## Usage in Game

These sprites are the base directional views for the Courier Cat character. They can be:

1. **Scaled down** to 16×16 or other sizes as needed (use nearest-neighbor filtering)
2. **Used as-is** at 48×48 for higher resolution gameplay
3. **Animated** using frame-based animation systems
4. **Rotated** programmatically using the 8 directions for smooth character turning

## Animation Notes

The GDD specifies a 2-frame idle animation with tail swish at 1 FPS. To create this:

1. Use the base rotation sprites as frame 1
2. Create or generate a second frame with tail in different position
3. Alternate between frames at 1 FPS rate

## Color Palette

The character uses a warm sunset-inspired palette with:
- **Purples** - Shadow tones, atmospheric depth
- **Oranges** - Warm highlights, sunset glow
- **Pinks** - Accent colors, blending tones

This palette aligns with the game's atmospheric sunset aesthetic as specified in the GDD (Art Direction section).

## Collision Detection

The `metadata.json` file includes keypoint data for:
- Nose, neck, shoulders
- Spine points
- Hip, knees, ankles
- Tail points

These can be used for:
- Pixel-perfect collision detection
- Animation rigging
- Hit-box definition

## Next Steps

- [ ] Create idle animation frames (tail swish)
- [ ] Add running animation sprites
- [ ] Add jump/wall-slide sprites
- [ ] Add delivery action sprites
- [ ] Integrate with game's animation system
- [ ] Test at target resolution (320×180 virtual resolution)
- [ ] Optimize sprite sheet for performance
