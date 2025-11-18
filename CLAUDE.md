# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Courier Cat** is a cozy action-platformer game built with LÖVE (Love2D) framework and Lua. The player controls a cat delivering letters across rooftops before sunrise, featuring tight platforming mechanics with a focus on speed, flow, and atmospheric storytelling.

## Engine & Technology Stack

- **Engine:** LÖVE (Love2D) - Lua-based 2D game framework
- **Language:** Lua
- **Key Libraries (Planned):**
  - `bump.lua` - collision detection
  - `anim8` - sprite animation
  - `sti` - Tiled map loader
  - `hump.camera` - camera system
- **Resolution:** 320×180 virtual resolution, scaled up with nearest-neighbor filtering
- **Art:** 16×16 pixel art tiles with 12-16 color palette

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

**Creating test apps:**
```bash
# Test apps MUST live in subdirectories (not root)
# Structure: test_feature_name/main.lua
mkdir test_steam_vent
# Create main.lua in test_steam_vent/
cd test_steam_vent && lovec .
```

**IMPORTANT: Package paths for test apps:**
```lua
-- At the top of test_feature_name/main.lua:
-- Add parent directory's src to package path
package.path = package.path .. ";../src/?.lua;../?.lua"
```

**Note on Windows Artifacts:**
- When running commands that redirect to `NUL` on Windows (e.g., `2>NUL`), a file named `NUL` may be created as an artifact
- This file and `test_output.txt` are ignored in `.gitignore` and can be safely ignored or deleted

## Development Workflow

This project uses JIRA for task management and follows a structured git workflow for feature development.

### Working on JIRA Tickets

**IMPORTANT: JIRA MCP Authentication:**
- The JIRA MCP integration occasionally loses authentication permissions
- If you encounter authentication errors (e.g., "Unauthorized", "Authentication failed", "accessibleResources.filter is not a function"), you should:
  1. **PAUSE your current work immediately**
  2. **Inform the user** that JIRA MCP authentication has been lost
  3. **Request that the user re-authenticate** the MCP before continuing
  4. **Do NOT attempt to continue** working on JIRA tickets without authentication
- Once the user has re-authenticated, you can resume the ticket workflow

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
   - Create a new git feature branch from the appropriate base branch
   - Branch naming convention: `feature/VETS-{ticket-number}-{brief-description}`
   - Example: `feature/VETS-2-project-setup` or `feature/VETS-7-player-running`

   **For Regular Tickets:**
   ```bash
   # First ticket only - create develop branch
   git checkout -b develop
   git push -u origin develop

   # For all regular tickets - create feature branch from develop
   git checkout develop
   git pull origin develop
   git checkout -b feature/VETS-2-project-setup
   ```

   **For Epic Tickets (e.g., Level Editor VETS-70-92):**
   ```bash
   # First ticket of epic - create epic branch from develop
   git checkout develop
   git pull origin develop
   git checkout -b epic/VETS-68-level-editor-core
   git push -u origin epic/VETS-68-level-editor-core

   # For subsequent tickets in epic - create feature branch from epic branch
   git checkout epic/VETS-68-level-editor-core
   git pull origin epic/VETS-68-level-editor-core
   git checkout -b feature/VETS-70-tiled-template
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
   - Open a pull request to merge the feature branch back into the appropriate base branch
   - **Regular tickets**: PR to `develop`
   - **Epic tickets**: PR to the epic branch (e.g., `epic/VETS-68-level-editor-core`)
   - PR title should reference the ticket: "VETS-2: Set up LÖVE project structure and configuration"
   - PR description should include:
     - Link to the JIRA ticket (e.g., `https://chrischappelear.atlassian.net/browse/VETS-2`)
     - Summary of changes
     - **Manual testing performed** (Phase 1: document all test steps and results)
     - Any notes or considerations
   - **IMPORTANT:** Do NOT merge the PR - wait for code review and approval

   **Regular Ticket:**
   ```bash
   git push origin feature/VETS-2-project-setup
   # Create PR to 'develop' branch
   ```

   **Epic Ticket:**
   ```bash
   git push origin feature/VETS-70-tiled-template
   # Create PR to 'epic/VETS-68-level-editor-core' branch
   ```

6. **Update JIRA Ticket**
   - Add a comment with the PR link
   - Move ticket to "In Review" status
   - Document any issues encountered or deviations from the spec
   - Ticket will move to "Done" after PR is reviewed and merged

### Git Branch Strategy

