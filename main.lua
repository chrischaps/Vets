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
local Platform = require("src.entities.platform")
local DeliveryZone = require("src.entities.delivery_zone")

-- Load systems
local CollisionSystem = require("src.systems.collision_system")
local CameraSystem = require("src.systems.camera")
local Input = require("src.systems.input")

-- Virtual resolution for pixel-perfect rendering
VIRTUAL_WIDTH = 320
VIRTUAL_HEIGHT = 180

-- Test entity for verification
local test_entity = nil

-- Game entities
local player = nil
local platforms = {}
local delivery_zones = {}

-- Game systems
local collision_system = nil
local camera = nil
local input = nil

-- Game canvas for rendering
local game_canvas = nil
local game_scale = 1
local offset_x = 0
local offset_y = 0

-- Debug display toggle (F4)
local show_debug_text = false

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

    -- Initialize input system
    print("\nInitializing Input System:")
    input = Input.new()
    input:init()
    print("  - Input system: OK")

    -- Initialize collision system
    print("\nInitializing Collision System:")
    collision_system = CollisionSystem.new(16)
    print("  - Collision system created with 16px cell size: OK")

    -- Create comprehensive test level with platforms (VETS-9 + VETS-10)
    print("\nCreating test level:")

    -- Ground level platform (160px wide as specified in VETS-10)
    local ground = Platform.new(10, 150, 160, 30)
    table.insert(platforms, ground)
    collision_system:add(ground, 10, 150, 160, 30)
    print("  - Ground platform: 160x30 at (10, 150)")

    -- Elevated platforms with varying gaps (32px, 48px, 64px)
    -- Platform 1: Starting platform
    local p1 = Platform.new(40, 120, 50, 8)
    table.insert(platforms, p1)
    collision_system:add(p1, 40, 120, 50, 8)
    print("  - Platform 1: 50x8 at (40, 120) - Start")

    -- Platform 2: 32px gap from Platform 1
    local p2 = Platform.new(122, 110, 45, 8)  -- 90 + 32 = 122
    table.insert(platforms, p2)
    collision_system:add(p2, 122, 110, 45, 8)
    print("  - Platform 2: 45x8 at (122, 110) - 32px gap")

    -- Platform 3: 48px gap from Platform 2
    local p3 = Platform.new(215, 95, 40, 8)  -- 167 + 48 = 215
    table.insert(platforms, p3)
    collision_system:add(p3, 215, 95, 40, 8)
    print("  - Platform 3: 40x8 at (215, 95) - 48px gap")

    -- Platform 4: 64px gap from Platform 3 (challenging jump)
    local p4 = Platform.new(40, 70, 50, 8)  -- Back to left side, 64px gap
    table.insert(platforms, p4)
    collision_system:add(p4, 40, 70, 50, 8)
    print("  - Platform 4: 50x8 at (40, 70) - 64px gap")

    -- Vertical section with walls for testing (VETS-10 spec)
    -- Left wall
    local wall_left = Platform.new(5, 30, 8, 90)
    table.insert(platforms, wall_left)
    collision_system:add(wall_left, 5, 30, 8, 90)
    print("  - Left wall: 8x90 at (5, 30)")

    -- Right wall (for wall mechanics testing in later phases)
    local wall_right = Platform.new(307, 30, 8, 90)
    table.insert(platforms, wall_right)
    collision_system:add(wall_right, 307, 30, 8, 90)
    print("  - Right wall: 8x90 at (307, 30)")

    -- Small platforms in vertical section
    local p5 = Platform.new(120, 50, 45, 8)
    table.insert(platforms, p5)
    collision_system:add(p5, 120, 50, 45, 8)
    print("  - Platform 5: 45x8 at (120, 50)")

    local p6 = Platform.new(180, 35, 40, 8)
    table.insert(platforms, p6)
    collision_system:add(p6, 180, 35, 40, 8)
    print("  - Platform 6: 40x8 at (180, 35)")

    print("  - Total platforms/walls: " .. #platforms)

    -- Create player
    print("\nCreating player:")
    player = Player.new(160, 100, collision_system, input)

    -- Add player to collision system
    local px = player.transform.x - player.collision.width / 2
    local py = player.transform.y - player.collision.height / 2
    collision_system:add(player, px, py, player.collision.width, player.collision.height)

    print("  - Player created at (" .. player.transform.x .. ", " .. player.transform.y .. ")")
    print("  - Player hitbox: " .. player.collision.width .. "x" .. player.collision.height .. " pixels")
    print("  - Run speed: " .. Constants.RUN_SPEED .. " px/s")
    print("  - Acceleration: " .. Constants.ACCELERATION .. " px/s²")
    print("  - Jump force: " .. Constants.JUMP_FORCE .. " px/s")
    print("\nPlayer: OK")

    -- Create delivery zones for testing (VETS-23)
    print("\nCreating delivery zones:")
    local zone1 = DeliveryZone.new(100, 145, collision_system)
    table.insert(delivery_zones, zone1)
    print("  - Zone 1 created at (100, 145)")

    local zone2 = DeliveryZone.new(200, 90, collision_system)
    table.insert(delivery_zones, zone2)
    print("  - Zone 2 created at (200, 90)")

    local zone3 = DeliveryZone.new(150, 45, collision_system)
    table.insert(delivery_zones, zone3)
    print("  - Zone 3 created at (150, 45)")

    print("  - Total delivery zones: " .. #delivery_zones)
    print("\nDelivery Zones: OK")

    -- Connect player to delivery zones (VETS-24)
    player.delivery_zones = delivery_zones
    print("  - Player connected to delivery zones")

    -- Initialize camera system
    print("\nInitializing Camera System:")
    -- Start camera at player position to avoid initial offset
    camera = CameraSystem.new(player.transform.x, player.transform.y)
    camera:setTarget(player)
    camera:setSmoothing(0.1)
    print("  - Camera created and targeting player")
    print("  - Camera smoothing: 0.1 (smooth following)")
    print("  - Camera initial position: (" .. player.transform.x .. ", " .. player.transform.y .. ")")
    print("  - Player position: (" .. player.transform.x .. ", " .. player.transform.y .. ")")
    print("\nCamera System: OK")

    print("\n=== Use arrow keys/WASD to move, Space to jump ===")
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
    -- Update input state once per frame (before fixed timestep loop)
    if input then
        input:update()
    end

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

        -- Update delivery zones (pass player position for proximity detection)
        if player then
            for _, zone in ipairs(delivery_zones) do
                zone:update(Time.FIXED_DT, player.transform.x, player.transform.y)
            end
        end

        -- Update camera (smooth following)
        if camera then
            camera:update(Time.FIXED_DT)

            -- Apply player screen shake to camera
            if player then
                local shake_x, shake_y = player:getScreenShakeOffset()
                camera.shake_x = shake_x
                camera.shake_y = shake_y
            end
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

    -- Apply camera transform (pass virtual resolution for correct centering)
    if camera then
        camera:attach(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    end

    -- Draw platforms
    for _, platform in ipairs(platforms) do
        platform:draw()
    end

    -- Draw delivery zones
    for _, zone in ipairs(delivery_zones) do
        zone:draw()
    end

    -- Draw player
    if player then
        player:draw()
    end

    -- Debug: Draw collision boundaries
    if collision_system and love.keyboard.isDown("f1") then
        collision_system:debugDraw()
    end

    -- Detach camera (UI elements drawn after this won't move with camera)
    if camera then
        camera:detach()
    end

    -- Draw UI overlay (toggle with F4)
    if show_debug_text then
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
            love.graphics.print("Grounded: " .. (player.grounded and "YES" or "NO") .. " | Jumping: " .. (player.jumping and "YES" or "NO"), 10, 175)
        end

        -- Camera debug info
        if camera then
            local cam_x, cam_y = camera:getPosition()
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(string.format("Camera pos: (%.1f, %.1f)", cam_x, cam_y), 200, 145)
        end

        -- Debug help
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("F1: Collision debug | F2: Camera debug | F3: Input debug | F4: Toggle text", 200, 10)
    end

    -- Input debug info (F3)
    if input and love.keyboard.isDown("f3") then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("=== INPUT DEBUG ===", 10, 200)
        local y_offset = 215
        local actions = input:get_actions()
        for i, action in ipairs(actions) do
            local state = input:is_down(action)
            local pressed = input:is_pressed(action)
            local released = input:is_released(action)
            local color = state and {0, 1, 0} or {0.5, 0.5, 0.5}
            love.graphics.setColor(color)
            local status = state and "DOWN" or "UP"
            if pressed then status = status .. " (PRESSED)" end
            if released then status = status .. " (RELEASED)" end
            love.graphics.print(action .. ": " .. status, 10, y_offset)
            y_offset = y_offset + 12
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Horizontal axis: " .. input:get_horizontal_axis(), 10, y_offset + 5)
    end

    -- Draw crosshair at camera center (world space)
    if camera and love.keyboard.isDown("f2") then
        camera:attach(0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
        love.graphics.setColor(1, 0, 0)
        local cam_x, cam_y = camera:getPosition()
        love.graphics.line(cam_x - 10, cam_y, cam_x + 10, cam_y)
        love.graphics.line(cam_x, cam_y - 10, cam_x, cam_y + 10)
        camera:detach()
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
    elseif key == "f4" then
        show_debug_text = not show_debug_text
    end
end

function love.joystickadded(joystick)
    if input then
        input:joystick_added(joystick)
    end
end

function love.joystickremoved(joystick)
    if input then
        input:joystick_removed(joystick)
    end
end
