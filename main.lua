-- main.lua
-- Entry point for Courier Cat

-- Virtual resolution for pixel-perfect rendering
VIRTUAL_WIDTH = 320
VIRTUAL_HEIGHT = 180

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
    -- Game update logic will go here
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
