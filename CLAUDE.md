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
love .
```

**Creating a distributable .love file:**
```bash
# From project root
zip -r game.love .
```

**Running tests (if implemented):**
```bash
love . --test
# or use lua testing framework like busted
busted tests/
```

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
   - If the ticket includes testing steps in the acceptance criteria, test the feature thoroughly
   - Verify that all acceptance criteria are met
   - Test edge cases and ensure no regressions
   - Run the game and manually verify the feature works as expected
   - **Phase 1 Note:** Document all manual testing in the PR description (automated tests not yet implemented)
   ```bash
   love .  # Test the game
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
love .  # Verify game launches correctly
# Document all testing steps and results for PR description

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
