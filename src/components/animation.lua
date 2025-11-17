-- animation.lua
-- Animation component for sprite-based entity animations using anim8 library
--
-- This component wraps the anim8 library to provide a simple interface for
-- defining, playing, and managing sprite animations.

local Animation = {}
Animation.__index = Animation

-- Load anim8 library
local anim8 = require("libraries.anim8")

-- Create a new Animation component
-- @param sprite_sheet: LÖVE Image object containing the sprite sheet
-- @param frame_width: Width of each frame in pixels
-- @param frame_height: Height of each frame in pixels
function Animation.new(sprite_sheet, frame_width, frame_height)
    local self = setmetatable({}, Animation)

    -- Sprite sheet image
    self.sprite_sheet = sprite_sheet
    self.frame_width = frame_width or 16
    self.frame_height = frame_height or 16

    -- Create anim8 grid for the sprite sheet
    if sprite_sheet then
        self.grid = anim8.newGrid(
            frame_width,
            frame_height,
            sprite_sheet:getWidth(),
            sprite_sheet:getHeight()
        )
    else
        self.grid = nil
    end

    -- Animation definitions storage
    -- Format: animations[name] = {anim8_animation, loop, on_complete}
    self.animations = {}

    -- Current animation state
    self.current = nil           -- Current animation name
    self.current_anim = nil      -- Current anim8 animation object
    self.playing = false         -- Is animation currently playing
    self.loop = true             -- Default loop mode
    self.on_complete = nil       -- Current animation callback

    -- Reference to owner entity (set by Entity:addComponent)
    self.owner = nil

    return self
end

-- Define a new animation
-- @param name: Unique identifier for this animation
-- @param frames: String (e.g., "1-4" for horizontal layout) OR table of (x,y) pairs (e.g., {1,1, 2,1})
-- @param duration: Duration per frame in seconds, or table of durations
-- @param options: Table with optional settings {loop=true/false, on_complete=function}
function Animation:define(name, frames, duration, options)
    if not self.grid then
        error("Animation component has no sprite sheet grid")
    end

    options = options or {}

    -- If frames is a table, it should contain (x, y) coordinate pairs
    -- If frames is a string, assume horizontal layout on row 1
    local grid_frames
    if type(frames) == "table" then
        -- Table contains (x, y) coordinate pairs
        -- e.g., {1, 1, 2, 1, 1, 2, 2, 2} means frames at (1,1), (2,1), (1,2), (2,2)
        grid_frames = self.grid(unpack(frames))
    elseif type(frames) == "string" then
        -- String format: assume horizontal layout, parse ranges
        -- e.g., "1-4" becomes grid("1-4", 1)
        grid_frames = self.grid(frames, 1)
    else
        error("Frames must be a string or table")
    end

    -- Create the anim8 animation
    local anim = anim8.newAnimation(grid_frames, duration)

    -- Store animation with metadata
    self.animations[name] = {
        anim = anim,
        loop = options.loop ~= false,  -- Default to true unless explicitly set to false
        on_complete = options.on_complete
    }
end

-- Play an animation by name
-- @param name: Name of the animation to play
-- @param reset: If true, restart the animation even if it's already playing
function Animation:play(name, reset)
    if not self.animations[name] then
        error("Animation '" .. name .. "' not defined")
    end

    -- If already playing this animation and not resetting, do nothing
    if self.current == name and not reset then
        return
    end

    local anim_data = self.animations[name]

    -- Switch to the new animation
    self.current = name
    self.current_anim = anim_data.anim
    self.loop = anim_data.loop
    self.on_complete = anim_data.on_complete
    self.playing = true

    -- Reset the animation to the first frame
    self.current_anim:gotoFrame(1)
end

-- Stop the current animation
function Animation:stop()
    self.playing = false
end

-- Resume the current animation
function Animation:resume()
    if self.current_anim then
        self.playing = true
    end
end

-- Pause the current animation
function Animation:pause()
    self.playing = false
end

-- Reset the current animation to the first frame
function Animation:reset()
    if self.current_anim then
        self.current_anim:gotoFrame(1)
    end
end

-- Update the animation (should be called every frame)
-- @param dt: Delta time in seconds
function Animation:update(dt)
    if not self.playing or not self.current_anim then
        return
    end

    -- Store the current frame before updating
    local was_on_last_frame = false
    if self.current_anim.position == #self.current_anim.frames then
        was_on_last_frame = true
    end

    -- Update the anim8 animation
    self.current_anim:update(dt)

    -- Check if we've looped back to the first frame (animation completed)
    if was_on_last_frame and self.current_anim.position == 1 then
        -- Animation completed one cycle
        if not self.loop then
            -- For one-shot animations, stop on last frame
            self.current_anim:gotoFrame(#self.current_anim.frames)
            self.playing = false
        end

        -- Call the completion callback if it exists
        if self.on_complete then
            self.on_complete(self)
        end
    end
end

-- Draw the current animation frame
-- @param x: X position to draw at
-- @param y: Y position to draw at
-- @param r: Rotation (optional)
-- @param sx: X scale (optional)
-- @param sy: Y scale (optional)
-- @param ox: X origin offset (optional)
-- @param oy: Y origin offset (optional)
function Animation:draw(x, y, r, sx, sy, ox, oy)
    if not self.current_anim or not self.sprite_sheet then
        return
    end

    x = x or 0
    y = y or 0
    r = r or 0
    sx = sx or 1
    sy = sy or 1
    ox = ox or 0
    oy = oy or 0

    self.current_anim:draw(self.sprite_sheet, x, y, r, sx, sy, ox, oy)
end

-- Get the current frame number
function Animation:getCurrentFrame()
    if not self.current_anim then
        return 0
    end
    return self.current_anim.position
end

-- Get the current animation name
function Animation:getCurrentAnimation()
    return self.current
end

-- Check if the animation is playing
function Animation:isPlaying()
    return self.playing
end

-- Get the dimensions of a single frame
function Animation:getFrameSize()
    return self.frame_width, self.frame_height
end

-- Helper function to create a grid from a sprite sheet
-- This is a static method that can be used without creating a component
function Animation.createGrid(sprite_sheet, frame_width, frame_height)
    return anim8.newGrid(
        frame_width,
        frame_height,
        sprite_sheet:getWidth(),
        sprite_sheet:getHeight()
    )
end

return Animation
