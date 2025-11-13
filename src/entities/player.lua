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

    -- Wall-sliding state
    self.wall_sliding = false  -- Is player currently wall-sliding?
    self.on_wall = false  -- Is player touching a wall?
    self.wall_direction = 0  -- Direction of wall: -1 left, 1 right, 0 none
    self.wall_stick_timer = 0  -- Timer for wall stick buffer

    -- Wall-jumping state
    self.control_lock_timer = 0  -- Timer for directional control lock after wall-jump

    -- Movement input
    self.input_x = 0  -- -1 for left, 1 for right, 0 for no input
    self.input_jump = false  -- Jump button pressed this frame
    self.input_jump_release = false  -- Jump button released this frame

    -- Visual representation (placeholder rectangle)
    self.color = {0.9, 0.6, 0.3}  -- Orange color for the cat

    return self
end

-- Handle input
function Player:handleInput()
    -- Reset input
    self.input_x = 0
    self.input_jump = false
    self.input_jump_release = false

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
end

-- Update player
function Player:update(dt)
    -- Handle input
    self:handleInput()

    -- Update control lock timer
    if self.control_lock_timer > 0 then
        self.control_lock_timer = self.control_lock_timer - dt
    end

    -- Apply running movement (only if not control-locked)
    if self.control_lock_timer <= 0 then
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

    -- Handle jumping
    -- Jump when on ground and jump pressed
    if self.grounded and self.input_jump then
        self:jump()
    -- Wall-jump when wall-sliding and jump pressed
    elseif self.wall_sliding and self.input_jump then
        self:wallJump()
    end

    -- Variable jump height: reduce upward velocity when jump released early
    if self.input_jump_release and self.jumping and self.physics.velocity_y < 0 then
        -- Cut jump short by reducing upward velocity
        self.physics:setVelocity(self.physics.velocity_x, self.physics.velocity_y * 0.5)
    end

    -- Wall-sliding mechanics
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

    -- Apply reduced gravity while holding jump and moving upward
    local gravity = Constants.GRAVITY
    if self.jumping and self.jump_held and self.physics.velocity_y < 0 then
        -- Use reduced gravity (50% of normal) for more floaty feel at apex
        gravity = Constants.GRAVITY * Constants.JUMP_HOLD_GRAVITY
    elseif self.wall_sliding then
        -- Override velocity for wall-slide (constant descent speed)
        -- Don't use gravity - directly set vertical velocity to slide speed
        self.physics:setVelocity(self.physics.velocity_x, Constants.WALL_SLIDE_SPEED)
        gravity = 0  -- No gravity while wall-sliding
    end

    -- Update physics (this applies gravity and velocity to position)
    self.physics:update(dt, gravity)

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
        self.on_wall = false
        self.wall_direction = 0

        for i = 1, len do
            local col = cols[i]

            -- Check if collision is from below (player landing on something)
            if col.normal.y < 0 then  -- Normal pointing up = ground
                self.grounded = true
                self.jumping = false
                self.wall_sliding = false
                self.physics:setVelocity(self.physics.velocity_x, 0)
            end

            -- Check for wall collision (left or right)
            if col.normal.x ~= 0 and not self.grounded then  -- Horizontal collision in air
                self.on_wall = true
                self.wall_direction = col.normal.x  -- -1 for left wall, 1 for right wall
                self.physics:setVelocity(0, self.physics.velocity_y)
            end
        end
    else
        -- No collision system, just move freely
        self.transform.x = desired_x
        self.transform.y = desired_y
    end
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
    -- wall_direction: -1 = left wall, 1 = right wall
    -- Jump direction should be opposite: left wall = jump right (+1), right wall = jump left (-1)
    local jump_direction = -self.wall_direction

    -- Apply wall-jump force (angled away from wall)
    self.physics:setVelocity(
        jump_direction * Constants.WALL_JUMP_FORCE_X,  -- Horizontal: away from wall
        Constants.WALL_JUMP_FORCE_Y                     -- Vertical: upward
    )

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

    -- Draw player as colored rectangle (placeholder)
    -- Change color based on state
    if self.control_lock_timer > 0 then
        -- Control-locked after wall-jump - bright cyan/white glow
        love.graphics.setColor(0.7, 1, 1)  -- Cyan glow when wall-jumping
    elseif self.wall_sliding then
        -- Wall-sliding - brighter orange/yellow glow
        love.graphics.setColor(1, 0.8, 0.5)
    else
        -- Normal state
        love.graphics.setColor(self.color)
    end
    love.graphics.rectangle("fill", x - w/2, y - h/2, w, h)

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

return Player
