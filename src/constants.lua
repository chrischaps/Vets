-- src/constants.lua
-- Game constants and configuration values

local constants = {}

-- Physics Constants
constants.GRAVITY = 800  -- pixels/second²
constants.TERMINAL_VELOCITY = 500  -- pixels/second

-- Player Movement Constants
constants.PLAYER = {
    -- Running
    RUN_SPEED = 120,  -- pixels/second
    RUN_ACCELERATION = 1200,  -- pixels/second²
    AIR_CONTROL = 0.8,  -- 80% control in air

    -- Jumping
    JUMP_FORCE = -300,  -- pixels/second
    JUMP_HEIGHT = 48,  -- pixels (3 tiles)
    JUMP_DURATION = 0.4,  -- seconds to apex
    JUMP_HOLD_GRAVITY = 0.5,  -- Reduced gravity while holding jump
    WALL_JUMP_FORCE_X = 200,  -- pixels/second
    WALL_JUMP_FORCE_Y = -320,  -- pixels/second

    -- Dashing
    DASH_SPEED = 300,  -- pixels/second
    DASH_DURATION = 0.2,  -- seconds
    DASH_DISTANCE = 60,  -- pixels
    DASH_COOLDOWN = 0.5,  -- seconds

    -- Wall Sliding
    WALL_SLIDE_SPEED = 40,  -- pixels/second (slow fall)
    WALL_STICK_TIME = 0.1,  -- seconds

    -- Input Buffering
    JUMP_BUFFER_FRAMES = 8,  -- frames (0.13s at 60fps)
    COYOTE_FRAMES = 5,  -- frames (0.083s at 60fps)

    -- Hitbox
    HITBOX_WIDTH = 10,  -- pixels
    HITBOX_HEIGHT = 14,  -- pixels
    SPRITE_SIZE = 16,  -- pixels (16x16 sprite)
}

-- Collision Layers
constants.CollisionLayers = {
    PLAYER = "player",
    TERRAIN = "terrain",
    HAZARD = "hazard",
    DELIVERY_ZONE = "delivery",
    POWERUP = "powerup",
    TRIGGER = "trigger",
}

-- Render Layers (Z-index)
constants.RenderLayers = {
    BACKGROUND_FAR = -100,
    BACKGROUND_MID = -50,
    BACKGROUND_NEAR = -10,
    WORLD = 0,
    PLAYER = 10,
    PARTICLES = 20,
    FOREGROUND = 50,
    UI = 100,
}

-- Game Configuration
constants.FIXED_DT = 1/60  -- 60 FPS fixed timestep
constants.MAX_FRAME_SKIP = 5  -- Prevent spiral of death

return constants
