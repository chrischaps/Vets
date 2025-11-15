-- timer.lua
-- Dawn timer system that counts down to sunrise
-- Manages timer states (calm, warning, urgent, critical) and time extensions

local Timer = {}
Timer.__index = Timer

-- Timer state thresholds (in seconds)
Timer.STATE_CALM_THRESHOLD = 90      -- >90s remaining
Timer.STATE_WARNING_THRESHOLD = 45   -- 90-45s remaining
Timer.STATE_URGENT_THRESHOLD = 15    -- 45-15s remaining
-- STATE_CRITICAL: <15s remaining

-- Timer state enum
Timer.STATE = {
    CALM = "calm",
    WARNING = "warning",
    URGENT = "urgent",
    CRITICAL = "critical"
}

-- Create new timer
-- @param initial_time: Starting time in seconds (default: 180s for Night 1)
function Timer.new(initial_time)
    local self = setmetatable({}, Timer)

    -- Timer values
    self.initial_time = initial_time or 180  -- Default 3 minutes (Night 1)
    self.time_remaining = self.initial_time
    self.max_time = self.initial_time  -- Cap for time extensions

    -- Timer state
    self.current_state = Timer.STATE.CALM
    self.previous_state = Timer.STATE.CALM

    -- Timer control
    self.paused = false
    self.expired = false

    -- State change callbacks (optional)
    self.on_state_change = nil  -- function(new_state, old_state)
    self.on_expire = nil  -- function()

    print("[Timer] Initialized with " .. self.initial_time .. "s (" .. self:formatTime(self.initial_time) .. ")")

    return self
end

-- Update timer (call every frame)
-- @param dt: Delta time in seconds
function Timer:update(dt)
    if self.paused or self.expired then
        return
    end

    -- Countdown
    self.time_remaining = self.time_remaining - dt

    -- Check for expiration
    if self.time_remaining <= 0 then
        self.time_remaining = 0
        self.expired = true

        -- Trigger expire callback
        if self.on_expire then
            self.on_expire()
        end

        print("[Timer] Timer expired!")
        return
    end

    -- Update state based on time remaining
    self:updateState()
end

-- Update timer state based on time remaining
function Timer:updateState()
    local new_state

    if self.time_remaining > Timer.STATE_CALM_THRESHOLD then
        new_state = Timer.STATE.CALM
    elseif self.time_remaining > Timer.STATE_WARNING_THRESHOLD then
        new_state = Timer.STATE.WARNING
    elseif self.time_remaining > Timer.STATE_URGENT_THRESHOLD then
        new_state = Timer.STATE.URGENT
    else
        new_state = Timer.STATE.CRITICAL
    end

    -- Check for state change
    if new_state ~= self.current_state then
        self.previous_state = self.current_state
        self.current_state = new_state

        print("[Timer] State changed: " .. self.previous_state .. " → " .. self.current_state ..
              " (" .. self:formatTime(self.time_remaining) .. " remaining)")

        -- Trigger state change callback
        if self.on_state_change then
            self.on_state_change(new_state, self.previous_state)
        end
    end
end

-- Add time to the timer
-- @param seconds: Amount of time to add
-- @return: Actual time added (capped by max_time)
function Timer:extend(seconds)
    if self.expired then
        return 0  -- Cannot extend expired timer
    end

    local old_time = self.time_remaining
    self.time_remaining = math.min(self.time_remaining + seconds, self.max_time)
    local actual_added = self.time_remaining - old_time

    print("[Timer] Extended by " .. actual_added .. "s (+" .. seconds .. "s requested)")

    -- Update state in case extension changed it
    self:updateState()

    return actual_added
end

-- Pause the timer
function Timer:pause()
    if not self.expired then
        self.paused = true
        print("[Timer] Paused at " .. self:formatTime(self.time_remaining))
    end
end

-- Resume the timer
function Timer:resume()
    if not self.expired then
        self.paused = false
        print("[Timer] Resumed at " .. self:formatTime(self.time_remaining))
    end
end

-- Toggle pause state
function Timer:togglePause()
    if self.paused then
        self:resume()
    else
        self:pause()
    end
end

-- Reset timer to initial time
function Timer:reset()
    self.time_remaining = self.initial_time
    self.current_state = Timer.STATE.CALM
    self.previous_state = Timer.STATE.CALM
    self.expired = false
    self.paused = false

    print("[Timer] Reset to " .. self:formatTime(self.initial_time))
end

-- Get time remaining in seconds
-- @return: Time remaining (float)
function Timer:getTimeRemaining()
    return self.time_remaining
end

-- Get time remaining as percentage (0-1)
-- @return: Percentage of time remaining
function Timer:getPercentRemaining()
    return self.time_remaining / self.initial_time
end

-- Get current timer state
-- @return: Current state (Timer.STATE enum value)
function Timer:getState()
    return self.current_state
end

-- Check if timer is paused
-- @return: true if paused
function Timer:isPaused()
    return self.paused
end

-- Check if timer has expired
-- @return: true if expired
function Timer:isExpired()
    return self.expired
end

-- Format time as MM:SS string
-- @param seconds: Time in seconds
-- @return: Formatted string "MM:SS"
function Timer:formatTime(seconds)
    seconds = math.max(0, seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", minutes, secs)
end

-- Get formatted time remaining string
-- @return: Time remaining as "MM:SS"
function Timer:getFormattedTime()
    return self:formatTime(self.time_remaining)
end

-- Get state color (for visual feedback)
-- @return: RGB color table {r, g, b}
function Timer:getStateColor()
    if self.current_state == Timer.STATE.CALM then
        return {0.5, 0.4, 0.8}  -- Deep purple
    elseif self.current_state == Timer.STATE.WARNING then
        return {0.8, 0.5, 0.3}  -- Purple/orange
    elseif self.current_state == Timer.STATE.URGENT then
        return {0.9, 0.6, 0.3}  -- Orange/pink
    else  -- CRITICAL
        return {1.0, 0.5, 0.2}  -- Bright orange
    end
end

-- Debug: Print timer status
function Timer:debugPrint()
    print("\n=== Timer Status ===")
    print("  Time Remaining: " .. self:getFormattedTime() .. " (" .. math.floor(self.time_remaining) .. "s)")
    print("  State: " .. self.current_state)
    print("  Paused: " .. tostring(self.paused))
    print("  Expired: " .. tostring(self.expired))
    print("  Progress: " .. math.floor(self:getPercentRemaining() * 100) .. "%")
    print("====================\n")
end

return Timer
