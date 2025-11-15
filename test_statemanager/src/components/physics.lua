-- physics.lua
-- Physics component for entity velocity, acceleration, and physics state

local Physics = {}
Physics.__index = Physics

-- Create a new Physics component
function Physics.new()
    local self = setmetatable({}, Physics)

    -- Velocity (pixels per second)
    self.velocity_x = 0
    self.velocity_y = 0

    -- Acceleration (pixels per second squared)
    self.acceleration_x = 0
    self.acceleration_y = 0

    -- Gravity scale (multiplier for global gravity)
    -- 0 = no gravity, 1 = normal gravity, >1 = heavier
    self.gravity_scale = 1

    -- Max velocity (terminal velocity)
    self.max_velocity_x = 500  -- Default max horizontal velocity
    self.max_velocity_y = 500  -- Default terminal velocity (falling)

    -- Friction coefficient (0-1, higher = more friction)
    self.friction = 0.15

    -- Physics state flags
    self.grounded = false      -- Is entity on the ground?
    self.on_wall = false       -- Is entity touching a wall?
    self.on_wall_left = false  -- Is entity touching left wall?
    self.on_wall_right = false -- Is entity touching right wall?
    self.wall_direction = 0    -- Direction of wall contact: -1 left, 1 right, 0 none

    -- Mass (for future physics interactions)
    self.mass = 1

    -- Reference to owner entity (set by Entity:addComponent)
    self.owner = nil

    return self
end

-- Apply force (changes acceleration)
function Physics:applyForce(fx, fy)
    self.acceleration_x = self.acceleration_x + (fx / self.mass)
    self.acceleration_y = self.acceleration_y + (fy / self.mass)
end

-- Apply impulse (changes velocity directly)
function Physics:applyImpulse(ix, iy)
    self.velocity_x = self.velocity_x + (ix / self.mass)
    self.velocity_y = self.velocity_y + (iy / self.mass)
end

-- Set velocity
function Physics:setVelocity(vx, vy)
    self.velocity_x = vx
    self.velocity_y = vy
end

-- Get velocity
function Physics:getVelocity()
    return self.velocity_x, self.velocity_y
end

-- Set max velocity
function Physics:setMaxVelocity(max_vx, max_vy)
    self.max_velocity_x = max_vx
    self.max_velocity_y = max_vy or max_vx
end

-- Update physics (called every fixed timestep)
function Physics:update(dt, gravity)
    -- Apply gravity
    if gravity and self.gravity_scale > 0 then
        self.acceleration_y = self.acceleration_y + (gravity * self.gravity_scale)
    end

    -- Update velocity from acceleration
    self.velocity_x = self.velocity_x + (self.acceleration_x * dt)
    self.velocity_y = self.velocity_y + (self.acceleration_y * dt)

    -- Apply friction to horizontal velocity (when grounded)
    if self.grounded and self.friction > 0 then
        self.velocity_x = self.velocity_x * (1 - self.friction)
        -- Stop if velocity is very small
        if math.abs(self.velocity_x) < 1 then
            self.velocity_x = 0
        end
    end

    -- Clamp velocity to max velocity
    if self.velocity_x > self.max_velocity_x then
        self.velocity_x = self.max_velocity_x
    elseif self.velocity_x < -self.max_velocity_x then
        self.velocity_x = -self.max_velocity_x
    end

    if self.velocity_y > self.max_velocity_y then
        self.velocity_y = self.max_velocity_y
    elseif self.velocity_y < -self.max_velocity_y then
        self.velocity_y = -self.max_velocity_y
    end

    -- Reset acceleration (forces are applied each frame)
    self.acceleration_x = 0
    self.acceleration_y = 0
end

-- Reset physics state flags
function Physics:resetState()
    self.grounded = false
    self.on_wall = false
    self.on_wall_left = false
    self.on_wall_right = false
    self.wall_direction = 0
end

return Physics
