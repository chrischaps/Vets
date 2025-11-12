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
function Player.new(x, y)
    local self = setmetatable({}, Player)

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

    -- Apply running movement
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

    -- Handle jumping
    -- Jump when on ground and jump pressed
    if self.grounded and self.input_jump then
        self:jump()
    end

    -- Variable jump height: reduce upward velocity when jump released early
    if self.input_jump_release and self.jumping and self.physics.velocity_y < 0 then
        -- Cut jump short by reducing upward velocity
        self.physics:setVelocity(self.physics.velocity_x, self.physics.velocity_y * 0.5)
    end

    -- Apply reduced gravity while holding jump and moving upward
    local gravity = Constants.GRAVITY
    if self.jumping and self.jump_held and self.physics.velocity_y < 0 then
        -- Use reduced gravity (50% of normal) for more floaty feel at apex
        gravity = Constants.GRAVITY * Constants.JUMP_HOLD_GRAVITY
    end

    -- Update physics (this applies gravity and velocity to position)
    self.physics:update(dt, gravity)

    -- Apply physics velocity to transform position
    self.transform:translate(
        self.physics.velocity_x * dt,
        self.physics.velocity_y * dt
    )

    -- TODO: Collision detection and response will be implemented in VETS-9
    -- For now, add simple ground clamping so player doesn't fall through floor
    local ground_y = 140  -- Temporary ground level
    if self.transform.y >= ground_y then
        self.transform.y = ground_y
        self.physics:setVelocity(self.physics.velocity_x, 0)
        self.grounded = true
        self.jumping = false  -- Reset jumping state when landing
    else
        self.grounded = false
    end
end

-- Perform jump
function Player:jump()
    -- Apply jump force (negative velocity = upward)
    self.physics:setVelocity(self.physics.velocity_x, Constants.JUMP_FORCE)
    self.jumping = true
    self.grounded = false
end

-- Draw player
function Player:draw()
    -- Get player position and size
    local x = self.transform.x
    local y = self.transform.y
    local w = self.collision.width
    local h = self.collision.height

    -- Draw player as colored rectangle (placeholder)
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", x - w/2, y - h/2, w, h)

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