- **main**: Production-ready code (reserved for releases) - **DO NOT interact with this branch during Phase 1**
- **develop**: Integration branch for features (primary development branch)
- **epic/**: Long-lived branches for large features spanning multiple tickets
- **feature/**: Individual feature branches created from develop or epic branches

**Standard Workflow (Regular Features):**
- Feature branches are created from and merge back to `develop`
- Example: `feature/VETS-7-player-running` → PR to `develop`

**Epic Workflow (Large Multi-Ticket Features):**
For major features spanning multiple tickets (e.g., Level Editor System - VETS-68, VETS-69):
1. Create an epic branch from `develop`: `epic/VETS-68-level-editor-core`
2. Create feature branches from the epic branch: `feature/VETS-70-tiled-template`
3. Submit PRs from feature branches back to the epic branch
4. When the epic is complete, merge the epic branch to `develop`

**Epic Branch Examples:**
- `epic/VETS-68-level-editor-core` - For Level Editor Core System (VETS-70 through VETS-81)
- `epic/VETS-69-ingame-editor` - For In-Game Editor (VETS-82 through VETS-92)

**Important Notes:**
- The `develop` branch will be created when starting the first ticket (VETS-2)
- Regular features: branch from `develop`, PR to `develop`
- Epic features: branch from epic branch, PR to epic branch
- Never merge PRs yourself - wait for code review and approval
- The `main` branch is reserved for releases and should not be touched during Phase 1 development

### Commit Message Guidelines

- Prefix commits with ticket number: `VETS-X: Description`
- Use present tense: "Add feature" not "Added feature"
- Be descriptive but concise
- Reference multiple tickets if applicable: `VETS-2, VETS-3: Set up project and libraries`

### Example Complete Workflow

**Example 1: Regular Feature (Standard Workflow)**
```bash
# 1. Check JIRA, select VETS-2 (highest priority, lowest number)
# 2. Move VETS-2 to "In Progress" in JIRA

# 3. Create feature branch (first ticket - create develop first)
git checkout -b develop
git push -u origin develop
git checkout -b feature/VETS-2-project-setup

# For subsequent regular tickets:
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

**Example 2: Epic Feature (Level Editor Workflow)**
```bash
# 1. Check JIRA, select VETS-70 (first ticket of VETS-68 epic)
# 2. Move VETS-70 to "In Progress" in JIRA

# 3. Create epic branch (first ticket of epic only)
git checkout develop
git pull origin develop
git checkout -b epic/VETS-68-level-editor-core
git push -u origin epic/VETS-68-level-editor-core

# 4. Create feature branch from epic branch
git checkout -b feature/VETS-70-tiled-template

# For subsequent tickets in same epic (VETS-71, 72, etc.):
# git checkout epic/VETS-68-level-editor-core
# git pull origin epic/VETS-68-level-editor-core
# git checkout -b feature/VETS-71-sti-integration

# 5. Implement, commit, and test (same as regular workflow)
git add .
git commit -m "VETS-70: Create Tiled project template"
lovec .  # Test thoroughly

# 6. Open pull request to EPIC BRANCH (not develop)
git push origin feature/VETS-70-tiled-template
# Create PR on GitHub with:
# - Title: "VETS-70: Set Up Tiled Template and Custom Object Types"
# - Description: JIRA link, changes summary, manual testing results
# - Target branch: epic/VETS-68-level-editor-core  ← IMPORTANT!
# - DO NOT MERGE - wait for review

# 7. Update JIRA with PR link and move to "In Review"
# When all epic tickets (VETS-70-81) are complete:
# - Create final PR from epic/VETS-68-level-editor-core to develop
# - Merge epic into develop after approval
```

## Project Architecture

### Core Game Systems

1. **Movement System**
   - Platforming physics with run, jump, wall-slide, and dash mechanics
   - Tight, forgiving controls optimized for flow
   - Basic gravity and friction simulation

2. **Delivery System**
   - Letter delivery mechanic triggered near glowing windows
   - Combo tracking for consecutive deliveries
   - Timer extension on successful deliveries

3. **Timer/Scoring System**
   - Dawn countdown mechanic (visual moon timer)
   - Score combo meter for ground-less delivery chains
   - Rank progression system

4. **Level System**
   - JSON or Tiled `.tmx` map format
   - Procedural shuffling of rooftop layouts and delivery locations
   - Night-to-night variations

5. **Rendering Pipeline**
   - Multi-layer parallax backgrounds (skyline, clouds)
   - Pixel-perfect rendering with nearest-neighbor scaling
   - Diegetic UI (moon as timer, minimal HUD)

### Design Principles

- **Flow over friction** - movement should feel intuitive and joyful
- **Sessions are 5-8 minutes** - designed for short, replayable runs
- **Atmosphere-driven narrative** - visual storytelling through environment and letter fragments
- **Expressive simplicity** - small sprites, minimal animation, maximum emotional impact

## Production Phases

1. **Prototype (MVP):** 1 level, basic movement, 5 delivery points, simple timer
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
