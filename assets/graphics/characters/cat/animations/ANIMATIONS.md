# Courier Cat Animations

Player animation sprite sheets for Courier Cat, generated with PixelLab MCP.

## Character Specifications
- Canvas: 48×48px
- Character size: ~28px tall, ~21px wide
- Style: Single color black outline, basic shading, medium detail
- View: High top-down perspective

## Available Animations

### Run Animation (running-4-frames)
- **Frames:** 4
- **FPS:** 12
- **Directions:** 8 (all directions)
- **Use:** Basic running movement

### Jump Animation (jumping-1)
- **Frames:** 9
- **FPS:** Default (varies by frame timing)
- **Directions:** 8 (all directions)
- **Use:** Jump/airborne state

### Dash Animation (running-8-frames)
- **Frames:** 8
- **FPS:** Fast (16-20 FPS recommended)
- **Directions:** 8 (all directions)
- **Use:** Dash ability with motion blur effect

### Wall-Slide Animation (crouched-walking)
- **Frames:** 6
- **FPS:** 8-10
- **Directions:** 8 (all directions)
- **Use:** Sliding down walls

### Delivery Animation (throw-object)
- **Frames:** 7
- **FPS:** 10
- **Directions:** 5 (west, north, south-west, north-west, south)
- **Use:** Delivering letters to mailboxes
- **Note:** Missing east, south-east, north-east (can mirror west)

## Side-Scroller Usage

For a side-scrolling platformer, **only west/east directions are needed**:

1. **West direction:** Use sprites as-is for left-facing movement
2. **East direction:** Horizontally flip/mirror west sprites for right-facing movement

This approach:
- Reduces memory usage
- Simplifies animation logic
- Maintains consistent visual quality

### Example (LÖVE/Lua):
```lua
-- Load west animation frames
local runWest = {frames...}

-- Render with horizontal flip for east
if facing == "east" then
    love.graphics.draw(frame, x, y, 0, -1, 1, frame:getWidth(), 0)
else
    love.graphics.draw(frame, x, y)
end
```

## File Structure

```
animations/
├── running-4-frames/       # Run animation
│   ├── west/              # 4 frames
│   ├── east/              # 4 frames
│   └── [6 other directions]
├── jumping-1/             # Jump animation
│   ├── west/              # 9 frames
│   ├── east/              # 9 frames
│   └── [6 other directions]
├── running-8-frames/      # Dash animation
│   ├── west/              # 8 frames
│   ├── east/              # 8 frames
│   └── [6 other directions]
├── crouched-walking/      # Wall-slide animation
│   ├── west/              # 6 frames
│   ├── east/              # 6 frames
│   └── [6 other directions]
└── throw-object/          # Delivery animation
    ├── west/              # 7 frames
    ├── north/             # 7 frames
    ├── south/             # 7 frames
    ├── north-west/        # 7 frames
    └── south-west/        # 7 frames

rotations/                 # Static directional sprites
├── west.png
├── east.png
└── [6 other directions]
```

## Notes

- All animations include 8 directions for flexibility
- Diagonal directions (NE, SE, NW, SW) and north/south included for future top-down gameplay
- Delivery animation missing 3 directions (east, south-east, north-east) - mirror west for side-scroller use
- Character ID: `ef4db8a3-6ce1-4831-a8a8-9a4d75e718fc`
- Generated: November 2025
