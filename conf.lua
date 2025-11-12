-- conf.lua
-- LÖVE configuration file for Courier Cat

function love.conf(t)
    -- Game identity and version
    t.identity = "courier-cat"
    t.version = "11.4"
    t.console = false  -- Set to true for debugging

    -- Window configuration
    t.window.title = "Courier Cat"
    t.window.icon = nil  -- Will add icon later
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.vsync = 1  -- Enable vsync for 60 FPS
    t.window.msaa = 0   -- No anti-aliasing (pixel art)
    t.window.minwidth = 640
    t.window.minheight = 360

    -- Module configuration
    t.modules.joystick = true
    t.modules.physics = false  -- Not using love.physics (custom implementation)
    t.modules.touch = false
    t.modules.video = false
end
