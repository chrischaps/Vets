-- menu_state.lua
-- Test menu state for StateManager testing
-- Displays a simple menu and allows switching to game state

local MenuState = {}

function MenuState:enter(message)
    print("[MenuState] Entered menu state" .. (message and ": " .. message or ""))
    self.timer = 0
    self.blink = true
    self.message = message or "Welcome!"
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
end

function MenuState:draw()
    love.graphics.setColor(0.1, 0.1, 0.2)
    love.graphics.rectangle("fill", 0, 0, 320, 180)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("MENU STATE", 120, 60)
    love.graphics.print(self.message, 120, 75)

    if self.blink then
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Press ENTER to start game", 80, 110)
    end

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Press F5 to test state switching", 65, 140)
end

return MenuState
