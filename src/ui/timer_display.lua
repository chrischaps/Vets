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

    -- Load moon sprite texture
    display.moon_sprite = love.graphics.newImage("assets/graphics/ui/moon_timer.png")
    display.moon_sprite:setFilter("nearest", "nearest")  -- Pixel-perfect scaling

    -- Load horizon skyline sprite
    display.horizon_sprite = love.graphics.newImage("assets/graphics/ui/horizon_skyline.png")
    display.horizon_sprite:setFilter("nearest", "nearest")  -- Pixel-perfect scaling

    -- Pulse effect properties
    display.pulse_timer = 0
    display.pulse_duration = 0.3  -- Seconds
    display.pulse_scale = 1.0
    display.pulsing = false

    -- Sparkle effect properties (VETS-61)
    display.sparkling = false
    display.sparkle_timer = 0
    display.sparkle_duration = 1.5  -- Sparkle lasts 1.5 seconds
    display.sparkle_particles = {}

    -- UI options
    display.show_digital = options.show_digital or false
    display.show_horizon = options.show_horizon ~= false  -- Default true

    -- Parallax tracking
    display.camera_x = 0  -- Track camera X position for parallax effect

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

    -- Update sparkle effect (VETS-61)
    if self.sparkling then
        self.sparkle_timer = self.sparkle_timer + dt

        -- Update existing particles
        for i = #self.sparkle_particles, 1, -1 do
            local p = self.sparkle_particles[i]
            p.life = p.life + dt
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.alpha = 1.0 - (p.life / self.sparkle_duration)

            -- Remove dead particles
            if p.life >= self.sparkle_duration then
                table.remove(self.sparkle_particles, i)
            end
        end

        -- Stop sparkling when time is up
        if self.sparkle_timer >= self.sparkle_duration then
            self.sparkling = false
            self.sparkle_timer = 0
            self.sparkle_particles = {}
        end
    end
end

-- Trigger pulse effect (e.g., on time extension)
function TimerDisplay:triggerPulse()
    self.pulsing = true
    self.pulse_timer = 0
end

-- Trigger sparkle effect (VETS-61: on success)
function TimerDisplay:triggerSparkle()
    self.sparkling = true
    self.sparkle_timer = 0
    self.sparkle_particles = {}

    -- Create sparkle particles around the moon
    local base_x, base_y = self:getScreenPosition()
    local moon_y = self:getMoonY(base_y)
    local radius = self:getMoonRadius()

    -- Create 12 sparkle particles in a burst pattern
    for i = 1, 12 do
        local angle = (i / 12) * math.pi * 2
        local speed = 20 + math.random() * 30  -- Random speed between 20-50
        local distance = radius + 5 + math.random() * 10  -- Start just outside moon

        table.insert(self.sparkle_particles, {
            x = base_x + math.cos(angle) * distance,
            y = moon_y + math.sin(angle) * distance,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0,
            size = 1 + math.random() * 2,  -- Random size 1-3
            alpha = 1.0
        })
    end

    print("[TimerDisplay] Sparkle effect triggered!")
end

-- Update camera position for parallax effect
function TimerDisplay:setCameraPosition(camera_x)
    self.camera_x = camera_x or 0
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

-- Draw background elements (moon + skyline) - called from game world rendering
function TimerDisplay:drawBackground()
    if not self.visible then return end

    local base_x, base_y = self:getScreenPosition()
    local moon_y = self:getMoonY(base_y)
    local radius = self:getMoonRadius()
    local color = self:getColor()

    -- Save graphics state
    local r, g, b, a = love.graphics.getColor()

    -- Draw moon sprite with color tinting and scaling (behind skyline)
    love.graphics.setColor(color)

    -- Calculate scale to match the desired radius
    -- Moon sprite is 40x40, so radius 20. Scale to match current radius
    local sprite_radius = self.moon_sprite:getWidth() / 2
    local scale = (radius * 2) / self.moon_sprite:getWidth()

    -- Draw moon sprite centered at position
    love.graphics.draw(
        self.moon_sprite,
        base_x,
        moon_y,
        0,  -- rotation
        scale,  -- scale X
        scale,  -- scale Y
        sprite_radius,  -- origin X (center)
        sprite_radius   -- origin Y (center)
    )

    -- Draw horizon cityscape silhouette (AFTER moon, so moon sets behind it)
    if self.show_horizon then
        local horizon_y = base_y + self.top_offset + self.horizon_offset

        -- Get the screen width and height in the current coordinate space
        local screen_width = love.graphics.getWidth()
        local screen_height = love.graphics.getHeight()
        local sprite_width = self.horizon_sprite:getWidth()
        local sprite_height = self.horizon_sprite:getHeight()

        -- Use a fixed scale for tiling (instead of stretching to fit)
        local scale = 3.0  -- 3x scale for pixel art
        local scaled_width = sprite_width * scale
        local scaled_height = sprite_height * scale
        local skyline_bottom = horizon_y - scaled_height

        -- Calculate parallax offset (skyline moves slower than player = depth effect)
        local parallax_factor = 0.2  -- 20% of camera movement (distant background)
        local parallax_offset = -self.camera_x * parallax_factor

        -- Wrap the parallax offset to create seamless tiling
        local wrapped_offset = parallax_offset % scaled_width

        -- Draw cityscape with horizontal tiling and parallax scrolling
        love.graphics.setColor(1, 1, 1, 0.95)  -- Nearly opaque

        -- Calculate how many tiles we need to cover the screen (plus extra for scrolling)
        local num_tiles = math.ceil(screen_width / scaled_width) + 2

        -- Draw tiled cityscape
        for i = 0, num_tiles do
            local x = wrapped_offset + (i * scaled_width) - scaled_width
            love.graphics.draw(
                self.horizon_sprite,
                x,  -- Tiled position with parallax
                skyline_bottom,  -- Top edge position
                0,  -- No rotation
                scale,  -- Fixed scale
                scale   -- Proportional scaling
            )
        end
    end

    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
    love.graphics.setLineWidth(1)
end

-- Draw foreground UI elements (sparkles, digital timer)
function TimerDisplay:draw()
    if not self.visible then return end

    local base_x, base_y = self:getScreenPosition()
    local moon_y = self:getMoonY(base_y)
    local radius = self:getMoonRadius()

    -- Save graphics state
    local r, g, b, a = love.graphics.getColor()

    -- Draw sparkle particles (VETS-61) - foreground UI effect
    if self.sparkling and #self.sparkle_particles > 0 then
        for _, p in ipairs(self.sparkle_particles) do
            love.graphics.setColor(1, 1, 1, p.alpha)
            love.graphics.circle("fill", p.x, p.y, p.size)
            -- Draw a small cross for extra sparkle effect
            love.graphics.setLineWidth(1)
            love.graphics.line(p.x - p.size, p.y, p.x + p.size, p.y)
            love.graphics.line(p.x, p.y - p.size, p.x, p.y + p.size)
        end
    end

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
