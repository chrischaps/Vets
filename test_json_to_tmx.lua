-- test_json_to_tmx.lua
-- Test script for JSON to TMX converter
-- Triggered by pressing F11 in-game or can be run standalone
--
-- This test loads night1_test.json and converts it to TMX format,
-- then optionally converts it back to verify round-trip conversion.

local libs = require("libraries.init")
local tmx_converter = require("src.systems.tmx_converter")
local json = libs.json

print("\n========================================")
print("JSON to TMX Converter Test")
print("========================================\n")

-- Convert the night1_test.json file to TMX
local json_path = "levels/night1_test.json"
local tmx_output_path = "assets/tiled/night1_from_json.tmx"

print("Converting: " .. json_path .. " -> " .. tmx_output_path .. "\n")

-- Load and convert
local success, err = tmx_converter.convert_and_export_to_tmx(json_path, tmx_output_path)

if not success then
    print("\n!!! CONVERSION FAILED !!!")
    print("Error: " .. err)
    return false
end

print("\n========================================")
print("JSON to TMX Conversion Successful!")
print("========================================\n")

print("TMX file created: " .. tmx_output_path)

-- Now test round-trip conversion: TMX -> JSON -> TMX
print("\n========================================")
print("Round-Trip Conversion Test")
print("========================================\n")

print("Step 1: Converting generated TMX back to JSON...")
local roundtrip_json_path = "levels/night1_roundtrip.json"
local level_data, convert_err = tmx_converter.convert(tmx_output_path)

if not level_data then
    print("Round-trip conversion failed: " .. convert_err)
    return false
end

-- Export to JSON
local export_success, export_err = tmx_converter.export_to_file(level_data, roundtrip_json_path)

if not export_success then
    print("Round-trip JSON export failed: " .. export_err)
    return false
end

print("✅ Round-trip JSON created: " .. roundtrip_json_path)

-- Compare key fields
print("\nStep 2: Comparing original and round-trip data...")

-- Load original JSON for comparison
local original_file = love.filesystem.read(json_path)
local original_data = json.decode(original_file)

local function compare_counts()
    local original_platforms = #(original_data.platforms or {})
    local roundtrip_platforms = #(level_data.platforms or {})

    local original_delivery = #(original_data.delivery_zones or {})
    local roundtrip_delivery = #(level_data.delivery_zones or {})

    local original_hazards = #(original_data.hazards or {})
    local roundtrip_hazards = #(level_data.hazards or {})

    local original_powerups = #(original_data.powerups or {})
    local roundtrip_powerups = #(level_data.powerups or {})

    print("  Platforms: " .. original_platforms .. " -> " .. roundtrip_platforms ..
          (original_platforms == roundtrip_platforms and " ✅" or " ❌"))
    print("  Delivery zones: " .. original_delivery .. " -> " .. roundtrip_delivery ..
          (original_delivery == roundtrip_delivery and " ✅" or " ❌"))
    print("  Hazards: " .. original_hazards .. " -> " .. roundtrip_hazards ..
          (original_hazards == roundtrip_hazards and " ✅" or " ❌"))
    print("  Powerups: " .. original_powerups .. " -> " .. roundtrip_powerups ..
          (original_powerups == roundtrip_powerups and " ✅" or " ❌"))

    return original_platforms == roundtrip_platforms and
           original_delivery == roundtrip_delivery and
           original_hazards == roundtrip_hazards and
           original_powerups == roundtrip_powerups
end

local counts_match = compare_counts()

if counts_match then
    print("\n✅ Round-trip conversion successful! All entity counts match.")
else
    print("\n⚠️  Warning: Some entity counts don't match after round-trip conversion.")
end

print("\n========================================")
print("Test Summary")
print("========================================\n")

print("✅ JSON to TMX conversion: SUCCESS")
print(counts_match and "✅" or "⚠️" .. " Round-trip conversion: " .. (counts_match and "SUCCESS" or "PARTIAL"))

print("\nGenerated files:")
print("  - " .. tmx_output_path)
print("  - " .. roundtrip_json_path)

print("\n========================================")
print("Test Complete!")
print("========================================\n")

return true
