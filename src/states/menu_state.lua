-- menu_state.lua
-- Main menu state for Courier Cat (VETS-58)
-- Displays menu options: Select Night, Options, Quit

local Input = require("src.systems.input")

local MenuState = {}

function MenuState:enter(message, state_manager)
    print("[MenuState] Entered menu state" .. (message and ": " .. message or ""))
    self.message = message or "Welcome to Courier Cat!"

    -- Store state_manager reference for state transitions
    self.state_manager = state_manager

    -- Initialize input system
    self.input = Input.new()
    self.input:init()
    -- Update immediately to consume any held buttons from previous state
    -- This prevents input from cascading through state transitions
    self.input:update()

    -- Menu options (VETS-58)
    self.selected_option = 1
    self.options = {
        {
            text = "SELECT NIGHT",
            action = function()
                if self.state_manager then
                    print("[MenuState] Transitioning to Night Select")
                    self.state_manager:switch("night_select", "", self.state_manager)
                end
            end
        },
        {
            text = "OPTIONS",
            action = function()
                print("[MenuState] Options not yet implemented")
                -- Future: Transition to options menu
            end
        },
        {
            text = "QUIT",
            action = function()
                print("[MenuState] Quitting game")
                love.event.quit()
            end
        }
    }

    -- For blinking selection indicator
    self.blink_timer = 0
    self.blink = true
end

function MenuState:exit()
    print("[MenuState] Exiting menu state")
end

function MenuState:update(dt)
    -- Blink selection indicator every 0.5 seconds
    self.blink_timer = self.blink_timer + dt
    if self.blink_timer >= 0.5 then
        self.blink = not self.blink
        self.blink_timer = 0
    end

    -- Update input system
    if self.input then
        self.input:update()

        -- Navigate up
        if self.input:is_pressed("up") then
            self.selected_option = self.selected_option - 1
            if self.selected_option < 1 then
                self.selected_option = #self.options
            end
            print("[MenuState] Selected option: " .. self.selected_option .. " - " .. self.options[self.selected_option].text)
        end

        -- Navigate down
        if self.input:is_pressed("down") then
            self.selected_option = self.selected_option + 1
            if self.selected_option > #self.options then
                self.selected_option = 1
            end
            print("[MenuState] Selected option: " .. self.selected_option .. " - " .. self.options[self.selected_option].text)
        end

        -- Confirm selection
        if self.input:is_pressed("confirm") then
            local selected = self.options[self.selected_option]
            print("[MenuState] Confirmed: " .. selected.text)
            if selected.action then
                selected.action()
            end
        end
    end
end

function MenuState:draw()
    -- Empty - menu state renders everything in drawUI() for high resolution
end

function MenuState:drawUI()
    -- Get window dimensions
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()
    local font = love.graphics.getFont()

    -- Draw dark background
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, screen_width, screen_height)

    -- Draw "COURIER CAT" title
    love.graphics.setColor(1, 1, 1)
    local title = "COURIER CAT"
    local title_scale = 3.0
    local title_width = font:getWidth(title) * title_scale
    love.graphics.print(title, screen_width / 2 - title_width / 2, screen_height * 0.2, 0, title_scale, title_scale)

    -- Draw menu options (VETS-58)
    local option_y_start = screen_height * 0.45
    local option_spacing = 60

    for i, option in ipairs(self.options) do
        local y_pos = option_y_start + (i - 1) * option_spacing
        local is_selected = (i == self.selected_option)

        -- Draw selection indicator (blinking)
        if is_selected and self.blink then
            love.graphics.setColor(0.8, 0.8, 1)
            local indicator = "> "
            local ind_scale = 2.5
            local ind_width = font:getWidth(indicator) * ind_scale
            love.graphics.print(indicator, screen_width / 2 - 150, y_pos, 0, ind_scale, ind_scale)
        end

        -- Draw option text
        if is_selected then
            love.graphics.setColor(1, 1, 1)  -- White for selected
        else
            love.graphics.setColor(0.6, 0.6, 0.6)  -- Gray for unselected
        end

        local option_scale = 2.5
        local option_width = font:getWidth(option.text) * option_scale
        love.graphics.print(option.text, screen_width / 2 - option_width / 2, y_pos, 0, option_scale, option_scale)
    end

    -- Draw hint text at bottom
    love.graphics.setColor(0.5, 0.5, 0.5)
    local hint = "[UP/DOWN] Navigate  [SPACE/ENTER] Select"
    local hint_scale = 1.5
    local hint_width = font:getWidth(hint) * hint_scale
    love.graphics.print(hint, screen_width / 2 - hint_width / 2, screen_height * 0.85, 0, hint_scale, hint_scale)
end

return MenuState
