-- batch_convert_to_tmx.lua
-- Batch converts all JSON levels to TMX format (ONE-TIME MIGRATION TOOL)
-- This is mainly useful for migrating existing JSON levels to TMX for editing in Tiled
-- Triggered by setting JSON_TO_TMX = true in main.lua

-- Note: libs already loaded in main.lua
local tmx_converter = require("src.systems.tmx_converter")

print("\n========================================")
print("Migration Tool: JSON → TMX Converter")
print("========================================\n")

-- List of level files to convert (excluding test files and templates)
local levels_to_convert = {
    {json = "levels/night1.json", tmx = "assets/tiled/night1.tmx"},
    {json = "levels/night2.json", tmx = "assets/tiled/night2.tmx"},
    {json = "levels/night3.json", tmx = "assets/tiled/night3.tmx"},
    {json = "levels/showcase.json", tmx = "assets/tiled/showcase.tmx"}
}

local success_count = 0
local failure_count = 0
local errors = {}

print("Converting JSON levels to TMX for editing in Tiled...\n")

for _, level in ipairs(levels_to_convert) do
    print("Converting: " .. level.json .. " → " .. level.tmx)

    local success, err = tmx_converter.convert_and_export_to_tmx(level.json, level.tmx)

    if success then
        print("✅ Successfully converted!")
        success_count = success_count + 1
    else
        print("❌ Failed to convert")
        print("  Error: " .. (err or "unknown error"))
        failure_count = failure_count + 1
        table.insert(errors, {file = level.json, error = err})
    end
    print("")
end

print("========================================")
print("Migration Summary")
print("========================================\n")

print("Successful: " .. success_count)
print("Failed: " .. failure_count)

if #errors > 0 then
    print("\nErrors:")
    for _, error_info in ipairs(errors) do
        print("  - " .. error_info.file .. ": " .. error_info.error)
    end
end

if success_count > 0 then
    print("\n✨ TMX files created successfully!")
    print("   You can now edit these levels in Tiled.")
    print("   After editing, run TMX_TO_JSON to update the JSON files.")
end

print("\n========================================")
print("Migration Complete!")
print("========================================\n")

return success_count > 0 and failure_count == 0
