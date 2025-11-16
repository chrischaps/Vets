-- results_state.lua
-- Results/end screen state for Courier Cat
-- Displays game completion stats, rank, and options to continue or restart

local Input = require("src.systems.input")

local ResultsState = {}

-- Rank thresholds (Night 1)
-- TODO: Adjust thresholds based on night number in future
local RANK_THRESHOLDS = {
    {rank = "S", title = "Master of Meow", min_score = 9000, color = {1, 0.8, 0.2}},      -- Gold
    {rank = "A", title = "Dawn Chaser", min_score = 7000, color = {0.9, 0.5, 0.9}},       -- Light purple
    {rank = "B", title = "Moonlight Runner", min_score = 5000, color = {0.4, 0.8, 1}},    -- Light blue
    {rank = "C", title = "Twilight Courier", min_score = 3000, color = {0.5, 1, 0.5}},    -- Light green
    {rank = "D", title = "Rooftop Rookie", min_score = 1000, color = {0.9, 0.9, 0.5}},    -- Yellow
    {rank = "E", title = "Sleepy Kitten", min_score = 0, color = {0.8, 0.8, 0.8}}         -- Gray
}

-- Enter results state with completion data
-- @param data: Table containing completion data
--   - success: boolean (true if won, false if lost)
--   - failure_reason: string (optional, "time" or "fall" for failures)
--   - night_number: number (which night was completed)
--   - score: number (final score)
--   - time_remaining: number (seconds left, or negative for overtime)
--   - deliveries_completed: number (number of deliveries made)
--   - total_deliveries: number (total delivery zones)
--   - combo_peak: number (highest combo achieved)
function ResultsState:enter(data)
    print("[ResultsState] Entering results state")

    -- Store completion data
    self.success = data.success or false
    self.failure_reason = data.failure_reason  -- "time" or "fall"
    self.night_number = data.night_number or 1
    self.score = data.score or 0
    self.time_remaining = data.time_remaining or 0
    self.deliveries_completed = data.deliveries_completed or 0
    self.total_deliveries = data.total_deliveries or 0
    self.combo_peak = data.combo_peak or 0

    -- Store state_manager reference for state transitions
    self.state_manager = data.state_manager

    -- Initialize input system
    self.input = Input.new()
    self.input:init()

    -- Calculate rank based on score
    self.rank_data = self:calculateRank(self.score)

    -- UI state
    self.selected_option = 1  -- 1 = Continue/Retry, 2 = Restart
    self.blink_timer = 0
    self.blink_state = true

    -- Input handling state
    self.input_cooldown = 0  -- Prevent rapid input spam
    self.INPUT_COOLDOWN_TIME = 0.15  -- 150ms between inputs

    -- Log results
    print("[ResultsState] Results:")
    print("  - Success: " .. tostring(self.success))
    print("  - Night: " .. self.night_number)
    print("  - Score: " .. self.score)
    print("  - Time: " .. self.time_remaining .. "s")
    print("  - Deliveries: " .. self.deliveries_completed .. "/" .. self.total_deliveries)
    print("  - Combo Peak: x" .. self.combo_peak)
    print("  - Rank: " .. self.rank_data.rank .. " (" .. self.rank_data.title .. ")")
end

function ResultsState:exit()
    print("[ResultsState] Exiting results state")
end

