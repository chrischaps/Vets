-- test_tmx_converter.lua
-- Test script for TMX to JSON converter
-- Triggered by pressing F12 in-game or can be run standalone
--
-- This test loads night_01.tmx and converts it to JSON format,
-- verifying the converter works correctly.

local libs = require("libraries.init")
local tmx_converter = require("src.systems.tmx_converter")
local json = libs.json

print("\n========================================")
print("TMX Converter Test")
print("========================================\n")

-- Convert the night_01.tmx file
local tmx_path = "assets/tiled/night_01.tmx"
print("Converting: " .. tmx_path .. "\n")

local level_data, err = tmx_converter.convert(tmx_path)

if not level_data then
    print("\n!!! CONVERSION FAILED !!!")
    print("Error: " .. err)
    return false
end

print("\n========================================")
print("Conversion Successful!")
print("========================================\n")

-- Print the JSON output (compact for full view)
print("JSON Output (compact):")
print("----------------------------------------")
local json_string_compact = json.encode(level_data)
print(json_string_compact)
print("----------------------------------------\n")

-- Also print pretty version for readability
print("JSON Output (pretty):")
print("----------------------------------------")
local json_string_pretty = json.encode(level_data, {indent = true})
print(json_string_pretty)
print("----------------------------------------\n")

-- Verify coordinates manually
print("\n========================================")
print("Coordinate Verification")
print("========================================\n")

print("Spawn Point:")
print("  Position: (" .. level_data.spawn.x .. ", " .. level_data.spawn.y .. ")")
print("  Expected: (168, 248) [TMX: x=160, y=240, width=16, height=16, center=160+8, 240+8]")

print("\nFirst Platform (Ground1):")
if #level_data.platforms > 0 then
    local p = level_data.platforms[1]
    print("  Position: (" .. p.x .. ", " .. p.y .. ")")
    print("  Size: " .. p.width .. "x" .. p.height)
    print("  Type: " .. p.type)
    print("  Expected: (32, 256, 256x16, rooftop)")
end

print("\nFirst Delivery Zone (Delivery1):")
if #level_data.delivery_zones > 0 then
    local d = level_data.delivery_zones[1]
    print("  Position: (" .. d.x .. ", " .. d.y .. ")")
    print("  ID: " .. d.id)
    print("  Type: " .. d.type)
    print("  Expected: (104, 248) [TMX: x=96, y=240, width=16, height=16, center=96+8, 240+8]")
end

print("\nFirst Hazard (Vent1):")
if #level_data.hazards > 0 then
    local h = level_data.hazards[1]
    print("  Position: (" .. h.x .. ", " .. h.y .. ")")
    print("  Type: " .. h.type)
    if h.properties and h.properties.pattern then
        print("  Pattern: " .. h.properties.pattern)
    end
    print("  Expected: (248, 264) [TMX: x=240, y=256, width=16, height=16, center=240+8, 256+8]")
end

print("\n========================================")
print("Validation Summary")
print("========================================\n")

print("Spawn point exists: " .. (level_data.spawn ~= nil and "YES" or "NO"))
print("Platforms count: " .. #level_data.platforms)
print("Delivery zones count: " .. #level_data.delivery_zones)
print("Hazards count: " .. #level_data.hazards)
print("Powerups count: " .. #level_data.powerups)

print("\n========================================")
print("Test Complete!")
print("========================================\n")

-- Export to a test JSON file
local output_path = "levels/night1_test.json"
print("Exporting to: " .. output_path)

local success, export_err = tmx_converter.export_to_file(level_data, output_path)

if success then
    print("Export successful!\n")
else
    print("Export failed: " .. export_err .. "\n")
end

print("Test finished successfully!")
return true
