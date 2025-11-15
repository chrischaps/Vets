-- laundry_line.lua
-- Laundry line hazard that players must jump over or dash under

local Entity = require("src.entities.entity")
local Transform = require("src.components.transform")
local Collision = require("src.components.collision")

local LaundryLine = {}
LaundryLine.__index = LaundryLine

-- Create a new laundry line
function LaundryLine.new(x, y, width)
    local self = setmetatable({}, LaundryLine)

    -- Create base entity
    self.entity = Entity.new("laundry_line")

    -- Add Transform component (center-based positioning)
    -- Y position should be 24 pixels above the platform
    self.transform = Transform.new(x, y)
    self.entity:addComponent("transform", self.transform)

    -- Store dimensions
    self.width = width or 32  -- Default width, can be 16-64 pixels
    self.height = 4  -- Thin collision box for the rope/clothes

    -- Add Collision component (trigger, non-solid)
    self.collision = Collision.new(self.width, self.height, Collision.SHAPE.AABB)
    self.collision:setLayer(Collision.LAYER.HAZARD)
    self.collision:setMask(Collision.LAYER.PLAYER)  -- Only interact with player
    self.collision:setTrigger(true)  -- Non-solid, players can pass through
    self.entity:addComponent("collision", self.collision)

    -- Stun configuration
    self.stun_duration = 0.5  -- 0.5 seconds stun when hit
    self.hit_cooldown = 1.0   -- 1.0 second cooldown after hitting player (prevents stun loop)
    self.hit_cooldown_timer = 0  -- Time remaining until can hit player again

    -- Visual configuration
    self.rope_color = {0.4, 0.35, 0.3}  -- Brown rope
    self.clothes_color = {0.8, 0.85, 0.9}  -- Light blue/white clothes

    -- Sway animation
    self.sway_time = 0  -- Time accumulator for animation
    self.sway_amplitude = 2  -- How far the line sways (pixels)
    self.sway_speed = 1.5  -- How fast the sway oscillates

    -- Clothes hanging on the line
    self.clothes = {}
    self:generateClothes()

    return self
end

-- Generate clothes hanging on the line
function LaundryLine:generateClothes()
    -- Place 2-4 clothes items evenly along the line
    local num_clothes = math.floor(self.width / 16)  -- One item per 16 pixels
    num_clothes = math.max(2, math.min(num_clothes, 4))  -- Clamp to 2-4 items

    for i = 1, num_clothes do
        -- Distribute clothes evenly along the line
        local offset_x = (i / (num_clothes + 1)) * self.width - (self.width / 2)

        -- Randomize cloth type
        local cloth_type = math.random(1, 2)  -- 1 = shirt, 2 = sheet

        table.insert(self.clothes, {
            offset_x = offset_x,
            type = cloth_type,
            width = cloth_type == 1 and 6 or 8,  -- Shirts are narrower
            height = cloth_type == 1 and 8 or 10  -- Sheets are taller
        })
    end
end

-- Update laundry line (mainly animation)
function LaundryLine:update(dt)
    -- Update sway animation
    self.sway_time = self.sway_time + dt

    -- Update hit cooldown timer
    if self.hit_cooldown_timer > 0 then
        self.hit_cooldown_timer = self.hit_cooldown_timer - dt
    end
end

-- Check if player collides with laundry line and apply stun
-- Returns true if player hit the line, false otherwise
function LaundryLine:checkPlayerContact(player_x, player_y, player_width, player_height, player_is_dashing)
    -- Calculate player bounding box
    local player_left = player_x - player_width / 2
    local player_right = player_x + player_width / 2
    local player_top = player_y - player_height / 2
    local player_bottom = player_y + player_height / 2

    -- Calculate line bounding box with current sway offset
    local sway_offset = math.sin(self.sway_time * self.sway_speed) * self.sway_amplitude
    local line_left = self.transform.x - self.width / 2 + sway_offset
    local line_right = self.transform.x + self.width / 2 + sway_offset
    local line_top = self.transform.y - self.height / 2
    local line_bottom = self.transform.y + self.height / 2

    -- Check for AABB overlap
    local overlaps = player_right > line_left and
                     player_left < line_right and
                     player_bottom > line_top and
                     player_top < line_bottom

    if not overlaps then
        return false
    end

    -- Check if cooldown is still active (prevents stun loop)
    if self.hit_cooldown_timer > 0 then
        return false  -- Still in cooldown, no hit
    end

    -- Player is overlapping the line
    -- Check if they're jumping over (player center is above line)
    if player_y < self.transform.y then
        return false  -- Successfully jumping over
    end

    -- Check if they're dashing under (dashed hitbox would be lower)
    if player_is_dashing then
        return false  -- Successfully dashing under
    end

    -- Player hit the line! Start cooldown to prevent immediate re-hit
    self.hit_cooldown_timer = self.hit_cooldown
    return true
end

-- Draw laundry line
function LaundryLine:draw()
    local x = self.transform.x
    local y = self.transform.y

    -- Calculate sway offset
    local sway_offset = math.sin(self.sway_time * self.sway_speed) * self.sway_amplitude

    -- Draw rope
    love.graphics.setColor(self.rope_color)
    love.graphics.setLineWidth(1)
    love.graphics.line(
        x - self.width/2 + sway_offset, y,
        x + self.width/2 + sway_offset, y
    )

    -- Draw clothes hanging from the rope
    for _, cloth in ipairs(self.clothes) do
        local cloth_x = x + cloth.offset_x + sway_offset
        local cloth_y = y + 2  -- Hang slightly below the rope

        -- Draw cloth with slight sway variation
        local cloth_sway = math.sin(self.sway_time * self.sway_speed + cloth.offset_x * 0.1) * 1

        love.graphics.setColor(self.clothes_color)
        love.graphics.rectangle(
            "fill",
            cloth_x - cloth.width/2 + cloth_sway,
            cloth_y,
            cloth.width,
            cloth.height
        )

        -- Draw simple cloth details
        if cloth.type == 1 then
            -- Shirt - add simple collar/sleeves
            love.graphics.setColor(0.6, 0.65, 0.7)
            love.graphics.rectangle(
                "fill",
                cloth_x - cloth.width/2 + cloth_sway,
                cloth_y,
                cloth.width,
                2
            )
        else
            -- Sheet - add simple fold lines
            love.graphics.setColor(0.7, 0.75, 0.8)
            for i = 1, 2 do
                local fold_y = cloth_y + i * 3
                love.graphics.line(
                    cloth_x - cloth.width/2 + cloth_sway,
                    fold_y,
                    cloth_x + cloth.width/2 + cloth_sway,
                    fold_y
                )
            end
        end

        -- Add clothespin at top
        love.graphics.setColor(0.6, 0.5, 0.3)
        love.graphics.rectangle(
            "fill",
            cloth_x - 1 + sway_offset,
            y - 1,
            2,
            3
        )
    end

    -- Debug: Draw collision box (if F2 is held)
    if love.keyboard.isDown("f2") then
        love.graphics.setColor(1, 1, 0, 0.3)
        love.graphics.rectangle(
            "line",
            x - self.width/2 + sway_offset,
            y - self.height/2,
            self.width,
            self.height
        )

        -- Draw info text
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(
            string.format("Laundry Line (w=%d)", self.width),
            x - self.width/2,
            y - 15
        )
    end
end

-- Get entity
function LaundryLine:getEntity()
    return self.entity
end

-- Destroy laundry line
function LaundryLine:destroy()
    self.clothes = {}
    self.entity:destroy()
end

return LaundryLine
