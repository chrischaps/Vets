-- Level System
-- Instantiates game entities from JSON level data
-- VETS-35: Create level loading system

local LevelLoader = require("src.systems.level_loader")
local Tilemap = require("src.systems.tilemap")
local Platform = require("src.entities.platform")
local Wall = require("src.entities.wall")
local DeliveryZone = require("src.entities.delivery_zone")

-- Hazard classes
local SteamVent = require("src.entities.hazards.steam_vent")
local LaundryLine = require("src.entities.hazards.laundry_line")

-- Powerup classes
local Coffee = require("src.entities.powerups.coffee")

-- Prop class
local Prop = require("src.entities.prop")

local Level = {}

-- Load a level by night number and instantiate all entities
-- @param night_number (number): The night number to load (1, 2, 3, etc.)
-- @param collision_system (CollisionSystem): The collision system to register entities with
-- @return level_instance (table): Table containing all instantiated entities and level data
-- @return error (string|nil): Error message if loading failed
function Level.load(night_number, collision_system)
    -- Validate parameters
    if not night_number or type(night_number) ~= "number" then
        return nil, "night_number must be a number"
    end

    if not collision_system then
        return nil, "collision_system is required"
    end

    -- Load level data from JSON
    local level_data, err = LevelLoader.loadNight(night_number)
    if not level_data then
        return nil, string.format("Failed to load level data: %s", err)
    end

    -- Load rooftop tileset for platforms and walls
    local rooftop_tileset, tileset_err = Tilemap.load("assets/graphics/tilesets/rooftop")
    if not rooftop_tileset then
        print(string.format("[Level] Warning: Failed to load rooftop tileset: %s", tileset_err))
        print("[Level] Platforms and walls will use fallback rendering")
    else
        print("[Level] Rooftop tileset loaded successfully")
    end

    -- Create level instance
    local level_instance = {
        night = level_data.night,
        name = level_data.name,
        description = level_data.description,
        spawn = level_data.spawn,
        metadata = level_data.metadata,
        camera = level_data.camera,
        environment = level_data.environment,
        background_layers = level_data.background_layers,

        -- Entity arrays (will be populated below)
        platforms = {},
        walls = {},
        delivery_zones = {},
        hazards = {},
        powerups = {},
        props = {},

        -- Reference to collision system for cleanup
        collision_system = collision_system
    }

    -- Instantiate platforms
    print(string.format("Loading %d platform(s)...", #level_data.platforms))
    for i, platform_data in ipairs(level_data.platforms) do
        local platform = Platform.new(
            platform_data.x,
            platform_data.y,
            platform_data.width,
            platform_data.height,
            rooftop_tileset  -- Pass tileset for rendering
        )

        -- Store platform type and properties
        platform.platform_type = platform_data.type
        platform.properties = platform_data.properties

        -- Add to collision system
        collision_system:add(
            platform,
            platform_data.x,
            platform_data.y,
            platform_data.width,
            platform_data.height
        )

        table.insert(level_instance.platforms, platform)
    end

    -- Instantiate walls
    if #level_data.walls > 0 then
        print(string.format("Loading %d wall(s)...", #level_data.walls))
        for i, wall_data in ipairs(level_data.walls) do
            local wall = Wall.new(
                wall_data.x,
                wall_data.y,
                wall_data.width,
                wall_data.height,
                rooftop_tileset  -- Pass tileset for rendering
            )

            -- Store wall type and properties from JSON
            wall.wall_type = wall_data.type or "building_wall"
            if wall_data.properties then
                wall.properties = wall_data.properties
            end

            -- Add to collision system
            collision_system:add(
                wall,
                wall_data.x,
                wall_data.y,
                wall_data.width,
                wall_data.height
            )

            table.insert(level_instance.walls, wall)
        end
    end

    -- Instantiate delivery zones
    print(string.format("Loading %d delivery zone(s)...", #level_data.delivery_zones))
    for i, zone_data in ipairs(level_data.delivery_zones) do
        local zone = DeliveryZone.new(
            zone_data.x,
            zone_data.y,
            collision_system
        )

        -- Store zone properties
        zone.id = zone_data.id
        zone.zone_type = zone_data.type
        zone.letter_fragment_id = zone_data.letter_fragment_id
        zone.properties = zone_data.properties
        zone.width = zone_data.width or 16
        zone.height = zone_data.height or 24

        table.insert(level_instance.delivery_zones, zone)
    end

    -- Instantiate hazards
    if #level_data.hazards > 0 then
        print(string.format("Loading %d hazard(s)...", #level_data.hazards))
        for i, hazard_data in ipairs(level_data.hazards) do
            local hazard = nil

            if hazard_data.type == "steam_vent" then
                hazard = SteamVent.new(hazard_data.x, hazard_data.y)
                hazard.type = "steam_vent"
            elseif hazard_data.type == "laundry_line" then
                hazard = LaundryLine.new(hazard_data.x, hazard_data.y, hazard_data.width)
                hazard.type = "laundry_line"
            else
                print(string.format("Warning: Unknown hazard type '%s' at (%d, %d)",
                    hazard_data.type, hazard_data.x, hazard_data.y))
            end

            if hazard then
                table.insert(level_instance.hazards, hazard)
            end
        end
    end

    -- Instantiate powerups
    if #level_data.powerups > 0 then
        print(string.format("Loading %d powerup(s)...", #level_data.powerups))
        for i, powerup_data in ipairs(level_data.powerups) do
            local powerup = nil

            if powerup_data.type == "coffee" then
                powerup = Coffee.new(powerup_data.x, powerup_data.y, powerup_data.respawn)
            else
                print(string.format("Warning: Unknown powerup type '%s' at (%d, %d)",
                    powerup_data.type, powerup_data.x, powerup_data.y))
            end

            if powerup then
                table.insert(level_instance.powerups, powerup)
            end
        end
    end

    -- Instantiate props
    if #level_data.props > 0 then
        print(string.format("Loading %d prop(s)...", #level_data.props))
        for i, prop_data in ipairs(level_data.props) do
            local success, prop = pcall(Prop.new, prop_data.x, prop_data.y, prop_data.prop_type, prop_data.properties)

            if success and prop then
                table.insert(level_instance.props, prop)
            else
                print(string.format("Warning: Failed to create prop '%s' at (%d, %d): %s",
                    prop_data.prop_type, prop_data.x, prop_data.y, tostring(prop)))
            end
        end
    end

    print(string.format("Level '%s' (Night %d) loaded successfully!", level_instance.name, level_instance.night))

    return level_instance, nil
end

-- Unload a level and clean up all entities
-- @param level_instance (table): The level instance to unload
function Level.unload(level_instance)
    if not level_instance then
        return
    end

    print(string.format("Unloading level '%s' (Night %d)...", level_instance.name or "Unknown", level_instance.night or 0))

    local collision_system = level_instance.collision_system

    -- Remove platforms from collision system
    if level_instance.platforms then
        for i, platform in ipairs(level_instance.platforms) do
            if collision_system and collision_system:hasEntity(platform) then
                collision_system:remove(platform)
            end
        end
        level_instance.platforms = {}
    end

    -- Remove walls from collision system (when implemented)
    if level_instance.walls then
        for i, wall in ipairs(level_instance.walls) do
            if collision_system and collision_system:hasEntity(wall) then
                collision_system:remove(wall)
            end
        end
        level_instance.walls = {}
    end

    -- Clean up delivery zones (they manage their own collision detection)
    if level_instance.delivery_zones then
        level_instance.delivery_zones = {}
    end

    -- Clean up hazards (when implemented)
    if level_instance.hazards then
        level_instance.hazards = {}
    end

    -- Clean up powerups (when implemented)
    if level_instance.powerups then
        level_instance.powerups = {}
    end

    -- Clean up props
    if level_instance.props then
        for i, prop in ipairs(level_instance.props) do
            if prop.destroy then
                prop:destroy()
            end
        end
        level_instance.props = {}
    end

    print("Level unloaded successfully")
end

-- Get the spawn point for a level
-- @param level_instance (table): The level instance
-- @return spawn (table): Table with x and y coordinates
function Level.get_spawn_point(level_instance)
    if not level_instance or not level_instance.spawn then
        return {x = 0, y = 0}
    end

    return {
        x = level_instance.spawn.x,
        y = level_instance.spawn.y
    }
end

return Level
