-- player.lua
-- Player entity with running mechanics

local Entity = require("src.entities.entity")
local Transform = require("src.components.transform")
local Physics = require("src.components.physics")
local Collision = require("src.components.collision")
local Constants = require("src.core.constants")
local Time = require("src.core.time")

local Player = {}
Player.__index = Player

-- Create a new player entity
function Player.new(x, y, collision_system)
    local self = setmetatable({}, Player)

    -- Store collision system reference
    self.collision_system = collision_system

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

    -- Visual representation (placeholder rectangle)
    self.color = {0.9, 0.6, 0.3}  -- Orange color for the cat

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
function Player:applyGravity(dt)
    -- Calculate gravity based on state
    local gravity = Constants.GRAVITY
    if self.dashing then
        -- No gravity while dashing
        gravity = 0
    elseif self.jumping and self.jump_held and self.physics.velocity_y < 0 then
        -- Use reduced gravity (50% of normal) for more floaty feel at apex
        gravity = Constants.GRAVITY * Constants.JUMP_HOLD_GRAVITY
    elseif self.wall_sliding then
        -- Override velocity for wall-slide (constant descent speed)
        -- Maintain a tiny horizontal velocity toward wall so bump detects collision
        local wall_push_velocity = -self.wall_direction * 1  -- 1 px/s toward wall
        self.physics:setVelocity(wall_push_velocity, Constants.WALL_SLIDE_SPEED)
        gravity = 0  -- No gravity while wall-sliding
    end

    -- Update physics (this applies gravity and velocity to position)
    self.physics:update(dt, gravity)
end

-- Update wall-sliding state
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
function Player:handleJumping()
    -- Handle jumping
    -- Jump when on ground and jump pressed
    if self.grounded and self.input_jump then
        self:jump()
    -- Wall-jump when wall-sliding and jump pressed (and actually on a wall)
    elseif self.wall_sliding and self.input_jump and self.wall_direction ~= 0 then
        self:wallJump()
    end

    -- Variable jump height: reduce upward velocity when jump released early
    if self.input_jump_release and self.jumping and self.physics.velocity_y < 0 then
        -- Cut jump short by reducing upward velocity
        self.physics:setVelocity(self.physics.velocity_x, self.physics.velocity_y * 0.5)
    end
end

-- Apply running movement (acceleration and deceleration)
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
    self:updateWallSliding(dt)
    self:applyGravity(dt)
    self:updatePhysicsAndCollision(dt)
    self:updateDashTrail(dt)
    self:updateScreenShake(dt)
end

-- Perform jump
function Player:jump()
    -- Apply jump force (negative velocity = upward)
    self.physics:setVelocity(self.physics.velocity_x, Constants.JUMP_FORCE)
    self.jumping = true
    self.grounded = false
end

-- Perform wall-jump
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
    -- Need to move at least half width (5px) to fully clear the wall
    local displacement = jump_direction * 6  -- 6 pixels clears the wall collision
    self.transform.x = self.transform.x + displacement

    -- Set control lock to prevent immediate directional change
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
        if love.keyboard.isDown("down") or love.keyboard.isDown("s") then
            self.dash_direction_y = 1  -- Down
        elseif love.keyboard.isDown("up") or love.keyboard.isDown("w") then
            self.dash_direction_y = -1  -- Up
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

    -- Draw player as colored rectangle (placeholder)
    -- Change color based on state
    if self.dashing then
        -- Dashing - bright white/cyan glow (distinct from magenta trail)
        love.graphics.setColor(0.3, 1, 1)  -- Cyan glow when dashing
    elseif self.dash_crouch_timer > 0 then
        -- Crouching before dash - yellow anticipation glow
        love.graphics.setColor(1, 1, 0.3)  -- Yellow glow when crouching
    elseif self.control_lock_timer > 0 then
        -- Control-locked after wall-jump - bright cyan/white glow
        love.graphics.setColor(0.7, 1, 1)  -- Cyan glow when wall-jumping
    elseif self.wall_sliding then
        -- Wall-sliding - brighter orange/yellow glow
        love.graphics.setColor(1, 0.8, 0.5)
    else
        -- Normal state
        love.graphics.setColor(self.color)
    end
    love.graphics.rectangle("fill", x - w/2, draw_y - draw_h/2, w, draw_h)

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

return Player
