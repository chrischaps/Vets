# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Courier Cat** is a cozy action-platformer game built with LÖVE (Love2D) framework and Lua. The player controls a cat delivering letters across rooftops before sunrise, featuring tight platforming mechanics with a focus on speed, flow, and atmospheric storytelling.

## Quick Reference for Common Tasks

### Starting Work on a New Feature
```bash
# 1. Check JIRA for next "To Do" ticket (highest priority, lowest number)
# 2. Move ticket to "In Progress" in JIRA
# 3. Create feature branch
git checkout develop
git pull origin develop
git checkout -b feature/VETS-X-description
```

### Testing Before Committing (REQUIRED)
```bash
lovec .  # MUST use lovec (not love) to see console output
# Test for minimum 2-3 minutes, watch console for errors
# Verify acceptance criteria, check for regressions
```

### Creating a Pull Request
```bash
git push origin feature/VETS-X-description
# Create PR on GitHub targeting develop branch
# Include JIRA link, changes summary, manual testing results
# DO NOT MERGE - wait for review
# Add PR link to JIRA comment, move to "In Review"
```

### Key File Locations
- **Player mechanics**: `src/entities/player.lua` (999 lines - complex)
- **Level data**: `levels/night1.json` (see `levels/SCHEMA.md` for schema)
- **Constants**: `src/constants.lua` (movement speeds, collision layers)
- **Main game loop**: `src/states/game_state.lua`
- **State switching**: `src/systems/state_manager.lua`

### Debug Commands
- **F1**: Show collision boundaries (in game_state)
- **F2**: Show debug info (player position, collision boxes)
- **Console**: `lovec .` shows all print statements with `[ModuleName]` prefixes

### Common Gotchas
1. **Center-based positioning** - Player transform is at center, not top-left
2. **Bitwise operations** - Use `bit.band()`, NOT `&` operator
3. **Delivery zones** - Distance-based (16px), not physics collision
4. **State manager reference** - States must store `self.state_manager`
5. **Module paths** - Use dots: `require("src.entities.player")`

## Engine & Technology Stack

- **Engine:** LÖVE (Love2D) 11.4 - Lua-based 2D game framework
- **Language:** Lua 5.1 (via LuaJIT)
- **Active Libraries:**
  - `bump.lua` (v3.1.7) - AABB collision detection
  - `hump.camera` - smooth camera following
  - `json.lua` - level data parsing
  - `anim8` - loaded but not yet used
- **Resolution:** 320×180 virtual resolution, scaled up with nearest-neighbor filtering
- **Physics:** 60 FPS fixed timestep (1/60s deterministic updates)
- **Art:** 16×16 pixel art tiles (not yet implemented - placeholder sprites)

## Development Commands

Since this is a LÖVE project, use the following commands:

**Running the game:**
```bash
love .       # Run game with window
lovec .      # Run game with console (better for testing/debugging)
```

**Creating a distributable .love file:**
```bash
# From project root
zip -r game.love .
```

**Running tests (if implemented):**
```bash
lovec . --test    # Use lovec to see test output
# or use lua testing framework like busted
busted tests/
```

**Note on Windows Artifacts:**
- When running commands that redirect to `NUL` on Windows (e.g., `2>NUL`), a file named `NUL` may be created as an artifact
- This file and `test_output.txt` are ignored in `.gitignore` and can be safely ignored or deleted

## Development Workflow

This project uses JIRA for task management and follows a structured git workflow for feature development.

### Working on JIRA Tickets

**JIRA Status Flow:**
- **To Do** → **In Progress** → **In Review** → **Done**

**Ticket Selection Process:**
1. Check JIRA for tickets in "To Do" status that have no blocking dependencies
2. Select the **highest priority** ticket available
3. If multiple tickets have the same priority, select the one with the **lowest ticket number** (e.g., VETS-2 before VETS-5)

**Implementation Workflow:**

1. **Move Ticket to In Progress**
   - Update the JIRA ticket status from "To Do" to "In Progress"
   - This signals that work has started on this ticket

