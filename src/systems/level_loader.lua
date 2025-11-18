-- Level Loader System
-- Handles loading and validating JSON level data files
-- VETS-34: Define JSON level data format

local json = require("libraries.json")

local LevelLoader = {}

-- Error messages for validation
LevelLoader.ERROR = {
    FILE_NOT_FOUND = "Level file not found",
    INVALID_JSON = "Invalid JSON format",
    MISSING_REQUIRED = "Missing required field",
    INVALID_TYPE = "Invalid field type",
    INVALID_VALUE = "Invalid field value"
}

-- Required fields for level validation
local REQUIRED_FIELDS = {
    "version",
    "night",
    "name",
    "spawn",
    "platforms",
    "delivery_zones"
}

-- Type validation helpers
local function isNumber(value)
    return type(value) == "number"
end

local function isString(value)
    return type(value) == "string"
end

local function isTable(value)
    return type(value) == "table"
end

local function isBoolean(value)
    return type(value) == "boolean"
end

-- Validate spawn point
local function validateSpawn(spawn)
    if not isTable(spawn) then
        return false, "spawn must be a table"
    end
    if not isNumber(spawn.x) or not isNumber(spawn.y) then
        return false, "spawn must have numeric x and y coordinates"
    end
    return true
end

-- Validate platform data
local function validatePlatform(platform, index)
    if not isTable(platform) then
        return false, string.format("Platform %d must be a table", index)
    end

    local required = {"x", "y", "width", "height"}
    for _, field in ipairs(required) do
        if not isNumber(platform[field]) then
            return false, string.format("Platform %d missing or invalid '%s'", index, field)
        end
    end

    if platform.width <= 0 or platform.height <= 0 then
        return false, string.format("Platform %d has invalid dimensions", index)
    end

    return true
end

-- Validate wall data
local function validateWall(wall, index)
    if not isTable(wall) then
        return false, string.format("Wall %d must be a table", index)
    end

    local required = {"x", "y", "width", "height"}
    for _, field in ipairs(required) do
        if not isNumber(wall[field]) then
            return false, string.format("Wall %d missing or invalid '%s'", index, field)
        end
    end

    return true
end

-- Validate delivery zone data
local function validateDeliveryZone(zone, index)
    if not isTable(zone) then
        return false, string.format("Delivery zone %d must be a table", index)
    end

    local required = {"x", "y", "id"}
    for _, field in ipairs(required) do
        if zone[field] == nil then
            return false, string.format("Delivery zone %d missing '%s'", index, field)
        end
    end

    if not isNumber(zone.x) or not isNumber(zone.y) then
        return false, string.format("Delivery zone %d has invalid coordinates", index)
    end

    if not isString(zone.id) then
        return false, string.format("Delivery zone %d has invalid id", index)
    end

    return true
end

-- Validate hazard data
local function validateHazard(hazard, index)
    if not isTable(hazard) then
        return false, string.format("Hazard %d must be a table", index)
    end

    local required = {"x", "y", "type"}
    for _, field in ipairs(required) do
        if hazard[field] == nil then
            return false, string.format("Hazard %d missing '%s'", index, field)
        end
    end

    return true
end

-- Validate powerup data
local function validatePowerup(powerup, index)
    if not isTable(powerup) then
        return false, string.format("Powerup %d must be a table", index)
    end

    local required = {"x", "y", "type"}
    for _, field in ipairs(required) do
        if powerup[field] == nil then
            return false, string.format("Powerup %d missing '%s'", index, field)
        end
    end

    return true
end

-- Validate prop data
local function validateProp(prop, index)
    if not isTable(prop) then
        return false, string.format("Prop %d must be a table", index)
    end

    local required = {"x", "y", "prop_type"}
    for _, field in ipairs(required) do
        if prop[field] == nil then
            return false, string.format("Prop %d missing '%s'", index, field)
        end
    end

    if not isNumber(prop.x) or not isNumber(prop.y) then
        return false, string.format("Prop %d has invalid coordinates", index)
    end

    if not isString(prop.prop_type) then
        return false, string.format("Prop %d has invalid prop_type", index)
    end

    return true
end

-- Validate background layer
local function validateBackgroundLayer(layer, index)
    if not isTable(layer) then
        return false, string.format("Background layer %d must be a table", index)
    end

    if not isString(layer.type) or not isNumber(layer.layer) then
        return false, string.format("Background layer %d missing type or layer number", index)
    end

    return true
end