-- Calculate rank based on score
-- @param score: Final score
-- @return: Rank data table with rank, title, min_score, and color
function ResultsState:calculateRank(score)
    -- Find the highest rank that the score qualifies for
    for _, rank_info in ipairs(RANK_THRESHOLDS) do
        if score >= rank_info.min_score then
            return rank_info
        end
    end

    -- Default to lowest rank (should never happen due to E rank having min_score = 0)
    return RANK_THRESHOLDS[#RANK_THRESHOLDS]
end

function ResultsState:update(dt)
    -- Update input system
    if self.input then
        self.input:update()
    end

    -- Update blink timer for selected option
    self.blink_timer = self.blink_timer + dt
    if self.blink_timer >= 0.5 then
        self.blink_state = not self.blink_state
        self.blink_timer = 0
    end

    -- Update input cooldown
    if self.input_cooldown > 0 then
        self.input_cooldown = self.input_cooldown - dt
    end

    -- Handle input (supports both keyboard and gamepad)
    if self.input and self.input_cooldown <= 0 then
        -- Move up (UP arrow, W, or D-pad up/left stick up)
        if self.input:is_down("up") then
            if self.selected_option ~= 1 then
                self.selected_option = 1
                -- Reset blink to make selection visible immediately
                self.blink_state = true
                self.blink_timer = 0
                self.input_cooldown = self.INPUT_COOLDOWN_TIME
            end
        -- Move down (DOWN arrow, S, or D-pad down/left stick down)
        elseif self.input:is_down("down") then
            if self.selected_option ~= 2 then
                self.selected_option = 2
                -- Reset blink to make selection visible immediately
                self.blink_state = true
                self.blink_timer = 0
                self.input_cooldown = self.INPUT_COOLDOWN_TIME
            end
        -- Confirm selection (ENTER, SPACE, or A button)
        elseif self.input:is_pressed("confirm") then
            self:confirmSelection()
        end
    end
end

function ResultsState:draw()
    -- Empty - results state renders everything in drawUI() for high resolution
end

function ResultsState:drawUI()
    -- Get window dimensions
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    local font = love.graphics.getFont()

    -- Draw dark background
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, screen_width, screen_height)

    local y_offset = screen_height * 0.05
    local text_scale = 2.0  -- Scale for high-res text

    -- Draw result header (win/lose message)
    if self.success then
        love.graphics.setColor(0.3, 1, 0.5)  -- Green for success
        local msg = "Dawn arrives safely"
        local msg_width = font:getWidth(msg) * text_scale * 1.2
        love.graphics.print(msg, screen_width / 2 - msg_width / 2, y_offset, 0, text_scale * 1.2, text_scale * 1.2)
    else
        -- Different messages based on failure reason
        if self.failure_reason == "fall" then
            love.graphics.setColor(1, 0.5, 0.3)  -- Orange for failure
            local msg = "Kitty fell from a great height..."
            local msg_width = font:getWidth(msg) * text_scale * 1.2
            love.graphics.print(msg, screen_width / 2 - msg_width / 2, y_offset, 0, text_scale * 1.2, text_scale * 1.2)
        else
            -- Default failure message (time ran out)
            love.graphics.setColor(1, 0.5, 0.3)  -- Orange for failure
            local msg = "Dawn has arrived..."
            local msg_width = font:getWidth(msg) * text_scale * 1.2
            love.graphics.print(msg, screen_width / 2 - msg_width / 2, y_offset, 0, text_scale * 1.2, text_scale * 1.2)
        end
    end

    y_offset = y_offset + 80

    -- Draw stats
    love.graphics.setColor(0.9, 0.9, 0.9)

    -- Deliveries
    y_offset = y_offset + 20
    local deliveries_text = string.format("Letters Delivered: %d/%d",
        self.deliveries_completed, self.total_deliveries)
    local deliveries_width = font:getWidth(deliveries_text) * text_scale
    love.graphics.print(deliveries_text, screen_width / 2 - deliveries_width / 2, y_offset, 0, text_scale, text_scale)

    -- Time
    y_offset = y_offset + 45
    if self.time_remaining >= 0 then
        local time_text = string.format("Time Remaining: %ds", math.floor(self.time_remaining))
        local time_width = font:getWidth(time_text) * text_scale
        love.graphics.print(time_text, screen_width / 2 - time_width / 2, y_offset, 0, text_scale, text_scale)
    else
        love.graphics.setColor(1, 0.5, 0.5)  -- Red for overtime
        local time_text = "Time: Expired"
        local time_width = font:getWidth(time_text) * text_scale
        love.graphics.print(time_text, screen_width / 2 - time_width / 2, y_offset, 0, text_scale, text_scale)
        love.graphics.setColor(0.9, 0.9, 0.9)
    end

    -- Combo Peak
    y_offset = y_offset + 45
    local combo_text = string.format("Combo Peak: x%d", self.combo_peak)
    local combo_width = font:getWidth(combo_text) * text_scale
    love.graphics.print(combo_text, screen_width / 2 - combo_width / 2, y_offset, 0, text_scale, text_scale)

    -- Final Score
    y_offset = y_offset + 45
    love.graphics.setColor(1, 1, 0.7)  -- Light yellow for score
    local score_text = string.format("Final Score: %d", self.score)
    local score_width = font:getWidth(score_text) * text_scale
    love.graphics.print(score_text, screen_width / 2 - score_width / 2, y_offset, 0, text_scale, text_scale)

    -- Rank display
    y_offset = y_offset + 60
    love.graphics.setColor(self.rank_data.color)
    local rank_text = string.format("Rank: %s (%s)",
        self.rank_data.rank, self.rank_data.title)
    local rank_width = font:getWidth(rank_text) * text_scale
    love.graphics.print(rank_text, screen_width / 2 - rank_width / 2, y_offset, 0, text_scale, text_scale)

    -- Encouragement text for failure
    if not self.success then
        y_offset = y_offset + 50
        love.graphics.setColor(0.7, 0.7, 0.8)
        local encourage_text = "Better luck next time!"
        local encourage_width = font:getWidth(encourage_text) * text_scale
        love.graphics.print(encourage_text, screen_width / 2 - encourage_width / 2, y_offset, 0, text_scale, text_scale)
    end

    -- Options (Continue/Retry and Restart)
    y_offset = y_offset + 80

    -- Option 1: Continue (if won) or Retry (if lost)
    local option1_text = self.success and "Continue" or "Retry"
    local option_scale = 2.5

    if self.selected_option == 1 then
        if self.blink_state then
            love.graphics.setColor(1, 1, 1)
            local opt1_text = "> " .. option1_text .. " <"
            local opt1_width = font:getWidth(opt1_text) * option_scale
            love.graphics.print(opt1_text, screen_width / 2 - opt1_width / 2, y_offset, 0, option_scale, option_scale)
        end
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        local opt1_text = "  " .. option1_text .. "  "
        local opt1_width = font:getWidth(opt1_text) * option_scale
        love.graphics.print(opt1_text, screen_width / 2 - opt1_width / 2, y_offset, 0, option_scale, option_scale)
    end

    -- Option 2: Restart
    y_offset = y_offset + 60

    if self.selected_option == 2 then
        if self.blink_state then
            love.graphics.setColor(1, 1, 1)
            local opt2_text = "> Restart <"
            local opt2_width = font:getWidth(opt2_text) * option_scale
            love.graphics.print(opt2_text, screen_width / 2 - opt2_width / 2, y_offset, 0, option_scale, option_scale)
        end
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        local opt2_text = "  Restart  "
        local opt2_width = font:getWidth(opt2_text) * option_scale
        love.graphics.print(opt2_text, screen_width / 2 - opt2_width / 2, y_offset, 0, option_scale, option_scale)
    end

    -- Instructions
    y_offset = y_offset + 70
    love.graphics.setColor(0.5, 0.5, 0.6)
    local inst_scale = 1.5
    local inst_text = "Arrow keys/D-pad to select, ENTER/A to confirm"
    local inst_width = font:getWidth(inst_text) * inst_scale
    love.graphics.print(inst_text, screen_width / 2 - inst_width / 2, y_offset, 0, inst_scale, inst_scale)
