-- main.lua
-- Entry point for Courier Cat

-- Load external libraries
local libs = require("libraries.init")

-- Load core systems
local Time = require("src.core.time")
local Constants = require("src.core.constants")

-- Load entity system
local Entity = require("src.entities.entity")

-- Load components
local Transform = require("src.components.transform")
local Physics = require("src.components.physics")
local Collision = require("src.components.collision")

-- Load entities
local Player = require("src.entities.player")

-- Virtual resolution for pixel-perfect rendering
VIRTUAL_WIDTH = 320
VIRTUAL_HEIGHT = 180

-- Test entity for verification
local test_entity = nil

-- Game entities
local player = nil

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

    -- Test Core Components
    print("\nTesting Core Components:")

    -- Test Transform component
    local test_transform = Transform.new(100, 50, 0, 1, 1, 0)
    print("  - Transform created at (" .. test_transform.x .. ", " .. test_transform.y .. "): OK")
    test_transform:translate(10, 20)
    print("  - Transform translate: " .. (test_transform.x == 110 and test_transform.y == 70 and "OK" or "FAILED"))
    test_transform:setRotation(math.pi / 4)
    print("  - Transform rotation: " .. (math.abs(test_transform.rotation - math.pi/4) < 0.001 and "OK" or "FAILED"))

    -- Test Physics component
    local test_physics = Physics.new()
    print("  - Physics created with velocity (" .. test_physics.velocity_x .. ", " .. test_physics.velocity_y .. "): OK")
    test_physics:setVelocity(100, -200)
    print("  - Physics velocity set: " .. (test_physics.velocity_x == 100 and test_physics.velocity_y == -200 and "OK" or "FAILED"))
    test_physics:applyImpulse(50, 0)
    print("  - Physics impulse: " .. (test_physics.velocity_x == 150 and "OK" or "FAILED"))

    -- Test Collision component
    local test_collision = Collision.new(16, 16, Collision.SHAPE.AABB)
    print("  - Collision created (AABB " .. test_collision.width .. "x" .. test_collision.height .. "): OK")
    test_collision:setLayer(Collision.LAYER.PLAYER)
    test_collision:setMask(Collision.LAYER.TERRAIN)
    print("  - Collision layer/mask: " .. (test_collision:collidesWithLayer(Collision.LAYER.TERRAIN) and "OK" or "FAILED"))

    -- Test integrated entity with all components
    print("\n  Testing integrated entity:")
    local player_entity = Entity.new("player")
    player_entity:addComponent("transform", Transform.new(160, 90))
    player_entity:addComponent("physics", Physics.new())
    player_entity:addComponent("collision", Collision.new(Constants.PLAYER_WIDTH, Constants.PLAYER_HEIGHT))
    print("  - Entity with all components: " .. (player_entity:hasComponent("transform") and player_entity:hasComponent("physics") and player_entity:hasComponent("collision") and "OK" or "FAILED"))

    print("\nCore Components: OK")

    -- Create player
    print("\nCreating player:")
    player = Player.new(160, 90)
    print("  - Player created at (" .. player.transform.x .. ", " .. player.transform.y .. ")")
    print("  - Player hitbox: " .. player.collision.width .. "x" .. player.collision.height .. " pixels")
    print("  - Run speed: " .. Constants.RUN_SPEED .. " px/s")
    print("  - Acceleration: " .. Constants.ACCELERATION .. " px/s²")
    print("\nPlayer: OK")
    print("\n=== Use arrow keys or WASD to move ===")
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

        -- Update player
        if player then
            player:update(Time.FIXED_DT)
        end
    end
end

function love.draw()
    -- Draw to game canvas
    love.graphics.setCanvas(game_canvas)
    love.graphics.clear()

    -- Draw game content here
    love.graphics.setColor(0.2, 0.2, 0.3)  -- Dark blue-purple background
    love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    -- Draw ground (placeholder)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("fill", 0, 140, VIRTUAL_WIDTH, VIRTUAL_HEIGHT - 140)

    -- Draw player
    if player then
        player:draw()
    end

    -- Draw UI overlay
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Courier Cat", 10, 10)
    love.graphics.print("LOVE " .. love.getVersion(), 10, 30)
    love.graphics.print("Press ESC to quit", 10, 50)

    -- Debug: Display time and player info
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Fixed timestep: " .. Time.FIXED_DT .. "s (" .. Time:getFPS() .. " FPS)", 10, 80)
    love.graphics.print("Frame: " .. Time.frame, 10, 95)
    love.graphics.print("Total time: " .. string.format("%.2f", Time.total) .. "s", 10, 110)
    love.graphics.print("Actual FPS: " .. love.timer.getFPS(), 10, 125)

    -- Player debug info
    if player then
        love.graphics.print(string.format("Player pos: (%.1f, %.1f)", player.transform.x, player.transform.y), 10, 145)
        love.graphics.print(string.format("Player vel: (%.1f, %.1f)", player.physics.velocity_x, player.physics.velocity_y), 10, 160)
        love.graphics.print("Grounded: " .. (player.grounded and "YES" or "NO"), 10, 175)
    end

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
