# Level JSON Schema Documentation

## Overview

This document defines the JSON schema for Courier Cat level data files. Level files are stored in the `levels/` directory and use the `.json` extension.

## Version

Current schema version: **1**

## File Structure

### Top-Level Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `version` | number | Yes | Schema version number (currently 1) |
| `night` | number | Yes | Night number identifier (1, 2, 3, etc.) |
| `name` | string | Yes | Display name for the level |
| `description` | string | No | Brief description of the level |
| `spawn` | object | Yes | Player spawn point coordinates |
| `platforms` | array | Yes | Array of platform objects |
| `walls` | array | No | Array of wall/climbable surface objects |
| `delivery_zones` | array | Yes | Array of delivery zone objects (minimum 1) |
| `hazards` | array | No | Array of hazard objects |
| `powerups` | array | No | Array of powerup objects |
| `background_layers` | array | No | Array of background layer objects |
| `camera` | object | No | Camera configuration |
| `environment` | object | No | Environmental settings (time, weather, wind) |
| `metadata` | object | No | Level metadata (author, difficulty, tags, etc.) |

---

## Field Definitions

### spawn

Player spawn point when the level starts.

**Type:** object

**Required Fields:**
- `x` (number): X coordinate in pixels
- `y` (number): Y coordinate in pixels

**Example:**
```json
"spawn": {
  "x": 80,
  "y": 100
}
```

---

### platforms

Solid platforms the player can stand on and jump from.

**Type:** array of objects

**Required Fields:**
- `x` (number): X position of top-left corner
- `y` (number): Y position of top-left corner
- `width` (number): Width in pixels (must be > 0)
- `height` (number): Height in pixels (must be > 0)
- `type` (string): Platform type (e.g., "rooftop", "ledge", "awning")

**Optional Fields:**
- `properties` (object): Additional platform properties
  - `friction` (number): Surface friction (default: 1.0)
  - `grippable` (boolean): Whether edges can be grabbed (default: true)

**Example:**
```json
"platforms": [
  {
    "x": 0,
    "y": 150,
    "width": 160,
    "height": 16,
    "type": "rooftop",
    "properties": {
      "friction": 1.0,
      "grippable": true
    }
  }
]
```

---

### walls

Vertical surfaces for wall-sliding and wall-jumping.

**Type:** array of objects

**Required Fields:**
- `x` (number): X position
- `y` (number): Y position
- `width` (number): Width in pixels
- `height` (number): Height in pixels
- `type` (string): Wall type (e.g., "building_wall", "fence")

**Optional Fields:**
- `properties` (object): Additional wall properties
  - `climbable` (boolean): Whether wall can be climbed (default: true)
  - `friction` (number): Wall friction for sliding (default: 0.8)

**Example:**
```json
"walls": [
  {
    "x": 200,
    "y": 100,
    "width": 16,
    "height": 50,
    "type": "building_wall",
    "properties": {
      "climbable": true,
      "friction": 0.8
    }
  }
]
```

---

### delivery_zones

Interactive zones where the player can deliver letters.

**Type:** array of objects

**Required Fields:**
- `x` (number): X position
- `y` (number): Y position
- `id` (string): Unique identifier for this delivery zone
- `type` (string): Zone type ("standard", "bonus", "story")

**Optional Fields:**
- `width` (number): Zone width (default: 16)
- `height` (number): Zone height (default: 24)
- `letter_fragment_id` (string|null): ID of letter fragment to unlock
- `properties` (object): Additional zone properties
  - `glow_color` (array): RGBA color array [R, G, B, A]
  - `recipient_name` (string): Name of recipient
  - `special` (boolean): Whether this is a special delivery

**Example:**
```json
"delivery_zones": [
  {
    "x": 120,
    "y": 135,
    "width": 16,
    "height": 24,
    "id": "delivery_1",
    "type": "standard",
    "letter_fragment_id": null,
    "properties": {
      "glow_color": [255, 220, 100, 200],
      "recipient_name": "Mrs. Henderson"
    }
  }
]
```

---

### hazards

Obstacles that affect player movement or cause damage.

**Type:** array of objects

**Required Fields:**
- `x` (number): X position
- `y` (number): Y position
- `type` (string): Hazard type ("vent", "spike", "bird", etc.)

**Optional Fields:**
- `width` (number): Hazard width (default varies by type)
- `height` (number): Hazard height (default varies by type)
- `properties` (object): Type-specific properties
  - `pattern` (string): Behavior pattern (e.g., "2s_on_1.5s_off")
  - `damage` (number): Damage dealt (0 for non-damaging)
  - `knockback` (boolean): Whether hazard applies knockback
  - `force_x` (number): Horizontal force applied
  - `force_y` (number): Vertical force applied

**Example:**
```json
"hazards": [
  {
    "x": 350,
    "y": 140,
    "width": 16,
    "height": 16,
    "type": "vent",
    "properties": {
      "pattern": "2s_on_1.5s_off",
      "damage": 0,
      "knockback": true,
      "force_y": -200
    }
  }
]
```

---

### powerups

Collectible items that provide temporary bonuses.

**Type:** array of objects

**Required Fields:**
- `x` (number): X position
- `y` (number): Y position
- `type` (string): Powerup type ("coffee", "dash_refill", etc.)

