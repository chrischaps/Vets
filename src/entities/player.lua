-- player.lua
-- Player entity with running mechanics

local Entity = require("src.entities.entity")
local Transform = require("src.components.transform")
local Physics = require("src.components.physics")
local Collision = require("src.components.collision")
local Animation = require("src.components.animation")
local Constants = require("src.core.constants")
local Time = require("src.core.time")

local Player = {}
Player.__index = Player

-- Create a new player entity
function Player.new(x, y, collision_system, input_system)
    local self = setmetatable({}, Player)

    -- Store collision system reference
    self.collision_system = collision_system

    -- Store input system reference
    self.input_system = input_system

    -- Create base entity
    self.entity = Entity.new("player")

    -- Add Transform component
    self.transform = Transform.new(x or 160, y or 90)
    self.entity:addComponent("transform", self.transform)

    -- Add Physics component with initial values
    self.physics = Physics.new()
    self.physics.gravity_scale = 1  -- Use normal gravity
    self.physics:setMaxVelocity(Constants.RUN_SPEED, Constants.TERMINAL_VELOCITY)
    self.entity:addComponent("physics", self.physics)

    -- Add Collision component with player hitbox (10×14 pixels)
    self.collision = Collision.new(Constants.PLAYER_WIDTH, Constants.PLAYER_HEIGHT, Collision.SHAPE.AABB)
    self.collision:setLayer(Collision.LAYER.PLAYER)
    self.collision:setMask(Collision.LAYER.TERRAIN)
    self.entity:addComponent("collision", self.collision)

    -- Player state
    self.grounded = false
    self.facing_right = true
    self.jumping = false  -- Is player currently jumping?
    self.jump_held = false  -- Is jump button currently held?
    self.dash_held = false  -- Is dash button currently held?

    -- Input buffering state
    self.coyote_frames = 0  -- Remaining frames of coyote time (can jump after leaving ground)

    -- Wall-sliding state
    self.wall_sliding = false  -- Is player currently wall-sliding?
    self.on_wall = false  -- Is player touching a wall?
    self.wall_direction = 0  -- Direction of wall: -1 left, 1 right, 0 none
    self.wall_stick_timer = 0  -- Timer for wall stick buffer

    -- Wall-jumping state
    self.control_lock_timer = 0  -- Timer for directional control lock after wall-jump

    -- Dashing state
    self.dashing = false  -- Is player currently dashing?
    self.dash_timer = 0  -- Time remaining in current dash
    self.dash_cooldown_timer = 0  -- Cooldown before next dash
    self.dash_direction_x = 0  -- Dash direction X (-1, 0, or 1)
    self.dash_direction_y = 0  -- Dash direction Y (-1, 0, or 1)
    self.air_dash_charges = 1  -- Number of air dashes available (resets on landing/wall touch)
    self.iframe_timer = 0  -- Invulnerability timer during dash
    self.is_ground_dash = false  -- Was this dash started on ground? (for dash canceling)

    -- Movement input
    self.input_x = 0  -- -1 for left, 1 for right, 0 for no input
    self.input_jump = false  -- Jump button pressed this frame
    self.input_jump_release = false  -- Jump button released this frame
    self.input_dash = false  -- Dash button pressed this frame
    self.input_deliver = false  -- Deliver button pressed this frame

    -- Delivery state
    self.delivery_zones = {}  -- Reference to delivery zones (set externally)
    self.deliver_held = false  -- Is deliver button currently held?
    self.timer = nil  -- Reference to timer system (set externally)
    self.moon_timer = nil  -- Reference to moon timer UI (set externally)
    self.scoring = nil  -- Reference to scoring system (set externally)

    -- Combo tracking (VETS-26)
    self.combo_count = 0  -- Current combo streak (consecutive deliveries without ground touch)
    self.combo_was_grounded = false  -- Track grounded state for combo reset detection

    -- Visual representation (placeholder rectangle)
    self.color = {0.9, 0.6, 0.3}  -- Orange color for the cat

    -- Create placeholder sprite sheet
    -- Total frames: idle(2) + run(4) + jump(3) + dash(2) + wall-slide(1) = 12 frames
    -- Layout: 12 frames horizontal, 16x16 pixels each = 192x16 sprite sheet
    self.sprite_sheet = self:createPlaceholderSpriteSheet()

    -- Create Animation component
    self.animation = Animation.new(self.sprite_sheet, 16, 16)
    self.entity:addComponent("animation", self.animation)

    -- Define all animations
    self:defineAnimations()

    -- Start with idle animation
    self.animation:play("idle")

    -- Dash visual effects
    self.dash_trail = {}  -- Array of trail positions {x, y, alpha, time}
    self.dash_trail_spawn_timer = 0  -- Timer for spawning trail images
    self.dash_crouch_timer = 0  -- Timer for dash startup crouch animation
    self.dash_screen_shake_timer = 0  -- Timer for screen shake effect
    self.dash_screen_shake_x = 0  -- Screen shake offset X
    self.dash_screen_shake_y = 0  -- Screen shake offset Y

    return self
end

