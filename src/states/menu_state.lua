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
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, 320, 180)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("MENU STATE", 120, 60)
    love.graphics.print(self.message, 120, 75)

    if self.blink then
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Press ENTER/A to start game", 80, 110)
    end

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("(supports keyboard and gamepad)", 70, 125)
end

return MenuState
