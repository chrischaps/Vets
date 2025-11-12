# Courier Cat

A cozy action-platformer game where you play as a cat delivering letters across rooftops before sunrise.

## Overview

**Courier Cat** combines precision platforming with time-attack urgency, wrapped in an atmospheric pixel-art package. Navigate a dreamy cityscape, deliver letters to glowing windows, and race against the dawn.

## Features

- **Tight platforming mechanics**: Run, jump, dash, wall-slide, and wall-jump
- **Time-attack gameplay**: Deliver all letters before sunrise
- **Combo system**: Chain deliveries without touching the ground for bonus points
- **Atmospheric storytelling**: Discover narrative through environmental details and letter fragments
- **16×16 pixel art**: Expressive simplicity with a 12-16 color palette

## Technology

- **Engine**: LÖVE (Love2D) 11.4+
- **Language**: Lua
- **Virtual Resolution**: 320×180 (scaled up with nearest-neighbor filtering)

### External Libraries

The project uses the following third-party libraries:

- **[bump.lua](https://github.com/kikito/bump.lua)** (v3.1.7) - AABB collision detection
  - License: MIT
  - Author: Enrique García Cota (kikito)

- **[anim8](https://github.com/kikito/anim8)** - Sprite animation management
  - License: MIT
  - Author: Enrique García Cota (kikito)

- **[hump.camera](https://github.com/vrld/hump)** - Camera system for LÖVE
  - License: MIT
  - Author: Matthias Richter (vrld)

- **[json.lua](https://github.com/rxi/json.lua)** - JSON encoding/decoding
  - License: MIT
  - Author: rxi

All libraries are located in the `libraries/` directory and can be loaded via `require("libraries.init")`.

## Development Setup

### Prerequisites

- [LÖVE 11.4+](https://love2d.org/) installed on your system

### Running the Game

```bash
# From the project root directory
love .
```

### Project Structure

```
courier-cat/
├── main.lua                 # Entry point
├── conf.lua                 # LÖVE configuration
├── src/                     # Source code
│   ├── components/          # Entity components
│   ├── entities/            # Game entities
│   ├── systems/             # Game systems
│   ├── states/              # Game states
│   ├── ui/                  # UI components
│   ├── data/                # Game data
│   ├── constants.lua        # Game constants
│   └── utils.lua            # Utility functions
├── assets/                  # Game assets
│   ├── sprites/             # Sprite sheets
│   ├── audio/               # Music and SFX
│   ├── levels/              # Level data
│   ├── backgrounds/         # Background images
│   └── fonts/               # Fonts
└── libraries/               # Third-party libraries
```

## Development Status

**Phase 1: Prototype (Weeks 1-2)** - In Progress

Current focus: Setting up project structure and implementing core movement mechanics.

## Design Documentation

- [Game Design Document (GDD)](GDD_CourierCat.md) - Gameplay systems, mechanics, and design
- [Technical Design Document (TDD)](TDD_CourierCat.md) - Technical architecture and implementation
- [Development Plan](DEVELOPMENT_PLAN.md) - Week-by-week development roadmap
- [Claude Instructions](CLAUDE.md) - Development workflow and guidelines

## License

Copyright © 2025. All rights reserved.

---

🐾 *Meow responsibly*
