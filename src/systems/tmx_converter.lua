-- src/systems/tmx_converter.lua
-- Converts Tiled TMX format to Courier Cat JSON level schema
--
-- This module transforms TMX object layers (loaded via STI) into the game's
-- JSON level format as defined in levels/SCHEMA.md
--
-- Dependencies:
--   - STI (Simple Tiled Implementation)
--   - libraries/json.lua
--
-- Usage:
--   local tmx_converter = require("src.systems.tmx_converter")
--   local level_data = tmx_converter.convert("assets/tiled/night_01.tmx")
--   tmx_converter.export_to_file(level_data, "levels/night1.json")

local libs = require("libraries.init")
local sti = libs.sti
local json = require("libraries.json")

local tmx_converter = {}

--- Convert a spawn point object to JSON format
-- @param obj table - TMX object with type "SpawnPoint"
-- @return spawn table - Spawn point in JSON schema format {x, y}
local function convert_spawn_point(obj)
    -- TMX uses top-left corner for rectangles, but spawn points should use center
    -- Add half width/height to get center position
    local center_x = obj.x + (obj.width or 0) / 2
    local center_y = obj.y + (obj.height or 0) / 2

    return {
        x = center_x,
        y = center_y
    }
end

--- Convert a platform object to JSON format
-- @param obj table - TMX object with type "Platform"
-- @return platform table - Platform in JSON schema format
local function convert_platform(obj)
    local platform = {
        x = obj.x,
        y = obj.y,
        width = obj.width,
        height = obj.height,
        type = (obj.properties and obj.properties.type) or "rooftop"
    }

    -- Add optional properties if they exist
    if obj.properties then
        platform.properties = {}

        -- Map custom properties
        if obj.properties.friction ~= nil then
            platform.properties.friction = obj.properties.friction
        end

        if obj.properties.grippable ~= nil then
            platform.properties.grippable = obj.properties.grippable
        end

        if obj.properties.climbable ~= nil then
            platform.properties.climbable = obj.properties.climbable
        end

        if obj.properties.semi_solid ~= nil then
            platform.properties.semi_solid = obj.properties.semi_solid
        end

        -- Only include properties object if it has content
        if next(platform.properties) == nil then
            platform.properties = nil
        end
    end

    return platform
end

--- Convert a delivery zone object to JSON format
-- @param obj table - TMX object with type "DeliveryZone"
-- @return delivery_zone table - Delivery zone in JSON schema format
local function convert_delivery_zone(obj)
    -- TMX uses top-left corner for rectangles, but delivery zones should use center
    local center_x = obj.x + (obj.width or 16) / 2
    local center_y = obj.y + (obj.height or 16) / 2

    local delivery_zone = {
        x = center_x,
        y = center_y,
        width = obj.width or 16,
        height = obj.height or 16,
        id = obj.name or ("delivery_" .. obj.id),
        type = (obj.properties and obj.properties.type) or "standard"
    }

    -- Handle letter_fragment_id
    if obj.properties and obj.properties.letter_fragment_id ~= nil then
        -- Convert to string if it's a number, keep as-is if string, or null if empty
        local frag_id = obj.properties.letter_fragment_id
        if type(frag_id) == "number" then
            delivery_zone.letter_fragment_id = tostring(frag_id)
        elseif frag_id == "" then
            delivery_zone.letter_fragment_id = nil  -- Will be serialized as null
        else
            delivery_zone.letter_fragment_id = frag_id
        end
    else
        delivery_zone.letter_fragment_id = nil  -- Will be serialized as null
    end

    -- Add optional properties
    if obj.properties then
        delivery_zone.properties = {}

        -- Map additional properties (excluding already handled ones)
        for key, value in pairs(obj.properties) do
            if key ~= "type" and key ~= "letter_fragment_id" then
                delivery_zone.properties[key] = value
            end
        end

        -- Only include properties object if it has content
        if next(delivery_zone.properties) == nil then
            delivery_zone.properties = nil
        end
    end

    return delivery_zone
end

