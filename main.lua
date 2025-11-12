-- main.lua
-- Entry point for Courier Cat

-- Load external libraries
local libs = require("libraries.init")

-- Load core systems
local Time = require("src.core.time")

-- Load entity system
local Entity = require("src.entities.entity")

-- Virtual resolution for pixel-perfect rendering
VIRTUAL_WIDTH = 320
VIRTUAL_HEIGHT = 180

-- Test entity for verification
local test_entity = nil

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

    print("Courier Cat initialized!")
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

    -- Test Entity-Component System
    print("\nTesting Entity-Component System:")
    test_entity = Entity.new("test")
    print("  - Entity created with ID: " .. test_entity.id .. ", type: " .. test_entity.type)

    -- Test component management
    local test_component = { name = "test_component", value = 42 }
    test_entity:addComponent("test", test_component)
    print("  - Component added: " .. (test_entity:hasComponent("test") and "OK" or "FAILED"))
    print("  - Component retrieval: " .. (test_entity:getComponent("test").value == 42 and "OK" or "FAILED"))

    -- Test tag system
    test_entity:addTag("player")
    test_entity:addTag("controllable")
    print("  - Tags added: " .. (test_entity:hasTag("player") and test_entity:hasTag("controllable") and "OK" or "FAILED"))

    -- Test active/inactive system
    test_entity:deactivate()
    print("  - Deactivate: " .. (not test_entity:isActive() and "OK" or "FAILED"))
    test_entity:activate()
    print("  - Activate: " .. (test_entity:isActive() and "OK" or "FAILED"))

    print("\nEntity-Component System: OK")
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
        -- Update game logic here using Time.FIXED_DT
        -- All game entities, physics, etc. should use Time.FIXED_DT for consistency

        -- This will be expanded as we add more systems
    end
end

function love.draw()
    -- Draw to game canvas
    love.graphics.setCanvas(game_canvas)
    love.graphics.clear()

    -- Draw game content here
    love.graphics.setColor(0.2, 0.2, 0.3)  -- Dark blue-purple background
    love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    -- Draw placeholder text
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Courier Cat", 10, 10)
    love.graphics.print("LOVE " .. love.getVersion(), 10, 30)
    love.graphics.print("Press ESC to quit", 10, 50)

    -- Debug: Display time info
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Fixed timestep: " .. Time.FIXED_DT .. "s (" .. Time:getFPS() .. " FPS)", 10, 80)
    love.graphics.print("Frame: " .. Time.frame, 10, 95)
    love.graphics.print("Total time: " .. string.format("%.2f", Time.total) .. "s", 10, 110)
    love.graphics.print("Actual FPS: " .. love.timer.getFPS(), 10, 125)

    -- Draw to screen
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
    if key == "escape" then
        love.event.quit()
    end
end
