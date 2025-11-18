-- Prop Entity
-- Handles rendering and logic for environmental props and decorative tiles
-- VETS-66: Create Environmental Props and Decorative Tiles

local Prop = {}
Prop.__index = Prop

-- Load prop metadata
local props_metadata = require("assets.graphics.props.props_metadata")

-- Cache for loaded prop images
local prop_images = {}

-- Load a prop image if not already cached
local function loadPropImage(prop_type)
    if prop_images[prop_type] then
        return prop_images[prop_type]
    end

    local metadata = props_metadata[prop_type]
    if not metadata then
        print(string.format("[Prop] Warning: No metadata found for prop type '%s'", prop_type))
        return nil
    end

    local image_path = "assets/graphics/props/" .. metadata.filename
    local success, image = pcall(love.graphics.newImage, image_path)

    if not success then
        print(string.format("[Prop] Error loading image for '%s': %s", prop_type, image))
        return nil
    end

    -- Cache the image
    prop_images[prop_type] = image
    print(string.format("[Prop] Loaded image for '%s'", prop_type))

    return image
end

-- Create a new prop instance
-- @param x (number): X position in world space
-- @param y (number): Y position in world space
-- @param prop_type (string): Type of prop from props_metadata (e.g., "chimney_tall")
-- @param properties (table): Optional custom properties
-- @return prop (table): New prop instance
function Prop.new(x, y, prop_type, properties)
    local self = setmetatable({}, Prop)

    self.x = x
    self.y = y
    self.prop_type = prop_type
    self.properties = properties or {}

    -- Load metadata for this prop type
    self.metadata = props_metadata[prop_type]
    if not self.metadata then
        error(string.format("[Prop] Invalid prop type: %s", prop_type))
    end

    -- Load the prop image
    self.image = loadPropImage(prop_type)
    if not self.image then
        error(string.format("[Prop] Failed to load image for prop type: %s", prop_type))
    end

    -- Get dimensions from metadata
    self.width = self.metadata.size.width
    self.height = self.metadata.size.height

    -- Calculate scale factors to fit image to metadata size
    local image_width = self.image:getWidth()
    local image_height = self.image:getHeight()
    self.scale_x = self.width / image_width
    self.scale_y = self.height / image_height

    -- Z-index for rendering order (lower = farther back)
    self.z_index = self.metadata.z_index or 10

    -- Collision and interaction properties
    self.solid = self.metadata.solid or false
    self.hazard = self.metadata.hazard or false
    self.interactive = self.metadata.interactive or false
    self.delivery_target = self.metadata.delivery_target or false

    -- Animation state (for animated props)
    self.animated = self.metadata.animated or false
    self.animation_time = 0

    -- Glow effect (for windows, etc.)
    self.glow = self.metadata.glow or false
    self.glow_pulse = 0

    return self
end

-- Update prop (for animations, effects, etc.)
function Prop:update(dt)
    if self.animated then
        self.animation_time = self.animation_time + dt
    end

    if self.glow then
        -- Pulse glow effect
        self.glow_pulse = (self.glow_pulse + dt) % (math.pi * 2)
    end
end

-- Render the prop
-- @param camera (Camera): Camera object (optional, for viewport culling)
function Prop:draw(camera)
    if not self.image then
        return
    end

    -- Apply glow effect for delivery target windows
    if self.glow then
        local alpha = 0.7 + math.sin(self.glow_pulse * 2) * 0.3
        love.graphics.setColor(1, 1, 1, alpha)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Draw the prop image with scaling to match metadata size
    -- love.graphics.draw(image, x, y, rotation, scale_x, scale_y)
    love.graphics.draw(self.image, self.x, self.y, 0, self.scale_x, self.scale_y)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Debug rendering (show collision box)
function Prop:debugDraw()
    if self.solid then
        love.graphics.setColor(0, 1, 0, 0.3)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end

    if self.hazard then
        love.graphics.setColor(1, 0, 0, 0.3)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Get bounding box for collision detection
function Prop:getBounds()
    return self.x, self.y, self.width, self.height
end

-- Check if prop should block player movement
function Prop:isSolid()
    return self.solid
end

-- Check if prop is a hazard
function Prop:isHazard()
    return self.hazard
end

-- Cleanup prop resources
function Prop:destroy()
    -- Images are cached globally, so we don't release them per-prop
    self.image = nil
end

return Prop