end

-- Handle confirmation of selected option
-- Switches to appropriate state based on selection
function ResultsState:confirmSelection()
    if not self.state_manager then
        print("[ResultsState] Warning: No state_manager reference, cannot confirm selection")
        return
    end

    if self.selected_option == 1 then
        if self.success then
            -- Continue - advance to next night
            local next_night = self.night_number + 1
            print("[ResultsState] Option 1 selected: Continue to Night " .. next_night)

            -- Check if next night level exists
            local level_path = "levels/night" .. next_night .. ".json"
            local level_info = love.filesystem.getInfo(level_path)

            if level_info then
                -- Next level exists, load it
                print("[ResultsState] Loading Night " .. next_night)
                self.state_manager:switch("game", next_night, self.state_manager)
            else
                -- No more levels, return to menu
                print("[ResultsState] No more levels available, returning to menu")
                self.state_manager:switch("menu", "All nights completed!", self.state_manager)
            end
        else
            -- Retry - restart same night
            print("[ResultsState] Option 1 selected: Retry Night " .. self.night_number)
            self.state_manager:switch("game", self.night_number, self.state_manager)
        end
    elseif self.selected_option == 2 then
        -- Restart same night
        print("[ResultsState] Option 2 selected: Restart Night " .. self.night_number)
        self.state_manager:switch("game", self.night_number, self.state_manager)
    end
end

return ResultsState