-- Handle input
function Player:handleInput()
    -- Reset input
    self.input_x = 0
    self.input_jump = false
    self.input_jump_release = false
    self.input_dash = false
    self.input_deliver = false

    -- Use input system if available, otherwise fallback to direct keyboard input
    if self.input_system then
        -- Get horizontal input from input system
        self.input_x = self.input_system:get_horizontal_axis()

        -- Update facing direction based on input
        if self.input_x < 0 then
            self.facing_right = false
        elseif self.input_x > 0 then
            self.facing_right = true
        end

        -- Check jump input using input system
        local jump_down = self.input_system:is_down("jump")

        -- Detect jump press (rising edge detection)
        if jump_down and not self.jump_held then
            self.input_jump = true
            -- Buffer the jump input for jump buffering system
            self.input_system:buffer_action("jump", Constants.JUMP_BUFFER_FRAMES)
        end

        -- Detect jump release (falling edge detection)
        if not jump_down and self.jump_held then
            self.input_jump_release = true
        end

        -- Update jump held state
        self.jump_held = jump_down

        -- Check dash input using input system
        local dash_down = self.input_system:is_down("dash")

        -- Detect dash press (rising edge detection)
        if dash_down and not self.dash_held then
            self.input_dash = true
        end

        -- Update dash held state (for edge detection)
        self.dash_held = dash_down

        -- Check deliver input using input system
        local deliver_down = self.input_system:is_down("deliver")

        -- Detect deliver press (rising edge detection)
        if deliver_down and not self.deliver_held then
            self.input_deliver = true
        end

        -- Update deliver held state (for edge detection)
        self.deliver_held = deliver_down
    else
        -- Fallback to direct keyboard input (for backwards compatibility)
        -- Check left/right arrow keys or WASD
        if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
            self.input_x = -1
            self.facing_right = false
        elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
            self.input_x = 1
            self.facing_right = true
        end

        -- Check jump input (Space, W, or Up Arrow)
        local jump_down = love.keyboard.isDown("space") or
                          love.keyboard.isDown("w") or
                          love.keyboard.isDown("up")

        -- Detect jump press (rising edge detection)
        if jump_down and not self.jump_held then
            self.input_jump = true
        end

        -- Detect jump release (falling edge detection)
        if not jump_down and self.jump_held then
            self.input_jump_release = true
        end

        -- Update jump held state
        self.jump_held = jump_down

        -- Check dash input (Shift or X key)
        local dash_down = love.keyboard.isDown("lshift") or
                          love.keyboard.isDown("rshift") or
                          love.keyboard.isDown("x")

        -- Detect dash press (rising edge detection)
        if dash_down and not self.dash_held then
            self.input_dash = true
        end

        -- Update dash held state (for edge detection)
        self.dash_held = dash_down

        -- Check deliver input (S, Down, or E key)
        local deliver_down = love.keyboard.isDown("s") or
                            love.keyboard.isDown("down") or
                            love.keyboard.isDown("e")

        -- Detect deliver press (rising edge detection)
        if deliver_down and not self.deliver_held then
            self.input_deliver = true
        end

        -- Update deliver held state (for edge detection)
        self.deliver_held = deliver_down
    end
end

-- Update physics and handle collision detection/response
function Player:updatePhysicsAndCollision(dt)
    -- Calculate desired position based on velocity
    local desired_x = self.transform.x + self.physics.velocity_x * dt
    local desired_y = self.transform.y + self.physics.velocity_y * dt

    -- Use collision system if available
    if self.collision_system then
        -- Convert from center position to top-left for bump
        local box_x = desired_x - self.collision.width / 2
        local box_y = desired_y - self.collision.height / 2

        -- Move with collision detection
        local actual_x, actual_y, cols, len = self.collision_system:update(
            self,
            box_x,
            box_y,
            self.collision.width,
            self.collision.height
        )

        -- Convert back from top-left to center position
        self.transform.x = actual_x + self.collision.width / 2
        self.transform.y = actual_y + self.collision.height / 2

        -- Check grounded and wall states from collisions
        self.grounded = false
        local wall_collision_detected = false
        -- Don't reset wall_direction during control lock (preserve for wall jump)
        if self.control_lock_timer <= 0 then
            self.wall_direction = 0
        end

        for i = 1, len do
            local col = cols[i]

            -- Check if collision is from below (player landing on something)
            if col.normal.y < 0 then  -- Normal pointing up = ground
                self.grounded = true
                self.jumping = false
                self.wall_sliding = false
                self.physics:setVelocity(self.physics.velocity_x, 0)
                -- Restore air dash charges on landing
                self.air_dash_charges = 1
                -- Reset coyote time when grounded
                self.coyote_frames = Constants.COYOTE_FRAMES

                -- Reset combo when landing (VETS-28)
                if self.combo_count > 0 and not self.combo_was_grounded then
                    print("[Player] Combo reset on landing (was " .. self.combo_count .. "x)")
                    self.combo_count = 0
                    -- Reset combo in scoring system as well
                    if self.scoring then
                        self.scoring:resetCombo()
                    end
                end
                self.combo_was_grounded = true
            end

            -- Check if collision is from above (player hitting head on ceiling)
            if col.normal.y > 0 then  -- Normal pointing down = ceiling
                self.jumping = false
                -- Cancel upward momentum when hitting ceiling
                if self.physics.velocity_y < 0 then
                    self.physics:setVelocity(self.physics.velocity_x, 0)
                end
            end

            -- Check for wall collision (left or right)
            if col.normal.x ~= 0 and not self.grounded then  -- Horizontal collision in air
                wall_collision_detected = true
                self.on_wall = true
                self.wall_direction = col.normal.x  -- -1 for left wall, 1 for right wall
                -- Don't reset horizontal velocity during control lock (wall jump in progress)
                if self.control_lock_timer <= 0 then
                    self.physics:setVelocity(0, self.physics.velocity_y)
                end
                -- Restore air dash charges on wall touch
                self.air_dash_charges = 1
            end
        end

        -- Clear on_wall if no collision detected
        if not wall_collision_detected then
            self.on_wall = false
        end
    else
        -- No collision system, just move freely
        self.transform.x = desired_x
        self.transform.y = desired_y
    end
