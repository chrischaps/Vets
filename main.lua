-- main.lua
-- Entry point for Courier Cat
-- Refactored to use StateManager for proper game flow

-- Build tools (can be triggered via command-line args or by setting these flags)
-- Usage: lovec . --tmx-to-json    (converts TMX to JSON for runtime)
--        lovec . --json-to-tmx    (converts JSON to TMX for editing)
-- Or manually set these to true and run normally:
local TMX_TO_JSON = false
local JSON_TO_TMX = false

-- Parse command-line arguments
if arg then
    for i = 1, #arg do
        if arg[i] == "--tmx-to-json" or arg[i] == "--convert" then
            TMX_TO_JSON = true
            print("[CMD] Running TMX → JSON converter from command line")
        elseif arg[i] == "--json-to-tmx" or arg[i] == "--migrate" then
            JSON_TO_TMX = true
            print("[CMD] Running JSON → TMX converter from command line")
        end
    end
end

-- Load external libraries
local libs = require("libraries.init")

-- Load core systems
local Time = require("src.core.time")
local Audio = require("src.systems.audio")  -- VETS-49
local SaveSystem = require("src.systems.save_system")  -- VETS-55
local Tilemap = require("src.systems.tilemap")  -- For Wang tileset debug toggle

-- Load StateManager and states
local StateManager = require("src.systems.state_manager")
local MenuState = require("src.states.menu_state")
local NightSelectState = require("src.states.night_select_state")  -- VETS-57
local GameState = require("src.states.game_state")
local ResultsState = require("src.states.results_state")
local PauseState = require("src.states.pause_state")  -- VETS-47

-- Virtual resolution for pixel-perfect rendering
VIRTUAL_WIDTH = 320
VIRTUAL_HEIGHT = 180

-- Global debug flag - toggle with F3
DEBUG_DRAW = false

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

    -- Run batch build tools if enabled (must be after libraries loaded in main scope)
    if TMX_TO_JSON then
        require("batch_convert_to_json")
        love.timer.sleep(2)  -- Pause to read output
        love.event.quit(0)
        return
    end

    if JSON_TO_TMX then
        require("batch_convert_to_tmx")
        love.timer.sleep(2)  -- Pause to read output
        love.event.quit(0)
        return
    end

    -- Continue with normal game initialization
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
    print("  - sti (v" .. (libs.sti and libs.sti._VERSION or "unknown") .. "): " .. (libs.sti and "OK" or "FAILED"))

    -- Initialize time system
    Time:init()
    print("\nTime system initialized:")
    print("  - Fixed timestep: " .. Time.FIXED_DT .. "s (" .. Time:getFPS() .. " FPS)")

    -- Initialize save system (VETS-55)
    print("\nInitializing SaveSystem...")
    SaveSystem.init()

    -- Initialize StateManager
    print("\nInitializing StateManager...")
    state_manager = StateManager.new()

    -- Register states
    state_manager:register("menu", MenuState)
    state_manager:register("night_select", NightSelectState)  -- VETS-57
    state_manager:register("game", GameState)
    state_manager:register("results", ResultsState)
    state_manager:register("pause", PauseState)  -- VETS-47

    -- Load audio files (VETS-49)
    print("\nLoading audio...")
    Audio:load_music("gameplay_music1", "assets/audio/music/music1.ogg")
    Audio:load_music("gameplay_music2", "assets/audio/music/music2.ogg")

    -- Load SFX (placeholder for future use)
    Audio:load_sfx("jump", "assets/audio/sfx/jump2.ogg")
    Audio:load_sfx("dash1", "assets/audio/sfx/dash1.ogg")
    Audio:load_sfx("dash2", "assets/audio/sfx/dash2.ogg")
    Audio:load_sfx("delivery1", "assets/audio/sfx/delivery1.ogg")
    Audio:load_sfx("delivery2", "assets/audio/sfx/delivery2.ogg")
    Audio:load_sfx("failure_sting", "assets/audio/sfx/failure_sting.ogg")  -- VETS-62
    Audio:load_sfx("success_jingle", "assets/audio/sfx/success_jingle.ogg")  -- VETS-61
    Audio:load_sfx("foot1", "assets/audio/sfx/foot1.ogg")  -- Footstep sound 1
    Audio:load_sfx("foot2", "assets/audio/sfx/foot2.ogg")  -- Footstep sound 2
    print("Audio loaded successfully")

    -- Start with MenuState (VETS-58)
    print("\nStarting game...")
    state_manager:switch("menu", "Welcome to Courier Cat!", state_manager)

    print("\n=== Game started! Navigate menu with arrow keys or gamepad ===")
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
    -- Update audio system (for fades) (VETS-49)
    Audio:update(dt)

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
    -- Draw to game canvas (low resolution game world)
    love.graphics.setCanvas(game_canvas)
    love.graphics.clear()

    -- Delegate to StateManager for game world rendering
    if state_manager then
        state_manager:draw()
    end

    -- Draw to screen with letterboxing
    love.graphics.setCanvas()

    -- Draw background UI elements (moon + skyline) at native resolution BEFORE game canvas
    -- This makes them appear behind the game world
    if state_manager then
        local current_state = state_manager:current()
        if current_state and current_state.drawBackgroundUI then
            current_state:drawBackgroundUI()
        end
    end

    -- Draw game canvas on top of background UI
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        game_canvas,
        offset_x, offset_y,
        0,
        game_scale, game_scale
    )

    -- Draw foreground UI at native window resolution (high resolution, sharp text)
    if state_manager then
        local current_state = state_manager:current()
        if current_state and current_state.drawUI then
            current_state:drawUI()
        end
    end
end

function love.keypressed(key)
    -- Handle global keypresses
    if key == "escape" then
        love.event.quit()
    elseif key == "f3" then
        -- Toggle debug visualization
        DEBUG_DRAW = not DEBUG_DRAW
        print("[DEBUG] Debug drawing: " .. (DEBUG_DRAW and "ON" or "OFF"))
    elseif key == "d" then
        -- Toggle Wang tileset debug labels
        Tilemap.debug_wang_tiles = not Tilemap.debug_wang_tiles
        print("[DEBUG] Wang tileset labels: " .. (Tilemap.debug_wang_tiles and "ON" or "OFF"))
    elseif key == "f11" then
        -- Run JSON to TMX converter test (VETS-72)
        print("\n[F11] Running JSON to TMX converter test...")
        require("test_json_to_tmx")
    elseif key == "f12" then
        -- Run TMX to JSON converter test (VETS-72)
        print("\n[F12] Running TMX to JSON converter test...")
        require("test_tmx_converter")
    end

    -- State-specific input is now handled internally by each state using the Input system
    -- Menu state: Confirmation handled by MenuState
    -- Results state: Confirmation handled by ResultsState
end

function love.gamepadpressed(joystick, button)
    -- Gamepad input for results state is now handled internally by ResultsState using Input system
    -- This handler can be used for other states as needed
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

function love.quit()
    -- Cleanup audio on exit (VETS-49)
    Audio:cleanup()
    print("Audio cleaned up")
end