--- Convert a hazard object to JSON format
-- @param obj table - TMX object with type "Hazard"
-- @return hazard table - Hazard in JSON schema format
local function convert_hazard(obj)
    -- Hazards use center position
    local center_x = obj.x + (obj.width or 16) / 2
    local center_y = obj.y + (obj.height or 16) / 2

    local hazard = {
        x = center_x,
        y = center_y,
        type = (obj.properties and obj.properties.type) or "vent"
    }

    -- Add optional dimensions if present
    if obj.width then
        hazard.width = obj.width
    end
    if obj.height then
        hazard.height = obj.height
    end

    -- Add properties
    if obj.properties then
        hazard.properties = {}

        -- Map all properties except the type (which is top-level)
        for key, value in pairs(obj.properties) do
            if key ~= "type" then
                hazard.properties[key] = value
            end
        end

        -- Only include properties object if it has content
        if next(hazard.properties) == nil then
            hazard.properties = nil
        end
    end

    return hazard
end

--- Convert a powerup object to JSON format
-- @param obj table - TMX object with type "Powerup"
-- @return powerup table - Powerup in JSON schema format
local function convert_powerup(obj)
    -- Powerups use center position
    local center_x = obj.x + (obj.width or 12) / 2
    local center_y = obj.y + (obj.height or 12) / 2

    local powerup = {
        x = center_x,
        y = center_y,
        type = (obj.properties and obj.properties.type) or "coffee"
    }

    -- Add optional dimensions if present
    if obj.width then
        powerup.width = obj.width
    end
    if obj.height then
        powerup.height = obj.height
    end

    -- Add properties
    if obj.properties then
        powerup.properties = {}

        -- Map all properties except the type (which is top-level)
        for key, value in pairs(obj.properties) do
            if key ~= "type" then
                powerup.properties[key] = value
            end
        end

        -- Only include properties object if it has content
        if next(powerup.properties) == nil then
            powerup.properties = nil
        end
    end

    return powerup
end

--- Parse a TMX XML file directly (for .tmx files)
-- @param tmx_path string - Path to the TMX file
-- @return objects table - Array of objects extracted from TMX
-- @return error string - Error message if parsing failed, nil otherwise
local function parse_tmx_xml(tmx_path)
    local file_contents = love.filesystem.read(tmx_path)
    if not file_contents then
        return nil, "Failed to read TMX file"
    end

    local objects = {}

    -- Extract object groups
    for object_group in file_contents:gmatch('<objectgroup[^>]*>(.-)</objectgroup>') do
        -- Extract layer name from the objectgroup tag
        local layer_name_match = file_contents:match('<objectgroup[^>]-id="2"[^>]-name="([^"]*)"')

        if layer_name_match == "Entities" then

            local obj_count = 0
            local i = 1
            while i <= #object_group do
                local obj_start = object_group:find('<object%s+', i)
                if not obj_start then
                    break
                end

                -- Find the end of this object (either /> or </object>)
                --  Need to check if this is truly a self-closing object tag,
                -- not just a property tag with />
                local obj_end
                local is_self_closing = false

                -- First, find where the opening tag ends (first >)
                local opening_tag_end = object_group:find('>', obj_start)

                if opening_tag_end then
                    -- Check if it's self-closing by looking at the character before >
                    local char_before = object_group:sub(opening_tag_end - 1, opening_tag_end - 1)

                    if char_before == '/' then
                        -- Self-closing tag: <object ... />
                        obj_end = opening_tag_end
                        is_self_closing = true
                    else
                        -- Regular tag with content: <object ...>...</object>
                        local tag_close_end = object_group:find('</object>', opening_tag_end)
                        if tag_close_end then
                            obj_end = tag_close_end + 8  -- length of "</object>"
                        else
                            break
                        end
                    end
                else
                    break
                end

                local object_str = object_group:sub(obj_start, obj_end)
                local obj = {}

                -- Extract attributes from the opening tag
                obj.id = tonumber(object_str:match('id="([^"]*)"'))
                obj.name = object_str:match('name="([^"]*)"') or ""
                obj.type = object_str:match('type="([^"]*)"') or ""
                obj.x = tonumber(object_str:match('x="([^"]*)"')) or 0
                obj.y = tonumber(object_str:match('y="([^"]*)"')) or 0
                obj.width = tonumber(object_str:match('width="([^"]*)"')) or 0
                obj.height = tonumber(object_str:match('height="([^"]*)"')) or 0

                -- Extract properties if they exist
                obj.properties = {}
                if not is_self_closing then
                    -- Use a pattern that matches across newlines
                    local prop_start = object_str:find('<properties>')
                    local prop_end = object_str:find('</properties>')

                    if prop_start and prop_end then
                        local properties_section = object_str:sub(prop_start, prop_end + 12)  -- +12 for length of "</properties>"

                        for prop in properties_section:gmatch('<property[^>]*/>') do
                            local name = prop:match('name="([^"]*)"')
                            local value_type = prop:match('type="([^"]*)"') or "string"
                            local value = prop:match('value="([^"]*)"')

                            if name and value then
                                if value_type == "int" then
                                    obj.properties[name] = tonumber(value)
                                elseif value_type == "float" then
                                    obj.properties[name] = tonumber(value)
                                elseif value_type == "bool" then
                                    obj.properties[name] = (value == "true")
                                else
                                    obj.properties[name] = value
                                end
                            end
                        end
                    end
                end

                table.insert(objects, obj)
                obj_count = obj_count + 1

                i = obj_end + 1
            end

            print("[TMX Parser] Extracted " .. obj_count .. " objects")
        end
    end


    return objects, nil