end

-- Apply gravity based on current state
-- This is the core physics function that determines how the player accelerates downward
-- Different movement states modify gravity to create different "feels"
--
-- Gravity States:
--   - Normal: 800 px/s² (standard falling)
--   - Jump Hold: 400 px/s² (50% reduction for floaty apex, only while moving upward)
--   - Dashing: 0 px/s² (gravity disabled entirely)
--   - Wall Sliding: 0 px/s² (velocity overridden to constant 40 px/s descent)
--
-- See: MOVEMENT_REFERENCE.md Section "Physics Constants"
function Player:applyGravity(dt)
    -- Calculate gravity based on state
    local gravity = Constants.GRAVITY
    if self.dashing then
        -- No gravity while dashing
        gravity = 0
    elseif self.jumping and self.jump_held and self.physics.velocity_y < 0 then
        -- Use reduced gravity (50% of normal) for more floaty feel at apex
        -- Only applies while holding jump AND moving upward (before apex)
        gravity = Constants.GRAVITY * Constants.JUMP_HOLD_GRAVITY
    elseif self.wall_sliding then
        -- Override velocity for wall-slide (constant descent speed)
        -- IMPORTANT: Maintain a tiny horizontal velocity toward wall so bump detects collision
        -- Without this 1 px/s push, the player would "pop off" the wall
        local wall_push_velocity = -self.wall_direction * 1  -- 1 px/s toward wall
        self.physics:setVelocity(wall_push_velocity, Constants.WALL_SLIDE_SPEED)
        gravity = 0  -- No gravity while wall-sliding
    end

    -- Update physics (this applies gravity and velocity to position)
    self.physics:update(dt, gravity)
end

-- Update wall-sliding state
-- Wall-sliding provides a safe, controlled descent when touching walls in midair
--
-- Activation Requirements:
--   1. Player is touching a wall (on_wall = true, from collision detection)
--   2. Player is in the air (not grounded)
--   3. Player is falling (velocity_y > 0, positive = downward)
--
-- Wall Stick Buffer:
--   - When wall-sliding starts, a 0.1s timer begins
--   - If player briefly leaves wall, they can "re-grab" it within this window
--   - Prevents frustrating pop-off from small wall irregularities
--   - Timer only decrements while wall-sliding (preserves state)
--
-- See: MOVEMENT_REFERENCE.md Section "Wall-Sliding"
function Player:updateWallSliding(dt)
    -- Check if player should be wall-sliding
    if self.on_wall and not self.grounded and self.physics.velocity_y > 0 then
        -- Player is touching wall, in air, and falling - start wall-slide
        self.wall_sliding = true
        self.wall_stick_timer = Constants.WALL_STICK_TIME
    elseif self.wall_sliding then
        -- Update wall stick timer
        self.wall_stick_timer = self.wall_stick_timer - dt

        -- Stop wall-sliding if no longer on wall and stick timer expired
        if not self.on_wall and self.wall_stick_timer <= 0 then
            self.wall_sliding = false
        end
    end
end

-- Handle jumping (ground jump, wall jump, and variable jump height)
-- This is the core jump controller that handles all jump types and input buffering
--
-- Jump Types:
--   1. Ground Jump: Standard jump from ground or platform (JUMP_FORCE = -300 px/s)
--   2. Coyote Jump: Can jump for 5 frames after leaving platform edge
--   3. Buffered Jump: Can press jump 8 frames before landing, executes on first grounded frame
--   4. Wall Jump: Launches away from wall at ~58° angle (see wallJump())
--   5. Variable Height: Releasing jump early cuts velocity by 50% (creates ~60% height short-hop)
--
-- Input Buffering:
--   - Jump buffer: 8 frames (~0.13s at 60 FPS) - forgiving pre-landing input
--   - Coyote time: 5 frames (~0.083s) - forgiving post-leaving-ground input
--   - Both systems prevent frustration from slightly mistimed inputs
--
-- Priority Order:
--   1. Coyote/Ground jump (if grounded or coyote frames available)
--   2. Wall jump (if wall-sliding)
--   3. Variable height (if releasing jump while jumping upward)
--
-- See: MOVEMENT_REFERENCE.md Section "Jumping"
function Player:handleJumping()
    -- Check for buffered jump input (if input system is available)
    local has_buffered_jump = false
    if self.input_system then
        has_buffered_jump = self.input_system:is_buffered("jump")
    end

    -- Check if player can jump with coyote time (grounded OR has coyote frames remaining)
    local can_coyote_jump = self.grounded or self.coyote_frames > 0

    -- Handle jumping
    -- Jump when on ground (or coyote time) and jump pressed or buffered
    if can_coyote_jump and (self.input_jump or (has_buffered_jump and self.grounded)) then
        self:jump()
        -- Consume buffered jump if input system is available
        if self.input_system then
            self.input_system:consume_buffer("jump")
        end
        -- Clear coyote time after jump
        self.coyote_frames = 0
    -- Wall-jump when wall-sliding and jump pressed (and actually on a wall)
    elseif self.wall_sliding and self.input_jump and self.wall_direction ~= 0 then
        self:wallJump()
        -- Consume buffered jump if input system is available
        if self.input_system then
            self.input_system:consume_buffer("jump")
        end
    end

    -- Variable jump height: reduce upward velocity when jump released early
    if self.input_jump_release and self.jumping and self.physics.velocity_y < 0 then
        -- Cut jump short by reducing upward velocity by 50%
        -- This creates a short-hop that's ~60% the height of a full jump
        self.physics:setVelocity(self.physics.velocity_x, self.physics.velocity_y * 0.5)
    end
