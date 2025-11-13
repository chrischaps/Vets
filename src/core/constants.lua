-- constants.lua
-- Global game constants for physics, movement, and gameplay

local Constants = {}

-- Physics Constants
Constants.GRAVITY = 800              -- Gravity acceleration (px/s²)
Constants.TERMINAL_VELOCITY = 500    -- Max falling speed (px/s)
Constants.RUN_SPEED = 120            -- Player run speed (px/s)

-- Movement Constants (will be expanded as we add more movement)
Constants.JUMP_FORCE = -300          -- Jump initial velocity (px/s)
Constants.JUMP_HOLD_GRAVITY = 0.5   -- Gravity multiplier while holding jump
Constants.ACCELERATION = 1200        -- Horizontal acceleration (px/s²)
Constants.DECELERATION = 0.15        -- Friction when releasing input (0-1)

-- Wall-Sliding Constants
Constants.WALL_SLIDE_SPEED = 40      -- Wall slide descent speed (px/s)
Constants.WALL_STICK_TIME = 0.1      -- Time buffer for wall sticking (seconds)

-- Wall-Jumping Constants
Constants.WALL_JUMP_FORCE_X = 200    -- Horizontal force away from wall (px/s)
Constants.WALL_JUMP_FORCE_Y = -320   -- Upward force for wall jump (px/s)
Constants.WALL_JUMP_CONTROL_LOCK = 0.15  -- Time before player regains directional control (seconds)

-- Player Constants
Constants.PLAYER_WIDTH = 10          -- Player hitbox width (px)
Constants.PLAYER_HEIGHT = 14         -- Player hitbox height (px)

-- Dashing Constants
Constants.DASH_SPEED = 300           -- Dash velocity (px/s)
Constants.DASH_DURATION = 0.2        -- Dash duration (seconds)
Constants.DASH_DISTANCE = 60         -- Dash distance (px) = DASH_SPEED * DASH_DURATION
Constants.DASH_COOLDOWN = 0.5        -- Cooldown after dash ends (seconds)
Constants.DASH_IFRAME_DURATION = 0.1 -- Invulnerability duration during dash (seconds)

return Constants
