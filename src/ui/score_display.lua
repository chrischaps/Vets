-- Score Display for Courier Cat
-- Shows current score with tick-up animation and delivery bonuses

local HUD = require("src.ui.hud")

local ScoreDisplay = setmetatable({}, {__index = HUD.UIElement})
ScoreDisplay.__index = ScoreDisplay

-- Combo color thresholds
local COMBO_COLORS = {
    [1] = {0.3, 1, 1, 1},      -- 1-2x: Cyan
    [2] = {0.3, 1, 1, 1},      -- 1-2x: Cyan
    [3] = {1, 1, 0.3, 1},      -- 3-4x: Yellow
    [4] = {1, 1, 0.3, 1},      -- 3-4x: Yellow
    [5] = {1, 0.3, 1, 1}       -- 5x: Magenta
}

-- Helper function: Format number with commas
local function formatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    return formatted
end

-- Helper function: Linear interpolation
local function lerp(a, b, t)
    return a + (b - a) * t
end

function ScoreDisplay:new(options)
    options = options or {}

    local display = HUD.UIElement.new(self, {
        x = options.x or 10,  -- 10px padding from edge
        y = options.y or 10,
        z_index = options.z_index or 100,
        anchor = options.anchor or HUD.ANCHOR.TOP_RIGHT,
        position_mode = options.position_mode or HUD.POSITION_MODE.ABSOLUTE
    })

    -- Score tracking
    display.current_score = options.initial_score or 0
    display.target_score = options.initial_score or 0
    display.displayed_score = options.initial_score or 0  -- The animating value

    -- Tick-up animation properties
    display.tick_duration = 0.5  -- Time to tick up to target
    display.tick_timer = 0
    display.tick_start_score = 0

    -- Bonus text display
    display.bonus_text = ""
    display.bonus_timer = 0
    display.bonus_duration = 2.0  -- Fade after 2 seconds
    display.bonus_alpha = 0
    display.bonus_color = {1, 1, 1, 1}

    -- Visual properties
    display.main_color = {1, 1, 1, 1}  -- White for main score
    display.font = options.font or love.graphics.getFont()
    display.bonus_font = options.bonus_font or love.graphics.getFont()

    return display
end

-- Update score display
function ScoreDisplay:update(dt)
    -- Update tick-up animation
    if self.displayed_score ~= self.target_score then
        self.tick_timer = self.tick_timer + dt

        if self.tick_timer >= self.tick_duration then
            -- Animation complete
            self.displayed_score = self.target_score
            self.tick_timer = 0
        else
            -- Smoothly interpolate
            local progress = self.tick_timer / self.tick_duration
            self.displayed_score = math.floor(lerp(self.tick_start_score, self.target_score, progress))
        end
    end

    -- Update bonus text fade
    if self.bonus_timer > 0 then
        self.bonus_timer = self.bonus_timer - dt

        if self.bonus_timer <= 0 then
            self.bonus_timer = 0
            self.bonus_alpha = 0
            self.bonus_text = ""
        else
            -- Fade out in last 0.5 seconds
            if self.bonus_timer < 0.5 then
                self.bonus_alpha = self.bonus_timer / 0.5
            else
                self.bonus_alpha = 1.0
            end
        end
    end
end

-- Set score (triggers tick-up animation)
function ScoreDisplay:setScore(score)
    if score ~= self.target_score then
        self.tick_start_score = self.displayed_score
        self.target_score = score
        self.tick_timer = 0
    end
end

-- Show delivery bonus text
-- @param points: Points awarded (e.g., 200)
-- @param multiplier: Combo multiplier (1-5)
function ScoreDisplay:showBonus(points, multiplier)
    multiplier = multiplier or 1
    self.bonus_text = string.format("+%d (×%d)", points, multiplier)
    self.bonus_timer = self.bonus_duration
    self.bonus_alpha = 1.0

    -- Set color based on multiplier
    self.bonus_color = COMBO_COLORS[multiplier] or {1, 1, 1, 1}
end

-- Draw the score display
function ScoreDisplay:draw()
    if not self.visible then return end

    local base_x, base_y = self:getScreenPosition()
    local scale = 2.0  -- 2x size

    -- Save graphics state
    local r, g, b, a = love.graphics.getColor()
    local currentFont = love.graphics.getFont()

    -- Draw main score
    love.graphics.setColor(self.main_color)
    love.graphics.setFont(self.font)

    local score_text = string.format("Score: %s", formatNumber(math.floor(self.displayed_score)))
    local score_width = self.font:getWidth(score_text) * scale

    -- Adjust position for right anchor (text should end at base_x, not start)
    local score_x = base_x - score_width
    love.graphics.print(score_text, score_x, base_y, 0, scale, scale)

    -- Draw bonus text (below main score)
    if self.bonus_timer > 0 and self.bonus_text ~= "" then
        love.graphics.setFont(self.bonus_font)

        -- Apply fade alpha
        love.graphics.setColor(
            self.bonus_color[1],
            self.bonus_color[2],
            self.bonus_color[3],
            self.bonus_alpha
        )

        local bonus_width = self.bonus_font:getWidth(self.bonus_text) * scale
        local bonus_x = base_x - bonus_width
        local bonus_y = base_y + (self.font:getHeight() * scale) + 8  -- 8px spacing (scaled)

        love.graphics.print(self.bonus_text, bonus_x, bonus_y, 0, scale, scale)
    end

    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(currentFont)
end

-- Get current displayed score (for debugging)
function ScoreDisplay:getCurrentScore()
    return math.floor(self.displayed_score)
end

return ScoreDisplay
