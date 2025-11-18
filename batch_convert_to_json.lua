-- batch_convert_to_json.lua
-- Batch converts TMX files to JSON format for runtime loading
-- This is the BUILD TOOL for level development workflow:
--   1. Edit levels in Tiled (TMX format)
--   2. Run this converter to update JSON files
--   3. Game loads JSON at runtime
--
-- Triggered by setting TMX_TO_JSON = true in main.lua

-- Note: libs already loaded in main.lua, just get the reference
local tmx_converter = require("src.systems.tmx_converter")

print("\n========================================")
print("Build Tool: TMX → JSON Converter")
print("========================================\n")

-- Map TMX files to their corresponding JSON output files
local levels_to_convert = {
    {tmx = "assets/tiled/night1.tmx", json = "levels/night1.json", name = "Night 1"},
    {tmx = "assets/tiled/night2.tmx", json = "levels/night2.json", name = "Night 2"},
    {tmx = "assets/tiled/night3.tmx", json = "levels/night3.json", name = "Night 3"},
    {tmx = "assets/tiled/showcase.tmx", json = "levels/showcase.json", name = "Showcase Level"}
}

local success_count = 0
local failure_count = 0
local errors = {}
local skipped_count = 0

print("Converting TMX levels to JSON for runtime loading...\n")

for _, level in ipairs(levels_to_convert) do
    -- Check if TMX file exists
    local tmx_exists = love.filesystem.getInfo(level.tmx)

    if not tmx_exists then
        print("⚠️  Skipping " .. level.name .. ": TMX file not found")
        print("   Missing: " .. level.tmx)
        skipped_count = skipped_count + 1
    else
        print("Converting: " .. level.name)
        print("  TMX: " .. level.tmx)
        print("  JSON: " .. level.json)

        -- Convert TMX to game JSON format
        local level_data, convert_err = tmx_converter.convert(level.tmx)

        if not level_data then
            print("  ❌ Conversion failed: " .. (convert_err or "unknown error"))
            failure_count = failure_count + 1
            table.insert(errors, {file = level.name, error = convert_err})
        else
            -- Update metadata
            level_data.name = level.name

            -- Extract night number from filename if possible
            local night_num = level.json:match("night(%d+)")
            if night_num then
                level_data.night = tonumber(night_num)
            end

            -- Export to JSON file
            local export_success, export_err = tmx_converter.export_to_file(level_data, level.json)

            if export_success then
                print("  ✅ Successfully converted!")
                print("     Platforms: " .. #level_data.platforms)
                print("     Delivery zones: " .. #level_data.delivery_zones)
                print("     Hazards: " .. #level_data.hazards)
                print("     Powerups: " .. #level_data.powerups)
                success_count = success_count + 1
            else
                print("  ❌ Export failed: " .. (export_err or "unknown error"))
                failure_count = failure_count + 1
                table.insert(errors, {file = level.name, error = export_err})
            end
        end
    end
    print("")
end

print("========================================")
print("Build Summary")
print("========================================\n")

print("✅ Successful: " .. success_count)
if failure_count > 0 then
    print("❌ Failed: " .. failure_count)
end
if skipped_count > 0 then
    print("⚠️  Skipped: " .. skipped_count .. " (TMX file not found)")
end

if #errors > 0 then
    print("\n⚠️  Errors:")
    for _, error_info in ipairs(errors) do
        print("  - " .. error_info.file .. ": " .. (error_info.error or "unknown"))
    end
end

if success_count > 0 then
    print("\n✨ JSON files updated successfully!")
    print("   Your levels are ready to load in-game.")
end

print("\n========================================")
print("Build Complete!")
print("========================================\n")

return success_count > 0 and failure_count == 0
