-- Background Buildings System
-- Procedurally places non-interactable buildings in the background with parallax scrolling

local BackgroundBuildings = {}
BackgroundBuildings.__index = BackgroundBuildings

function BackgroundBuildings:new(options)
    options = options or {}

    local bg = {
        buildings = {},
        sprites = {},
        camera_x = 0,
        camera_y = 0,
        parallax_factor = options.parallax_factor or 0.4,  -- 40% of horizontal camera movement
        vertical_parallax_factor = options.vertical_parallax_factor or 0.2,  -- 20% of vertical camera movement
        opacity = options.opacity or 0.6,  -- Semi-transparent to appear distant
        scale = options.scale or 2.0,  -- 2x scale for pixel art
        ground_y = options.ground_y or 500,  -- Y position for building bottoms
        level_width = options.level_width or 5000,  -- Width of level to fill
        spacing_min = options.spacing_min or 200,  -- Minimum spacing between buildings
        spacing_max = options.spacing_max or 400,  -- Maximum spacing between buildings
        seed = options.seed or os.time()
    }

    setmetatable(bg, self)

    return bg
end

-- Load building sprites
function BackgroundBuildings:loadSprites()
    local building_files = {
        "assets/graphics/background/building_apartment_tall.png",    -- Flat brick apartment
        "assets/graphics/background/building_office_tall.png",       -- Flat office tower
        "assets/graphics/background/building_skyscraper.png",        -- Glass skyscraper
        --"assets/graphics/background/building_apartment_modern.png",  -- Modern concrete apartment
        "assets/graphics/background/building1.png",                  -- Medium retail building
        "assets/graphics/background/building2.png",                  -- Short restaurant building
        "assets/graphics/background/building3.png",                  -- Tall hotel with balconies
        --"assets/graphics/background/building4.png",                  -- Red brick warehouse
        "assets/graphics/background/building5.png",                   -- Art deco tower
        "assets/graphics/background/building6.png",                   -- Art deco tower
        "assets/graphics/background/building7.png"                   -- Art deco tower
    }

    for i, file_path in ipairs(building_files) do
        local sprite = love.graphics.newImage(file_path)
        sprite:setFilter("nearest", "nearest")  -- Pixel-perfect scaling
        table.insert(self.sprites, sprite)
    end

    print(string.format("[BackgroundBuildings] Loaded %d building sprites", #self.sprites))
end

-- Procedurally generate building positions
function BackgroundBuildings:generateBuildings()
    if #self.sprites == 0 then
        print("[BackgroundBuildings] Warning: No sprites loaded, cannot generate buildings")
        return
    end

    -- Seed the random generator for consistent placement
    math.randomseed(self.seed)

    local x = -500  -- Start slightly before the level
    local end_x = self.level_width + 500  -- Extend slightly past the level

    while x < end_x do
        -- Randomly select a building sprite
        local sprite_index = math.random(1, #self.sprites)
        local sprite = self.sprites[sprite_index]

        -- Create building data
        local building = {
            x = x,
            y = self.ground_y - (sprite:getHeight() * self.scale),  -- Bottom-aligned
            sprite = sprite,
            scale = self.scale
        }

        table.insert(self.buildings, building)

        -- Random spacing to next building
        x = x + sprite:getWidth() * self.scale + math.random(self.spacing_min, self.spacing_max)
    end

    print(string.format("[BackgroundBuildings] Generated %d buildings", #self.buildings))
end

-- Update camera position for parallax
function BackgroundBuildings:setCameraPosition(camera_x, camera_y)
    self.camera_x = camera_x or 0
    self.camera_y = camera_y or 0
end

-- Draw buildings with parallax
function BackgroundBuildings:draw()
    -- Save graphics state
    local r, g, b, a = love.graphics.getColor()

    -- Calculate parallax offsets
    local parallax_offset_x = -self.camera_x * self.parallax_factor
    local parallax_offset_y = -self.camera_y * self.vertical_parallax_factor

    -- Draw each building with opacity and parallax
    love.graphics.setColor(0.5, .8, 1, self.opacity)

    for _, building in ipairs(self.buildings) do
        -- Apply parallax to both X and Y positions
        local draw_x = building.x + parallax_offset_x
        local draw_y = building.y + parallax_offset_y

        -- Only draw if visible on screen (simple culling)
        local screen_width = love.graphics.getWidth()
        local building_width = building.sprite:getWidth() * building.scale

        if draw_x + building_width > 0 and draw_x < screen_width then
            love.graphics.draw(
                building.sprite,
                draw_x,
                draw_y,
                0,  -- rotation
                building.scale,
                building.scale
            )
        end
    end

    -- Restore graphics state
    love.graphics.setColor(r, g, b, a)
end

-- Initialize system (load sprites and generate buildings)
function BackgroundBuildings:init()
    self:loadSprites()
    self:generateBuildings()
end

return BackgroundBuildings
