-- src/states/night_select_state.lua
-- Night selection state for choosing which night to play
--
-- Displays available nights with lock status, best scores, and ranks.
-- Allows navigation and selection using keyboard or gamepad.

local Input = require("src.systems.input")
local SaveSystem = require("src.systems.save_system")
local Scoring = require("src.systems.scoring")

local NightSelectState = {}

function NightSelectState:enter(message, state_manager)
    print("[NightSelectState] Entered night selection")

    -- Store state_manager reference for state transitions
    self.state_manager = state_manager

    -- Initialize input system
    self.input = Input.new()
    self.input:init()
    -- Update immediately to consume any held buttons from previous state
    -- This prevents input from cascading through state transitions
    self.input:update()

    -- UI state
    self.selected_night = 1
    self.blink_timer = 0
    self.blink = true

    -- Load night data from save system
    self:loadNightData()
end

function NightSelectState:exit()
    print("[NightSelectState] Exiting night selection")
end

-- Load night data from SaveSystem
function NightSelectState:loadNightData()
    -- Get save data
    local save_data = SaveSystem.getData()

    if not save_data then
        print("[NightSelectState] Warning: No save data found, using defaults")
        save_data = {
            nights_unlocked = 1,
            nights_completed = {},
            best_scores = {},
            best_ranks = {}
        }
    end

    -- Build nights table with information for each night
    self.nights = {}

    for i = 1, 3 do
        local night_key = "night" .. i
        local unlocked = i <= save_data.nights_unlocked
        local completed = save_data.nights_completed[night_key] or false
        local best_score = save_data.best_scores[night_key] or 0
        local best_rank = save_data.best_ranks[night_key]

        table.insert(self.nights, {
            number = i,
            name = "Night " .. i,
            unlocked = unlocked,
            completed = completed,
            best_score = best_score,
            best_rank = best_rank
        })

        print(string.format("[NightSelectState] Night %d: unlocked=%s, completed=%s, score=%d, rank=%s",
            i, tostring(unlocked), tostring(completed), best_score, tostring(best_rank)))
    end
end

function NightSelectState:update(dt)
    -- Update blink timer for selection indicator
    self.blink_timer = self.blink_timer + dt
    if self.blink_timer >= 0.5 then
        self.blink = not self.blink
        self.blink_timer = 0
    end

    -- Update input system
    if self.input then
        self.input:update()

        -- Handle navigation (up/down)
        if self.input:is_pressed("up") then
            self.selected_night = self.selected_night - 1
            if self.selected_night < 1 then
                self.selected_night = #self.nights  -- Wrap around
            end
            print("[NightSelectState] Selected Night " .. self.selected_night)
        elseif self.input:is_pressed("down") then
            self.selected_night = self.selected_night + 1
            if self.selected_night > #self.nights then
                self.selected_night = 1  -- Wrap around
            end
            print("[NightSelectState] Selected Night " .. self.selected_night)
        end

        -- Handle selection (confirm)
        if self.input:is_pressed("confirm") then
            self:selectNight()
        end

        -- Handle back (pause/escape)
        if self.input:is_pressed("pause") then
            self:goBack()
        end
    end
end

-- Select the current night
function NightSelectState:selectNight()
    local night = self.nights[self.selected_night]

    if night.unlocked then
        print("[NightSelectState] Starting Night " .. night.number)
        if self.state_manager then
            self.state_manager:switch("game", night.number, self.state_manager)
        else
            print("[NightSelectState] Warning: No state_manager reference")
        end
    else
        print("[NightSelectState] Night " .. night.number .. " is locked!")
        -- TODO: Play error sound when audio system is available
    end
end

-- Go back to menu
function NightSelectState:goBack()
    print("[NightSelectState] Going back to menu")
    if self.state_manager then
        self.state_manager:switch("menu", "Night selection cancelled", self.state_manager)
    else
        print("[NightSelectState] Warning: No state_manager reference")
    end
end

function NightSelectState:draw()
    -- Empty - night select state renders everything in drawUI() for high resolution
end

function NightSelectState:drawUI()
    -- Get window dimensions and font
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    local font = love.graphics.getFont()

    -- Draw dark background
    love.graphics.setColor(0.1, 0.1, 0.15)
    love.graphics.rectangle("fill", 0, 0, screen_width, screen_height)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    local title = "SELECT YOUR NIGHT"
    local title_scale = 2.5
    local title_width = font:getWidth(title) * title_scale
    love.graphics.print(title, screen_width / 2 - title_width / 2, screen_height * 0.1, 0, title_scale, title_scale)

    -- Draw nights list
    local start_y = screen_height * 0.25
    local night_spacing = 100

    for i, night in ipairs(self.nights) do
        local y = start_y + (i - 1) * night_spacing
        local is_selected = (i == self.selected_night)

        -- Draw selection indicator (blinking)
        if is_selected and self.blink then
            love.graphics.setColor(1, 1, 0.5)
            local indicator = ">"
            local indicator_scale = 2.0
            love.graphics.print(indicator, screen_width * 0.2, y, 0, indicator_scale, indicator_scale)
        end

        -- Draw night name
        local name_x = screen_width * 0.25
        local name_scale = 2.0

        if night.unlocked then
            -- Unlocked night - white text
            love.graphics.setColor(1, 1, 1)
        else
            -- Locked night - gray text with lock icon
            love.graphics.setColor(0.4, 0.4, 0.4)
        end

        local display_name = night.name
        if not night.unlocked then
            display_name = display_name .. " [LOCKED]"
        end

        love.graphics.print(display_name, name_x, y, 0, name_scale, name_scale)

        -- Draw score and rank info (if unlocked and completed)
        if night.unlocked then
            local info_y = y + 30
            local info_scale = 1.5

            if night.completed and night.best_rank then
                -- Show best score
                love.graphics.setColor(0.8, 0.8, 0.8)
                local score_text = string.format("Best: %d pts", night.best_score)
                love.graphics.print(score_text, name_x, info_y, 0, info_scale, info_scale)

                -- Show best rank with color
                local rank_color = Scoring.getRankColor(night.best_rank)
                love.graphics.setColor(rank_color[1], rank_color[2], rank_color[3])
                local rank_text = "Rank: " .. night.best_rank
                local score_width = font:getWidth(score_text) * info_scale
                love.graphics.print(rank_text, name_x + score_width + 30, info_y, 0, info_scale, info_scale)
            else
                -- Not completed yet
                love.graphics.setColor(0.6, 0.6, 0.6)
                local text = "Not Completed"
                love.graphics.print(text, name_x, info_y, 0, info_scale, info_scale)
            end
        else
            -- Show unlock requirement
            local info_y = y + 30
            local info_scale = 1.3
            love.graphics.setColor(0.5, 0.5, 0.5)
            local unlock_text = "Complete Night " .. (i - 1) .. " to unlock"
            love.graphics.print(unlock_text, name_x, info_y, 0, info_scale, info_scale)
        end
    end

    -- Draw controls at bottom
    local controls_y = screen_height * 0.85
    love.graphics.setColor(0.7, 0.7, 0.7)
    local controls = "UP/DOWN: Navigate | ENTER/A: Select | ESC/B: Back"
    local controls_scale = 1.5
    local controls_width = font:getWidth(controls) * controls_scale
    love.graphics.print(controls, screen_width / 2 - controls_width / 2, controls_y, 0, controls_scale, controls_scale)
end

return NightSelectState
