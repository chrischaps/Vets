-- moon_timer.lua
-- Visual representation of the dawn timer as a shrinking moon

local MoonTimer = {}
MoonTimer.__index = MoonTimer

-- Create new moon timer visualization
-- @param timer: Reference to Timer system
-- @param x, y: Screen position (default: top-right)
function MoonTimer.new(timer, x, y)
    local self = setmetatable({}, MoonTimer)

    -- Reference to timer system
    self.timer = timer

    -- Position on screen
    self.x = x or 280  -- Default: near top-right
    self.y = y or 20

    -- Visual properties
    self.max_radius = 16  -- Maximum moon radius (full time)
    self.min_radius = 4   -- Minimum moon radius (almost expired)
    self.current_radius = self.max_radius

    -- Colors based on timer state
    self.moon_color = {1, 1, 0.9}  -- Warm white/cream
    self.glow_color = {1, 1, 0.8, 0.4}  -- Soft glow
    self.sky_color = {0.5, 0.4, 0.8}  -- Deep purple (calm state)

    -- Animation
    self.pulse_timer = 0
    self.pulse_speed = 2  -- Pulsing cycles per second
    self.pulse_intensity = 0.1  -- How much the moon pulses

    -- Delivery effect (VETS-26)
    self.delivery_pulse_timer = 0  -- Timer for delivery pulse effect
    self.delivery_pulse_duration = 0.4  -- How long the delivery pulse lasts
    self.delivery_pulse_intensity = 0  -- Current intensity of delivery pulse (0-1)

    print("[MoonTimer] Moon visual created at (" .. self.x .. ", " .. self.y .. ")")

    return self
end

-- Update moon visual (animation)
function MoonTimer:update(dt)
    if not self.timer then
        return
    end

    -- Update pulse animation
    self.pulse_timer = self.pulse_timer + dt

    -- Calculate moon size based on time remaining
    local time_percent = self.timer:getPercentRemaining()
    self.current_radius = self.min_radius + (self.max_radius - self.min_radius) * time_percent

    -- Update sky color based on timer state
    local state = self.timer:getState()
    self.sky_color = self.timer:getStateColor()

    -- Update delivery pulse effect (VETS-26)
    if self.delivery_pulse_timer > 0 then
        self.delivery_pulse_timer = self.delivery_pulse_timer - dt
        -- Calculate pulse intensity (starts at 1, fades to 0)
        self.delivery_pulse_intensity = self.delivery_pulse_timer / self.delivery_pulse_duration
    else
        self.delivery_pulse_intensity = 0
    end
end

-- Draw moon and sky gradient
function MoonTimer:draw()
    if not self.timer then
        return
    end

    local x = self.x
    local y = self.y

    -- Calculate pulse offset
    local pulse_phase = (self.pulse_timer * self.pulse_speed) * math.pi * 2
    local pulse_offset = math.sin(pulse_phase) * self.pulse_intensity * self.current_radius

    -- Add delivery pulse effect (VETS-26)
    local delivery_pulse_offset = self.delivery_pulse_intensity * self.current_radius * 0.5  -- Grow by 50%

    local display_radius = self.current_radius + pulse_offset + delivery_pulse_offset

    -- Draw outer glow
    love.graphics.setColor(
        self.glow_color[1],
        self.glow_color[2],
        self.glow_color[3],
        self.glow_color[4] or 0.4
    )
    love.graphics.circle("fill", x, y, display_radius * 1.5)

    -- Draw moon circle
    love.graphics.setColor(self.moon_color)
    love.graphics.circle("fill", x, y, display_radius)

    -- Draw time text below moon
    love.graphics.setColor(1, 1, 1, 0.9)
    local time_text = self.timer:getFormattedTime()
    local text_width = love.graphics.getFont():getWidth(time_text)
    love.graphics.print(time_text, x - text_width / 2, y + display_radius + 6)

    -- Draw state indicator (optional - for debugging)
    if love.keyboard.isDown("f3") then
        local state_text = self.timer:getState()
        local state_width = love.graphics.getFont():getWidth(state_text)
        love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
        love.graphics.print(state_text, x - state_width / 2, y + display_radius + 18)
    end
end

-- Draw sky gradient background (optional full-screen effect)
function MoonTimer:drawSkyGradient()
    if not self.timer then
        return
    end

    -- This would draw a full-screen gradient background
    -- For now, just a placeholder - can be expanded later
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    -- Simple gradient effect using sky color
    love.graphics.setColor(
        self.sky_color[1],
        self.sky_color[2],
        self.sky_color[3],
        0.1  -- Very subtle overlay
    )
    love.graphics.rectangle("fill", 0, 0, screen_width, screen_height)
end

-- Trigger delivery pulse effect (VETS-26)
-- Called when player makes a successful delivery
function MoonTimer:triggerDeliveryPulse()
    self.delivery_pulse_timer = self.delivery_pulse_duration
    self.delivery_pulse_intensity = 1  -- Start at full intensity
end

return MoonTimer
