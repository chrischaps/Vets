-- HUD/UI Framework for Courier Cat
-- Provides base UI element system with positioning, z-indexing, and rendering

local HUD = {}

-- Anchor positions for UI elements
HUD.ANCHOR = {
    TOP_LEFT = "top_left",
    TOP_CENTER = "top_center",
    TOP_RIGHT = "top_right",
    CENTER_LEFT = "center_left",
    CENTER = "center",
    CENTER_RIGHT = "center_right",
    BOTTOM_LEFT = "bottom_left",
    BOTTOM_CENTER = "bottom_center",
    BOTTOM_RIGHT = "bottom_right"
}

-- Position modes
HUD.POSITION_MODE = {
    ABSOLUTE = "absolute",  -- Fixed pixel positions
    RELATIVE = "relative"   -- Percentage of screen (0.0-1.0)
}

-- UIElement base class
local UIElement = {}
UIElement.__index = UIElement

function UIElement:new(options)
    local element = {
        x = options.x or 0,
        y = options.y or 0,
        z_index = options.z_index or 0,
        visible = options.visible ~= false,  -- Default to visible
        position_mode = options.position_mode or HUD.POSITION_MODE.ABSOLUTE,
        anchor = options.anchor or HUD.ANCHOR.TOP_LEFT,
        data = options.data or {}  -- Custom data storage for element
    }
    setmetatable(element, self)
    return element
end

-- Get the actual screen position based on position mode and anchor
function UIElement:getScreenPosition()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local finalX, finalY = self.x, self.y

    -- Convert relative to absolute
    if self.position_mode == HUD.POSITION_MODE.RELATIVE then
        finalX = self.x * screenWidth
        finalY = self.y * screenHeight
    end

    -- Apply anchor offset
    if self.anchor == HUD.ANCHOR.TOP_CENTER then
        finalX = screenWidth / 2 + finalX
    elseif self.anchor == HUD.ANCHOR.TOP_RIGHT then
        finalX = screenWidth - finalX
    elseif self.anchor == HUD.ANCHOR.CENTER_LEFT then
        finalY = screenHeight / 2 + finalY
    elseif self.anchor == HUD.ANCHOR.CENTER then
        finalX = screenWidth / 2 + finalX
        finalY = screenHeight / 2 + finalY
    elseif self.anchor == HUD.ANCHOR.CENTER_RIGHT then
        finalX = screenWidth - finalX
        finalY = screenHeight / 2 + finalY
    elseif self.anchor == HUD.ANCHOR.BOTTOM_LEFT then
        finalY = screenHeight - finalY
    elseif self.anchor == HUD.ANCHOR.BOTTOM_CENTER then
        finalX = screenWidth / 2 + finalX
        finalY = screenHeight - finalY
    elseif self.anchor == HUD.ANCHOR.BOTTOM_RIGHT then
        finalX = screenWidth - finalX
        finalY = screenHeight - finalY
    end
    -- TOP_LEFT is default, no offset needed

    return finalX, finalY
end

function UIElement:update(dt)
    -- Override in subclasses
end

function UIElement:draw()
    -- Override in subclasses
end

-- Text UI Element (helper for rendering text)
local TextElement = setmetatable({}, {__index = UIElement})
TextElement.__index = TextElement

function TextElement:new(options)
    local element = UIElement.new(self, options)
    element.text = options.text or ""
    element.font = options.font or love.graphics.getFont()
    element.color = options.color or {1, 1, 1, 1}  -- White by default
    element.align = options.align or "left"  -- left, center, right
    element.scale = options.scale or 1.0
    return element
end

function TextElement:draw()
    if not self.visible then return end

    local x, y = self:getScreenPosition()

    -- Save current color and font
    local r, g, b, a = love.graphics.getColor()
    local currentFont = love.graphics.getFont()

    -- Set element color and font
    love.graphics.setColor(self.color)
    love.graphics.setFont(self.font)

    -- Calculate text width for alignment
    local textWidth = self.font:getWidth(self.text) * self.scale
    if self.align == "center" then
        x = x - textWidth / 2
    elseif self.align == "right" then
        x = x - textWidth
    end

    -- Draw text with scaling
    love.graphics.print(self.text, x, y, 0, self.scale, self.scale)

    -- Restore color and font
    love.graphics.setColor(r, g, b, a)
    love.graphics.setFont(currentFont)
end

function TextElement:setText(text)
    self.text = text
end

function TextElement:setColor(r, g, b, a)
    self.color = {r, g, b, a or 1}
end

-- HUD Manager
local HUDManager = {
    elements = {},
    visible = true,
    scale = 1.0
}

function HUDManager:new()
    local hud = {
        elements = {},
        visible = true,
        scale = 1.0
    }
    setmetatable(hud, {__index = self})
    return hud
end

-- Add an element to the HUD
function HUDManager:addElement(element)
    table.insert(self.elements, element)
    -- Sort by z-index after adding
    self:sortElements()
end

-- Remove an element from the HUD
function HUDManager:removeElement(element)
    for i, elem in ipairs(self.elements) do
        if elem == element then
            table.remove(self.elements, i)
            return true
        end
    end
    return false
end

-- Clear all elements
function HUDManager:clear()
    self.elements = {}
end

-- Sort elements by z-index (lower z-index renders first/behind)
function HUDManager:sortElements()
    table.sort(self.elements, function(a, b)
        return a.z_index < b.z_index
    end)
end

-- Update all elements
function HUDManager:update(dt)
    if not self.visible then return end

    for _, element in ipairs(self.elements) do
        if element.visible then
            element:update(dt)
        end
    end
end

-- Draw all elements in z-index order
function HUDManager:draw()
    if not self.visible then return end

    -- Save graphics state
    love.graphics.push()
    love.graphics.scale(self.scale, self.scale)

    -- Draw elements in order (sorted by z-index)
    for _, element in ipairs(self.elements) do
        if element.visible then
            element:draw()
        end
    end

    -- Restore graphics state
    love.graphics.pop()
end

-- Toggle HUD visibility
function HUDManager:toggle()
    self.visible = not self.visible
end

function HUDManager:setVisible(visible)
    self.visible = visible
end

function HUDManager:setScale(scale)
    self.scale = scale
end

-- Get element count
function HUDManager:getElementCount()
    return #self.elements
end

-- Helper function to create a text element
function HUD.createTextElement(text, x, y, options)
    options = options or {}
    options.text = text
    options.x = x
    options.y = y
    return TextElement:new(options)
end

-- Helper function to create a custom UI element
function HUD.createUIElement(options)
    return UIElement:new(options)
end

-- Helper function to create a new HUD manager
function HUD.new()
    return HUDManager:new()
end

-- Export classes for extension
HUD.UIElement = UIElement
HUD.TextElement = TextElement
HUD.HUDManager = HUDManager

return HUD