-- Main validation function
function LevelLoader.validate(levelData)
    -- Check required fields exist
    for _, field in ipairs(REQUIRED_FIELDS) do
        if levelData[field] == nil then
            return false, string.format("%s: %s", LevelLoader.ERROR.MISSING_REQUIRED, field)
        end
    end

    -- Validate version
    if not isNumber(levelData.version) then
        return false, "version must be a number"
    end

    -- Validate night number
    if not isNumber(levelData.night) then
        return false, "night must be a number"
    end

    -- Validate name
    if not isString(levelData.name) then
        return false, "name must be a string"
    end

    -- Validate spawn point
    local valid, err = validateSpawn(levelData.spawn)
    if not valid then
        return false, err
    end

    -- Validate platforms
    if not isTable(levelData.platforms) then
        return false, "platforms must be a table"
    end

    for i, platform in ipairs(levelData.platforms) do
        valid, err = validatePlatform(platform, i)
        if not valid then
            return false, err
        end
    end

    -- Validate walls (optional)
    if levelData.walls then
        if not isTable(levelData.walls) then
            return false, "walls must be a table"
        end
        for i, wall in ipairs(levelData.walls) do
            valid, err = validateWall(wall, i)
            if not valid then
                return false, err
            end
        end
    end

    -- Validate delivery zones
    if not isTable(levelData.delivery_zones) then
        return false, "delivery_zones must be a table"
    end

    if #levelData.delivery_zones == 0 then
        return false, "level must have at least one delivery zone"
    end

    for i, zone in ipairs(levelData.delivery_zones) do
        valid, err = validateDeliveryZone(zone, i)
        if not valid then
            return false, err
        end
    end

    -- Validate hazards (optional)
    if levelData.hazards then
        if not isTable(levelData.hazards) then
            return false, "hazards must be a table"
        end
        for i, hazard in ipairs(levelData.hazards) do
            valid, err = validateHazard(hazard, i)
            if not valid then
                return false, err
            end
        end
    end

    -- Validate powerups (optional)
    if levelData.powerups then
        if not isTable(levelData.powerups) then
            return false, "powerups must be a table"
        end
        for i, powerup in ipairs(levelData.powerups) do
            valid, err = validatePowerup(powerup, i)
            if not valid then
                return false, err
            end
        end
    end

    -- Validate background layers (optional)
    if levelData.background_layers then
        if not isTable(levelData.background_layers) then
            return false, "background_layers must be a table"
        end
        for i, layer in ipairs(levelData.background_layers) do
            valid, err = validateBackgroundLayer(layer, i)
            if not valid then
                return false, err
            end
        end
    end

    -- Validate props (optional)
    if levelData.props then
        if not isTable(levelData.props) then
            return false, "props must be a table"
        end
        for i, prop in ipairs(levelData.props) do
            valid, err = validateProp(prop, i)
            if not valid then
                return false, err
            end
        end
    end

    return true, "Validation successful"
end

-- Load a level from file
function LevelLoader.load(filepath)
    -- Check if file exists
    local fileInfo = love.filesystem.getInfo(filepath)
    if not fileInfo then
        return nil, string.format("%s: %s", LevelLoader.ERROR.FILE_NOT_FOUND, filepath)
    end

    -- Read file contents
    local contents, readError = love.filesystem.read(filepath)
    if not contents then
        return nil, string.format("Error reading file: %s", readError)
    end

    -- Parse JSON
    local success, levelData = pcall(json.decode, contents)
    if not success then
        return nil, string.format("%s: %s", LevelLoader.ERROR.INVALID_JSON, levelData)
    end

    -- Validate level data
    local valid, validationError = LevelLoader.validate(levelData)
    if not valid then
        return nil, string.format("Validation error: %s", validationError)
    end

    -- Set default values for optional fields
    levelData.walls = levelData.walls or {}
    levelData.hazards = levelData.hazards or {}
    levelData.powerups = levelData.powerups or {}
    levelData.props = levelData.props or {}
    levelData.background_layers = levelData.background_layers or {}
    levelData.camera = levelData.camera or {}
    levelData.environment = levelData.environment or {}
    levelData.metadata = levelData.metadata or {}

    return levelData, nil
end

-- Load a level by night number
function LevelLoader.loadNight(nightNumber)
    local filepath = string.format("levels/night%d.json", nightNumber)
    return LevelLoader.load(filepath)
end

-- Get information about a level without fully loading it
function LevelLoader.getInfo(filepath)
    local fileInfo = love.filesystem.getInfo(filepath)
    if not fileInfo then
        return nil, string.format("%s: %s", LevelLoader.ERROR.FILE_NOT_FOUND, filepath)
    end

    local contents, readError = love.filesystem.read(filepath)
    if not contents then
        return nil, string.format("Error reading file: %s", readError)
    end

    local success, levelData = pcall(json.decode, contents)
    if not success then
        return nil, string.format("%s: %s", LevelLoader.ERROR.INVALID_JSON, levelData)
    end

    -- Return basic info only
    return {
        version = levelData.version,
        night = levelData.night,
        name = levelData.name,
        description = levelData.description,
        metadata = levelData.metadata
    }, nil
end

-- List all available level files
function LevelLoader.listLevels()
    local files = love.filesystem.getDirectoryItems("levels")
    local levels = {}

    for _, filename in ipairs(files) do
        if filename:match("%.json$") and filename ~= "template.json" then
            local filepath = "levels/" .. filename
            local info, err = LevelLoader.getInfo(filepath)
            if info then
                table.insert(levels, {
                    filename = filename,
                    filepath = filepath,
                    info = info
                })
            end
        end
    end

    -- Sort by night number
    table.sort(levels, function(a, b)
        return (a.info.night or 0) < (b.info.night or 0)
    end)

    return levels
end

return LevelLoader
