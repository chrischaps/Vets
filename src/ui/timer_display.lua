-- Moon Timer Display for Courier Cat
-- Diegetic timer showing time until dawn via a shrinking moon

local HUD = require("src.ui.hud")

local TimerDisplay = setmetatable({}, {__index = HUD.UIElement})
TimerDisplay.__index = TimerDisplay

-- Color thresholds (in seconds)
local COLOR_CALM_THRESHOLD = 90      -- > 90s: White
local COLOR_WARNING_THRESHOLD = 45   -- 90-45s: Pale yellow
local COLOR_URGENT_THRESHOLD = 15    -- 45-15s: Orange
-- < 15s: Bright orange + pulse

-- Colors for different urgency states
local COLORS = {
    CALM = {1.0, 1.0, 1.0, 1.0},        -- White
    WARNING = {1.0, 1.0, 0.7, 1.0},     -- Pale yellow
    URGENT = {1.0, 0.6, 0.2, 1.0},      -- Orange
    CRITICAL = {1.0, 0.4, 0.0, 1.0}     -- Bright orange
}

-- Helper function: Linear interpolation
local function lerp(a, b, t)
    return a + (b - a) * t
end

function TimerDisplay:new(options)
    options = options or {}

    local display = HUD.UIElement.new(self, {
        x = options.x or 0,
        y = options.y or 0,
        z_index = options.z_index or 100,  -- High z-index (render in front)
        anchor = options.anchor or HUD.ANCHOR.TOP_CENTER,
        position_mode = options.position_mode or HUD.POSITION_MODE.ABSOLUTE
    })

    -- Timer properties
    display.current_time = options.initial_time or 180  -- Default 3 minutes
    display.max_time = options.max_time or 180
    display.paused = options.paused or false

    -- Visual properties
    display.max_radius = options.max_radius or 30
    display.min_radius = options.min_radius or 4
    display.horizon_offset = options.horizon_offset or 60  -- Distance to horizon
    display.top_offset = options.top_offset or 20  -- Distance from top

    -- Pulse effect properties
    display.pulse_timer = 0
    display.pulse_duration = 0.3  -- Seconds
    display.pulse_scale = 1.0
    display.pulsing = false

    -- UI options
    display.show_digital = options.show_digital or false
    display.show_horizon = options.show_horizon ~= false  -- Default true

    return display
end

-- Update timer
function TimerDisplay:update(dt)
    if not self.paused then
        self.current_time = math.max(0, self.current_time - dt)
    end

    -- Update pulse effect
    if self.pulsing then
        self.pulse_timer = self.pulse_timer + dt
        if self.pulse_timer >= self.pulse_duration then
            self.pulsing = false
            self.pulse_timer = 0
            self.pulse_scale = 1.0
        else
            -- Ease-out pulse: starts big, returns to normal
            local progress = self.pulse_timer / self.pulse_duration
            self.pulse_scale = 1.0 + (0.3 * (1.0 - progress))
        end
    end

    -- Critical pulse (automatic when < 15s)
    if self.current_time < COLOR_URGENT_THRESHOLD and not self.pulsing then
        -- Continuous pulse at critical time
        local pulse_speed = 3.0  -- Pulses per second
        self.pulse_scale = 1.0 + 0.1 * math.sin(love.timer.getTime() * pulse_speed * math.pi * 2)
    end
end

-- Trigger pulse effect (e.g., on time extension)
function TimerDisplay:triggerPulse()
    self.pulsing = true
    self.pulse_timer = 0
end

-- Add time to timer
function TimerDisplay:addTime(seconds)
    self.current_time = math.min(self.max_time, self.current_time + seconds)
    self:triggerPulse()
end

-- Set time
function TimerDisplay:setTime(seconds)
    self.current_time = math.max(0, math.min(self.max_time, seconds))
end

-- Get time as percentage (0.0 = empty, 1.0 = full)
function TimerDisplay:getTimePercent()
    return self.current_time / self.max_time
end

-- Get color based on remaining time
function TimerDisplay:getColor()
    if self.current_time > COLOR_CALM_THRESHOLD then
        return COLORS.CALM
    elseif self.current_time > COLOR_WARNING_THRESHOLD then
        return COLORS.WARNING
    elseif self.current_time > COLOR_URGENT_THRESHOLD then
        return COLORS.URGENT
    else
        return COLORS.CRITICAL
    end
end

-- Calculate moon radius based on time
function TimerDisplay:getMoonRadius()
    local time_percent = self:getTimePercent()
    local base_radius = lerp(self.min_radius, self.max_radius, time_percent)
    return base_radius * self.pulse_scale
end

-- Calculate moon Y position (shrinks toward horizon)
function TimerDisplay:getMoonY(base_y)
    local time_percent = self:getTimePercent()
    local start_y = base_y + self.top_offset
    local end_y = base_y + self.top_offset + self.horizon_offset
    return lerp(start_y, end_y, 1.0 - time_percent)
end

-- Draw the moon timer
function TimerDisplay:draw()
    if not self.visible then return end

    local base_x, base_y = self:getScreenPosition()
    local moon_y = self:getMoonY(base_y)
    local radius = self:getMoonRadius()
    local color = self:getColor()

    -- Save graphics state
    local r, g, b, a = love.graphics.getColor()

    -- Draw horizon line reference
    if self.show_horizon then
        love.graphics.setColor(0.3, 0.3, 0.4, 0.5)
        local horizon_y = base_y + self.top_offset + self.horizon_offset
        love.graphics.line(base_x - 50, horizon_y, base_x + 50, horizon_y)
    end

    -- Draw moon circle
    love.graphics.setColor(color)
    love.graphics.circle("fill", base_x, moon_y, radius)

    -- Draw subtle rim for depth
    love.graphics.setColor(color[1] * 0.8, color[2] * 0.8, color[3] * 0.8, color[4] * 0.7)
    love.graphics.setLineWidth(1)
    love.graphics.circle("line", base_x, moon_y, radius)

    -- Draw digital timer (optional, for accessibility)
    if self.show_digital then
        local minutes = math.floor(self.current_time / 60)
        local seconds = math.floor(self.current_time % 60)
        local time_str = string.format("%d:%02d", minutes, seconds)

        love.graphics.setColor(1, 1, 1, 0.9)
        local font = love.graphics.getFont()
        local text_width = font:getWidth(time_str)
        love.graphics.print(time_str, base_x - text_width / 2, moon_y + radius + 8)
    end

    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
    love.graphics.setLineWidth(1)
end

-- Toggle digital timer display
function TimerDisplay:toggleDigitalTimer()
    self.show_digital = not self.show_digital
end

-- Check if time has run out
function TimerDisplay:isTimeUp()
    return self.current_time <= 0
end

-- Get formatted time string
function TimerDisplay:getFormattedTime()
    local minutes = math.floor(self.current_time / 60)
    local seconds = math.floor(self.current_time % 60)
    return string.format("%d:%02d", minutes, seconds)
end

-- Pause/resume timer
function TimerDisplay:pause()
    self.paused = true
end

function TimerDisplay:resume()
    self.paused = false
end

function TimerDisplay:togglePause()
    self.paused = not self.paused
end

-- Reset timer
function TimerDisplay:reset(time)
    self.current_time = time or self.max_time
    self.pulsing = false
    self.pulse_timer = 0
    self.pulse_scale = 1.0
end

return TimerDisplay
