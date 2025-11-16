-- pause_state.lua
-- Pause menu state for Courier Cat
-- Provides menu options to resume, restart, or quit to menu

local Input = require("src.systems.input")

local PauseState = {}

-- Virtual resolution (for positioning)
local VIRTUAL_WIDTH = 320
local VIRTUAL_HEIGHT = 180

-- Menu options
local MENU_OPTIONS = {
    {label = "Resume", action = "resume"},
    {label = "Restart", action = "restart"},
    {label = "Quit to Menu", action = "quit"}
}

function PauseState:enter(state_manager, night_number)
    print("[PauseState] Entering pause state")

    -- Store state_manager reference for state transitions
    self.state_manager = state_manager

    -- Store night number for restart functionality
    self.night_number = night_number or 1

    -- Menu state
    self.selected_option = 1  -- Start with "Resume" selected
    self.menu_options = MENU_OPTIONS

    -- Initialize input system
    self.input = Input.new()
    self.input:init()

    -- Input cooldown to prevent accidental double-presses
    self.cooldown_duration = 0.2  -- 200ms between inputs
    -- IMPORTANT: Start with cooldown active to ignore the pause button that opened this menu
    self.input_cooldown = self.cooldown_duration
end

function PauseState:exit()
    print("[PauseState] Exiting pause state")
end

function PauseState:update(dt)
    -- Update input system
    if self.input then
        self.input:update()
    end

    -- Update input cooldown
    if self.input_cooldown > 0 then
        self.input_cooldown = self.input_cooldown - dt
    end

    -- Handle menu navigation (only if cooldown expired)
    if self.input_cooldown <= 0 then
        -- Navigate up
        if self.input:is_pressed("up") then
            self.selected_option = self.selected_option - 1
            if self.selected_option < 1 then
                self.selected_option = #self.menu_options  -- Wrap to bottom
            end
            self.input_cooldown = self.cooldown_duration
            print("[PauseState] Selected option: " .. self.menu_options[self.selected_option].label)
        end

        -- Navigate down
        if self.input:is_pressed("down") then
            self.selected_option = self.selected_option + 1
            if self.selected_option > #self.menu_options then
                self.selected_option = 1  -- Wrap to top
            end
            self.input_cooldown = self.cooldown_duration
            print("[PauseState] Selected option: " .. self.menu_options[self.selected_option].label)
        end

        -- Handle selection (confirm or pause button to resume)
        if self.input:is_pressed("confirm") or
           (self.input:is_pressed("pause") and self.selected_option == 1) then
            self:selectOption(self.selected_option)
        end
    end
end

-- Handle menu option selection
function PauseState:selectOption(index)
    local option = self.menu_options[index]
    if not option then
        return
    end

    print("[PauseState] Executing action: " .. option.action)

    if option.action == "resume" then
        self:resume()
    elseif option.action == "restart" then
        self:restart()
    elseif option.action == "quit" then
        self:quit()
    end
end

-- Resume gameplay (pop pause state)
function PauseState:resume()
    print("[PauseState] Resuming gameplay")

    if self.state_manager then
        self.state_manager:pop()
    else
        print("[PauseState] Warning: No state_manager reference, cannot resume")
    end
end

-- Restart current night
function PauseState:restart()
    print("[PauseState] Restarting Night " .. self.night_number)

    if self.state_manager then
        -- Pop pause state first, then switch to fresh game state
        self.state_manager:pop()
        self.state_manager:switch("game", self.night_number, self.state_manager)
    else
        print("[PauseState] Warning: No state_manager reference, cannot restart")
    end
end

-- Quit to main menu
function PauseState:quit()
    print("[PauseState] Quitting to menu")

    if self.state_manager then
        -- Pop pause state, then pop game state to return to menu
        -- For now, just pop pause and switch to menu (since menu state exists)
        self.state_manager:pop()
        self.state_manager:switch("menu", "Returned from gameplay", self.state_manager)
    else
        print("[PauseState] Warning: No state_manager reference, cannot quit")
    end
end

function PauseState:draw()
    -- Draw dimmed background (semi-transparent black overlay)
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    -- Draw "PAUSED" title
    love.graphics.setColor(1, 1, 1)
    local title = "PAUSED"
    local title_x = VIRTUAL_WIDTH / 2 - 30
    local title_y = 40
    love.graphics.print(title, title_x, title_y, 0, 1.5, 1.5)  -- 1.5x scale for title

    -- Draw menu options
    local menu_start_y = 80
    local menu_spacing = 20

    for i, option in ipairs(self.menu_options) do
        local y = menu_start_y + (i - 1) * menu_spacing

        -- Highlight selected option
        if i == self.selected_option then
            -- Draw selection indicator
            love.graphics.setColor(1, 1, 0.3)  -- Yellow for selected
            love.graphics.print("> " .. option.label, VIRTUAL_WIDTH / 2 - 40, y, 0, 1.2, 1.2)
        else
            -- Normal text
            love.graphics.setColor(0.7, 0.7, 0.7)  -- Gray for unselected
            love.graphics.print("  " .. option.label, VIRTUAL_WIDTH / 2 - 40, y)
        end
    end

    -- Draw control hints
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Arrow Keys/D-pad: Navigate", VIRTUAL_WIDTH / 2 - 65, VIRTUAL_HEIGHT - 30)
    love.graphics.print("Enter/A: Select", VIRTUAL_WIDTH / 2 - 40, VIRTUAL_HEIGHT - 15)
end

return PauseState
