-- time.lua
-- Time management system for tracking game time and frame counting

local Time = {
    -- Fixed timestep for deterministic physics
    FIXED_DT = 1/60,  -- 60 FPS

    -- Current delta time (fixed)
    dt = 0,

    -- Total elapsed game time
    total = 0,

    -- Frame counter
    frame = 0,

    -- Accumulator for fixed timestep
    accumulator = 0,

    -- Maximum frame skip to prevent spiral of death
    MAX_FRAME_SKIP = 5
}

-- Initialize the time system
function Time:init()
    self.dt = self.FIXED_DT
    self.total = 0
    self.frame = 0
    self.accumulator = 0
end

-- Update time tracking (call once per frame)
function Time:update(raw_dt)
    -- Clamp raw_dt to prevent huge jumps (e.g., when debugging or window dragging)
    -- Max 0.25 seconds = 15 frames worth of time
    raw_dt = math.min(raw_dt, 0.25)

    -- Add to accumulator
    self.accumulator = self.accumulator + raw_dt

    -- Return number of fixed updates to perform
    local updates = 0
    while self.accumulator >= self.FIXED_DT and updates < self.MAX_FRAME_SKIP do
        self.accumulator = self.accumulator - self.FIXED_DT
        self.total = self.total + self.FIXED_DT
        self.frame = self.frame + 1
        updates = updates + 1
    end

    return updates
end

-- Get interpolation alpha for smooth rendering
-- This allows rendering between fixed update steps
function Time:getAlpha()
    return self.accumulator / self.FIXED_DT
end

-- Get current FPS (for debugging)
function Time:getFPS()
    return 1 / self.FIXED_DT
end

return Time