end

-- Apply running movement (acceleration and deceleration)
-- Handles horizontal ground movement with smooth acceleration/deceleration curves
--
-- Movement Control:
--   - Target velocity: input_x (-1/0/1) × RUN_SPEED (120 px/s)
--   - Acceleration: 1200 px/s² - reaches max speed in ~0.1s
--   - Deceleration: Exponential decay with 0.15 factor - stops in ~0.15s
--
-- Control Lock:
--   - Movement disabled during wall-jump control lock (0.15s)
--   - Allows wall-jump arc to complete without player interference
--   - Also disabled during dashing (dash maintains its own velocity)
--
-- Deceleration Formula:
--   velocity *= pow(1 - DECELERATION, dt * 60)
--   This creates a smooth, natural-feeling slowdown
--   Velocity snapped to 0 when below 0.5 px/s threshold
--
-- See: MOVEMENT_REFERENCE.md Section "Running"
function Player:applyMovement(dt)
    -- Only apply movement if not control-locked and not dashing
    if self.control_lock_timer <= 0 and not self.dashing then
        if self.input_x ~= 0 then
            -- Apply acceleration toward run speed
            local target_velocity = self.input_x * Constants.RUN_SPEED
            local acceleration = Constants.ACCELERATION * dt

            -- Smoothly accelerate toward target velocity
            if math.abs(target_velocity - self.physics.velocity_x) < acceleration then
                self.physics:setVelocity(target_velocity, self.physics.velocity_y)
            else
                local accel_direction = target_velocity > self.physics.velocity_x and 1 or -1
                self.physics:setVelocity(
                    self.physics.velocity_x + acceleration * accel_direction,
                    self.physics.velocity_y
                )
            end
        else
            -- Apply deceleration when no input
            -- Using Constants.DECELERATION as a friction factor (0.15 = 0.15 seconds to stop)
            -- This creates smooth deceleration
            local decel_factor = math.pow(1 - Constants.DECELERATION, dt * 60)  -- Scale by dt
            self.physics:setVelocity(
                self.physics.velocity_x * decel_factor,
                self.physics.velocity_y
            )

            -- Stop completely when velocity is very small
            if math.abs(self.physics.velocity_x) < 0.5 then
                self.physics:setVelocity(0, self.physics.velocity_y)
            end
        end
    end
end

-- Update dash state and handle dash input
function Player:updateDash(dt)
    -- Handle dash input with crouch startup
    if self.input_dash and not self.dashing and self.dash_cooldown_timer <= 0 and self.dash_crouch_timer <= 0 then
        -- Check if can dash (always can on ground, or have air dash charge)
        if self.grounded or self.air_dash_charges > 0 then
            -- Start crouch animation before dash
            self.dash_crouch_timer = Constants.DASH_CROUCH_DURATION
        end
    end

    -- Execute dash after crouch animation completes
    if self.dash_crouch_timer > 0 and self.dash_crouch_timer <= dt then
        self:dash()
    end

    -- Update dash state
    if self.dashing then
        self.dash_timer = self.dash_timer - dt

        -- Check for dash canceling with jump FIRST (before setting velocity)
        if self.input_jump then
            if self.is_ground_dash then
                self:jump()
                self.dashing = false
                self.dash_cooldown_timer = Constants.DASH_COOLDOWN
                -- Restore normal max velocity
                self.physics:setMaxVelocity(Constants.RUN_SPEED, Constants.TERMINAL_VELOCITY)
            elseif self.wall_sliding and self.wall_direction ~= 0 then
                self:wallJump()
                self.dashing = false
                self.dash_cooldown_timer = Constants.DASH_COOLDOWN
                -- Restore normal max velocity
                self.physics:setMaxVelocity(Constants.RUN_SPEED, Constants.TERMINAL_VELOCITY)
            end
        end

        -- Only maintain dash velocity if still dashing (not canceled)
        if self.dashing then
            -- Temporarily increase max velocity for dash
            self.physics:setMaxVelocity(Constants.DASH_SPEED, Constants.DASH_SPEED)

            -- Maintain dash velocity
            self.physics:setVelocity(
                self.dash_direction_x * Constants.DASH_SPEED,
                self.dash_direction_y * Constants.DASH_SPEED
            )

            -- Check if dash ended
            if self.dash_timer <= 0 then
                self.dashing = false
                self.dash_cooldown_timer = Constants.DASH_COOLDOWN
                -- Restore normal max velocity
                self.physics:setMaxVelocity(Constants.RUN_SPEED, Constants.TERMINAL_VELOCITY)
            end
        end
    end
end

