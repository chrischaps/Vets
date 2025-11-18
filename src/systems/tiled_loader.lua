-- src/systems/tiled_loader.lua
-- Tiled map loader system using STI (Simple Tiled Implementation)
--
-- This module wraps the STI library to provide a clean interface for
-- loading and parsing Tiled TMX maps exported to Lua format.
--
-- Dependencies:
--   - STI v1.2.3.0 (Simple Tiled Implementation)
--
-- Usage:
--   local tiled_loader = require("src.systems.tiled_loader")
--   local map = tiled_loader.load("assets/tiled/night_01.lua")
--   local objects = tiled_loader.get_objects(map, "Objects")

local libs = require("libraries.init")
local sti = libs.sti

local tiled_loader = {}

--- Load a Tiled map from a Lua file
-- @param map_path string - Path to the map file (e.g., "assets/tiled/night_01.lua")
-- @param plugins table - Optional STI plugins to load (default: none)
-- @return map table - The loaded STI map object
function tiled_loader.load(map_path, plugins)
    plugins = plugins or {}

    print("[Tiled Loader] Loading map: " .. map_path)

    -- Load the map using STI
    local map = sti(map_path, plugins)

    if map then
        print("[Tiled Loader] Map loaded successfully!")
        print("[Tiled Loader]   Map dimensions: " .. map.width .. "x" .. map.height .. " tiles")
        print("[Tiled Loader]   Tile size: " .. map.tilewidth .. "x" .. map.tileheight .. " pixels")
        print("[Tiled Loader]   Number of layers: " .. #map.layers)
    else
        print("[Tiled Loader] ERROR: Failed to load map!")
    end

    return map
end

--- Get all objects from a specific object layer
-- @param map table - The loaded STI map object
-- @param layer_name string - Name of the object layer (e.g., "Objects")
-- @return objects table - Array of objects from the layer, or empty table if not found
function tiled_loader.get_objects(map, layer_name)
    if not map then
        print("[Tiled Loader] ERROR: Map is nil!")
        return {}
    end

    -- Find the layer by name
    local layer = nil
    for _, l in ipairs(map.layers) do
        if l.name == layer_name then
            layer = l
            break
        end
    end

    if not layer then
        print("[Tiled Loader] WARNING: Layer '" .. layer_name .. "' not found!")
        return {}
    end

    if layer.type ~= "objectgroup" then
        print("[Tiled Loader] WARNING: Layer '" .. layer_name .. "' is not an object layer!")
        return {}
    end

    print("[Tiled Loader] Found object layer '" .. layer_name .. "' with " .. #layer.objects .. " objects")

    return layer.objects
end

--- Print detailed information about all objects in a layer
-- @param map table - The loaded STI map object
-- @param layer_name string - Name of the object layer
function tiled_loader.print_objects(map, layer_name)
    local objects = tiled_loader.get_objects(map, layer_name)

    if #objects == 0 then
        print("[Tiled Loader] No objects to print")
        return
    end

    print("\n[Tiled Loader] ===== Objects in layer '" .. layer_name .. "' =====")

    for i, obj in ipairs(objects) do
        print("\n  Object #" .. i .. ":")
        print("    ID: " .. (obj.id or "nil"))
        print("    Name: " .. (obj.name or "(unnamed)"))
        print("    Type: " .. (obj.type or "(no type)"))
        print("    Position: (" .. obj.x .. ", " .. obj.y .. ")")
        print("    Size: " .. (obj.width or 0) .. "x" .. (obj.height or 0))
        print("    Visible: " .. tostring(obj.visible))

        -- Print custom properties if they exist
        if obj.properties and next(obj.properties) ~= nil then
            print("    Properties:")
            for key, value in pairs(obj.properties) do
                print("      " .. key .. " = " .. tostring(value))
            end
        end
    end

    print("\n[Tiled Loader] ===== End of objects =====\n")
end

--- List all layers in the map
-- @param map table - The loaded STI map object
function tiled_loader.list_layers(map)
    if not map then
        print("[Tiled Loader] ERROR: Map is nil!")
        return
    end

    print("\n[Tiled Loader] ===== Map Layers =====")
    for i, layer in ipairs(map.layers) do
        print("  Layer #" .. i .. ": " .. layer.name .. " (type: " .. layer.type .. ")")
    end
    print("[Tiled Loader] ===== End of layers =====\n")
end

return tiled_loader
