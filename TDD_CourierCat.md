# Courier Cat - Technical Design Document (TDD)

**Version:** 1.0
**Last Updated:** November 11, 2025
**Engine:** LÖVE (Love2D) 11.4+
**Language:** Lua 5.1 / LuaJIT
**Target Platforms:** Windows, macOS, Linux

---

## Table of Contents

1. [Technical Overview](#1-technical-overview)
2. [System Architecture](#2-system-architecture)
3. [Core Engine Systems](#3-core-engine-systems)
4. [Entity-Component System](#4-entity-component-system)
5. [Physics & Collision](#5-physics--collision)
6. [Input System](#6-input-system)
7. [Rendering Pipeline](#7-rendering-pipeline)
8. [Audio System](#8-audio-system)
9. [State Management](#9-state-management)
10. [Level System](#10-level-system)
11. [Data Structures](#11-data-structures)
12. [File Organization](#12-file-organization)
13. [External Libraries](#13-external-libraries)
14. [Asset Pipeline](#14-asset-pipeline)
15. [Performance Optimization](#15-performance-optimization)
16. [Save System](#16-save-system)
17. [Build & Deployment](#17-build--deployment)
18. [Testing Strategy](#18-testing-strategy)
19. [Development Phases](#19-development-phases)
20. [Technical Constraints](#20-technical-constraints)

---

## 1. Technical Overview

### Engine Choice: LÖVE (Love2D)

**Rationale:**
- Lightweight 2D framework perfect for pixel art
- Immediate mode rendering ideal for our fixed resolution
- Lua scripting enables rapid iteration
- Cross-platform support out of the box
- Excellent community and documentation
- No licensing fees
- Easy distribution (.love files)

**LÖVE Version:** 11.4 (latest stable)
- Supports modern graphics features
- Improved performance over 0.10.x
- Better audio handling
- Enhanced shader support

### Language: Lua / LuaJIT

**Features Used:**
- Tables for all data structures
- Metatables for OOP-style programming
- Coroutines for animations/sequences
- Module system for code organization

**Coding Standards:**
- Functional where possible
- Minimal global state
- Clear naming conventions (snake_case for functions, PascalCase for classes)
- Comprehensive comments for complex logic

---

## 2. System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    LÖVE Framework                       │
│  (love.load, love.update, love.draw, love.handlers)    │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────┴────────────────────────────────────┐
│                  Game State Manager                     │
│         (MenuState, GameState, PauseState, etc.)        │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
┌───────▼──────┐ ┌──▼───────┐ ┌─▼──────────┐
│ Input System │ │  World   │ │ UI Manager │
└───────┬──────┘ └──┬───────┘ └─┬──────────┘
        │           │             │
        │    ┌──────┴──────┐      │
        │    │             │      │
    ┌───▼────▼───┐  ┌──────▼──────▼────┐
    │   Player   │  │   Game Systems   │
    │ Controller │  │ (Physics, Audio,  │
    └────────────┘  │  Render, etc.)    │
                    └───────────────────┘
```

### Component Systems

```
┌─────────────────────────────────────────────────────────┐
│                    Entity System                        │
│  - Player                                               │
│  - DeliveryPoints                                       │
│  - PowerUps                                             │
│  - Hazards                                              │
│  - ParticleEmitters                                     │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
┌───────▼──────┐ ┌──▼───────┐ ┌─▼──────────┐
│  Transform   │ │ Collision│ │  Renderer  │
│  Component   │ │Component │ │ Component  │
└──────────────┘ └──────────┘ └────────────┘
        │            │            │
┌───────▼──────┐ ┌──▼───────┐ ┌─▼──────────┐
│   Physics    │ │Animation │ │   Audio    │
│  Component   │ │Component │ │ Component  │
└──────────────┘ └──────────┘ └────────────┘
```

### System Execution Order

**Every Frame (60 FPS fixed timestep):**

1. **Input Processing** (love.update start)
   - Poll keyboard/gamepad
   - Update input state
   - Buffer inputs

2. **State Update** (current state's update method)
   - Update timer
   - Update entities
   - Process physics
   - Handle collisions
   - Update animations
   - Process game logic

3. **Audio Update**
   - Update adaptive music layers
   - Process 3D audio positions
   - Trigger queued sounds

4. **Render** (love.draw)
   - Clear frame
   - Set camera transform
   - Draw parallax backgrounds
   - Draw entities (sorted by layer)
   - Draw particles
   - Draw UI
   - Present frame

---

## 3. Core Engine Systems

### Game Loop

**Fixed Timestep Implementation:**

```lua
-- main.lua

local FIXED_DT = 1/60  -- 60 FPS
local accumulator = 0
local max_frame_skip = 5

function love.update(dt)
    -- Cap dt to prevent spiral of death
    if dt > 0.25 then dt = 0.25 end

    accumulator = accumulator + dt

    local updates = 0
    while accumulator >= FIXED_DT and updates < max_frame_skip do
        -- Fixed update
        current_state:update(FIXED_DT)
        accumulator = accumulator - FIXED_DT
        updates = updates + 1
    end
end

function love.draw()
    -- Interpolation factor for smooth rendering
    local alpha = accumulator / FIXED_DT
    current_state:draw(alpha)
end
```

**Rationale:**
- Deterministic physics
- Consistent gameplay across frame rates
- Prevents physics tunneling
- Allows for frame interpolation (stretch goal)

### Time Management

**Time System:**

```lua
-- systems/time.lua

Time = {
    dt = 0,              -- Delta time (fixed)
    total = 0,           -- Total elapsed time
    scale = 1.0,         -- Time scale (for slow-mo effects)
    frame = 0,           -- Frame counter
}

function Time:update(dt)
    self.dt = dt * self.scale
    self.total = self.total + self.dt
    self.frame = self.frame + 1
end

function Time:get_scaled_dt()
    return self.dt
end
```

**Use Cases:**
- Animations reference Time.total
- Physics use Time.dt
- Timers use scaled time
- Frame counters for input buffering

---

## 4. Entity-Component System

### Entity Structure

**Simple Entity Model:**

Each entity is a table with:
- `id`: Unique identifier
- `type`: Entity type (string)
- `active`: Boolean (for pooling)
- `components`: Table of component data
- `tags`: Set of string tags

```lua
-- entities/entity.lua

function Entity:new(type)
    local e = {
        id = generate_id(),
        type = type,
        active = true,
        components = {},
        tags = {},
    }
    setmetatable(e, self)
    self.__index = self
    return e
end

function Entity:add_component(name, component)
    self.components[name] = component
    component.owner = self
end

function Entity:get_component(name)
    return self.components[name]
end

function Entity:has_component(name)
    return self.components[name] ~= nil
end
```

### Core Components

**Transform Component:**

```lua
-- components/transform.lua

Transform = {
    x = 0,
    y = 0,
    rotation = 0,
    scale_x = 1,
    scale_y = 1,
    z_index = 0,  -- Render layer
}

function Transform:new(x, y)
    local t = {x = x, y = y, rotation = 0, scale_x = 1, scale_y = 1, z_index = 0}
    setmetatable(t, self)
    self.__index = self
    return t
end
```

**Physics Component:**

```lua
-- components/physics.lua

Physics = {
    velocity_x = 0,
    velocity_y = 0,
    acceleration_x = 0,
    acceleration_y = 0,
    gravity_scale = 1,
    max_velocity_x = 300,
    max_velocity_y = 500,
    friction = 0.15,
    grounded = false,
    on_wall = false,
    wall_direction = 0,  -- -1 left, 1 right
}

function Physics:update(dt)
    -- Apply acceleration
    self.velocity_x = self.velocity_x + self.acceleration_x * dt
    self.velocity_y = self.velocity_y + self.acceleration_y * dt

    -- Apply gravity
    if not self.grounded then
        self.velocity_y = self.velocity_y + (GRAVITY * self.gravity_scale * dt)
    end

    -- Apply friction (when grounded)
    if self.grounded and self.acceleration_x == 0 then
        self.velocity_x = self.velocity_x * (1 - self.friction)
    end

    -- Clamp velocities
    self.velocity_x = clamp(self.velocity_x, -self.max_velocity_x, self.max_velocity_x)
    self.velocity_y = clamp(self.velocity_y, -self.max_velocity_y, self.max_velocity_y)
end
```

**Collision Component:**

```lua
-- components/collision.lua

Collision = {
    type = "aabb",  -- "aabb", "circle", "point"
    width = 16,
    height = 16,
    offset_x = 0,
    offset_y = 0,
    static = false,
    layer = "default",
    mask = {"default"},  -- What layers to collide with
    trigger = false,     -- Triggers don't block movement
}
```

**Sprite Component:**

```lua
-- components/sprite.lua

Sprite = {
    image = nil,       -- Love2D Image object
    quad = nil,        -- Quad (for spritesheets)
    offset_x = 0,
    offset_y = 0,
    flip_x = false,
    flip_y = false,
    color = {1, 1, 1, 1},  -- RGBA
    visible = true,
}
```

**Animation Component:**

```lua
-- components/animation.lua

Animation = {
    animations = {},   -- Table of animation definitions
    current = nil,     -- Current animation name
    frame = 1,
    timer = 0,
    playing = true,
    loop = true,
}

function Animation:play(name, reset)
    if self.current ~= name or reset then
        self.current = name
        self.frame = 1
        self.timer = 0
        self.playing = true
    end
end

function Animation:update(dt)
    if not self.playing then return end

    local anim = self.animations[self.current]
    if not anim then return end

    self.timer = self.timer + dt
    if self.timer >= anim.frame_duration then
        self.timer = 0
        self.frame = self.frame + 1

        if self.frame > #anim.frames then
            if self.loop then
                self.frame = 1
            else
                self.frame = #anim.frames
                self.playing = false
            end
        end
    end
end
```

---

## 5. Physics & Collision

### Physics Constants

```lua
-- constants.lua

GRAVITY = 800  -- pixels/second²
TERMINAL_VELOCITY = 500  -- pixels/second
```

### Movement Physics

**Player Movement Constants:**

```lua
-- entities/player.lua

PLAYER_CONSTANTS = {
    -- Running
    RUN_SPEED = 120,
    RUN_ACCELERATION = 1200,  -- Instant feel
    AIR_CONTROL = 0.8,        -- Reduced air control

    -- Jumping
    JUMP_FORCE = -300,
    JUMP_HOLD_GRAVITY = 0.5,  -- Reduced gravity while holding jump
    WALL_JUMP_FORCE_X = 200,
    WALL_JUMP_FORCE_Y = -320,

    -- Dashing
    DASH_SPEED = 300,
    DASH_DURATION = 0.2,
    DASH_COOLDOWN = 0.5,

    -- Wall sliding
    WALL_SLIDE_SPEED = 40,
    WALL_STICK_TIME = 0.1,

    -- Buffering
    JUMP_BUFFER_FRAMES = 8,
    COYOTE_FRAMES = 5,
}
```

**Movement State Machine:**

```lua
-- entities/player.lua

PlayerState = {
    GROUNDED = "grounded",
    AIRBORNE = "airborne",
    WALL_SLIDING = "wall_sliding",
    DASHING = "dashing",
}

function Player:update_movement(dt)
    if self.state == PlayerState.GROUNDED then
        self:update_grounded(dt)
    elseif self.state == PlayerState.AIRBORNE then
        self:update_airborne(dt)
    elseif self.state == PlayerState.WALL_SLIDING then
        self:update_wall_sliding(dt)
    elseif self.state == PlayerState.DASHING then
        self:update_dashing(dt)
    end
end
```

### Collision Detection

**Using bump.lua Library:**

```lua
-- systems/collision_system.lua

CollisionSystem = {}

function CollisionSystem:init()
    self.world = bump.newWorld(16)  -- Cell size 16px
end

function CollisionSystem:add(entity, x, y, w, h)
    self.world:add(entity, x, y, w, h)
end

function CollisionSystem:update(entity, x, y)
    local actual_x, actual_y, cols, len = self.world:move(
        entity, x, y,
        function(item, other)
            return self:collision_filter(item, other)
        end
    )
    return actual_x, actual_y, cols
end

function CollisionSystem:collision_filter(item, other)
    -- Determine collision response
    if other.collision.trigger then
        return "cross"  -- No blocking, but detect overlap
    elseif other.collision.static then
        return "slide"  -- Slide along walls
    else
        return "touch"  -- Just detect
    end
end
```

**Collision Layers:**

```lua
-- constants.lua

CollisionLayers = {
    PLAYER = "player",
    TERRAIN = "terrain",
    HAZARD = "hazard",
    DELIVERY_ZONE = "delivery",
    POWERUP = "powerup",
    TRIGGER = "trigger",
}

-- Collision matrix (what collides with what)
CollisionMatrix = {
    player = {"terrain", "hazard", "delivery", "powerup", "trigger"},
    terrain = {},
    hazard = {"player"},
    delivery = {"player"},
    powerup = {"player"},
    trigger = {"player"},
}
```

### Ground Detection

**Raycast-Based Ground Check:**

```lua
function Player:check_grounded()
    local collision_comp = self:get_component("collision")
    local transform = self:get_component("transform")

    -- Cast ray downward from feet
    local x = transform.x
    local y = transform.y + collision_comp.height/2

    local items, len = collision_world:queryRect(
        x - collision_comp.width/2,
        y,
        collision_comp.width,
        2  -- Small check distance
    )

    for i = 1, len do
        if items[i].collision.layer == "terrain" then
            return true
        end
    end

    return false
end
```

### Wall Detection

```lua
function Player:check_wall()
    local collision_comp = self:get_component("collision")
    local transform = self:get_component("transform")

    -- Check left
    local left_items = collision_world:queryRect(
        transform.x - collision_comp.width/2 - 2,
        transform.y - collision_comp.height/2,
        2,
        collision_comp.height
    )

    -- Check right
    local right_items = collision_world:queryRect(
        transform.x + collision_comp.width/2,
        transform.y - collision_comp.height/2,
        2,
        collision_comp.height
    )

    if #left_items > 0 then return -1 end  -- Left wall
    if #right_items > 0 then return 1 end   -- Right wall
    return 0  -- No wall
end
```

---

## 6. Input System

### Input Manager

**Abstraction Layer:**

```lua
-- systems/input.lua

Input = {
    -- Current frame state
    keys = {},
    gamepad = nil,

    -- Previous frame state
    prev_keys = {},

    -- Action bindings
    bindings = {
        left = {"a", "left", "gamepad:dpleft"},
        right = {"d", "right", "gamepad:dpright"},
        jump = {"space", "w", "up", "gamepad:a"},
        dash = {"lshift", "x", "z", "gamepad:x"},
        deliver = {"s", "down", "e", "gamepad:b"},
        pause = {"escape", "gamepad:start"},
    },

    -- Input buffer (for jump buffering, etc.)
    buffer = {},
}

function Input:update()
    -- Save previous state
    self.prev_keys = self.keys
    self.keys = {}

    -- Poll keyboard
    for action, keys in pairs(self.bindings) do
        for _, key in ipairs(keys) do
            if key:sub(1, 8) == "gamepad:" then
                -- Handle gamepad
                if self.gamepad then
                    local button = key:sub(9)
                    if self.gamepad:isGamepadDown(button) then
                        self.keys[action] = true
                        break
                    end
                end
            else
                -- Handle keyboard
                if love.keyboard.isDown(key) then
                    self.keys[action] = true
                    break
                end
            end
        end
    end

    -- Update buffer
    self:update_buffer()
end

function Input:is_down(action)
    return self.keys[action] == true
end

function Input:is_pressed(action)
    return self.keys[action] and not self.prev_keys[action]
end

function Input:is_released(action)
    return not self.keys[action] and self.prev_keys[action]
end
```

### Input Buffering

```lua
-- systems/input.lua

function Input:buffer_action(action, frames)
    self.buffer[action] = frames or 8
end

function Input:consume_buffer(action)
    if self.buffer[action] and self.buffer[action] > 0 then
        self.buffer[action] = 0
        return true
    end
    return false
end

function Input:update_buffer()
    for action, frames in pairs(self.buffer) do
        if frames > 0 then
            self.buffer[action] = frames - 1
        end
    end
end
```

**Usage in Player:**

```lua
function Player:update(dt)
    -- Check for jump input
    if Input:is_pressed("jump") then
        Input:buffer_action("jump", JUMP_BUFFER_FRAMES)
    end

    -- Consume buffered jump when grounded
    if self.grounded and Input:consume_buffer("jump") then
        self:jump()
    end
end
```

---

## 7. Rendering Pipeline

### Camera System

**Using hump.camera:**

```lua
-- systems/camera.lua

Camera = {
    camera = nil,
    target = nil,  -- Entity to follow
    smoothing = 0.1,
    offset_x = 0,
    offset_y = 0,
    shake = {
        x = 0,
        y = 0,
        intensity = 0,
        duration = 0,
    },
}

function Camera:init()
    self.camera = camera.new()
end

function Camera:update(dt)
    if self.target then
        local transform = self.target:get_component("transform")
        local target_x = transform.x + self.offset_x
        local target_y = transform.y + self.offset_y

        -- Smooth follow
        local cam_x, cam_y = self.camera:position()
        local new_x = lerp(cam_x, target_x, self.smoothing)
        local new_y = lerp(cam_y, target_y, self.smoothing)

        -- Apply screen shake
        if self.shake.duration > 0 then
            new_x = new_x + (math.random() - 0.5) * self.shake.intensity
            new_y = new_y + (math.random() - 0.5) * self.shake.intensity
            self.shake.duration = self.shake.duration - dt
        end

        self.camera:lookAt(new_x, new_y)
    end
end

function Camera:shake(intensity, duration)
    self.shake.intensity = intensity
    self.shake.duration = duration
end
```

### Rendering Layers

**Z-Index Sorting:**

```lua
-- systems/render_system.lua

RenderSystem = {
    entities = {},
    layers = {},
}

function RenderSystem:add(entity)
    table.insert(self.entities, entity)
    self:sort()
end

function RenderSystem:sort()
    table.sort(self.entities, function(a, b)
        local z_a = a:get_component("transform").z_index
        local z_b = b:get_component("transform").z_index
        return z_a < z_b
    end)
end

function RenderSystem:draw()
    for _, entity in ipairs(self.entities) do
        if entity:has_component("sprite") then
            self:draw_entity(entity)
        end
    end
end
```

**Layer Indices:**

```lua
-- constants.lua

RenderLayers = {
    BACKGROUND_FAR = -100,
    BACKGROUND_MID = -50,
    BACKGROUND_NEAR = -10,
    WORLD = 0,
    PLAYER = 10,
    PARTICLES = 20,
    FOREGROUND = 50,
    UI = 100,
}
```

### Parallax Background

```lua
-- systems/parallax.lua

Parallax = {
    layers = {},
}

function Parallax:add_layer(image, scroll_factor, z_index)
    table.insert(self.layers, {
        image = image,
        scroll_factor = scroll_factor,
        z_index = z_index,
        offset_x = 0,
        offset_y = 0,
    })

    -- Sort by z-index
    table.sort(self.layers, function(a, b)
        return a.z_index < b.z_index
    end)
end

function Parallax:draw(camera_x, camera_y)
    for _, layer in ipairs(self.layers) do
        local offset_x = camera_x * layer.scroll_factor
        local offset_y = camera_y * layer.scroll_factor

        -- Draw tiled
        local img_w = layer.image:getWidth()
        local img_h = layer.image:getHeight()

        for x = -1, 2 do
            for y = -1, 2 do
                love.graphics.draw(
                    layer.image,
                    x * img_w - offset_x % img_w,
                    y * img_h - offset_y % img_h
                )
            end
        end
    end
end
```

### Pixel-Perfect Rendering

```lua
-- main.lua

function love.load()
    -- Virtual resolution
    VIRTUAL_WIDTH = 320
    VIRTUAL_HEIGHT = 180

    -- Create canvas
    game_canvas = love.graphics.newCanvas(VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    game_canvas:setFilter("nearest", "nearest")

    -- Calculate scale
    local window_width, window_height = love.graphics.getDimensions()
    local scale_x = window_width / VIRTUAL_WIDTH
    local scale_y = window_height / VIRTUAL_HEIGHT
    game_scale = math.min(scale_x, scale_y)

    -- Calculate letterbox offsets
    offset_x = (window_width - VIRTUAL_WIDTH * game_scale) / 2
    offset_y = (window_height - VIRTUAL_HEIGHT * game_scale) / 2
end

function love.draw()
    -- Draw to canvas
    love.graphics.setCanvas(game_canvas)
    love.graphics.clear()

    current_state:draw()

    -- Draw canvas to screen
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        game_canvas,
        offset_x, offset_y,
        0,
        game_scale, game_scale
    )
end
```

### Particle System

```lua
-- systems/particle_system.lua

ParticleSystem = {
    emitters = {},
}

function ParticleSystem:create_emitter(x, y, config)
    local particle_image = love.graphics.newImage("assets/particles/particle.png")
    local ps = love.graphics.newParticleSystem(particle_image, config.max_particles or 100)

    ps:setParticleLifetime(config.lifetime_min or 0.5, config.lifetime_max or 1.0)
    ps:setEmissionRate(config.emission_rate or 50)
    ps:setSizeVariation(config.size_variation or 0.5)
    ps:setLinearAcceleration(
        config.accel_x_min or 0, config.accel_y_min or 0,
        config.accel_x_max or 0, config.accel_y_max or 0
    )
    ps:setColors(unpack(config.colors or {{1,1,1,1}, {1,1,1,0}}))

    local emitter = {
        ps = ps,
        x = x,
        y = y,
        active = true,
    }

    table.insert(self.emitters, emitter)
    return emitter
end

function ParticleSystem:update(dt)
    for i = #self.emitters, 1, -1 do
        local emitter = self.emitters[i]
        emitter.ps:update(dt)

        -- Remove dead emitters
        if emitter.ps:getCount() == 0 and not emitter.active then
            table.remove(self.emitters, i)
        end
    end
end

function ParticleSystem:draw()
    for _, emitter in ipairs(self.emitters) do
        love.graphics.draw(emitter.ps, emitter.x, emitter.y)
    end
end
```

---

## 8. Audio System

### Audio Manager

```lua
-- systems/audio.lua

Audio = {
    music = {},
    sfx = {},
    current_music = nil,
    music_volume = 1.0,
    sfx_volume = 1.0,
    master_volume = 1.0,
}

function Audio:load_music(name, path)
    local source = love.audio.newSource(path, "stream")
    source:setVolume(self.music_volume * self.master_volume)
    source:setLooping(true)
    self.music[name] = source
end

function Audio:load_sfx(name, path, static)
    local source_type = static and "static" or "stream"
    local source = love.audio.newSource(path, source_type)
    source:setVolume(self.sfx_volume * self.master_volume)
    self.sfx[name] = source
end

function Audio:play_music(name, fade_time)
    if self.current_music == name then return end

    -- Fade out current
    if self.current_music and self.music[self.current_music] then
        -- TODO: Implement fade (use timer or tween library)
        self.music[self.current_music]:stop()
    end

    -- Fade in new
    if self.music[name] then
        self.music[name]:play()
        self.current_music = name
    end
end

function Audio:play_sfx(name, pitch, volume)
    if not self.sfx[name] then return end

    -- Clone source for overlapping sounds
    local source = self.sfx[name]:clone()
    source:setPitch(pitch or 1.0)
    source:setVolume((volume or 1.0) * self.sfx_volume * self.master_volume)
    source:play()
end
```

### Adaptive Music System

```lua
-- systems/adaptive_music.lua

AdaptiveMusic = {
    layers = {},
    current_state = "calm",
    states = {
        calm = {layers = {"base", "rhythm"}},
        warning = {layers = {"base", "rhythm", "harmony"}},
        urgent = {layers = {"base", "rhythm", "harmony", "tension"}},
        critical = {layers = {"base", "rhythm", "harmony", "tension"}},
    },
    transition_time = 1.0,
}

function AdaptiveMusic:load(name, layer_paths)
    self.layers = {}
    for layer_name, path in pairs(layer_paths) do
        local source = love.audio.newSource(path, "stream")
        source:setLooping(true)
        source:setVolume(0)  -- Start muted
        source:play()  -- Play all layers synced
        self.layers[layer_name] = {
            source = source,
            target_volume = 0,
            current_volume = 0,
        }
    end
end

function AdaptiveMusic:set_state(state)
    if self.current_state == state then return end
    self.current_state = state

    local active_layers = self.states[state].layers

    for layer_name, layer in pairs(self.layers) do
        if table.contains(active_layers, layer_name) then
            layer.target_volume = 1.0
        else
            layer.target_volume = 0.0
        end
    end
end

function AdaptiveMusic:update(dt)
    for _, layer in pairs(self.layers) do
        -- Smooth volume transition
        if layer.current_volume ~= layer.target_volume then
            local delta = (layer.target_volume - layer.current_volume) * (dt / self.transition_time)
            layer.current_volume = layer.current_volume + delta
            layer.source:setVolume(layer.current_volume * Audio.music_volume * Audio.master_volume)
        end
    end
end
```

**Integration with Gameplay:**

```lua
-- In gameplay update:
function GameState:update(dt)
    -- Update adaptive music based on timer
    if self.timer > 90 then
        AdaptiveMusic:set_state("calm")
    elseif self.timer > 45 then
        AdaptiveMusic:set_state("warning")
    elseif self.timer > 15 then
        AdaptiveMusic:set_state("urgent")
    else
        AdaptiveMusic:set_state("critical")
    end

    AdaptiveMusic:update(dt)
end
```

---

## 9. State Management

### State Machine

```lua
-- systems/state_manager.lua

StateManager = {
    states = {},
    current = nil,
    previous = nil,
}

function StateManager:register(name, state)
    self.states[name] = state
end

function StateManager:switch(name, ...)
    if self.current then
        self.current:exit()
    end

    self.previous = self.current
    self.current = self.states[name]

    if self.current then
        self.current:enter(...)
    end
end

function StateManager:update(dt)
    if self.current then
        self.current:update(dt)
    end
end

function StateManager:draw()
    if self.current then
        self.current:draw()
    end
end
```

### State Template

```lua
-- states/base_state.lua

BaseState = {}

function BaseState:new()
    local state = {}
    setmetatable(state, self)
    self.__index = self
    return state
end

function BaseState:enter(...) end
function BaseState:exit() end
function BaseState:update(dt) end
function BaseState:draw() end
function BaseState:keypressed(key) end
function BaseState:mousepressed(x, y, button) end
```

### Game States

**Menu State:**

```lua
-- states/menu_state.lua

MenuState = BaseState:new()

function MenuState:enter()
    Audio:play_music("main_theme")
    self.selected_option = 1
    self.options = {"Start Night", "Letter Archive", "Options", "Exit"}
end

function MenuState:update(dt)
    -- Handle input
    if Input:is_pressed("up") then
        self.selected_option = math.max(1, self.selected_option - 1)
        Audio:play_sfx("menu_move")
    elseif Input:is_pressed("down") then
        self.selected_option = math.min(#self.options, self.selected_option + 1)
        Audio:play_sfx("menu_move")
    elseif Input:is_pressed("jump") then
        self:select_option()
    end
end

function MenuState:select_option()
    Audio:play_sfx("menu_select")
    if self.selected_option == 1 then
        StateManager:switch("night_select")
    elseif self.selected_option == 2 then
        StateManager:switch("letter_archive")
    -- etc.
    end
end
```

**Game State:**

```lua
-- states/game_state.lua

GameState = BaseState:new()

function GameState:enter(night_number)
    self.night = night_number
    self.timer = NIGHT_TIMERS[night_number]
    self.deliveries_remaining = NIGHT_DELIVERIES[night_number]

    -- Load level
    self.level = Level:load(night_number)

    -- Create player
    self.player = Player:new(self.level.spawn_x, self.level.spawn_y)

    -- Initialize systems
    Camera:set_target(self.player)

    Audio:play_music("night_run")
end

function GameState:update(dt)
    -- Update timer
    self.timer = self.timer - dt
    if self.timer <= 0 then
        self:game_over(false)
        return
    end

    -- Update player
    self.player:update(dt)

    -- Update camera
    Camera:update(dt)

    -- Update systems
    ParticleSystem:update(dt)

    -- Check win condition
    if self.deliveries_remaining == 0 then
        self:game_over(true)
    end
end

function GameState:game_over(success)
    StateManager:switch("results", {
        success = success,
        night = self.night,
        score = self:calculate_score(),
    })
end
```

---

## 10. Level System

### Level Data Format

**JSON Structure:**

```json
{
    "version": 1,
    "night": 1,
    "name": "First Flight",
    "spawn": {
        "x": 80,
        "y": 100
    },
    "platforms": [
        {
            "x": 0,
            "y": 150,
            "width": 160,
            "height": 16,
            "type": "rooftop"
        }
    ],
    "delivery_zones": [
        {
            "x": 120,
            "y": 135,
            "id": "delivery_1",
            "type": "standard",
            "letter_fragment_id": 1
        }
    ],
    "hazards": [
        {
            "x": 200,
            "y": 140,
            "type": "vent",
            "pattern": "2s_on_1.5s_off"
        }
    ],
    "powerups": [
        {
            "x": 240,
            "y": 120,
            "type": "coffee"
        }
    ],
    "background_layers": [
        {
            "image": "bg_far.png",
            "scroll_factor": 0.1,
            "z_index": -100
        }
    ]
}
```

### Level Loader

```lua
-- systems/level.lua

Level = {}

function Level:load(night_number)
    local path = string.format("assets/levels/night_%02d.json", night_number)
    local data = json.decode(love.filesystem.read(path))

    local level = {
        night = night_number,
        spawn_x = data.spawn.x,
        spawn_y = data.spawn.y,
        platforms = {},
        delivery_zones = {},
        hazards = {},
        powerups = {},
    }

    -- Create platforms
    for _, platform_data in ipairs(data.platforms) do
        local platform = Platform:new(platform_data)
        table.insert(level.platforms, platform)
        CollisionSystem:add(platform, platform_data.x, platform_data.y, platform_data.width, platform_data.height)
    end

    -- Create delivery zones
    for _, delivery_data in ipairs(data.delivery_zones) do
        local zone = DeliveryZone:new(delivery_data)
        table.insert(level.delivery_zones, zone)
    end

    -- Create hazards
    for _, hazard_data in ipairs(data.hazards) do
        local hazard = self:create_hazard(hazard_data)
        table.insert(level.hazards, hazard)
    end

    -- Create powerups
    for _, powerup_data in ipairs(data.powerups) do
        local powerup = PowerUp:new(powerup_data)
        table.insert(level.powerups, powerup)
    end

    -- Load backgrounds
    Parallax:clear()
    for _, bg_data in ipairs(data.background_layers) do
        local img = love.graphics.newImage("assets/backgrounds/" .. bg_data.image)
        Parallax:add_layer(img, bg_data.scroll_factor, bg_data.z_index)
    end

    return level
end
```

### Procedural Variation System

```lua
-- systems/level_variation.lua

LevelVariation = {}

function LevelVariation:randomize(level, seed)
    -- Set seed for reproducibility
    math.randomseed(seed)

    -- Randomize delivery zone positions (within valid ranges)
    for _, zone in ipairs(level.delivery_zones) do
        zone.x = zone.x + math.random(-16, 16)
        zone.y = zone.y + math.random(-8, 8)
    end

    -- Randomize hazard timing
    for _, hazard in ipairs(level.hazards) do
        hazard.phase_offset = math.random() * hazard.cycle_duration
    end

    -- Randomize powerup positions
    for _, powerup in ipairs(level.powerups) do
        powerup.x = powerup.x + math.random(-32, 32)
    end

    -- Randomize decorative elements
    -- (chimneys, window positions, etc.)
end
```

### Tiled Integration (Optional)

```lua
-- Using STI (Simple Tiled Implementation) library

function Level:load_from_tiled(night_number)
    local sti = require "libraries/sti"
    local map = sti(string.format("assets/maps/night_%02d.lua", night_number))

    -- Extract objects from Tiled layers
    local platforms_layer = map.layers["Platforms"]
    local delivery_layer = map.layers["Deliveries"]

    -- Convert Tiled objects to game entities
    -- ...

    return level
end
```

---

## 11. Data Structures

### Save Data Structure

```lua
-- data/save_data.lua

SaveData = {
    version = 1,

    -- Progress
    nights_unlocked = 1,
    nights_completed = {},  -- Array of night numbers
    best_ranks = {},        -- {night_number = rank_letter}
    best_scores = {},       -- {night_number = score}

    -- Letter fragments
    fragments_collected = {},  -- Array of fragment IDs

    -- Settings
    settings = {
        music_volume = 1.0,
        sfx_volume = 1.0,
        master_volume = 1.0,
        screen_shake = true,
        colorblind_mode = false,
        -- etc.
    },

    -- Stats
    stats = {
        total_deliveries = 0,
        total_playtime = 0,
        highest_combo = 0,
        -- etc.
    },
}
```

### Delivery Zone Structure

```lua
-- entities/delivery_zone.lua

DeliveryZone = {
    id = "",
    x = 0,
    y = 0,
    radius = 32,
    type = "standard",  -- "standard", "priority", "fragile", "chain"
    letter_fragment_id = nil,
    completed = false,
    glow_phase = 0,

    -- Chain delivery specific
    chain_index = 0,
    chain_next = nil,
}
```

### Letter Fragment Structure

```lua
-- data/letter_fragments.lua

LetterFragment = {
    id = 1,
    text = "You never look up, but I still see your light.",
    rarity = "common",  -- "common", "uncommon", "rare", "legendary"
    category = "mundane",  -- "mundane", "wistful", "mysterious", "revelatory"
}

-- Database of all fragments
LETTER_FRAGMENTS = {
    [1] = {
        id = 1,
        text = "Remind me to water the plants on Tuesday.",
        rarity = "common",
        category = "mundane",
    },
    -- ... (30 total)
}
```

---

## 12. File Organization

### Directory Structure

```
courier-cat/
├── main.lua                    # Entry point
├── conf.lua                    # LÖVE configuration
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   │   ├── idle.png
│   │   │   ├── run.png
│   │   │   └── jump.png
│   │   ├── tiles/
│   │   │   ├── rooftop_01.png
│   │   │   └── ...
│   │   ├── props/
│   │   └── ui/
│   ├── audio/
│   │   ├── music/
│   │   │   ├── main_theme.ogg
│   │   │   ├── night_run/
│   │   │   │   ├── base.ogg
│   │   │   │   ├── rhythm.ogg
│   │   │   │   ├── harmony.ogg
│   │   │   │   └── tension.ogg
│   │   │   └── ...
│   │   └── sfx/
│   │       ├── jump.wav
│   │       ├── dash.wav
│   │       └── ...
│   ├── levels/
│   │   ├── night_01.json
│   │   ├── night_02.json
│   │   └── ...
│   ├── backgrounds/
│   │   ├── bg_far.png
│   │   ├── bg_mid.png
│   │   └── bg_near.png
│   ├── fonts/
│   │   └── pixel_font.ttf
│   └── shaders/
│       └── palette_swap.glsl
├── src/
│   ├── constants.lua           # Game constants
│   ├── utils.lua               # Utility functions
│   ├── components/
│   │   ├── transform.lua
│   │   ├── physics.lua
│   │   ├── collision.lua
│   │   ├── sprite.lua
│   │   └── animation.lua
│   ├── entities/
│   │   ├── entity.lua          # Base entity class
│   │   ├── player.lua
│   │   ├── delivery_zone.lua
│   │   ├── powerup.lua
│   │   └── hazard.lua
│   ├── systems/
│   │   ├── input.lua
│   │   ├── physics_system.lua
│   │   ├── collision_system.lua
│   │   ├── render_system.lua
│   │   ├── audio.lua
│   │   ├── adaptive_music.lua
│   │   ├── camera.lua
│   │   ├── parallax.lua
│   │   ├── particle_system.lua
│   │   ├── level.lua
│   │   └── state_manager.lua
│   ├── states/
│   │   ├── base_state.lua
│   │   ├── menu_state.lua
│   │   ├── night_select_state.lua
│   │   ├── game_state.lua
│   │   ├── pause_state.lua
│   │   ├── results_state.lua
│   │   └── letter_archive_state.lua
│   ├── ui/
│   │   ├── button.lua
│   │   ├── timer_display.lua
│   │   ├── combo_display.lua
│   │   └── hud.lua
│   └── data/
│       ├── save_data.lua
│       └── letter_fragments.lua
├── libraries/
│   ├── bump.lua                # Collision
│   ├── anim8.lua               # Animation
│   ├── camera.lua              # hump.camera
│   ├── json.lua                # JSON parsing
│   └── sti/                    # Simple Tiled Implementation (optional)
└── README.md
```

---

## 13. External Libraries

### Core Libraries

**1. bump.lua - Collision Detection**
- Version: Latest
- Purpose: AABB collision detection and resolution
- License: MIT
- URL: https://github.com/kikito/bump.lua

**2. anim8 - Animation**
- Version: Latest
- Purpose: Sprite animation management
- License: MIT
- URL: https://github.com/kikito/anim8

**3. hump.camera - Camera System**
- Version: Latest
- Purpose: Camera movement and effects
- License: MIT
- URL: https://github.com/vrld/hump

**4. json.lua - JSON Parsing**
- Version: Latest
- Purpose: Level data parsing
- License: MIT
- URL: https://github.com/rxi/json.lua

### Optional Libraries

**5. STI - Simple Tiled Implementation**
- Version: Latest
- Purpose: Tiled map loader (if using Tiled)
- License: MIT
- URL: https://github.com/karai17/Simple-Tiled-Implementation

**6. lume - Utility Functions**
- Version: Latest
- Purpose: General Lua utilities
- License: MIT
- URL: https://github.com/rxi/lume

**7. flux - Tweening**
- Version: Latest
- Purpose: Smooth value interpolation
- License: MIT
- URL: https://github.com/rxi/flux

### Library Integration

```lua
-- libraries/init.lua

-- Load all libraries
bump = require "libraries.bump"
anim8 = require "libraries.anim8"
camera = require "libraries.camera"
json = require "libraries.json"

-- Optional
-- sti = require "libraries.sti"
-- lume = require "libraries.lume"
-- flux = require "libraries.flux"
```

---

## 14. Asset Pipeline

### Sprite Creation Workflow

1. **Create sprites in Aseprite/GraphicsGale**
   - 16×16 tile size
   - 16-color palette
   - Export as PNG sprite sheets

2. **Organize sprite sheets**
   - Group by entity type
   - Include metadata (frame size, duration)

3. **Load in game**
   ```lua
   local sprite_sheet = love.graphics.newImage("assets/sprites/player/run.png")
   local grid = anim8.newGrid(16, 16, sprite_sheet:getWidth(), sprite_sheet:getHeight())
   local run_anim = anim8.newAnimation(grid('1-4', 1), 0.1)
   ```

### Audio Asset Pipeline

**Music:**
- Create in DAW (FL Studio, Ableton, etc.)
- Export stems for adaptive music
- Convert to OGG Vorbis (lower file size than WAV)
- Target bitrate: 160-192 kbps

**SFX:**
- Create/find sounds
- Process in Audacity
- Normalize volume
- Export as WAV or OGG
- Keep file sizes small (< 100KB each)

**Integration:**
```lua
function Audio:load_assets()
    -- Music
    self:load_music("main_theme", "assets/audio/music/main_theme.ogg")

    -- Adaptive music layers
    AdaptiveMusic:load("night_run", {
        base = "assets/audio/music/night_run/base.ogg",
        rhythm = "assets/audio/music/night_run/rhythm.ogg",
        harmony = "assets/audio/music/night_run/harmony.ogg",
        tension = "assets/audio/music/night_run/tension.ogg",
    })

    -- SFX
    self:load_sfx("jump", "assets/audio/sfx/jump.wav", true)
    self:load_sfx("dash", "assets/audio/sfx/dash.wav", true)
    -- etc.
end
```

### Level Creation Workflow

**Option 1: JSON by Hand**
- Create JSON file
- Define platforms, delivery zones, etc.
- Test in-game
- Iterate

**Option 2: Tiled Editor**
- Create tilemap in Tiled
- Add object layers for entities
- Export as Lua or JSON
- Load via STI library

**Option 3: In-Game Editor (Stretch Goal)**
- Build level editor mode
- Place tiles and entities visually
- Export to JSON
- Professional workflow

---

## 15. Performance Optimization

### Target Performance

- **Frame Rate:** 60 FPS (fixed)
- **Frame Time Budget:** 16.67ms
- **Memory Usage:** < 100MB
- **Load Time:** < 2 seconds

### Optimization Strategies

**1. Object Pooling**

```lua
-- utils/pool.lua

Pool = {}

function Pool:new(create_func, initial_size)
    local pool = {
        create = create_func,
        available = {},
        active = {},
    }

    -- Pre-allocate
    for i = 1, initial_size do
        table.insert(pool.available, create_func())
    end

    setmetatable(pool, self)
    self.__index = self
    return pool
end

function Pool:acquire()
    local obj
    if #self.available > 0 then
        obj = table.remove(self.available)
    else
        obj = self.create()
    end
    table.insert(self.active, obj)
    return obj
end

function Pool:release(obj)
    for i, active_obj in ipairs(self.active) do
        if active_obj == obj then
            table.remove(self.active, i)
            table.insert(self.available, obj)
            obj:reset()  -- Reset state
            return
        end
    end
end
```

**Usage:**
```lua
-- Pool particles
particle_pool = Pool:new(function() return Particle:new() end, 100)

-- Acquire
local particle = particle_pool:acquire()

-- Release when done
particle_pool:release(particle)
```

**2. Spatial Partitioning**

- bump.lua already handles this with its grid
- Use appropriate cell size (16px recommended)

**3. Render Culling**

```lua
function RenderSystem:draw()
    local cam_x, cam_y = Camera.camera:position()
    local view_left = cam_x - VIRTUAL_WIDTH/2
    local view_right = cam_x + VIRTUAL_WIDTH/2
    local view_top = cam_y - VIRTUAL_HEIGHT/2
    local view_bottom = cam_y + VIRTUAL_HEIGHT/2

    for _, entity in ipairs(self.entities) do
        local transform = entity:get_component("transform")

        -- Cull entities outside view
        if transform.x > view_left and transform.x < view_right and
           transform.y > view_top and transform.y < view_bottom then
            self:draw_entity(entity)
        end
    end
end
```

**4. Batch Drawing**

```lua
-- Use SpriteBatch for static tiles
function Level:create_tile_batch()
    local tileset_image = love.graphics.newImage("assets/tiles/tileset.png")
    local batch = love.graphics.newSpriteBatch(tileset_image, 1000)

    for _, tile in ipairs(self.tiles) do
        batch:add(tile.quad, tile.x, tile.y)
    end

    batch:flush()
    self.tile_batch = batch
end

function Level:draw()
    love.graphics.draw(self.tile_batch)
end
```

**5. Minimize Garbage Collection**

- Reuse tables instead of creating new ones
- Avoid string concatenation in loops
- Use object pools
- Profile with `collectgarbage("count")`

---

## 16. Save System

### Save File Location

```lua
-- systems/save_system.lua

SaveSystem = {}

function SaveSystem:get_save_path()
    -- LÖVE save directory: OS-specific
    -- Windows: %APPDATA%/LOVE/courier-cat
    -- macOS: ~/Library/Application Support/LOVE/courier-cat
    -- Linux: ~/.local/share/love/courier-cat
    return "save_data.json"
end
```

### Saving

```lua
function SaveSystem:save()
    local data = json.encode(SaveData)
    love.filesystem.write(self:get_save_path(), data)
end
```

### Loading

```lua
function SaveSystem:load()
    local path = self:get_save_path()

    if love.filesystem.getInfo(path) then
        local data = love.filesystem.read(path)
        local loaded = json.decode(data)

        -- Merge with SaveData (in case of version changes)
        for k, v in pairs(loaded) do
            SaveData[k] = v
        end

        return true
    end

    return false
end
```

### Auto-Save

```lua
-- Trigger auto-save after:
-- - Completing a night
-- - Unlocking a letter fragment
-- - Changing settings

function GameState:complete_night()
    -- Update save data
    SaveData.nights_completed[self.night] = true
    SaveData.best_ranks[self.night] = self.final_rank
    SaveData.best_scores[self.night] = math.max(
        SaveData.best_scores[self.night] or 0,
        self.final_score
    )

    -- Auto-save
    SaveSystem:save()
end
```

---

## 17. Build & Deployment

### conf.lua Configuration

```lua
-- conf.lua

function love.conf(t)
    t.identity = "courier-cat"
    t.version = "11.4"
    t.console = false  -- Set to true for debugging

    t.window.title = "Courier Cat"
    t.window.icon = "assets/icon.png"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.vsync = 1
    t.window.msaa = 0

    t.modules.joystick = true
    t.modules.physics = false  -- Not using love.physics
end
```

### Creating .love File

```bash
# From project root
zip -9 -r courier-cat.love . -x "*.git*" -x "*.DS_Store"
```

### Platform Builds

**Windows:**
```bash
# Concatenate love with .love file
cat love.exe courier-cat.love > courier-cat.exe
```

**macOS:**
```bash
# Copy .love into LÖVE.app bundle
cp courier-cat.love Courier\ Cat.app/Contents/Resources/
```

**Linux:**
```bash
# Distribute .love file
# Users run: love courier-cat.love
```

### Distribution

**Itch.io:**
- Upload .love file
- Upload platform-specific builds
- Set pricing (free or paid)

**Steam (Stretch Goal):**
- Integrate Steamworks (if needed)
- Follow Steam Direct process

---

## 18. Testing Strategy

### Unit Testing

**Using busted framework:**

```lua
-- tests/test_physics.lua

describe("Physics Component", function()
    local Physics = require "src.components.physics"

    it("should apply gravity", function()
        local phys = Physics:new()
        phys.grounded = false
        phys:update(1/60)

        assert.is_true(phys.velocity_y > 0)
    end)

    it("should clamp velocity", function()
        local phys = Physics:new()
        phys.velocity_x = 1000
        phys:update(0)

        assert.is_true(phys.velocity_x <= phys.max_velocity_x)
    end)
end)
```

**Run tests:**
```bash
busted tests/
```

### Integration Testing

- Manually test each night
- Verify delivery mechanics
- Test edge cases (combo breaking, timer expiry)
- Test all input combinations

### Playtesting

**Alpha Testing (Weeks 1-4):**
- Developer testing
- Core mechanics validation
- Basic gameplay loop

**Beta Testing (Weeks 5-8):**
- External playtesters (5-10 people)
- Gather feedback on difficulty
- Find bugs and edge cases
- Validate design pillars

**Metrics to Track:**
- Average completion time
- Success rate per night
- Common failure points
- Player-reported issues

### Performance Testing

```lua
-- Debug overlay
function love.draw()
    current_state:draw()

    if DEBUG_MODE then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
        love.graphics.print("Memory: " .. collectgarbage("count") .. " KB", 10, 30)
        love.graphics.print("Entities: " .. #RenderSystem.entities, 10, 50)
    end
end
```

---

## 19. Development Phases

### Phase 1: Prototype (Week 1-2)

**Goal:** Prove core movement feels good

**Deliverables:**
- Basic player movement (run, jump)
- One test level (platforms only)
- Camera following player
- Placeholder graphics (rectangles)

**Success Criteria:**
- Movement feels responsive
- Jump height/distance is satisfying
- Can traverse basic platforming

---

### Phase 2: Vertical Slice (Week 3-5)

**Goal:** One complete night with all systems

**Deliverables:**
- Full movement (dash, wall-slide, wall-jump)
- Delivery system working
- Timer system functional
- Scoring and combo system
- 5 delivery points
- Basic hazards (1-2 types)
- Placeholder art and audio
- Win/lose states

**Success Criteria:**
- Complete gameplay loop functional
- Night can be completed in 3-5 minutes
- All core mechanics feel good

---

### Phase 3: Content & Polish (Week 6-8)

**Goal:** Expand content, add juice

**Deliverables:**
- 3 playable nights with progression
- All movement mechanics polished
- All hazard types implemented
- Power-ups functional
- Pixel art sprites (player, tiles, props)
- UI implementation (moon timer, combo display)
- Audio (music track, core SFX)
- Particle effects
- Animations

**Success Criteria:**
- Visually cohesive
- 3 nights feel distinct
- Audio enhances mood
- Players describe as "fun"

---

### Phase 4: Full Production (Week 9-12)

**Goal:** Complete 10 nights, add features

**Deliverables:**
- 10 nights total
- All art assets finalized
- All audio assets (music, SFX)
- Letter fragment system
- Menu system (main, night select, results)
- Save system
- Settings menu
- Accessibility options
- Parallax backgrounds
- Adaptive music system

**Success Criteria:**
- All nights completable
- Difficulty curve smooth
- Letter fragments collectible
- Save/load working

---

### Phase 5: Beta & Refinement (Week 13-14)

**Goal:** Bug fixing and balancing

**Deliverables:**
- Bug fixes
- Balancing adjustments
- Playtester feedback implemented
- Performance optimization
- Platform builds (Windows, macOS, Linux)

**Success Criteria:**
- No critical bugs
- Playtesters enjoy experience
- 60 FPS on target hardware

---

### Phase 6: Launch Prep (Week 15-16)

**Goal:** Marketing and release

**Deliverables:**
- Trailer
- Screenshots
- Store page (itch.io)
- Press kit
- Release!

---

## 20. Technical Constraints

### Platform Requirements

**Minimum Specs:**
- OS: Windows 7+, macOS 10.11+, Ubuntu 16.04+
- CPU: Dual-core 1.5 GHz
- RAM: 512 MB
- GPU: OpenGL 2.1 support
- Storage: 100 MB

**Target Hardware:**
- Modern laptops (2015+)
- Integrated graphics OK
- Should run on low-end machines

### File Size Budget

- Total game size: < 100 MB
- Compressed .love file: < 30 MB
- Breakdown:
  - Sprites: ~10 MB
  - Audio: ~15 MB
  - Levels: ~1 MB
  - Code: ~1 MB

### LÖVE Limitations

**Positive:**
- Fast 2D rendering
- Cross-platform
- Easy distribution
- Great for pixel art

**Negative:**
- No built-in UI library (need to build)
- No built-in entity system (need to build)
- Limited 3D support (not relevant for this project)
- No visual editor (level creation is manual)

### Design Constraints

**Technical:**
- 60 FPS fixed timestep
- Pixel-perfect rendering (no sub-pixel movement)
- Limited color palette (16 colors)
- Small sprite size (16×16)

**Scope:**
- Solo developer or small team
- 16-week development timeline
- Limited budget
- Focused on core experience

---

## Appendix: Code Style Guide

### Naming Conventions

**Variables:**
```lua
local player_speed = 120  -- snake_case
local MAX_HEALTH = 100    -- SCREAMING_SNAKE_CASE for constants
```

**Functions:**
```lua
function calculate_score()  -- snake_case
function Player:update()    -- PascalCase for classes, snake_case for methods
```

**Tables/Classes:**
```lua
Player = {}     -- PascalCase
AudioSystem = {}
```

### File Naming

```
player.lua              -- snake_case
collision_system.lua
adaptive_music.lua
```

### Comments

```lua
-- Single-line comment for brief explanations

--[[
    Multi-line comment
    for longer explanations
    or documentation
]]

--- Documentation comment (LDoc style)
-- @param dt Delta time in seconds
-- @return Updated velocity
function Physics:update(dt)
    -- ...
end
```

### Code Organization

```lua
-- 1. Requires at top
local bump = require "libraries.bump"

-- 2. Local variables and constants
local GRAVITY = 800

-- 3. Class definition
Player = {}

-- 4. Constructor
function Player:new()
    -- ...
end

-- 5. Methods
function Player:update(dt)
    -- ...
end

-- 6. Return (if module)
return Player
```

---

**End of Technical Design Document**

*This TDD will evolve as implementation progresses and technical challenges are discovered.*
