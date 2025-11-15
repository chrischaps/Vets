-- main.lua
-- Entry point for Courier Cat
-- Refactored to use StateManager for proper game flow

-- Load external libraries
local libs = require("libraries.init")

-- Load core systems
local Time = require("src.core.time")

-- Load StateManager and states
local StateManager = require("src.systems.state_manager")
local MenuState = require("src.states.menu_state")
local GameState = require("src.states.game_state")

-- Virtual resolution for pixel-perfect rendering
VIRTUAL_WIDTH = 320
VIRTUAL_HEIGHT = 180

-- Game state management
local state_manager = nil

-- Game canvas for rendering
local game_canvas = nil
local game_scale = 1
local offset_x = 0
local offset_y = 0

function love.load()
    -- Set up pixel-perfect rendering
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- Create game canvas at virtual resolution
    game_canvas = love.graphics.newCanvas(VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    game_canvas:setFilter("nearest", "nearest")

    -- Calculate scale and offsets for letterboxing
    calculate_scale()

    -- Set window title
    love.window.setTitle("Courier Cat")

    print("=== Courier Cat ===")
    print("Virtual resolution: " .. VIRTUAL_WIDTH .. "x" .. VIRTUAL_HEIGHT)
    print("Window resolution: " .. love.graphics.getWidth() .. "x" .. love.graphics.getHeight())

    -- Verify libraries loaded
    print("\nLibraries loaded:")
    print("  - bump.lua: " .. (libs.bump and "OK" or "FAILED"))
    print("  - anim8: " .. (libs.anim8 and "OK" or "FAILED"))
    print("  - camera: " .. (libs.camera and "OK" or "FAILED"))
    print("  - json: " .. (libs.json and "OK" or "FAILED"))

    -- Initialize time system
    Time:init()
    print("\nTime system initialized:")
    print("  - Fixed timestep: " .. Time.FIXED_DT .. "s (" .. Time:getFPS() .. " FPS)")

    -- Initialize StateManager
    print("\nInitializing StateManager...")
    state_manager = StateManager.new()

    -- Register states
    state_manager:register("menu", MenuState)
    state_manager:register("game", GameState)

    -- Start with GameState (Option 1: Direct to GameState)
    -- TODO: Switch to MenuState when it's fully functional (Option 2)
    print("\nStarting game...")
    state_manager:switch("game", 1)  -- Night 1

    print("\n=== Game started! Use arrow keys/WASD to move, Space to jump, P to pause ===")
end

function love.resize(w, h)
    -- Recalculate scale when window is resized
    calculate_scale()
end

function calculate_scale()
    local window_width, window_height = love.graphics.getDimensions()
    local scale_x = window_width / VIRTUAL_WIDTH
    local scale_y = window_height / VIRTUAL_HEIGHT

    -- Use smallest scale to maintain aspect ratio
    game_scale = math.min(scale_x, scale_y)

    -- Calculate letterbox offsets
    offset_x = (window_width - VIRTUAL_WIDTH * game_scale) / 2
    offset_y = (window_height - VIRTUAL_HEIGHT * game_scale) / 2
end

function love.update(dt)
    -- Fixed timestep game loop
    -- This ensures consistent physics and deterministic gameplay at 60 FPS
    local updates = Time:update(dt)

    -- Perform fixed updates
    for i = 1, updates do
        -- Delegate to StateManager
        if state_manager then
            state_manager:update(Time.FIXED_DT)
        end
    end
end

function love.draw()
    -- Draw to game canvas
    love.graphics.setCanvas(game_canvas)
    love.graphics.clear()

    -- Delegate to StateManager
    if state_manager then
        state_manager:draw()
    end

    -- Draw to screen with letterboxing
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        game_canvas,
        offset_x, offset_y,
        0,
        game_scale, game_scale
    )
end

function love.keypressed(key)
    -- Handle global keypresses
    if key == "escape" then
        love.event.quit()
    end

    -- Handle state-specific keypresses
    -- Menu state: ENTER to start game
    if state_manager and state_manager:current() == MenuState then
        if key == "return" then
            state_manager:switch("game", 1)  -- Start Night 1
        end
    end
end

function love.joystickadded(joystick)
    -- Forward to current state if it has input system
    local current = state_manager and state_manager:current()
    if current and current.input then
        current.input:joystick_added(joystick)
    end
end

function love.joystickremoved(joystick)
    -- Forward to current state if it has input system
    local current = state_manager and state_manager:current()
    if current and current.input then
        current.input:joystick_removed(joystick)
    end
end
