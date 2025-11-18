# Tiled Map Editor Workflow for Courier Cat

This guide explains how to use the Tiled Map Editor to create levels for Courier Cat.

## Table of Contents
1. [Installation](#installation)
2. [Project Setup](#project-setup)
3. [Creating a New Level](#creating-a-new-level)
4. [Entity Types Reference](#entity-types-reference)
5. [Level Design Guidelines](#level-design-guidelines)
6. [Exporting and Testing](#exporting-and-testing)
7. [Troubleshooting](#troubleshooting)

---

## Installation

### Download Tiled
1. Visit [https://www.mapeditor.org/](https://www.mapeditor.org/)
2. Download Tiled **version 1.9 or later**
3. Install for your operating system (Windows, macOS, or Linux)

### Verify Installation
- Launch Tiled
- Check: `Help` → `About Tiled` to confirm version 1.9+

---

## Project Setup

### 1. Load Custom Object Types
On first use, you need to import the Courier Cat custom object types:

1. Open Tiled
2. Go to `View` → `Object Types Editor` (or press `Ctrl+Shift+O`)
3. Click `File` → `Import Object Types...`
4. Navigate to `assets/tiled/objecttypes.xml`
5. Click `Open`
6. Click `OK` to close the Object Types Editor

**Result**: You now have 5 custom object types available:
- Platform (green)
- DeliveryZone (yellow)
- Hazard (red)
- Powerup (cyan)
- SpawnPoint (magenta)

### 2. Set Up Project Preferences
Configure Tiled for Courier Cat development:

1. Go to `Edit` → `Preferences`
2. Under `General`:
   - Set default grid size: **16×16 pixels**
3. Under `Object Types`:
   - Verify `objecttypes.xml` is loaded
4. Click `OK`

---

## Creating a New Level

### Step 1: Create a New Map
1. `File` → `New` → `New Map...`
2. Configure map settings:
   - **Orientation**: Orthogonal
   - **Tile layer format**: CSV (compact, human-readable)
   - **Tile render order**: Right Down
   - **Map size**: 60×30 tiles (960×480 pixels)
   - **Tile size**: 16×16 pixels
3. Click `OK`

### Step 2: Add Object Layer
1. In the Layers panel (right side), click `+` → `Object Layer`
2. Rename layer to "Entities"
3. This layer will contain all game entities (platforms, deliveries, etc.)

### Step 3: Place Spawn Point (Required)
**Every level must have exactly ONE spawn point!**

1. Select the Entities layer
2. Click the `Insert Rectangle` tool (toolbar) or press `R`
3. In the toolbar, select `SpawnPoint` from the Type dropdown
4. Click on the map to place a 16×16 rectangle where the player starts
5. **Recommended position**: Near center-left of screen (e.g., x=160, y=240)

### Step 4: Add Platforms
Platforms are solid ground the player can stand on, jump from, or climb.

1. Select `Platform` type from dropdown
2. Draw rectangles for ground, walls, and platforms
3. Select each platform and set properties in the Properties panel (left side):
   - **type**: Choose from `rooftop`, `brick`, `metal`, `awning`
   - **climbable**: `true` for walls (player can wall-slide), `false` otherwise
   - **semi_solid**: `true` for drop-through platforms, `false` for solid ground

**Platform Guidelines**:
- Ground platforms: 16px height, variable width
- Wall platforms: 16px width, variable height, set `climbable=true`
- Drop-through platforms: Set `semi_solid=true`
- Minimum platform width: 32px (2 tiles)

### Step 5: Add Delivery Zones
Delivery zones are glowing windows where the player delivers letters.

1. Select `DeliveryZone` type
2. Place 16×16 point objects (not rectangles!) for windows
3. Set properties for each:
   - **type**: `standard`, `priority`, `fragile`, or `chain`
   - **letter_fragment_id**: Unique ID (1, 2, 3, etc.) for story fragments
   - **chain_next**: (Optional) Name of next delivery in chain sequence

**Delivery Guidelines**:
- **5-15 delivery zones per level** (recommended)
- Place near platforms (within 32px radius)
- `priority` deliveries give bonus points
- `fragile` deliveries have time limits
- `chain` deliveries must be done in sequence

### Step 6: Add Hazards (Optional)
Hazards are obstacles that damage or hinder the player.

1. Select `Hazard` type
2. Place 16×16 point objects for hazards
3. Set properties:
   - **type**: `vent`, `laundry`, `pigeon`, `antenna`, `skylight`
   - **pattern**: Timing pattern (e.g., `2s_on_1.5s_off`)
   - **phase_offset**: Delay before pattern starts (0.0 - 5.0 seconds)

**Hazard Types**:
- **Vent**: Pushes player upward when active
- **Laundry**: Swinging clothesline obstacle
- **Pigeon**: Flying hazard with patrol pattern
- **Antenna**: Static obstacle to navigate around
- **Skylight**: Falling debris trigger

### Step 7: Add Powerups (Optional)
Powerups give the player temporary abilities.

1. Select `Powerup` type
2. Place 16×16 point objects
3. Set property:
   - **type**: `coffee` (speed boost), `balloon` (extra jump), or `lantern` (timer freeze)

---

## Entity Types Reference

### Platform
**Type**: Rectangle
**Color**: Green
**Properties**:
- `type` (string): `rooftop`, `brick`, `metal`, `awning`
- `climbable` (bool): Can player wall-slide on this?
- `semi_solid` (bool): Can player jump through from below?

### DeliveryZone
**Type**: Point (16×16)
**Color**: Yellow
**Properties**:
- `type` (string): `standard`, `priority`, `fragile`, `chain`
- `letter_fragment_id` (int): Story fragment ID (1, 2, 3...)
- `chain_next` (string): Next delivery name in chain

### Hazard
**Type**: Point (16×16)
**Color**: Red
**Properties**:
- `type` (string): `vent`, `laundry`, `pigeon`, `antenna`, `skylight`
- `pattern` (string): Timing (e.g., `2s_on_1.5s_off`)
- `phase_offset` (float): Start delay (0.0 - 5.0)

### Powerup
**Type**: Point (16×16)
**Color**: Cyan
**Properties**:
- `type` (string): `coffee`, `balloon`, `lantern`

### SpawnPoint
**Type**: Point (16×16)
**Color**: Magenta
**Properties**: None
**Important**: Exactly ONE per level!

---

## Level Design Guidelines

### Spatial Metrics (from GDD)
- **Tile size**: 16×16 pixels
- **Virtual resolution**: 320×180 (visible area on screen)
- **Map size**: 60×30 tiles (960×480 pixels) - about 3 screens wide

### Jump Distances
- **Easy jump**: 32px (2 tiles) gap
- **Medium jump**: 48px (3 tiles) gap - requires running start
- **Hard jump**: 64px (4 tiles) gap - requires dash
- **Expert jump**: 80px (5 tiles) gap - requires coffee powerup + dash
- **Impossible**: > 80px gap (don't create these!)

### Platform Heights
- **Player jump height**: 48px (3 tiles)
- **Platform spacing**: 32-48px vertical gaps work well

### Design Tips
1. **Start safe**: Make the spawn area easy with nearby platforms
2. **Escalate difficulty**: Harder jumps and more hazards toward the end
3. **Reward exploration**: Place powerups in challenging locations
4. **Visual flow**: Guide player's eye with platform layout
5. **Test, test, test**: Play your level multiple times!

---

## Exporting and Testing

### Save Your Work
1. `File` → `Save As...`
2. Save as `.tmx` in `assets/tiled/`
3. Naming convention: `night_XX.tmx` (e.g., `night_04.tmx`)

### Quick Test in Tiled
- Use `View` → `Snap to Grid` to verify alignment
- Check properties panel to ensure all entities have correct values
- Verify exactly ONE spawn point exists

### Export for Game
The game will load `.tmx` files directly via the TMX Converter (VETS-72). No manual export needed!

### Load in Game (Once Loader is Implemented)
```lua
-- In your game code (after VETS-73 is complete)
local level_loader = require("src.systems.level_loader")
level_loader.loadLevelFromTMX("assets/tiled/night_04.tmx")
```

### Test with Hot-Reload (After VETS-76)
1. Run the game with `lovec .`
2. Edit your TMX file in Tiled
3. Press `F5` in the game to reload the level
4. See changes instantly!

---

## Troubleshooting

### Issue: Custom object types not showing
**Solution**: Re-import `objecttypes.xml` via Object Types Editor

### Issue: Spawn point missing or multiple spawns
**Solution**: Every level needs exactly ONE `SpawnPoint`. Add or remove as needed.

### Issue: Grid not snapping to 16×16
**Solution**: `View` → `Snap to Grid`, verify grid size in `Map` → `Map Properties`

### Issue: Properties not saving
**Solution**: Make sure you press Enter after typing property values

### Issue: Level too large/small
**Solution**: `Map` → `Resize Map` to adjust tiles. Recommended: 60×30 tiles.

### Issue: Objects not visible in game
**Solution**: Ensure objects are on the "Entities" object layer, not a tile layer

### Issue: Tiled crashes or won't open TMX
**Solution**: Verify TMX file is valid XML. Check for syntax errors. Use example `night_01.tmx` as reference.

---

## Example Workflow

Here's a complete workflow for creating "Night 4":

1. **Create new map**: 60×30 tiles, 16×16 tile size
2. **Add Entities layer**
3. **Place SpawnPoint**: x=160, y=240
4. **Add ground**: 256×16 platform at y=256
5. **Add 3-5 platforms** at varying heights
6. **Add 8 delivery zones** near platforms
7. **Add 2-3 hazards** for challenge
8. **Add 1-2 powerups** in hard-to-reach spots
9. **Test in Tiled**: Verify all properties, check spawn
10. **Save as** `night_04.tmx`
11. **Load in game** and test with `lovec .`
12. **Iterate**: Edit in Tiled, press F5 in game to reload

---

## Next Steps

Once you're comfortable creating levels:
- See `docs/LEVEL_DESIGN_GUIDE.md` for advanced design patterns
- See `docs/JSON_SCHEMA.md` for the underlying data format
- See `docs/VALIDATION_GUIDE.md` for understanding validation errors

Happy level designing! 🐱📮
