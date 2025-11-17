# Level Editor Implementation Plan

## Epic Overview

**Epic ID**: VETS-EPIC-2
**Epic Name**: Level Editor System
**Epic Goal**: Create a comprehensive level creation pipeline to support rapid iteration and community content creation for Courier Cat

### Epic Description

Implement a two-phase level editor system:
1. **Phase 1 (MVP)**: Tiled Map Editor integration with custom object types, JSON export pipeline, and in-game level loader
2. **Phase 2 (Enhanced)**: Advanced validation tools and visual debug overlays for level design quality assurance
3. **Phase 3 (Stretch Goal)**: Full in-game level editor with integrated playtesting and visual aids

### Success Metrics

- Reduce level creation time from hours (manual code) to minutes (visual editor)
- Catch 100% of critical design errors (missing spawn, unreachable deliveries)
- Enable non-programmers to create levels
- Support fast iteration (< 5 second test-edit cycle)

### Strategic Value

- **Weeks 9-10**: Needed to create Nights 4-10 efficiently
- **Post-Launch**: Enable community-created levels
- **Long-term**: Potential for level-sharing platform

---

## Phase 1: Tiled Integration (MVP)

**Timeline**: Weeks 9-10
**Goal**: Functional level creation workflow with Tiled Map Editor

### Ticket 1: VETS-22 - Set Up Tiled Template and Custom Object Types

**Priority**: Highest
**Story Points**: 3
**Type**: Task

**Description**:
Create a Tiled project template with custom object types for all level entities (platforms, delivery zones, hazards, powerups, spawn point). Configure custom properties and validation rules within Tiled.

**Context**:
Tiled is a free, mature map editor with support for custom object types and properties. We'll use it as our primary level creation tool in Phase 1 to accelerate development of Nights 4-10.

**Technical Requirements**:
- Create `assets/tiled/courier_cat_template.tsx` tileset
- Define custom object types:
  - Platform (rectangle) with properties: type (enum: rooftop, brick, metal, awning, etc.), climbable (bool), semi_solid (bool)
  - DeliveryZone (point) with properties: type (enum: standard, priority, fragile, chain), letter_fragment_id (int), chain_next (string)
  - Hazard (point) with properties: type (enum: vent, laundry, pigeon, antenna, skylight), pattern (string), phase_offset (float)
  - Powerup (point) with properties: type (enum: coffee, balloon, lantern)
  - SpawnPoint (point) - no additional properties
- Configure 16×16 grid size
- Set up custom properties panel templates
- Create example level: `assets/tiled/night_01.tmx`

**Acceptance Criteria**:
- [ ] Tiled template file created with all object types
- [ ] Custom properties defined for each object type
- [ ] Grid set to 16×16 pixels
- [ ] Example level created with all entity types placed
- [ ] Documentation in `docs/TILED_WORKFLOW.md` explaining how to use the template

**Testing Checklist**:
- [ ] Open template in Tiled (version 1.9+)
- [ ] Create new map from template
- [ ] Place each object type and verify properties appear
- [ ] Save as TMX and verify XML structure
- [ ] Grid snapping works at 16×16

**Branch**: `feature/VETS-22-tiled-template-setup`

**Dependencies**: None

---

### Ticket 2: VETS-23 - Integrate STI (Simple Tiled Implementation) Library

**Priority**: Highest
**Story Points**: 2
**Type**: Task

**Description**:
Integrate the STI library to load and parse Tiled TMX files within the LÖVE game engine.

**Context**:
STI is the standard library for loading Tiled maps in LÖVE. It handles TMX parsing, tile rendering, and object layer extraction.