-- Update all timers
function Player:updateTimers(dt)
    -- Update control lock timer
    if self.control_lock_timer > 0 then
        self.control_lock_timer = self.control_lock_timer - dt
    end

    -- Update dash cooldown timer
    if self.dash_cooldown_timer > 0 then
        self.dash_cooldown_timer = self.dash_cooldown_timer - dt
    end

    -- Update iframe timer
    if self.iframe_timer > 0 then
        self.iframe_timer = self.iframe_timer - dt
    end

    -- Update dash crouch timer
    if self.dash_crouch_timer > 0 then
        self.dash_crouch_timer = self.dash_crouch_timer - dt
    end

    -- Update coyote time (frame-based decay)
    -- Decay coyote frames when not grounded
    if not self.grounded and self.coyote_frames > 0 then
        self.coyote_frames = self.coyote_frames - 1
    end

    -- Update screen shake timer
    if self.dash_screen_shake_timer > 0 then
        self.dash_screen_shake_timer = self.dash_screen_shake_timer - dt
        if self.dash_screen_shake_timer <= 0 then
            -- Reset shake offsets when timer expires
            self.dash_screen_shake_x = 0
            self.dash_screen_shake_y = 0
        end
    end
end

-- Update dash trail effect
function Player:updateDashTrail(dt)
    -- Update existing trail positions (fade them out)
    local i = 1
    while i <= #self.dash_trail do
        local trail = self.dash_trail[i]
        trail.time = trail.time - dt

        -- Remove trail if faded out
        if trail.time <= 0 then
            table.remove(self.dash_trail, i)
        else
            -- Update alpha based on remaining time
            trail.alpha = trail.time / Constants.DASH_TRAIL_FADE_TIME
            i = i + 1
        end
    end

    -- Spawn new trail images while dashing (at specified rate)
    if self.dashing then
        self.dash_trail_spawn_timer = self.dash_trail_spawn_timer - dt

        if self.dash_trail_spawn_timer <= 0 then
            -- Add trail position at current location
            table.insert(self.dash_trail, {
                x = self.transform.x,
                y = self.transform.y,
                alpha = 1.0,
                time = Constants.DASH_TRAIL_FADE_TIME
            })
            -- Reset spawn timer
            self.dash_trail_spawn_timer = Constants.DASH_TRAIL_SPAWN_RATE
        end
    else
        -- Reset spawn timer when not dashing
        self.dash_trail_spawn_timer = 0
    end
end

-- Update screen shake effect
function Player:updateScreenShake(dt)
    if self.dash_screen_shake_timer > 0 then
        -- Random shake within intensity bounds
        local intensity = Constants.DASH_SCREEN_SHAKE_INTENSITY
        self.dash_screen_shake_x = (math.random() * 2 - 1) * intensity
        self.dash_screen_shake_y = (math.random() * 2 - 1) * intensity
    end
end

-- Update player (main update loop)
function Player:update(dt)
    self:handleInput()
    self:updateTimers(dt)
    self:updateDash(dt)
    self:applyMovement(dt)
    self:handleJumping()
    self:handleDelivery()  -- Handle delivery action
    self:updateWallSliding(dt)
    self:applyGravity(dt)
    self:updatePhysicsAndCollision(dt)
    self:updateDashTrail(dt)
    self:updateScreenShake(dt)
    self:updateAnimation(dt)  -- Update animation state machine
end

-- Perform jump
function Player:jump()
    -- Apply jump force (negative velocity = upward)
    self.physics:setVelocity(self.physics.velocity_x, Constants.JUMP_FORCE)
    self.jumping = true
    self.grounded = false
end

