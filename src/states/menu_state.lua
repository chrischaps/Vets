-- menu_state.lua
-- Test menu state for StateManager testing
-- Displays a simple menu and allows switching to game state

local Input = require("src.systems.input")

local MenuState = {}

function MenuState:enter(message, state_manager)
    print("[MenuState] Entered menu state" .. (message and ": " .. message or ""))
    self.timer = 0
    self.blink = true
    self.message = message or "Welcome!"

    -- Store state_manager reference for state transitions
    self.state_manager = state_manager

    -- Initialize input system
    self.input = Input.new()
    self.input:init()
end

function MenuState:exit()
    print("[MenuState] Exiting menu state")
end

function MenuState:update(dt)
    self.timer = self.timer + dt

    -- Blink text every 0.5 seconds
    if self.timer >= 0.5 then
        self.blink = not self.blink
        self.timer = 0
    end

    -- Update input system
    if self.input then
        self.input:update()

        -- Check for confirm input (ENTER, SPACE, or gamepad A button)
        if self.input:is_pressed("confirm") then
            self:startGame()
        end
    end
end

-- Start the game by switching to GameState
function MenuState:startGame()
    if self.state_manager then
        print("[MenuState] Starting Night 1")
        self.state_manager:switch("game", 1, self.state_manager)
    else
        print("[MenuState] Warning: No state_manager reference, cannot start game")
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

    -- Draw "MENU STATE" title
    love.graphics.setColor(1, 1, 1)
    local title = "MENU STATE"
    local title_scale = 3.0
    local title_width = font:getWidth(title) * title_scale
    love.graphics.print(title, screen_width / 2 - title_width / 2, screen_height * 0.3, 0, title_scale, title_scale)

    -- Draw message
    local msg_scale = 2.0
    local msg_width = font:getWidth(self.message) * msg_scale
    love.graphics.print(self.message, screen_width / 2 - msg_width / 2, screen_height * 0.4, 0, msg_scale, msg_scale)

    -- Draw blinking prompt
    if self.blink then
        love.graphics.setColor(0.8, 0.8, 1)
        local prompt = "Press ENTER/A to start game"
        local prompt_scale = 2.5
        local prompt_width = font:getWidth(prompt) * prompt_scale
        love.graphics.print(prompt, screen_width / 2 - prompt_width / 2, screen_height * 0.6, 0, prompt_scale, prompt_scale)
    end

    -- Draw hint text
    love.graphics.setColor(0.6, 0.6, 0.6)
    local hint = "(supports keyboard and gamepad)"
    local hint_scale = 1.5
    local hint_width = font:getWidth(hint) * hint_scale
    love.graphics.print(hint, screen_width / 2 - hint_width / 2, screen_height * 0.7, 0, hint_scale, hint_scale)
end

return MenuState