**Optional Fields:**
- `width` (number): Powerup width (default: 12)
- `height` (number): Powerup height (default: 12)
- `properties` (object): Type-specific properties
  - `duration` (number): Effect duration in seconds
  - `speed_multiplier` (number): Speed boost multiplier

**Example:**
```json
"powerups": [
  {
    "x": 240,
    "y": 130,
    "width": 12,
    "height": 12,
    "type": "coffee",
    "properties": {
      "duration": 5.0,
      "speed_multiplier": 1.5
    }
  }
]
```

---

### background_layers

Visual background layers with parallax scrolling.

**Type:** array of objects

**Required Fields:**
- `type` (string): Layer type ("color", "skyline", "clouds", "gradient")
- `layer` (number): Layer index (0 = back, higher = closer to front)

**Optional Fields:**
- `properties` (object): Type-specific properties
  - For "color": `color` (array): RGBA color [R, G, B, A]
  - For "skyline": `parallax_factor` (number), `texture` (string), `y_offset` (number)
  - For "clouds": `parallax_factor` (number), `speed` (number), `density` (number)

**Example:**
```json
"background_layers": [
  {
    "type": "color",
    "layer": 0,
    "properties": {
      "color": [30, 20, 40, 255]
    }
  },
  {
    "type": "skyline",
    "layer": 1,
    "properties": {
      "parallax_factor": 0.3,
      "texture": "skyline_far",
      "y_offset": 80
    }
  }
]
```

---

### camera

Camera behavior and boundaries.

**Type:** object

**Optional Fields:**
- `bounds` (object): Camera boundary limits
  - `left` (number): Left boundary
  - `right` (number): Right boundary
  - `top` (number): Top boundary
  - `bottom` (number): Bottom boundary
- `follow_speed` (number): Camera follow smoothing (higher = faster)
- `dead_zone` (object): Camera dead zone (player can move without camera)
  - `x` (number): Horizontal dead zone radius
  - `y` (number): Vertical dead zone radius

**Example:**
```json
"camera": {
  "bounds": {
    "left": 0,
    "right": 880,
    "top": 0,
    "bottom": 180
  },
  "follow_speed": 3.0,
  "dead_zone": {
    "x": 40,
    "y": 30
  }
}
```

---

### environment

Environmental settings affecting gameplay.

**Type:** object

**Optional Fields:**
- `time_limit` (number): Maximum time for level in seconds
- `starting_time` (number): Starting time remaining in seconds
- `wind` (object): Wind settings
  - `enabled` (boolean): Whether wind is active
  - `direction_x` (number): Horizontal wind direction (-1 to 1)
  - `strength` (number): Wind strength
- `weather` (string): Weather type ("clear", "rain", "snow", "fog")

**Example:**
```json
"environment": {
  "time_limit": 300,
  "starting_time": 240,
  "wind": {
    "enabled": false,
    "direction_x": 0,
    "strength": 0
  },
  "weather": "clear"
}
```

---

### metadata

Level metadata for display and organization.

**Type:** object

**Optional Fields:**
- `author` (string): Level creator name
- `created_date` (string): Creation date (YYYY-MM-DD format)
- `difficulty` (string): Difficulty rating ("beginner", "easy", "medium", "hard", "expert")
- `required_deliveries` (number): Minimum deliveries to complete level
- `par_time` (number): Target completion time in seconds
- `tags` (array): Array of string tags for categorization

**Example:**
```json
"metadata": {
  "author": "Courier Cat Team",
  "created_date": "2024-11-15",
  "difficulty": "beginner",
  "required_deliveries": 3,
  "par_time": 60,
  "tags": ["tutorial", "easy", "beginner"]
}
```

---

## Validation Rules

1. **Required Fields:** `version`, `night`, `name`, `spawn`, `platforms`, `delivery_zones` must be present
2. **Minimum Requirements:**
   - At least 1 platform
   - At least 1 delivery zone
3. **Type Enforcement:**
   - All coordinates must be numbers
   - All dimensions (width/height) must be positive numbers
   - IDs must be unique strings
4. **Coordinate System:**
   - Origin (0,0) is top-left corner
   - X increases to the right
   - Y increases downward
5. **Extra Fields:**
   - Unknown/extra fields are allowed and will be ignored
   - This supports future expansion without breaking compatibility

---

## Usage with Level Loader

```lua
local LevelLoader = require("src.systems.level_loader")

-- Load a specific level file
local level, err = LevelLoader.load("levels/night1.json")
if not level then
    print("Error loading level:", err)
end

-- Load by night number
local level, err = LevelLoader.loadNight(1)

-- Get level info without full load
local info, err = LevelLoader.getInfo("levels/night1.json")

-- List all available levels
local levels = LevelLoader.listLevels()
for _, levelEntry in ipairs(levels) do
    print(levelEntry.info.name, "- Night", levelEntry.info.night)
end
```

---

## File Naming Convention

- Level files should be named: `night{number}.json`
- Example: `night1.json`, `night2.json`, `night3.json`
- Template file: `template.json` (excluded from level loading)

---

## Future Expansion

The schema is designed to be extensible:
- New optional fields can be added without breaking existing levels
- New entity types can be added to existing arrays
- Properties objects allow type-specific customization
- Version field allows for schema migrations if needed

---

## Examples

See the following example files:
- `levels/template.json` - Minimal template for creating new levels
- `levels/night1.json` - Comprehensive example with all features

---

**Last Updated:** 2024-11-15
**Schema Version:** 1
**JIRA Ticket:** VETS-34