end

--- Convert a TMX map to game JSON format
-- @param tmx_path string - Path to the TMX or Lua file
-- @return level_data table - Level data in JSON schema format
-- @return error string - Error message if conversion failed, nil otherwise
function tmx_converter.convert(tmx_path)
    print("[TMX Converter] Converting to JSON: " .. tmx_path)

    local objects
    local ext = tmx_path:sub(-4, -1)

    if ext == ".tmx" then
        -- Parse TMX XML directly
        print("[TMX Converter] Parsing TMX XML file...")
        local err
        objects, err = parse_tmx_xml(tmx_path)

        if not objects then
            return nil, err
        end

        print("[TMX Converter] Found " .. #objects .. " objects in Entities layer")

    elseif ext == ".lua" then
        -- Load using STI
        print("[TMX Converter] Loading Lua-exported map with STI...")
        local map = sti(tmx_path)

        if not map then
            return nil, "Failed to load Lua file: " .. tmx_path
        end

        -- Find the Entities object layer
        local entities_layer = nil
        for _, layer in ipairs(map.layers) do
            if layer.name == "Entities" and layer.type == "objectgroup" then
                entities_layer = layer
                break
            end
        end

        if not entities_layer then
            return nil, "No 'Entities' object layer found in map file"
        end

        print("[TMX Converter] Found Entities layer with " .. #entities_layer.objects .. " objects")
        objects = entities_layer.objects

    else
        return nil, "Unsupported file type: " .. ext .. ". Expected .tmx or .lua"
    end

    -- Initialize level data structure
    local level_data = {
        version = 1,
        night = 1,  -- Default, should be overridden
        name = "Untitled Level",
        spawn = nil,
        platforms = {},
        delivery_zones = {},
        hazards = {},
        powerups = {}
    }

    -- Process each object
    local spawn_count = 0

    for _, obj in ipairs(objects) do
        if obj.type == "SpawnPoint" then
            level_data.spawn = convert_spawn_point(obj)
            spawn_count = spawn_count + 1
            print("[TMX Converter]   + Spawn point at (" .. level_data.spawn.x .. ", " .. level_data.spawn.y .. ")")

        elseif obj.type == "Platform" then
            table.insert(level_data.platforms, convert_platform(obj))
            print("[TMX Converter]   + Platform: " .. (obj.name or "unnamed"))

        elseif obj.type == "DeliveryZone" then
            table.insert(level_data.delivery_zones, convert_delivery_zone(obj))
            print("[TMX Converter]   + Delivery zone: " .. (obj.name or "unnamed"))

        elseif obj.type == "Hazard" then
            table.insert(level_data.hazards, convert_hazard(obj))
            print("[TMX Converter]   + Hazard: " .. (obj.name or "unnamed"))

        elseif obj.type == "Powerup" then
            table.insert(level_data.powerups, convert_powerup(obj))
            print("[TMX Converter]   + Powerup: " .. (obj.name or "unnamed"))

        else
            print("[TMX Converter]   ? Unknown object type: " .. (obj.type or "nil") .. " (" .. (obj.name or "unnamed") .. ")")
        end
    end

    -- Validate the conversion
    local validation_errors = {}

    if spawn_count == 0 then
        table.insert(validation_errors, "No spawn point found (exactly 1 required)")
    elseif spawn_count > 1 then
        table.insert(validation_errors, "Multiple spawn points found (" .. spawn_count .. "), exactly 1 required")
    end

    if #level_data.platforms == 0 then
        table.insert(validation_errors, "No platforms found (at least 1 required)")
    end

    if #level_data.delivery_zones == 0 then
        table.insert(validation_errors, "No delivery zones found (at least 1 required)")
    end

    if #validation_errors > 0 then
        local error_msg = "Validation failed:\n  - " .. table.concat(validation_errors, "\n  - ")
        return nil, error_msg
    end

    print("[TMX Converter] Conversion successful!")
    print("[TMX Converter]   Platforms: " .. #level_data.platforms)
    print("[TMX Converter]   Delivery zones: " .. #level_data.delivery_zones)
    print("[TMX Converter]   Hazards: " .. #level_data.hazards)
    print("[TMX Converter]   Powerups: " .. #level_data.powerups)

    return level_data, nil
end

--- Export level data to a JSON file
-- @param level_data table - Level data in JSON schema format
-- @param output_path string - Path to save the JSON file
-- @return success boolean - True if export succeeded, false otherwise
-- @return error string - Error message if export failed, nil otherwise
function tmx_converter.export_to_file(level_data, output_path)
    print("[TMX Converter] Exporting to JSON: " .. output_path)

    -- Convert to JSON with pretty printing
    local json_string = json.encode(level_data, {indent = true})

    -- Write to file
    local file, err = io.open(output_path, "w")
    if not file then
        return false, "Failed to open file for writing: " .. err
    end

    file:write(json_string)
    file:close()

    print("[TMX Converter] Export successful!")
    return true, nil
end

--- Convert and export in one step (TMX to JSON)
-- @param tmx_path string - Path to the TMX file
-- @param json_path string - Path to save the JSON file
-- @return success boolean - True if conversion and export succeeded
-- @return error string - Error message if failed, nil otherwise
function tmx_converter.convert_and_export(tmx_path, json_path)
    local level_data, err = tmx_converter.convert(tmx_path)

    if not level_data then
        return false, err
    end

    return tmx_converter.export_to_file(level_data, json_path)
end

--------------------------------------------------------------------------------
-- JSON to TMX Conversion Functions
--------------------------------------------------------------------------------

--- Convert game JSON format to TMX XML string
-- @param level_data table - Level data in JSON schema format
-- @return tmx_string string - TMX XML content
-- @return error string - Error message if conversion failed, nil otherwise
function tmx_converter.convert_json_to_tmx(level_data)
    print("[TMX Converter] Converting JSON to TMX...")

    -- Validate input
    if not level_data.spawn then
        return nil, "Missing spawn point in level data"
    end

    -- Start building TMX XML
    local xml = {}
    table.insert(xml, '<?xml version="1.0" encoding="UTF-8"?>')
    table.insert(xml, '<!-- Generated by Courier Cat TMX Converter -->')
    table.insert(xml, '<map version="1.10" tiledversion="1.11.0" orientation="orthogonal" renderorder="right-down"')
    table.insert(xml, '     width="60" height="30" tilewidth="16" tileheight="16" infinite="0" nextlayerid="3" nextobjectid="1">')
    table.insert(xml, '')
    table.insert(xml, '  <!-- Object Layer: Contains all game entities -->')
    table.insert(xml, '  <objectgroup id="2" name="Entities">')
    table.insert(xml, '')

    local object_id = 1

    -- Add spawn point
    local spawn = level_data.spawn
    -- Spawn uses center position in JSON, convert to top-left for TMX
    local spawn_width = 16
    local spawn_height = 16
    local spawn_x = spawn.x - spawn_width / 2
    local spawn_y = spawn.y - spawn_height / 2

    table.insert(xml, string.format('    <!-- Spawn Point -->'))
    table.insert(xml, string.format('    <object id="%d" name="PlayerSpawn" type="SpawnPoint" x="%g" y="%g" width="%g" height="%g"/>',
        object_id, spawn_x, spawn_y, spawn_width, spawn_height))
    table.insert(xml, '')
    object_id = object_id + 1

    -- Add platforms
    if level_data.platforms and #level_data.platforms > 0 then
        table.insert(xml, '    <!-- Platforms -->')
        for i, platform in ipairs(level_data.platforms) do
            local name = "Platform" .. i
            table.insert(xml, string.format('    <object id="%d" name="%s" type="Platform" x="%g" y="%g" width="%g" height="%g">',
                object_id, name, platform.x, platform.y, platform.width, platform.height))

            -- Add properties
            if platform.type or (platform.properties and next(platform.properties)) then
                table.insert(xml, '      <properties>')
                table.insert(xml, string.format('        <property name="type" value="%s"/>', platform.type or "rooftop"))

                if platform.properties then
                    if platform.properties.climbable ~= nil then
                        table.insert(xml, string.format('        <property name="climbable" type="bool" value="%s"/>', tostring(platform.properties.climbable)))
                    end
                    if platform.properties.semi_solid ~= nil then
                        table.insert(xml, string.format('        <property name="semi_solid" type="bool" value="%s"/>', tostring(platform.properties.semi_solid)))
                    end
                    if platform.properties.friction then
                        table.insert(xml, string.format('        <property name="friction" type="float" value="%g"/>', platform.properties.friction))
                    end
                    if platform.properties.grippable ~= nil then
                        table.insert(xml, string.format('        <property name="grippable" type="bool" value="%s"/>', tostring(platform.properties.grippable)))
                    end
                end

                table.insert(xml, '      </properties>')
            end

            table.insert(xml, '    </object>')
            object_id = object_id + 1
        end
        table.insert(xml, '')
    end

    -- Add delivery zones
    if level_data.delivery_zones and #level_data.delivery_zones > 0 then
        table.insert(xml, '    <!-- Delivery Zones -->')
        for i, zone in ipairs(level_data.delivery_zones) do
            local name = zone.id or ("Delivery" .. i)
            local width = zone.width or 16
            local height = zone.height or 16
            -- Convert from center position (JSON) to top-left (TMX)
            local x = zone.x - width / 2
            local y = zone.y - height / 2

            table.insert(xml, string.format('    <object id="%d" name="%s" type="DeliveryZone" x="%g" y="%g" width="%g" height="%g">',
                object_id, name, x, y, width, height))

            -- Add properties
            table.insert(xml, '      <properties>')
            table.insert(xml, string.format('        <property name="type" value="%s"/>', zone.type or "standard"))

            if zone.letter_fragment_id then
                table.insert(xml, string.format('        <property name="letter_fragment_id" type="int" value="%s"/>', zone.letter_fragment_id))
            end

            if zone.properties then
                for key, value in pairs(zone.properties) do
                    if type(value) == "boolean" then
                        table.insert(xml, string.format('        <property name="%s" type="bool" value="%s"/>', key, tostring(value)))
                    elseif type(value) == "number" then
                        table.insert(xml, string.format('        <property name="%s" type="float" value="%g"/>', key, value))
                    else
                        table.insert(xml, string.format('        <property name="%s" value="%s"/>', key, tostring(value)))
                    end
                end
            end

            table.insert(xml, '      </properties>')
            table.insert(xml, '    </object>')
            object_id = object_id + 1
        end
        table.insert(xml, '')
    end

    -- Add hazards
    if level_data.hazards and #level_data.hazards > 0 then
        table.insert(xml, '    <!-- Hazards -->')
        for i, hazard in ipairs(level_data.hazards) do
            local name = "Hazard" .. i
            local width = hazard.width or 16
            local height = hazard.height or 16
            -- Convert from center position (JSON) to top-left (TMX)
            local x = hazard.x - width / 2
            local y = hazard.y - height / 2

            table.insert(xml, string.format('    <object id="%d" name="%s" type="Hazard" x="%g" y="%g" width="%g" height="%g">',
                object_id, name, x, y, width, height))

            -- Add properties
            table.insert(xml, '      <properties>')
            table.insert(xml, string.format('        <property name="type" value="%s"/>', hazard.type or "vent"))

            if hazard.properties then
                for key, value in pairs(hazard.properties) do
                    if type(value) == "boolean" then
                        table.insert(xml, string.format('        <property name="%s" type="bool" value="%s"/>', key, tostring(value)))
                    elseif type(value) == "number" then
                        table.insert(xml, string.format('        <property name="%s" type="float" value="%g"/>', key, value))
                    else
                        table.insert(xml, string.format('        <property name="%s" value="%s"/>', key, tostring(value)))
                    end
                end
            end

            table.insert(xml, '      </properties>')
            table.insert(xml, '    </object>')
            object_id = object_id + 1
        end
        table.insert(xml, '')
    end

    -- Add powerups
    if level_data.powerups and #level_data.powerups > 0 then
        table.insert(xml, '    <!-- Powerups -->')
        for i, powerup in ipairs(level_data.powerups) do
            local name = "Powerup" .. i
            local width = powerup.width or 12
            local height = powerup.height or 12
            -- Convert from center position (JSON) to top-left (TMX)
            local x = powerup.x - width / 2
            local y = powerup.y - height / 2

            table.insert(xml, string.format('    <object id="%d" name="%s" type="Powerup" x="%g" y="%g" width="%g" height="%g">',
                object_id, name, x, y, width, height))

            -- Add properties
            table.insert(xml, '      <properties>')
            table.insert(xml, string.format('        <property name="type" value="%s"/>', powerup.type or "coffee"))

            if powerup.properties then
                for key, value in pairs(powerup.properties) do
                    if type(value) == "boolean" then
                        table.insert(xml, string.format('        <property name="%s" type="bool" value="%s"/>', key, tostring(value)))
                    elseif type(value) == "number" then
                        table.insert(xml, string.format('        <property name="%s" type="float" value="%g"/>', key, value))
                    else
                        table.insert(xml, string.format('        <property name="%s" value="%s"/>', key, tostring(value)))
                    end
                end
            end

            table.insert(xml, '      </properties>')
            table.insert(xml, '    </object>')
            object_id = object_id + 1
        end
        table.insert(xml, '')
    end

    table.insert(xml, '  </objectgroup>')
    table.insert(xml, '</map>')

    local tmx_string = table.concat(xml, '\n')
    print("[TMX Converter] JSON to TMX conversion successful!")

    return tmx_string, nil
end

--- Export level data to a TMX file
-- @param level_data table - Level data in JSON schema format
-- @param output_path string - Path to save the TMX file
-- @return success boolean - True if export succeeded, false otherwise
-- @return error string - Error message if export failed, nil otherwise
function tmx_converter.export_to_tmx(level_data, output_path)
    print("[TMX Converter] Exporting to TMX: " .. output_path)

    -- Convert to TMX XML
    local tmx_string, err = tmx_converter.convert_json_to_tmx(level_data)

    if not tmx_string then
        return false, err
    end

    -- Write to file
    local file, file_err = io.open(output_path, "w")
    if not file then
        return false, "Failed to open file for writing: " .. file_err
    end

    file:write(tmx_string)
    file:close()

    print("[TMX Converter] TMX export successful!")
    return true, nil
end

--- Convert and export in one step (JSON to TMX)
-- @param json_path string - Path to the JSON file
-- @param tmx_path string - Path to save the TMX file
-- @return success boolean - True if conversion and export succeeded
-- @return error string - Error message if failed, nil otherwise
function tmx_converter.convert_and_export_to_tmx(json_path, tmx_path)
    -- Load JSON file
    local file_contents = love.filesystem.read(json_path)
    if not file_contents then
        return false, "Failed to read JSON file: " .. json_path
    end

    -- Parse JSON
    local level_data = json.decode(file_contents)
    if not level_data then
        return false, "Failed to parse JSON file: " .. json_path
    end

    -- Export to TMX
    return tmx_converter.export_to_tmx(level_data, tmx_path)
end

return tmx_converter
