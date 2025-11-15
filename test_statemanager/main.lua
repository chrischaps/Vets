-- test_statemanager.lua
-- Standalone test for StateManager system (VETS-29)
-- Run with: lovec test_statemanager.lua

-- Load StateManager and test states
local StateManager = require("src.systems.state_manager")
local MenuState = require("src.states.menu_state")
local GameState = require("src.states.game_state")

-- Global state manager
local state_manager = nil

-- Rapid switching test variables
local rapid_test_active = false
local rapid_test_timer = 0
local rapid_test_count = 0

function love.load()
    -- Set up pixel-perfect rendering
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Set window size and title
    love.window.setMode(640, 360)
    love.window.setTitle("StateManager Test - VETS-29")

    print("=== StateManager Test (VETS-29) ===\n")

    -- Create state manager
    print("1. Creating StateManager...")
    state_manager = StateManager.new()
    print("   StateManager created: " .. (state_manager and "OK" or "FAILED"))

    -- Register states
    print("\n2. Registering states...")
    state_manager:register("menu", MenuState)
    print("   MenuState registered: " .. (state_manager:hasState("menu") and "OK" or "FAILED"))

    state_manager:register("game", GameState)
    print("   GameState registered: " .. (state_manager:hasState("game") and "OK" or "FAILED"))

    -- Test switching to initial state
    print("\n3. Switching to initial state (menu)...")
    state_manager:switch("menu", "Welcome to StateManager test!")
    print("   Current state: " .. (state_manager:current() == MenuState and "MenuState" or "Unknown"))

    print("\n=== StateManager initialized successfully! ===")
    print("\nControls:")
    print("  ENTER - Switch from Menu to Game")
    print("  BACKSPACE - Switch from Game to Menu")
    print("  F5 - Test rapid state switching (10 switches)")
    print("  F6 - Test state stack (push/pop)")
    print("  ESC - Quit")
    print("\nWatch console for enter/exit callbacks!")
    print("=====================================\n")
end

function love.update(dt)
    -- Update current state
    if state_manager then
        state_manager:update(dt)
    end

    -- Rapid switching test
    if rapid_test_active then
        rapid_test_timer = rapid_test_timer + dt

        if rapid_test_timer >= 0.1 then  -- Switch every 0.1 seconds
            rapid_test_timer = 0
            rapid_test_count = rapid_test_count + 1

            -- Alternate between menu and game
            if rapid_test_count % 2 == 0 then
                state_manager:switch("menu", "Rapid test switch #" .. rapid_test_count)
            else
                state_manager:switch("game", "Switch", rapid_test_count)
            end

            -- Stop after 10 switches
            if rapid_test_count >= 10 then
                rapid_test_active = false
                rapid_test_count = 0
                print("\n[Test] Rapid switching test completed - no crashes!")
                state_manager:switch("menu", "Rapid test complete!")
            end
        end
    end
end

function love.draw()
    -- Draw current state
    if state_manager then
        state_manager:draw()
    end

    -- Draw test info overlay
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", 0, 0, 640, 30)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("StateManager Test (VETS-29)", 10, 8)

    -- Show previous state if available
    local prev_state = state_manager:previous()
    if prev_state then
        local prev_name = (prev_state == MenuState) and "MenuState" or (prev_state == GameState) and "GameState" or "Unknown"
        love.graphics.print("Previous: " .. prev_name, 250, 8)
    end

    -- Show stack size if using stack
    if state_manager:isUsingStack() then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("Stack size: " .. state_manager:getStackSize(), 450, 8)
    end

    -- Show rapid test status
    if rapid_test_active then
        love.graphics.setColor(1, 0.5, 0)
        love.graphics.print("RAPID TEST: " .. rapid_test_count .. "/10", 500, 8)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "return" then
        -- Switch to game state with parameters
        print("\n[User] Switching to GameState...")
        state_manager:switch("game", "test_param1", 42)
    elseif key == "backspace" then
        -- Switch back to menu state
        print("\n[User] Switching back to MenuState...")
        state_manager:switch("menu", "Welcome back!")
    elseif key == "f5" then
        -- Test rapid state switching
        print("\n[Test] Starting rapid state switching test...")
        rapid_test_active = true
        rapid_test_timer = 0
        rapid_test_count = 0
    elseif key == "f6" then
        -- Test state stack
        if not state_manager:isUsingStack() then
            print("\n[Test] Testing state stack - pushing GameState...")
            state_manager:push("game", "Pushed state", 99)
        else
            print("\n[Test] Popping state from stack...")
            state_manager:pop()
        end
    end
end