-- Perform wall-jump
-- Launches player away from wall at a steep angle with temporary control lock
--
-- Wall Jump Mechanics:
--   - Direction: Away from wall (wall_direction already points outward)
--   - Angle: atan2(-320, 200) ≈ -58° from horizontal (steeper than 45°)
--   - Forces: 200 px/s horizontal, -320 px/s vertical
--   - Height: ~55 pixels (slightly higher than ground jump's ~53 pixels)
--
-- Control Lock:
--   - Player cannot change horizontal direction for 0.15s
--   - Prevents immediately moving back into the wall
--   - Allows wall-jump arc to complete naturally
--   - Vertical input (dash) still works during lock
--
-- Displacement:
--   - Player moved 6 pixels away from wall immediately
--   - Required because hitbox is 10px wide (need >5px clearance)
--   - Without displacement, bump would immediately re-collide
--   - Ensures clean separation from wall surface
--
-- State Updates:
--   - Facing direction set to match jump direction
--   - Wall-slide state cleared (on_wall, wall_sliding)
--   - Jumping flag set (enables variable height control)
--
-- See: MOVEMENT_REFERENCE.md Section "Wall-Jumping"
function Player:wallJump()
    -- Calculate horizontal direction (away from wall)
    -- The collision normal (wall_direction) already points AWAY from the wall surface
    -- So we jump in the same direction as the normal
    local jump_direction = self.wall_direction

    -- Apply wall-jump force (angled away from wall)
    self.physics:setVelocity(
        jump_direction * Constants.WALL_JUMP_FORCE_X,  -- Horizontal: away from wall
        Constants.WALL_JUMP_FORCE_Y                     -- Vertical: upward
    )

    -- Move player away from wall to clear collision
    -- IMPORTANT: Need to move at least half width (5px) to fully clear the wall
    -- Using 6px to ensure clean separation and prevent immediate re-collision
    local displacement = jump_direction * 6  -- 6 pixels clears the wall collision
    self.transform.x = self.transform.x + displacement

    -- Set control lock to prevent immediate directional change
    -- This ensures the wall-jump arc completes without player interference
    self.control_lock_timer = Constants.WALL_JUMP_CONTROL_LOCK

    -- Clear wall-sliding state
    self.wall_sliding = false
    self.on_wall = false

    -- Set jumping state
    self.jumping = true
    self.grounded = false

    -- Update facing direction to match jump direction
    self.facing_right = jump_direction > 0
end

-- Perform dash
-- Executes a high-speed directional dash with temporary invulnerability
--
-- Dash Types:
--   1. Ground Dash:
--      - Direction: Horizontal only (facing direction)
--      - Doesn't consume air dash charge
--      - Can be repeated with 0.5s cooldown
--      - Direction vector: (±1, 0)
--
--   2. Air Dash:
--      - Direction: 8-directional based on input (cardinal + diagonal)
--      - Consumes 1 air dash charge (restored on landing/wall touch)
--      - Limited to 1 per jump cycle
--      - Direction vector: Normalized if diagonal
--
-- Direction Calculation:
--   - Horizontal: Use input_x if pressed, else facing direction
--   - Vertical (air only): Up (-1) if W/Up, Down (1) if S/Down, else 0
--   - Diagonal Normalization: Divide by vector length to maintain 300 px/s speed
--
-- Dash Properties:
--   - Speed: 300 px/s (2.5× run speed)
--   - Duration: 0.2s (covers exactly 60 pixels)
--   - Cooldown: 0.5s (applies after dash ends)
--   - I-Frames: First 0.1s grants invulnerability
--
-- Visual Effects:
--   - Motion blur trail (spawns every 0.02s, fades over 0.15s)
--   - Screen shake (2px intensity for 0.1s)
--   - Player color changes to cyan
--   - Max velocity temporarily raised to 300 px/s
--
-- State Changes:
--   - Gravity disabled for duration
--   - Wall-slide cleared
--   - Control lock cleared (dash overrides)
--
-- Known Issue:
--   - Up-dash requires raw keyboard check (no dedicated "up" action)
--   - Down-dash uses "deliver" action binding
--
-- See: MOVEMENT_REFERENCE.md Section "Dashing"
function Player:dash()
    -- Determine dash direction based on grounded state
    if self.grounded then
        -- Ground dash: horizontal only, in facing direction
        self.dash_direction_x = self.facing_right and 1 or -1
        self.dash_direction_y = 0
        self.is_ground_dash = true  -- Track that this is a ground dash
    else
        -- Air dash: 8-directional based on input
        -- Default to facing direction if no horizontal input
        self.dash_direction_x = self.input_x ~= 0 and self.input_x or (self.facing_right and 1 or -1)

        -- Vertical direction based on input (up/down keys)
        self.dash_direction_y = 0
        if self.input_system then
            -- Use input system if available
            if self.input_system:is_down("deliver") then  -- "deliver" action includes down/s
                self.dash_direction_y = 1  -- Down
            -- Note: There's no dedicated "up" action in current bindings, so check raw keys
            elseif love.keyboard.isDown("up") or love.keyboard.isDown("w") then
                self.dash_direction_y = -1  -- Up
            end
        else
            -- Fallback to direct keyboard input
            if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
                self.dash_direction_y = 1  -- Down
            elseif love.keyboard.isDown("up") or love.keyboard.isDown("w") then
                self.dash_direction_y = -1  -- Up
            end
        end

        -- Normalize diagonal dashes (8-directional movement)
        if self.dash_direction_x ~= 0 and self.dash_direction_y ~= 0 then
            -- Diagonal dash: normalize to maintain consistent speed
            local length = math.sqrt(self.dash_direction_x * self.dash_direction_x +
                                   self.dash_direction_y * self.dash_direction_y)
            self.dash_direction_x = self.dash_direction_x / length
            self.dash_direction_y = self.dash_direction_y / length
        end

        -- Consume air dash charge
        self.air_dash_charges = self.air_dash_charges - 1
        self.is_ground_dash = false  -- Track that this is an air dash
    end

    -- Set dash state
    self.dashing = true
    self.dash_timer = Constants.DASH_DURATION
    self.iframe_timer = Constants.DASH_IFRAME_DURATION

    -- Trigger screen shake
    self.dash_screen_shake_timer = Constants.DASH_SCREEN_SHAKE_DURATION

    -- Clear dash trail (start fresh trail for this dash)
    self.dash_trail = {}

    -- Apply dash velocity
    self.physics:setVelocity(
        self.dash_direction_x * Constants.DASH_SPEED,
        self.dash_direction_y * Constants.DASH_SPEED
    )

    -- Clear other movement states
    self.wall_sliding = false
    self.control_lock_timer = 0
end

-- Handle delivery input
function Player:handleDelivery()
    if self.input_deliver then
        self:attemptDelivery()
    end
end

-- Attempt to deliver to a nearby delivery zone
function Player:attemptDelivery()
    -- Check if we have delivery zones reference
    if not self.delivery_zones or #self.delivery_zones == 0 then
        return false
    end

    -- Try to deliver to each zone
    for _, zone in ipairs(self.delivery_zones) do
        if zone:canDeliver() then
            -- Perform delivery
            if zone:deliver() then
                -- Increment combo if in air (VETS-28)
                if not self.grounded then
                    self.combo_count = self.combo_count + 1
                    self.combo_was_grounded = false  -- Mark that combo is active
                else
                    -- Reset combo if delivering on ground
                    self.combo_count = 0
                    self.combo_was_grounded = true
                end

                -- Calculate combo multiplier using VETS-28 formula
                -- floor(consecutive_deliveries / 2) + 1, capped at 5x
                -- Examples: 1→1x, 2-3→2x, 4-5→3x, 6-7→4x, 8+→5x
                local combo_multiplier = math.floor(self.combo_count / 2) + 1
                combo_multiplier = math.min(combo_multiplier, 5)

                -- Calculate time bonus based on combo level (VETS-26)
                -- Standard: +8s, 2x: +10s, 3x: +12s, 4x: +14s, 5x: +16s
                local time_bonus = 8 + (combo_multiplier - 1) * 2

                -- Extend timer if available
                if self.timer then
                    local actual_added = self.timer:extend(time_bonus)
                    print(string.format("[Player] Delivery successful! Combo: %dx | Time bonus: +%ds",
                        combo_multiplier, actual_added))

                    -- Trigger moon pulse visual feedback (VETS-26)
                    if self.moon_timer then
                        self.moon_timer:triggerDeliveryPulse()
                    end
                else
                    print(string.format("[Player] Delivery successful! Combo: %dx (timer not connected)",
                        combo_multiplier))
                end

                -- Add score for delivery with combo (VETS-28)
                if self.scoring then
                    local points = self.scoring:addDelivery(self.combo_count)
                    print(string.format("[Scoring] Delivery scored! Combo: %dx | +%d points | Total: %d",
                        combo_multiplier, points, self.scoring:getTotal()))
                end

                return true
            end
        end
    end

    return false
end

-- Draw player
function Player:draw()
    -- Get player position and size
    local x = self.transform.x
    local y = self.transform.y
    local w = self.collision.width
    local h = self.collision.height

    -- Debug: Print draw position when F2 is held
    if love.keyboard.isDown("f2") then
        print(string.format("[Player] Drawing at: (%.1f, %.1f) size: %dx%d",
            x - w/2, y - h/2, w, h))
    end

    -- Draw dash trail (motion blur effect)
    if #self.dash_trail > 0 then
        for i = 1, #self.dash_trail do
            local trail = self.dash_trail[i]
            -- Fade from magenta to transparent
            love.graphics.setColor(1, 0.3, 1, trail.alpha * 0.5)  -- 50% max opacity for trail
            love.graphics.rectangle("fill", trail.x - w/2, trail.y - h/2, w, h)
        end
    end

    -- Apply crouch deformation during dash startup
    local draw_h = h
    local draw_y = y
    if self.dash_crouch_timer > 0 then
        -- Squash player vertically (crouch)
        local crouch_factor = 0.7  -- 70% of normal height
        draw_h = h * crouch_factor
        draw_y = y + (h - draw_h) / 2  -- Offset to keep bottom aligned
    end

    -- Draw player animation sprite
    -- Center the sprite on the player's position
    -- Calculate scale factor to match desired size (sprite is 16x16, player hitbox is 10x14)
    local scale_x = w / 16  -- Scale width to match hitbox
    local scale_y = draw_h / 16  -- Scale height to match hitbox (can be squashed during dash crouch)

    -- Flip sprite horizontally based on facing direction
    if not self.facing_right then
        scale_x = -scale_x  -- Negative scale flips horizontally
    end

    -- Origin offset (center of 16x16 sprite)
    local origin_x = 8
    local origin_y = 8

    -- Apply color tint based on state
    if self.dashing then
        -- Dashing - cyan tint
        love.graphics.setColor(0.3, 1, 1, 1)
    elseif self.dash_crouch_timer > 0 then
        -- Crouching before dash - yellow tint
        love.graphics.setColor(1, 1, 0.3, 1)
    elseif self.control_lock_timer > 0 then
        -- Control-locked after wall-jump - bright cyan tint
        love.graphics.setColor(0.7, 1, 1, 1)
    elseif self.wall_sliding then
        -- Wall-sliding - brighter orange tint
        love.graphics.setColor(1, 0.8, 0.5, 1)
    else
        -- Normal state - no tint
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Draw the animation
    self.animation:draw(x, draw_y, 0, scale_x, scale_y, origin_x, origin_y)

    -- Draw dash direction indicator when dashing
    if self.dashing then
        love.graphics.setColor(1, 1, 1)  -- White line
        local line_length = 8
        love.graphics.line(
            x, y,
            x + self.dash_direction_x * line_length,
            y + self.dash_direction_y * line_length
        )
    end

    -- Draw wall contact indicator (line on the wall side)
    if self.wall_sliding then
        love.graphics.setColor(1, 1, 0)  -- Yellow indicator
        local wall_x = self.wall_direction < 0 and (x - w/2) or (x + w/2)
        love.graphics.line(wall_x, y - h/2, wall_x, y + h/2)
    end

    -- Draw facing direction indicator (small line)
    love.graphics.setColor(1, 1, 1)
    local indicator_x = self.facing_right and (x + w/2) or (x - w/2)
    love.graphics.line(x, y, indicator_x, y)

    -- Debug: Draw velocity vector
    love.graphics.setColor(0, 1, 0)
    love.graphics.line(
        x, y,
        x + self.physics.velocity_x * 0.1,
        y + self.physics.velocity_y * 0.1
    )
end

-- Get entity
function Player:getEntity()
    return self.entity
end

-- Get screen shake offset (for camera)
function Player:getScreenShakeOffset()
    return self.dash_screen_shake_x, self.dash_screen_shake_y
end

-- Create placeholder sprite sheet for player animations
-- Layout: 12 frames horizontal (idle, run, jump, dash, wall-slide)
-- Frame breakdown:
--   Frames 1-2: idle (orange)
--   Frames 3-6: run (yellow-orange gradient for motion)
--   Frames 7-9: jump (green shades: squat, rise, fall)
--   Frames 10-11: dash (cyan)
--   Frame 12: wall-slide (magenta)
function Player:createPlaceholderSpriteSheet()
    local frame_width = 16
    local frame_height = 16
    local num_frames = 12
    local sheet_width = frame_width * num_frames
    local sheet_height = frame_height

    -- Create canvas for sprite sheet
    local canvas = love.graphics.newCanvas(sheet_width, sheet_height)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)  -- Transparent background

    -- Helper function to draw a simple cat sprite (rectangle with ears)
    local function drawCatSprite(x, y, r, g, b)
        -- Body
        love.graphics.setColor(r, g, b, 1)
        love.graphics.rectangle("fill", x + 3, y + 4, 10, 10)

        -- Ears (triangular shapes approximated with rectangles)
        love.graphics.rectangle("fill", x + 3, y + 2, 3, 3)  -- Left ear
        love.graphics.rectangle("fill", x + 10, y + 2, 3, 3)  -- Right ear

        -- Tail (small rectangle extending from body)
        love.graphics.rectangle("fill", x + 11, y + 11, 4, 2)
    end

    -- Frames 1-2: idle (orange cat)
    drawCatSprite(0, 0, 0.9, 0.6, 0.3)    -- Frame 1
    drawCatSprite(16, 0, 0.95, 0.65, 0.35)  -- Frame 2 (slightly brighter)

    -- Frames 3-6: run (yellow-orange gradient)
    drawCatSprite(32, 0, 1.0, 0.7, 0.2)    -- Frame 3
    drawCatSprite(48, 0, 1.0, 0.75, 0.25)  -- Frame 4
    drawCatSprite(64, 0, 1.0, 0.7, 0.2)    -- Frame 5
    drawCatSprite(80, 0, 1.0, 0.65, 0.15)  -- Frame 6

    -- Frames 7-9: jump (green shades: squat, rise, fall)
    drawCatSprite(96, 0, 0.4, 0.9, 0.4)    -- Frame 7 (squat - bright green)
    drawCatSprite(112, 0, 0.3, 0.8, 0.3)   -- Frame 8 (rise - medium green)
    drawCatSprite(128, 0, 0.2, 0.7, 0.2)   -- Frame 9 (fall - darker green)

    -- Frames 10-11: dash (cyan)
    drawCatSprite(144, 0, 0.3, 1.0, 1.0)   -- Frame 10
    drawCatSprite(160, 0, 0.4, 0.95, 0.95) -- Frame 11

    -- Frame 12: wall-slide (magenta)
    drawCatSprite(176, 0, 1.0, 0.3, 1.0)   -- Frame 12

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color

    -- Get image data from canvas and create image
    local image_data = canvas:newImageData()
    local sprite_sheet = love.graphics.newImage(image_data)

    return sprite_sheet