**Technical Requirements**:
- Download STI library (https://github.com/karai17/Simple-Tiled-Implementation)
- Add to `libraries/sti/` directory
- Update `libraries/init.lua` to load STI
- Create wrapper module `src/systems/level_loader.lua` with STI integration
- Handle TMX parsing and object layer extraction

**Acceptance Criteria**:
- [ ] STI library added to `libraries/sti/`
- [ ] Library loaded in `libraries/init.lua`
- [ ] `src/systems/level_loader.lua` created with basic STI wrapper
- [ ] Successfully loads example TMX file from VETS-22
- [ ] Can extract object layers and print object data

**Testing Checklist**:
- [ ] Run `lovec .` with test code that loads `night_01.tmx`
- [ ] Console output shows parsed object data
- [ ] No Lua errors or warnings
- [ ] Library version documented in comments

**Branch**: `feature/VETS-23-sti-library-integration`

**Dependencies**: VETS-22

---

### Ticket 3: VETS-24 - Create TMX to Game JSON Converter

**Priority**: Highest
**Story Points**: 5
**Type**: Feature

**Description**:
Build a converter that transforms Tiled TMX format into the game's JSON schema (as defined in TDD lines 1292-1343). Handle all entity types and custom properties.

**Context**:
Our game uses a specific JSON schema for level data. We need to convert Tiled's TMX XML format to this JSON structure during level loading.

**Technical Requirements**:
- Create `src/systems/tmx_converter.lua` module
- Parse TMX object layers using STI
- Convert each object type to JSON schema:
  - Platforms: Extract x, y, width, height from rectangles, map custom properties
  - Delivery zones: Extract x, y from points, convert type and fragment_id
  - Hazards: Extract position and pattern data
  - Powerups: Extract position and type
  - Spawn point: Extract position (validate only one exists)
- Handle coordinate system conversions:
  - Tiled uses top-left for rectangles, center for points
  - Game uses top-left for platforms, center for entities
- Validate TMX data before conversion
- Export to JSON using `libraries/json.lua`

**Acceptance Criteria**:
- [ ] `tmx_converter.lua` created with conversion functions
- [ ] Handles all 5 entity types (platform, delivery, hazard, powerup, spawn)
- [ ] Outputs valid JSON matching TDD schema
- [ ] Validates spawn point exists and is unique
- [ ] Coordinate system conversions are correct
- [ ] Custom properties mapped correctly
- [ ] Handles missing optional properties with defaults

**Testing Checklist**:
- [ ] Load `night_01.tmx` and convert to JSON
- [ ] Run `lovec .` and verify no errors
- [ ] Print JSON output and validate against schema
- [ ] Manually verify coordinates match Tiled placement
- [ ] Test with missing optional properties
- [ ] Test with multiple spawn points (should error)
- [ ] Test with zero spawn points (should error)

**Branch**: `feature/VETS-24-tmx-json-converter`

**Dependencies**: VETS-22, VETS-23

---

### Ticket 4: VETS-25 - Implement Level Loader System

**Priority**: Highest
**Story Points**: 5
**Type**: Feature

**Description**:
Create the level loading system that reads JSON (from converter or direct file) and instantiates all game entities with proper components and collision.

**Context**:
This is the core system that transforms level data into playable game entities. It must create all entity types and register them with the collision system.

**Technical Requirements**:
- Create `src/systems/level_loader.lua` (or extend existing from VETS-23)
- Add functions:
  - `loadLevelFromJSON(json_data)` - main loader
  - `loadLevelFromFile(filepath)` - loads JSON file directly
  - `loadLevelFromTMX(tmx_filepath)` - converts TMX then loads
- For each entity type, create instances:
  - Platforms: Use existing `Platform.new()`, add to collision world
  - Spawn point: Set player initial position
  - Delivery zones: Create new `DeliveryZone` entity (create stub for now)
  - Hazards: Create new `Hazard` entity (create stub for now)
  - Powerups: Create new `Powerup` entity (create stub for now)
- Register all entities with collision system (`collision_system.lua`)
- Store level metadata (name, night number, etc.)
- Clear previous level before loading new one

**Acceptance Criteria**:
- [ ] `level_loader.lua` implements all three load functions
- [ ] Creates platforms and registers with collision
- [ ] Sets player spawn position
- [ ] Creates stub entities for delivery zones, hazards, powerups
- [ ] Clears previous level data before loading
- [ ] Stores level metadata in accessible structure
- [ ] Returns level object with entity references

**Testing Checklist**:
- [ ] Create test JSON file: `assets/levels/test_level.json`
- [ ] Load level in `main.lua` using `loadLevelFromFile()`
- [ ] Run `lovec .` and verify platforms appear
- [ ] Player spawns at correct position
- [ ] Move player around, collision works on loaded platforms
- [ ] No Lua errors during load or gameplay
- [ ] Test loading multiple levels in sequence (no leftovers)

**Branch**: `feature/VETS-25-level-loader-system`

**Dependencies**: VETS-24

---

### Ticket 5: VETS-26 - Create Delivery Zone Entity

**Priority**: High
**Story Points**: 3
**Type**: Feature

**Description**:
Implement the DeliveryZone entity with collision detection, visual rendering (glowing window), and interaction trigger.

**Context**:
Delivery zones are the core gameplay mechanic. Players enter zones and press a button to deliver letters. Zones must be visible, detectable, and have configurable types.

**Technical Requirements**:
- Create `src/entities/delivery_zone.lua`
- Entity components:
  - Transform: Position (x, y as center)
  - Collision: Circle trigger with 32px radius (use AABB approximation for bump.lua)
  - Properties: type (standard/priority/fragile/chain), letter_fragment_id, delivered (bool)
- Collision layer: `DELIVERY_ZONE`, trigger mode (doesn't block movement)
- Visual rendering:
  - Placeholder: Circle with glow effect (use color coding for type)
  - Standard = green, Priority = red, Fragile = blue, Chain = yellow
  - Pulse animation (0.8s cycle)
- Interaction detection:
  - Check if player overlaps zone
  - Display prompt when in range
  - Handle delivery input (Down/S/E key)
- Create factory function: `DeliveryZone.new(x, y, type, fragment_id)`

**Acceptance Criteria**:
- [ ] `delivery_zone.lua` created with entity implementation
- [ ] Renders as colored circle with pulse animation
- [ ] Collision detection works (player can overlap)
- [ ] Different types use different colors
- [ ] Can be instantiated from level loader
- [ ] Integration test with level loader

**Testing Checklist**:
- [ ] Create test level with 3 delivery zones (different types)
- [ ] Run `lovec .` and verify zones appear as colored circles
- [ ] Move player into zone, verify overlap detection
- [ ] Zones pulse with 0.8s cycle
- [ ] No collision blocking (player passes through)
- [ ] Print debug message when player enters zone

**Branch**: `feature/VETS-26-delivery-zone-entity`

**Dependencies**: VETS-25

---

### Ticket 6: VETS-27 - Create Hazard and Powerup Entities

**Priority**: Medium
**Story Points**: 5
**Type**: Feature

**Description**:
Implement Hazard and Powerup entity types with basic functionality, collision, and visual placeholders.

**Context**:
Hazards damage/hinder the player, while powerups provide temporary abilities. Both need collision detection and type-specific behavior.

**Technical Requirements**:

**Hazard Entity** (`src/entities/hazard.lua`):
- Components: Transform, Collision (trigger), Properties (type, pattern, phase_offset, active)
- Collision layer: `HAZARD`, trigger mode
- Types to implement:
  - Vent: Pushes player upward when active, cycles on/off based on pattern
  - (Other types: stub implementations for now)
- Visual: Icon/shape based on type (colored rectangles as placeholder)
- Pattern system: Parse pattern string like "2s_on_1.5s_off", cycle state
- Factory: `Hazard.new(x, y, type, pattern, phase_offset)`

**Powerup Entity** (`src/entities/powerup.lua`):
- Components: Transform, Collision (trigger), Properties (type, collected)
- Collision layer: `POWERUP`, trigger mode
- Types to implement:
  - Coffee: Speed boost +50%, 15s duration (apply to player on collect)
  - Balloon: Extra mid-air jump (add to player state)
  - Lantern: Freeze timer 10s (stub for now)
- Visual: Icon based on type (colored circles as placeholder)
- Collect behavior: Disable entity, apply effect to player
- Factory: `Powerup.new(x, y, type)`

**Acceptance Criteria**:
- [ ] `hazard.lua` created with vent hazard implementation
- [ ] Pattern parsing works for "Xs_on_Ys_off" format
- [ ] Vent cycles active/inactive states
- [ ] `powerup.lua` created with all three types
- [ ] Powerups can be collected (disappear on touch)
- [ ] Effects apply to player (coffee speed, balloon jump)
- [ ] Both integrated with level loader
- [ ] Visual placeholders render correctly

**Testing Checklist**:
- [ ] Create test level with 2 vents (different patterns) and 3 powerups
- [ ] Run `lovec .` and verify entities appear
- [ ] Vents cycle on/off with correct timing
- [ ] Collect coffee, verify player speed increases (print debug)
- [ ] Collect balloon, verify extra jump available
- [ ] Powerups disappear after collection
- [ ] No errors in console

**Branch**: `feature/VETS-27-hazard-powerup-entities`

**Dependencies**: VETS-25

---

### Ticket 7: VETS-28 - Implement Hot-Reload System for Fast Iteration

**Priority**: High
**Story Points**: 3
**Type**: Feature

**Description**:
Create a hot-reload system that allows reloading the current level without restarting the game, enabling rapid level design iteration.

**Context**:
Fast iteration is critical for level design. Designers need to test changes quickly without closing and reopening the game each time.

**Technical Requirements**:
- Add keyboard shortcut: F5 or R key to reload current level
- Create `reloadCurrentLevel()` function in level loader
- Preserve player state option (position, powerups) vs. full reset
- Clear all entities from previous load
- Re-parse TMX/JSON and reload
- Reset game state (timer, score, combo)
- Display on-screen notification: "Level Reloaded"
- Handle errors gracefully (show error message, don't crash)

**Acceptance Criteria**:
- [ ] F5 key reloads current level
- [ ] All entities cleared and recreated
- [ ] Player respawns at spawn point
- [ ] Game state resets (timer, score)
- [ ] On-screen notification appears for 2 seconds
- [ ] Errors during reload show message instead of crashing
- [ ] Works with both TMX and JSON sources

**Testing Checklist**:
- [ ] Load level, press F5, verify reload works
- [ ] Run `lovec .` and watch console output during reload
- [ ] Modify TMX file while game running, press F5, see changes
- [ ] Introduce syntax error in JSON, press F5, verify error message
- [ ] Reload multiple times in succession, no memory leaks
- [ ] Notification appears and disappears correctly

**Branch**: `feature/VETS-28-hot-reload-system`

**Dependencies**: VETS-25

---

### Ticket 8: VETS-29 - Create Level Validation Framework

**Priority**: High
**Story Points**: 3
**Type**: Feature

**Description**:
Build a validation system that checks level data for common errors and design issues, running automatically during level load.

**Context**:
Invalid levels cause crashes or poor player experience. Validation catches errors early in the design process.

**Technical Requirements**:
- Create `src/systems/level_validator.lua` module
- Validation checks:
  1. **Spawn point validation**: Exactly one spawn point exists
  2. **Delivery count validation**: 5-15 delivery zones (configurable range)
  3. **Bounds validation**: All entities within reasonable bounds (0-1000 x/y)
  4. **Overlap validation**: Platforms don't overlap excessively
  5. **Type validation**: All entity types are valid enum values
  6. **Required properties**: All required properties exist
- Validation levels: Error (blocks load), Warning (allows load but shows message), Info
- Return validation report with all issues
- Display errors in console with line numbers/entity IDs
- Optionally show in-game overlay with validation results

**Acceptance Criteria**:
- [ ] `level_validator.lua` created with all 6 validation checks
- [ ] Runs automatically during level load
- [ ] Errors prevent level load and show clear message
- [ ] Warnings allow load but print to console
- [ ] Validation report includes entity IDs and descriptions
- [ ] Integration with level loader (call before entity creation)

**Testing Checklist**:
- [ ] Create invalid level: zero spawn points → error blocks load
- [ ] Create invalid level: two spawn points → error blocks load
- [ ] Create invalid level: 3 deliveries → warning shown, loads anyway
- [ ] Create invalid level: 20 deliveries → warning shown
- [ ] Create invalid level: platform at x=9999 → error blocks load
- [ ] Run `lovec .` and verify error messages are clear and actionable
- [ ] Fix errors, reload with F5, verify load succeeds

**Branch**: `feature/VETS-29-level-validation-framework`

**Dependencies**: VETS-25

---

## Phase 2: Enhanced Validation & Debug Tools

**Timeline**: Weeks 11-12
**Goal**: Advanced quality assurance tools for level design

### Ticket 9: VETS-30 - Implement Reachability Analysis

**Priority**: Medium
**Story Points**: 8
**Type**: Feature

**Description**:
Create a pathfinding/reachability analyzer that detects delivery zones unreachable from the spawn point, preventing softlocks.

**Context**:
The most critical level design error is creating unreachable deliveries. This validator simulates player movement to verify all deliveries can be reached.

**Technical Requirements**:
- Create `src/systems/reachability_analyzer.lua` module
- Algorithm:
  1. Start from spawn point
  2. Simulate all possible player movements (run, jump, dash, wall-jump)
  3. Mark all reachable positions using flood-fill or A* search
  4. Check if all delivery zones are within reachable area
- Movement simulation:
  - Jump: 48px up, ~53px horizontal
  - Dash: 60px in 8 directions
  - Wall-jump: 52px up, 30px horizontal from walls
  - Run: Horizontal movement on platforms
- Grid-based approach: Discretize world into 8×8 or 16×16 cells
- Return list of unreachable deliveries with coordinates
- Integrate with level validator (error level)

**Acceptance Criteria**:
- [ ] `reachability_analyzer.lua` implemented
- [ ] Correctly simulates all movement types
- [ ] Detects unreachable deliveries accurately
- [ ] False positive rate < 5% (some complex jumps may appear unreachable)
- [ ] Runs in < 1 second for typical levels
- [ ] Integrated with level validator
- [ ] Shows unreachable delivery IDs and positions in error message

**Testing Checklist**:
- [ ] Create test level: all deliveries reachable → passes validation
- [ ] Create test level: one delivery on isolated platform → fails validation
- [ ] Create test level: delivery requires precise dash-jump → should pass
- [ ] Run `lovec .` with each test level
- [ ] Verify console output shows analysis results
- [ ] Test with 15 deliveries, verify performance < 1s

**Branch**: `feature/VETS-30-reachability-analysis`

**Dependencies**: VETS-29

---

### Ticket 10: VETS-31 - Add Gap Distance Validation

**Priority**: Medium
**Story Points**: 2
**Type**: Feature

**Description**:
Validate that gaps between platforms don't exceed maximum jump distance (80px with coffee + dash). Warn about very large gaps.

**Context**:
Per GDD spatial metrics, maximum traversable gap is 80px (5 tiles) with coffee powerup and dash. Larger gaps are impossible and indicate design errors.

**Technical Requirements**:
- Add validation check to `level_validator.lua`
- Algorithm:
  1. Find all platform pairs with vertical overlap (same Y range)
  2. Calculate horizontal gap distance
  3. Classify gaps:
     - ≤ 32px (2 tiles): Easy
     - 33-48px (3 tiles): Medium
     - 49-64px (4 tiles): Hard (dash required)
     - 65-80px (5 tiles): Expert (coffee + dash)
     - > 80px: **Impossible** (error)
- Error if any gap > 80px
- Warning if gap > 64px but no coffee powerup in level
- Info summary: "Gap distribution: 5 easy, 3 medium, 2 hard, 1 expert"

**Acceptance Criteria**:
- [ ] Gap validation added to validator
- [ ] Detects gaps > 80px and errors
- [ ] Warns about expert gaps without coffee powerup
- [ ] Gap distribution summary in validation report
- [ ] Only checks gaps that are actual traversal points (not vertical gaps)

**Testing Checklist**:
- [ ] Create test level: 85px gap → error
- [ ] Create test level: 70px gap, no coffee → warning
- [ ] Create test level: 70px gap, with coffee → passes
- [ ] Create test level: various gap sizes → correct distribution
- [ ] Run `lovec .` and verify validation messages
- [ ] No false positives on vertical gaps

**Branch**: `feature/VETS-31-gap-distance-validation`

**Dependencies**: VETS-29

---

### Ticket 11: VETS-32 - Create Visual Debug Overlay System

**Priority**: High
**Story Points**: 5
**Type**: Feature

**Description**:
Implement in-game debug overlay showing collision boxes, jump arcs, dash ranges, and delivery radii to visualize level constraints.

**Context**:
Visual aids help level designers understand movement constraints and verify placement accuracy without manual calculation.

**Technical Requirements**:
- Create `src/systems/debug_overlay.lua` module
- Keyboard toggle: F3 to show/hide overlay
- Render layers (all with transparency):
  1. **Collision boxes**: Outline all collision AABBs (green for platforms, red for hazards)
  2. **Delivery zones**: 32px radius circles (yellow)
  3. **Grid overlay**: 16×16 grid lines (gray)
  4. **Jump arc**: Parabolic arc from player position showing jump trajectory (white)
  5. **Dash range**: 60px radius circle from player (cyan)
  6. **Reachable area**: Highlight reachable regions from reachability analysis (green tint)
- Text overlay showing:
  - Player position (x, y)
  - Velocity (vx, vy)
  - Current state (grounded, airborne, wall-sliding)
  - Grid coordinates
- Draw using love.graphics with alpha blending
- Persist across level reloads

**Acceptance Criteria**:
- [ ] `debug_overlay.lua` created with all visualization layers
- [ ] F3 toggles overlay on/off
- [ ] Collision boxes drawn for all entities
- [ ] Delivery zone radii visible
- [ ] 16×16 grid overlay shown
- [ ] Jump arc updates in real-time as player moves
- [ ] Text info displayed in top-left corner
- [ ] No performance impact when disabled
- [ ] Visual aids are semi-transparent (don't obscure gameplay)

**Testing Checklist**:
- [ ] Load any level, press F3, verify overlay appears
- [ ] Run `lovec .` and verify no errors
- [ ] All collision boxes match entity positions
- [ ] Delivery zones show 32px radius exactly
- [ ] Jump arc updates as player moves/jumps
- [ ] Toggle F3 multiple times, verify persistence
- [ ] Test with 15 deliveries, verify performance remains 60fps

**Branch**: `feature/VETS-32-visual-debug-overlay`

**Dependencies**: VETS-25, VETS-30 (optional integration)

---

### Ticket 12: VETS-33 - Documentation and Example Levels

**Priority**: Medium
**Story Points**: 3
**Type**: Documentation

**Description**:
Create comprehensive documentation for the level editor workflow and example levels demonstrating all features and best practices.

**Context**:
Good documentation ensures smooth onboarding for level designers and serves as reference for common patterns.

**Technical Requirements**:
- Create documentation files:
  1. `docs/TILED_WORKFLOW.md`: Step-by-step Tiled usage guide
  2. `docs/LEVEL_DESIGN_GUIDE.md`: Design principles, spatial metrics, patterns
  3. `docs/JSON_SCHEMA.md`: Complete JSON schema reference
  4. `docs/VALIDATION_GUIDE.md`: Understanding validation errors
- Create example levels:
  1. `assets/tiled/examples/tutorial_level.tmx`: Simple first level
  2. `assets/tiled/examples/advanced_patterns.tmx`: Shows all design patterns from GDD
  3. `assets/tiled/examples/hazards_demo.tmx`: All hazard types
  4. `assets/levels/night_01.json`: Finalized Night 1 level
- Include screenshots in documentation
- Add troubleshooting section for common errors

**Acceptance Criteria**:
- [ ] All 4 documentation files created
- [ ] Tiled workflow guide has step-by-step instructions with screenshots
- [ ] Level design guide references GDD spatial metrics
- [ ] JSON schema fully documented with examples
- [ ] Validation guide explains all error types and fixes
- [ ] 3 example TMX files created and loadable
- [ ] `night_01.json` created and playable
- [ ] All examples pass validation

**Testing Checklist**:
- [ ] Follow Tiled workflow guide from scratch, create new level
- [ ] Load all example levels with `lovec .`, verify they work
- [ ] Verify all example levels pass validation
- [ ] Check documentation for broken links/formatting
- [ ] Have another person follow guide (if possible)

**Branch**: `feature/VETS-33-documentation-examples`

**Dependencies**: VETS-29, VETS-32

---

## Phase 3: In-Game Editor (Post-Launch Stretch Goal)

**Timeline**: Post-launch, community-driven
**Goal**: Full-featured in-game level editor for community content

### Epic Breakdown

This phase consists of 10+ tickets covering:

1. **VETS-34**: UI Framework for Editor Mode (6 SP)
   - Custom button, panel, dropdown, text input widgets
   - Mouse input handling
   - Keyboard shortcuts
   - Layout system

2. **VETS-35**: Entity Placement Tool System (5 SP)
   - Tool selector (select, platform, delivery, hazard, powerup, spawn)
   - Drag-to-create platforms
   - Click-to-place entities
   - Grid snapping
   - Undo/redo stack

3. **VETS-36**: Property Panel System (4 SP)
   - Entity selection
   - Property editing (type, position, size, custom)
   - Type dropdowns
   - Value validation
   - Apply/cancel buttons

4. **VETS-37**: Entity Visual Representation (3 SP)
   - Render all entity types in editor
   - Selection highlights
   - Handles for resizing platforms
   - Grid overlay
   - Camera pan/zoom

5. **VETS-38**: File Operations (Save/Load/New) (4 SP)
   - New level dialog
   - Open JSON browser
   - Save to JSON
   - Save As dialog
   - Auto-save system

6. **VETS-39**: Integrated Playtesting (5 SP)
   - "Test Level" button
   - Switch from editor mode to play mode
   - Return to editor (preserves state)
   - Test from spawn vs. test from current position
   - Temporary level save

7. **VETS-40**: Advanced Visual Aids in Editor (5 SP)
   - Real-time jump arc preview
   - Dash range circles
   - Movement capability overlay
   - Reachability heatmap
   - Toggle layers

8. **VETS-41**: Template and Prefab System (3 SP)
   - Save entity groups as templates
   - Template library browser
   - Drag-drop prefabs
   - Common patterns (gauntlet, split, climb, gap, run)

9. **VETS-42**: Multi-Layer Support (4 SP)
   - Background layer management
   - Parallax preview
   - Z-index visualization
   - Layer visibility toggles

10. **VETS-43**: Advanced Validation in Editor (3 SP)
    - Real-time validation feedback
    - Visual error indicators (red highlights)
    - Validation panel with error list
    - Click to jump to error

11. **VETS-44**: Community Features (8 SP)
    - Export to shareable .love file
    - Level metadata (author, description, tags)
    - Screenshot system
    - Level browser/importer

---

## Development Workflow Summary

### For Each Ticket

1. **Select Ticket**: Choose highest priority ticket from "To Do" in JIRA
2. **Move to In Progress**: Update JIRA status
3. **Create Branch**: `feature/VETS-X-brief-description` from `develop`
4. **Implement**: Follow technical requirements and acceptance criteria
5. **Test with lovec**: Run `lovec .` and verify all testing checklist items
6. **Commit**: Use message format `VETS-X: Description`
7. **Create PR**:
   - Title: "VETS-X: Ticket title"
   - Description: JIRA link, changes summary, testing results
   - Target: `develop` branch
   - **DO NOT MERGE** - wait for review
8. **Update JIRA**: Add PR link, move to "In Review"
9. **After Approval**: Ticket moves to "Done"

### Testing Requirements

**Critical**: All tickets must be tested with `lovec .` (not `love .`) to see console output before creating PR.

- Run for minimum 2-3 minutes
- Check console for errors, warnings, print statements
- Verify all acceptance criteria in-game
- Document testing steps in PR description
- No PR should be created if `lovec .` shows errors

### Dependencies

Tickets must be completed in order within each phase due to dependencies:
- Phase 1: Sequential (22→23→24→25, then 26/27/28/29 can parallel)
- Phase 2: Requires Phase 1 complete
- Phase 3: Requires Phase 2 complete

---

## Success Criteria for Epic

### Phase 1 Complete When:
- [ ] Can create levels in Tiled with all entity types
- [ ] Levels load in-game from TMX or JSON
- [ ] All entities render and function (platforms, deliveries, hazards, powerups)
- [ ] F5 hot-reload works for rapid iteration
- [ ] Basic validation prevents critical errors
- [ ] Nights 4-10 can be created efficiently

### Phase 2 Complete When:
- [ ] Reachability analysis catches unreachable deliveries
- [ ] Gap validation prevents impossible jumps
- [ ] F3 debug overlay shows all visual aids
- [ ] Documentation enables designer onboarding
- [ ] Example levels demonstrate all patterns

### Phase 3 Complete When:
- [ ] In-game editor allows full level creation without Tiled
- [ ] One-click playtesting with instant return to editor
- [ ] Visual aids show movement constraints in real-time
- [ ] Template system enables rapid level prototyping
- [ ] Community can create and share levels

---

## Technical Notes

### Coordinate System Reference
- **Platform**: Top-left corner (x, y, width, height)
- **Player/Entities**: Center point (x, y)
- **Delivery Zones**: Center point with 32px radius
- **Tiled Objects**: Rectangles = top-left, Points = exact position

### Spatial Metrics (from GDD)
- Tile size: 16×16 pixels
- Virtual resolution: 320×180 (16:9)
- Min gap: 32px (easy jump)
- Med gap: 48px (run + jump)
- Hard gap: 64px (dash required)
- Max gap: 80px (coffee + dash)
- Jump height: 48px (3 tiles)
- Dash distance: 60px

### File Paths
```
assets/
├── tiled/
│   ├── courier_cat_template.tsx    # Tiled template
│   ├── examples/
│   │   ├── tutorial_level.tmx
│   │   ├── advanced_patterns.tmx
│   │   └── hazards_demo.tmx
│   └── night_XX.tmx                # Working files
├── levels/
│   ├── night_01.json               # Exported levels
│   ├── night_02.json
│   └── ...
└── sprites/                         # Future: actual sprites

src/
├── systems/
│   ├── level_loader.lua            # VETS-25
│   ├── tmx_converter.lua           # VETS-24
│   ├── level_validator.lua         # VETS-29
│   ├── reachability_analyzer.lua   # VETS-30
│   └── debug_overlay.lua           # VETS-32
├── entities/
│   ├── delivery_zone.lua           # VETS-26
│   ├── hazard.lua                  # VETS-27
│   └── powerup.lua                 # VETS-27

docs/
├── TILED_WORKFLOW.md               # VETS-33
├── LEVEL_DESIGN_GUIDE.md           # VETS-33
├── JSON_SCHEMA.md                  # VETS-33
└── VALIDATION_GUIDE.md             # VETS-33
```

---

## Estimated Timeline

### Week 9
- VETS-22: Tiled Template (2 days)
- VETS-23: STI Integration (1 day)
- VETS-24: TMX Converter (2 days)

### Week 10
- VETS-25: Level Loader (2 days)
- VETS-26: Delivery Zones (1.5 days)
- VETS-27: Hazards/Powerups (2.5 days)

### Week 11
- VETS-28: Hot-Reload (1 day)
- VETS-29: Validation Framework (1.5 days)
- VETS-30: Reachability Analysis (3 days)

### Week 12
- VETS-31: Gap Validation (1 day)
- VETS-32: Debug Overlay (2 days)
- VETS-33: Documentation (1.5 days)

**Total**: 4 weeks for Phase 1-2 (12 tickets)

### Post-Launch
- Phase 3: 6-8 weeks (10 tickets)

---

## Risk Mitigation

### Risk: Reachability analysis too complex/slow
**Mitigation**: Start with simple grid-based flood-fill, optimize later if needed. Can be optional validation (warning vs. error).

### Risk: Tiled learning curve too steep
**Mitigation**: Comprehensive documentation (VETS-33), example levels, video walkthrough if needed.

### Risk: STI library limitations
**Mitigation**: Fallback to manual TMX parsing with xml2lua if STI doesn't support needed features.

### Risk: In-game UI too complex to build
**Mitigation**: Phase 3 is stretch goal. Tiled + validation tools (Phase 1-2) are sufficient for development.

### Risk: Performance issues with validation
**Mitigation**: Make validation optional (toggle), run asynchronously, cache results.

---

## Future Enhancements

- **Procedural variation editor**: UI for configuring randomization ranges
- **Difficulty calculator**: Automatic difficulty rating based on gap distribution, hazards
- **Level graph visualization**: Show delivery path flow
- **Collaborative editing**: Multi-user level creation (very long-term)
- **Level analytics**: Track player deaths, completion times per zone
- **Workshop integration**: Steam Workshop or itch.io level sharing

---

**Document Version**: 1.0
**Last Updated**: 2025-11-17
**Author**: Claude Code
**Status**: Ready for JIRA import
