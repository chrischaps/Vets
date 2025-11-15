-- results_state.lua
-- Results/end screen state for Courier Cat
-- Displays game completion stats, rank, and options to continue or restart

local ResultsState = {}

-- Virtual resolution (shared across states)
local VIRTUAL_WIDTH = 320
local VIRTUAL_HEIGHT = 180

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
    self.night_number = data.night_number or 1
    self.score = data.score or 0
    self.time_remaining = data.time_remaining or 0
    self.deliveries_completed = data.deliveries_completed or 0
    self.total_deliveries = data.total_deliveries or 0
    self.combo_peak = data.combo_peak or 0

    -- Calculate rank based on score
    self.rank_data = self:calculateRank(self.score)

    -- UI state
    self.selected_option = 1  -- 1 = Continue/Retry, 2 = Restart
    self.blink_timer = 0
    self.blink_state = true

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
    -- Update blink timer for selected option
    self.blink_timer = self.blink_timer + dt
    if self.blink_timer >= 0.5 then
        self.blink_state = not self.blink_state
        self.blink_timer = 0
    end

    -- Handle input (simple keyboard input for now)
    -- TODO: Use Input system when integrated
    if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
        if self.selected_option ~= 1 then
            self.selected_option = 1
            -- Reset blink to make selection visible immediately
            self.blink_state = true
            self.blink_timer = 0
        end
    elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
        if self.selected_option ~= 2 then
            self.selected_option = 2
            -- Reset blink to make selection visible immediately
            self.blink_state = true
            self.blink_timer = 0
        end
    end
end

function ResultsState:draw()
    -- Draw dark background
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    local y_offset = 20

    -- Draw result header (win/lose message)
    if self.success then
        love.graphics.setColor(0.3, 1, 0.5)  -- Green for success
        love.graphics.print("Dawn arrives safely", VIRTUAL_WIDTH / 2 - 65, y_offset)
    else
        love.graphics.setColor(1, 0.5, 0.3)  -- Orange for failure
        love.graphics.print("Dawn has arrived...", VIRTUAL_WIDTH / 2 - 65, y_offset)
    end

    y_offset = y_offset + 20

    -- Draw stats
    love.graphics.setColor(0.9, 0.9, 0.9)

    -- Deliveries
    y_offset = y_offset + 5
    love.graphics.print(string.format("Letters Delivered: %d/%d",
        self.deliveries_completed, self.total_deliveries),
        VIRTUAL_WIDTH / 2 - 70, y_offset)

    -- Time
    y_offset = y_offset + 12
    if self.time_remaining >= 0 then
        love.graphics.print(string.format("Time Remaining: %ds", math.floor(self.time_remaining)),
            VIRTUAL_WIDTH / 2 - 65, y_offset)
    else
        love.graphics.setColor(1, 0.5, 0.5)  -- Red for overtime
        love.graphics.print("Time: Expired", VIRTUAL_WIDTH / 2 - 40, y_offset)
        love.graphics.setColor(0.9, 0.9, 0.9)
    end

    -- Combo Peak
    y_offset = y_offset + 12
    love.graphics.print(string.format("Combo Peak: x%d", self.combo_peak),
        VIRTUAL_WIDTH / 2 - 50, y_offset)

    -- Final Score
    y_offset = y_offset + 12
    love.graphics.setColor(1, 1, 0.7)  -- Light yellow for score
    love.graphics.print(string.format("Final Score: %d", self.score),
        VIRTUAL_WIDTH / 2 - 50, y_offset)

    -- Rank display
    y_offset = y_offset + 18
    love.graphics.setColor(self.rank_data.color)
    love.graphics.print(string.format("Rank: %s (%s)",
        self.rank_data.rank, self.rank_data.title),
        VIRTUAL_WIDTH / 2 - 80, y_offset)

    -- Encouragement text for failure
    if not self.success then
        y_offset = y_offset + 15
        love.graphics.setColor(0.7, 0.7, 0.8)
        love.graphics.print("Better luck next time!", VIRTUAL_WIDTH / 2 - 65, y_offset)
    end

    -- Options (Continue/Retry and Restart)
    y_offset = y_offset + 25

    -- Option 1: Continue (if won) or Retry (if lost)
    local option1_text = self.success and "Continue" or "Retry"
    local option1_x = VIRTUAL_WIDTH / 2 - 60

    if self.selected_option == 1 then
        if self.blink_state then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("> " .. option1_text .. " <", option1_x, y_offset)
        end
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("  " .. option1_text .. "  ", option1_x, y_offset)
    end

    -- Option 2: Restart
    y_offset = y_offset + 15
    local option2_x = VIRTUAL_WIDTH / 2 - 60

    if self.selected_option == 2 then
        if self.blink_state then
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("> Restart <", option2_x, y_offset)
        end
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("  Restart  ", option2_x, y_offset)
    end

    -- Instructions
    y_offset = y_offset + 20
    love.graphics.setColor(0.5, 0.5, 0.6)
    love.graphics.print("Arrow keys to select, ENTER to confirm", VIRTUAL_WIDTH / 2 - 95, y_offset)
end

return ResultsState
