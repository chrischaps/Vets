-- game_state.lua
-- Test game state for StateManager testing
-- Displays a simple game screen and allows returning to menu

local GameState = {}

function GameState:enter(param1, param2)
    print("[GameState] Entered game state" .. (param1 and " with params: " .. tostring(param1) .. ", " .. tostring(param2) or ""))
    self.timer = 0
    self.counter = 0
    self.param1 = param1
    self.param2 = param2
end

function GameState:exit()
    print("[GameState] Exiting game state after " .. string.format("%.1f", self.timer) .. " seconds")
end

function GameState:update(dt)
    self.timer = self.timer + dt
    self.counter = math.floor(self.timer)
end

function GameState:draw()
    love.graphics.setColor(0.2, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, 0, 320, 180)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("GAME STATE", 120, 60)
    love.graphics.print("Time: " .. string.format("%.1f", self.timer) .. "s", 120, 75)
    love.graphics.print("Counter: " .. self.counter, 120, 90)

    if self.param1 then
        love.graphics.setColor(0.7, 1, 0.7)
        love.graphics.print("Param 1: " .. tostring(self.param1), 120, 105)
        love.graphics.print("Param 2: " .. tostring(self.param2), 120, 120)
    end

    love.graphics.setColor(1, 0.8, 0.8)
    love.graphics.print("Press BACKSPACE to return to menu", 55, 145)
end

return GameState
