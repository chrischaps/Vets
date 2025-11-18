# Level Development Workflow

This document explains the workflow for creating and editing levels for Courier Cat.

## Overview

- **Design Tool**: Tiled Map Editor (TMX format)
- **Runtime Format**: JSON
- **Build Tool**: Batch converters in main.lua

## Workflow

### 1. Initial Setup (One-Time Migration)

If you have existing JSON levels and want to edit them in Tiled:

**Command-line (Recommended):**
```bash
lovec . --json-to-tmx
# or
lovec . --migrate
```

**Manual flag:**
1. Open `main.lua`
2. Set `JSON_TO_TMX = true`
3. Run the game with `lovec .`
4. This creates TMX files in `assets/tiled/` from your JSON levels
5. Set `JSON_TO_TMX = false` when done

### 2. Development Workflow (Regular Editing)

#### Edit Levels in Tiled:
1. Open Tiled Map Editor
2. Open the level file from `assets/tiled/` (e.g., `night1.tmx`)
3. Edit platforms, delivery zones, hazards, powerups, etc.
4. Save the file

#### Convert to JSON for Runtime:

**Command-line (Recommended):**
```bash
lovec . --tmx-to-json
# or shorthand:
lovec . --convert
```

**Manual flag:**
1. Open `main.lua`
2. Set `TMX_TO_JSON = true`
3. Run the game with `lovec .`
4. This updates all JSON files in `levels/` from the TMX sources
5. Set `TMX_TO_JSON = false` when done

#### Test the Level:
```bash
lovec .  # Run normally without flags
```

#### Single-File Testing (F11/F12 Hotkeys):
- **F11**: Convert a single test JSON file to TMX (test_json_to_tmx.lua)
- **F12**: Convert a single test TMX file to JSON (test_tmx_converter.lua)

## Files

### Build Tools
- `batch_convert_to_json.lua` - Batch TMX → JSON converter
- `batch_convert_to_tmx.lua` - Batch JSON → TMX converter
- `src/systems/tmx_converter.lua` - Core converter implementation

### Test Tools
- `test_json_to_tmx.lua` - Single-file JSON → TMX test (F11)
- `test_tmx_converter.lua` - Single-file TMX → JSON test (F12)

### Level Files
- `assets/tiled/*.tmx` - Design-time Tiled map files (edit these)
- `levels/*.json` - Runtime level files (game loads these)

## Level List

Current levels configured for batch conversion:

| Level Name | TMX Source | JSON Output |
|------------|-----------|-------------|
| Night 1 | `assets/tiled/night1.tmx` | `levels/night1.json` |
| Night 2 | `assets/tiled/night2.tmx` | `levels/night2.json` |
| Night 3 | `assets/tiled/night3.tmx` | `levels/night3.json` |
| Showcase | `assets/tiled/showcase.tmx` | `levels/showcase.json` |

To add new levels, edit the `levels_to_convert` table in both batch converter files.

## Command-Line Reference

| Command | Description |
|---------|-------------|
| `lovec . --tmx-to-json` | Convert TMX to JSON (development workflow) |
| `lovec . --convert` | Shorthand for `--tmx-to-json` |
| `lovec . --json-to-tmx` | Convert JSON to TMX (one-time migration) |
| `lovec . --migrate` | Shorthand for `--json-to-tmx` |
| `lovec .` | Run game normally (no conversion) |

## Tips

- **Use command-line args**: Much faster than editing code flags
- **Always convert after editing**: The game loads JSON files, so TMX edits won't appear until converted
- **Test frequently**: Run the converter after each significant change to catch issues early
- **Version control**: Commit both TMX and JSON files to track level design history
- **Backup**: Keep backups of both formats in case of conversion issues

## Troubleshooting

### "TMX file not found" during conversion
- Make sure the TMX file exists in `assets/tiled/`
- Check the filename matches the entry in `batch_convert_to_json.lua`

### "JSON file not found" during reverse conversion
- Make sure the JSON file exists in `levels/`
- Check the filename matches the entry in `batch_convert_to_tmx.lua`

### Conversion succeeds but changes don't appear in-game
- Verify you ran the TMX → JSON converter (not JSON → TMX)
- Check the JSON file was actually updated (check timestamp)
- Make sure the game is loading the correct level file