end

-- Define all player animations using the sprite sheet
function Player:defineAnimations()
    -- idle: frames 1-2, 1 FPS (1 second per frame), loops
    self.animation:define("idle", "1-2", 1.0, {
        loop = true
    })

    -- run: frames 3-6, 12 FPS (~0.083 seconds per frame), loops
    self.animation:define("run", "3-6", 1/12, {
        loop = true
    })

    -- jump: frames 7-9, 10 FPS (0.1 seconds per frame), no loop
    self.animation:define("jump", "7-9", 0.1, {
        loop = false
    })

    -- dash: frames 10-11, 8 FPS (0.125 seconds per frame), loops
    self.animation:define("dash", "10-11", 0.125, {
        loop = true
    })

    -- wall-slide: frame 12, static (no animation)
    self.animation:define("wall-slide", "12", 1.0, {
        loop = true
    })
end

-- Update animation based on player state
-- Animation priority:
--   1. Dash (highest priority)
--   2. Wall-slide
--   3. Jump (airborne with upward velocity)
--   4. Fall (airborne with downward velocity) - uses jump animation frame 3
--   5. Run (grounded with movement)
--   6. Idle (grounded, no movement)
function Player:updateAnimation(dt)
    -- Update the animation component
    self.animation:update(dt)

    -- Determine which animation should be playing based on state
    local desired_animation = "idle"  -- Default to idle

    if self.dashing then
        desired_animation = "dash"
    elseif self.wall_sliding then
        desired_animation = "wall-slide"
    elseif not self.grounded then
        -- Airborne - use jump animation
        desired_animation = "jump"
        -- If falling (velocity_y > 0), lock to last frame of jump animation (fall pose)
        if self.physics.velocity_y > 0 and self.animation:getCurrentAnimation() == "jump" then
            -- Let the jump animation play through naturally, it will stay on frame 3 (fall)
            -- since it's a non-looping animation
        end
    elseif math.abs(self.physics.velocity_x) > 5 then
        -- Grounded and moving - run animation
        desired_animation = "run"
    else
        -- Grounded and stationary - idle animation
        desired_animation = "idle"
    end

    -- Only switch animations if different from current
    if self.animation:getCurrentAnimation() ~= desired_animation then
        self.animation:play(desired_animation)
    end
end

return Player