2. **Create Feature Branch**
   - Create a new git feature branch from the develop branch
   - Branch naming convention: `feature/VETS-{ticket-number}-{brief-description}`
   - Example: `feature/VETS-2-project-setup` or `feature/VETS-7-player-running`
   - **Note:** If this is the first ticket, create the `develop` branch first:
   ```bash
   # First ticket only - create develop branch
   git checkout -b develop
   git push -u origin develop

   # For all tickets - create feature branch from develop
   git checkout develop
   git pull origin develop
   git checkout -b feature/VETS-2-project-setup
   ```

3. **Implement the Feature**
   - Work through the tasks listed in the JIRA ticket description
   - Follow the technical specifications and acceptance criteria
   - Write clean, well-commented code following Lua best practices
   - Make regular commits with clear, descriptive messages
   ```bash
   git add .
   git commit -m "VETS-2: Set up initial LÖVE project structure"
   ```

4. **Test the Implementation**
   - **CRITICAL:** Always test with `lovec .` before committing or creating PRs
   - Use `lovec .` (not `love .`) to see console output and print statements
   - Run the game and verify:
     - No syntax or runtime errors in the console output
     - All acceptance criteria are met
     - The changes work as expected in-game
     - No regressions or unintended side effects
   - Test edge cases and boundary conditions
   - **Only proceed to PR if testing succeeds and output confirms changes work correctly**
   - **Phase 1 Note:** Document all manual testing in the PR description (automated tests not yet implemented)
   ```bash
   lovec .  # Test with console output - must succeed before proceeding
   # Watch console output carefully for errors and print statements
   # Verify feature works as expected in-game
   # Test for 2-3 minutes minimum
   ```

5. **Open Pull Request**
   - Push the feature branch to GitHub
   - Open a pull request to merge the feature branch back into the `develop` branch
   - PR title should reference the ticket: "VETS-2: Set up LÖVE project structure and configuration"
   - PR description should include:
     - Link to the JIRA ticket (e.g., `https://chrischappelear.atlassian.net/browse/VETS-2`)
     - Summary of changes
     - **Manual testing performed** (Phase 1: document all test steps and results)
     - Any notes or considerations
   - **IMPORTANT:** Do NOT merge the PR - wait for code review and approval
   ```bash
   git push origin feature/VETS-2-project-setup
   # Then create PR via GitHub UI and wait for review
   ```

6. **Update JIRA Ticket**
   - Add a comment with the PR link
   - Move ticket to "In Review" status
   - Document any issues encountered or deviations from the spec
   - Ticket will move to "Done" after PR is reviewed and merged

### Git Branch Strategy

- **main**: Production-ready code (reserved for releases) - **DO NOT interact with this branch during Phase 1**
- **develop**: Integration branch for features (primary development branch) - **all work branches from here**
- **feature/**: Individual feature branches created from develop

**Important Notes:**
- The `develop` branch will be created when starting the first ticket (VETS-2)
- All feature branches are created from and merge back to `develop`
- Never merge PRs yourself - wait for code review and approval
- The `main` branch is reserved for releases and should not be touched during Phase 1 development

### Commit Message Guidelines

- Prefix commits with ticket number: `VETS-X: Description`
- Use present tense: "Add feature" not "Added feature"
- Be descriptive but concise
- Reference multiple tickets if applicable: `VETS-2, VETS-3: Set up project and libraries`

### Example Complete Workflow

```bash
# 1. Check JIRA, select VETS-2 (highest priority, lowest number)
# 2. Move VETS-2 to "In Progress" in JIRA

# 3. Create feature branch (first ticket - create develop first)
git checkout -b develop
git push -u origin develop
git checkout -b feature/VETS-2-project-setup

# For subsequent tickets:
# git checkout develop
# git pull origin develop
# git checkout -b feature/VETS-X-description

# 4. Implement the feature
# ... work on the feature ...
git add .
git commit -m "VETS-2: Create project directory structure"
git add .
git commit -m "VETS-2: Configure conf.lua with game settings"
git add .
git commit -m "VETS-2: Add constants and utilities"

# 5. Test the implementation
lovec .  # Use lovec (not love) to see console output
# MUST run successfully with no errors before proceeding
# Watch console output carefully for errors and print statements
# Verify feature works as expected in-game
# Test for 2-3 minutes minimum
# Document all testing steps and results for PR description
# DO NOT proceed to PR if testing fails or shows errors

# 6. Open pull request
git push origin feature/VETS-2-project-setup
# Create PR on GitHub with:
# - Title: "VETS-2: Set up LÖVE project structure and configuration"
# - Description: JIRA link, changes summary, manual testing results
# - Target branch: develop
# - DO NOT MERGE - wait for review

# 7. Update JIRA with PR link and move to "In Review"
# Ticket moves to "Done" after PR is reviewed and merged
```

## Codebase Architecture (ACTUAL - as of VETS-36)

### Directory Structure
```
src/
├── components/          # ECS components (transform, physics, collision)
├── core/               # Core systems (time, constants)
├── entities/           # Entity factories (player, platform, delivery_zone)
├── states/             # Game states (menu_state, game_state, results_state)
├── systems/            # Core systems (collision, input, level, camera, timer, scoring)
├── ui/                 # UI components (moon_timer)
├── constants.lua       # Game constants (movement speeds, collision layers)
└── utils.lua          # Utility functions

libraries/              # Third-party Lua libraries
levels/                # JSON level data (night1.json, template.json, SCHEMA.md)
```

### Entity-Component System (ECS)
- **Base Entity** (`src/entities/entity.lua`): Auto-incrementing IDs, component storage, update/draw delegation
- **Components** (`src/components/`):
  - `transform.lua`: Position (x, y), rotation, scale, z-index
  - `physics.lua`: Velocity, acceleration, gravity, friction, grounded/wall states
  - `collision.lua`: Shape types, collision layers/masks (bitwise filtering)
- **Entity Factories**: `Player.new()`, `Platform.new()`, `DeliveryZone.new()`

### State Management
- **StateManager** (`src/systems/state_manager.lua`): Handles state switching with enter/exit callbacks
- **State Flow**: `MenuState → GameState → ResultsState → MenuState`
- **State Contract**: States must implement `enter(...)`, `update(dt)`, `draw()`, optional `exit()`
- **Important**: States need to store `self.state_manager` reference to trigger transitions

### Collision System (Layer-Based)
- **Implementation**: Wrapper around bump.lua with bitwise layer filtering
- **Layers** (bit flags): NONE (0), PLAYER (1), TERRAIN (2), HAZARD (4), DELIVERY_ZONE (8), POWERUP (16), TRIGGER (32)
- **Filtering**: `if bit.band(item_mask, other_layer) ~= 0 then` (collides)
- **Response Types**: SLIDE (terrain), CROSS (triggers), TOUCH (sensors)
- **Critical**: Use `bit.band()` (LuaJIT), NOT `&` operator (not available in Lua 5.1)

### Level System (Two-Layer Design)
1. **LevelLoader** (`src/systems/level_loader.lua`): File I/O, JSON validation, returns raw data
2. **Level** (`src/systems/level.lua`): Entity instantiation, collision registration
3. **JSON Schema** (`levels/SCHEMA.md`): Complete schema documentation
   - **Coordinate System**: Top-left origin (0,0), X right, Y down
   - **Required Fields**: version, night, name, spawn, platforms, delivery_zones
   - **Platform Properties**: friction, grippable
   - **Delivery Zones**: glow_color, recipient_name, special flag, letter_fragment_id

### Input System
- **Abstraction**: Maps keyboard + gamepad to actions (left, right, jump, confirm, dash, deliver, pause)
- **Queries**: `is_down(action)`, `is_pressed(action)` (rising edge), `get_horizontal_axis()`
- **Gamepad Support**: D-pad, left stick, A/B/X/Y buttons, shoulders (deadzone internally applied)

### Core Systems & Interactions

**Player** (`src/entities/player.lua` - 999 lines):
- State machine: grounded detection (5-frame coyote time), jump buffering (8 frames)
- Wall-sliding, wall-jumping, dashing (cooldown + air charges)
- Combo tracking (consecutive deliveries without ground touch)
- Movement constants in `src/constants.lua`:
  ```lua
  RUN_SPEED = 120 px/s
  GRAVITY = 800 px/s²
  JUMP_FORCE = -300 px/s
  TERMINAL_VELOCITY = 500 px/s
  ```

**Timer** (`src/systems/timer.lua`):
- Countdown with state thresholds: CALM (>90s), WARNING (45-90s), URGENT (15-45s), CRITICAL (<15s)
- Fires `on_expire` callback when time runs out

**Scoring** (`src/systems/scoring.lua`):
- Base delivery: 100 points
- Combo multiplier: `floor(consecutive_deliveries / 2) + 1` (capped at 5x)
- Time bonus: `seconds_remaining × 10`
- Completion bonus: 500 points

**GameState** (`src/states/game_state.lua`):
- Main game loop: Initialize systems → Load level → Update (player, zones, timer, camera) → Draw
- Win/lose conditions → Transition to ResultsState with completion data

**ResultsState** (`src/states/results_state.lua`):
- Displays stats, calculates rank (S-E) based on score thresholds
- Keyboard + gamepad input for continue/restart

### Design Principles

- **Flow over friction** - movement should feel intuitive and joyful
- **Sessions are 5-8 minutes** - designed for short, replayable runs
- **Atmosphere-driven narrative** - visual storytelling through environment and letter fragments
- **Expressive simplicity** - small sprites, minimal animation, maximum emotional impact

## Project Status (as of VETS-36)

### ✅ Implemented Features
- Fixed 60 FPS timestep system (VETS-2, VETS-3)
- Entity-Component System architecture (VETS-4, VETS-5)
- Player movement (run, jump, wall-slide, wall-jump, dash) (VETS-6-18)
- Collision system with layer/mask filtering (VETS-11)
- Input abstraction (keyboard + gamepad) (VETS-13, VETS-14)
- Camera system with smooth following (VETS-15)
- Delivery zones with visual effects (VETS-17, VETS-19)
- Timer system with state thresholds (VETS-25)
- Time extension on delivery (VETS-26)
- Scoring system with combo multipliers (VETS-27, VETS-28)
- State management (menu, game, results) (VETS-29, VETS-30, VETS-31)
- Level loading from JSON (VETS-34, VETS-35)
- Night 1 complete level design (VETS-36)
- Results screen with rank calculation (VETS-31)
- Full gamepad support (VETS-31)

### ❌ Not Yet Implemented
- Animation system (anim8 loaded but not used)
- Background parallax layers (in JSON schema, not rendered)
- Hazards/obstacles (JSON support, no entity class)
- Powerups (JSON support, no mechanics)
- Wall entity class (TODO in level.lua)
- Music/sound effects (no audio system)
- Automated test framework
- Save system (high scores, unlocks)
- Multiple nights (only Night 1 designed)
- Letter fragment collection/story
- Art assets (using placeholder shapes)

### 📋 Completed JIRA Tickets (by number)
VETS-2, VETS-3, VETS-4, VETS-5, VETS-6, VETS-7, VETS-8, VETS-9, VETS-10, VETS-11, VETS-13, VETS-14, VETS-15, VETS-16, VETS-17, VETS-18, VETS-19, VETS-21, VETS-23, VETS-24, VETS-25, VETS-26, VETS-27, VETS-28, VETS-29, VETS-30, VETS-31, VETS-34, VETS-35, VETS-36, VETS-52

### 🎯 Current Phase
**Prototype (MVP)** - Nearly complete! Has:
- 1 level (Night 1 - "First Flight") ✅
- Basic movement (run, jump, wall-jump, dash) ✅
- 5 delivery points ✅
- Timer system ✅
- Scoring/combo system ✅
- Win/lose states ✅

**Next Phase**: Vertical Slice (3 levels, parallax backgrounds, music)

## Production Phases

1. **Prototype (MVP):** 1 level, basic movement, 5 delivery points, simple timer ✅ **NEARLY COMPLETE**
2. **Vertical Slice:** 3 levels, scoring system, parallax backgrounds, music
3. **Full Release:** 10+ night variations, story fragments, polish

## Art Direction Notes

- **Palette:** Sunset-focused with warm/cool contrast (purples, oranges, pinks)
- **Tile size:** 16×16 sprites
- **Animation:** Minimal but expressive (tail flicks, bag bounce, window glows)
- **Inspirations:** Celeste (movement), Night in the Woods (tone), Katana Zero (lighting), Kiki's Delivery Service (theme)

## Audio Specifications

- **Music:** Lo-fi chill beats + ambient jazz with tempo increase as dawn approaches
- **Key SFX:** Footsteps, letter flutter, distant city ambience, combo piano chords
- **Adaptive music layers** based on combo streaks (stretch goal)

## Important Implementation Details

- **Fixed timestep** recommended for consistent physics
- **Camera follows player** with smooth interpolation
- **Collision layers:** platforms, hazards, delivery zones, power-ups
- **State management:** menu → gameplay → results → menu loop
- **Save system:** high scores, unlocked ranks, discovered letter fragments

## Lua/LÖVE Specific Notes

- **Bitwise Operations:** LÖVE uses LuaJIT which provides the `bit` library (not `bit32`)
  - Use `bit.band(a, b)` for bitwise AND operations
  - Use `bit.bor(a, b)` for bitwise OR operations
  - Avoid using `&`, `|` operators as they're not available in Lua 5.1/LuaJIT

## Critical Implementation Gotchas

### 1. Positioning System (CENTER-BASED, not top-left)
- **Player transform is at CENTER** of the entity
- **Collision detection uses center position**
- **Convert to top-left for bump.lua**: `x - width/2, y - height/2`
- **Example**: Player at (40, 128) with 12px width means center is at 40, left edge at 34, right edge at 46

### 2. Delivery Zone Mechanics
- **Two detection ranges**:
  - **Proximity (48px)**: Visual feedback only (glow intensity)
  - **Contact (16px)**: Actual delivery trigger
- **Distance-based** (NOT physics-based collision)
- **Zone positioning**: Center should align with platform Y coordinate
  - Platform at y=144 → Zone center at y=144
  - 16px radius naturally covers standing player (player height is 12px)
- **Zones don't reset** between attempts (per level instance)
- **Visual effects**: Glow pulse (sine wave, 0.8s), letter float, sparkle particles

### 3. Input Edge Detection (Single-Frame Actions)
```lua
-- REQUIRED for single-frame actions like jump:
if jump_down and not self.jump_held then
    self.input_jump = true  -- Rising edge detected
end
self.jump_held = jump_down  -- Store state for next frame
```
- **Jump buffering**: 8 frames (0.133s)
- **Coyote time**: 5 frames after leaving ground
- **Both keyboard and gamepad** are checked simultaneously

### 4. Collision Layer Filtering (Bitwise)
```lua
-- ALWAYS use bit.band() for collision checks:
if bit.band(item_mask, other_layer) ~= 0 then
    -- Collision will occur
end

-- NEVER use & operator (not available in Lua 5.1/LuaJIT)
```

### 5. Level Loading (JSON Validation)
- **Night number mapping**: `Level.load(1)` → `levels/night1.json`
- **Platforms ARE added** to collision system
- **Delivery zones are NOT** (distance-based detection)
- **Walls not yet implemented** (TODO comment in level.lua)
- **JSON extra fields allowed** (future extensibility)

### 6. State Transitions
- **States MUST store** `self.state_manager` reference
- **Pass state_manager** when switching: `state_manager:switch("game", 1, state_manager)`
- **Cleanup in exit()**: Null out all references to prevent stale pointers
- **Level.unload()** required to remove entities from collision system

### 7. Fixed Timestep System
```lua
-- In main.lua, multiple fixed updates per frame if needed:
local updates = Time:update(dt)  -- Returns number of 1/60s steps
for i = 1, updates do
    state_manager:update(Time.FIXED_DT)  -- Always 1/60s
end
```
- **Deterministic physics** at 60 FPS
- **Max frame skip**: 5 updates to prevent spiral of death

### 8. Lua Module Paths
```lua
-- Use dots, not slashes:
local Player = require("src.entities.player")  -- CORRECT
-- NOT require("src/entities/player")
```

### 9. Debug Output Conventions
- **Print statements**: Use `[ModuleName]` prefix for filtering
  ```lua
  print("[GameState] Loading level for Night " .. night_number)
  print("[StateManager] Switched to state: " .. name)
  ```
- **F2 key toggle**: Shows debug info in several systems (player position, collision boxes, etc.)
- **F1 key (game_state)**: Shows collision boundaries

### 10. Testing Requirements
- **MUST use `lovec .`** (not `love .`) to see console output
- **Test minimum 2-3 minutes** before committing
- **Watch console** for errors and print statements
- **Test files ignored**: `*_test.txt`, `NUL` (Windows artifact) in .gitignore
- **No automated tests yet** - manual testing only
