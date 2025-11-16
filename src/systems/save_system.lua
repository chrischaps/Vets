-- src/systems/save_system.lua
-- Save/load system for persisting player progress, high scores, and night unlocks
--
-- Uses LÖVE's filesystem API and JSON for cross-platform save file management.
-- Save file is stored at love.filesystem.getSaveDirectory()/save.json

local json = require("libraries.json")
local SaveDataTemplate = require("src.data.save_data")

local SaveSystem = {}

-- Internal state
local currentSaveData = nil
local SAVE_FILENAME = "save.json"

-- Deep copy helper function
local function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Validate save data structure
local function validateSaveData(data)
    if not data then return false end
    if type(data) ~= "table" then return false end

    -- Check required fields
    if not data.version then return false end
    if not data.nights_unlocked then return false end
    if not data.nights_completed then return false end
    if not data.best_ranks then return false end
    if not data.best_scores then return false end

    return true
end

-- Initialize the save system (call on game start)
function SaveSystem.init()
    print("[SaveSystem] Initializing...")
    print("[SaveSystem] Save directory: " .. love.filesystem.getSaveDirectory())

    -- Try to load existing save file
    local success, data = pcall(SaveSystem.load)

    if success and data then
        currentSaveData = data
        print("[SaveSystem] Loaded existing save file")
    else
        -- Create default save data
        currentSaveData = deepCopy(SaveDataTemplate)
        SaveSystem.save(currentSaveData)
        print("[SaveSystem] Created new save file")
    end

    return currentSaveData
end

-- Load save data from disk
function SaveSystem.load()
    -- Check if save file exists
    local fileInfo = love.filesystem.getInfo(SAVE_FILENAME)
    if not fileInfo then
        print("[SaveSystem] No save file found")
        return nil
    end

    -- Read save file
    local contents, err = love.filesystem.read(SAVE_FILENAME)
    if not contents then
        print("[SaveSystem] Error reading save file: " .. tostring(err))
        return nil
    end

    -- Parse JSON (using pcall for safe parsing)
    local success, data = pcall(json.decode, contents)
    if not success then
        print("[SaveSystem] Error parsing JSON: " .. tostring(data))
        print("[SaveSystem] Corrupted save file - will reset to default")
        return nil
    end

    -- Validate data structure
    if not validateSaveData(data) then
        print("[SaveSystem] Invalid save data structure - will reset to default")
        return nil
    end

    return data
end

-- Save data to disk
function SaveSystem.save(data)
    if not data then
        print("[SaveSystem] Error: Cannot save nil data")
        return false
    end

    -- Encode to JSON with pretty printing
    local success, jsonStr = pcall(json.encode, data, {indent = true})
    if not success then
        print("[SaveSystem] Error encoding JSON: " .. tostring(jsonStr))
        return false
    end

    -- Write to file
    local writeSuccess, writeErr = love.filesystem.write(SAVE_FILENAME, jsonStr)
    if not writeSuccess then
        print("[SaveSystem] Error writing save file: " .. tostring(writeErr))
        return false
    end

    -- Update current save data
    currentSaveData = data
    print("[SaveSystem] Save file written successfully")
    return true
end

-- Get current save data
function SaveSystem.getData()
    return currentSaveData
end

-- Update night completion and scores
function SaveSystem.updateNightProgress(night_num, score, rank)
    if not currentSaveData then
        print("[SaveSystem] Error: No save data loaded")
        return false
    end

    local night_key = "night" .. night_num

    -- Update completion status
    currentSaveData.nights_completed[night_key] = true

    -- Update best score if current score is higher
    if score > (currentSaveData.best_scores[night_key] or 0) then
        currentSaveData.best_scores[night_key] = score
        print("[SaveSystem] New high score for " .. night_key .. ": " .. score)
    end

    -- Update best rank if current rank is better
    local ranks = {D = 1, C = 2, B = 3, A = 4, S = 5}
    local current_rank_value = ranks[rank] or 0
    local best_rank = currentSaveData.best_ranks[night_key]
    local best_rank_value = best_rank and ranks[best_rank] or 0

    if current_rank_value > best_rank_value then
        currentSaveData.best_ranks[night_key] = rank
        print("[SaveSystem] New best rank for " .. night_key .. ": " .. rank)
    end

    -- Unlock next night (if not already unlocked)
    if night_num < 3 and currentSaveData.nights_unlocked <= night_num then
        currentSaveData.nights_unlocked = night_num + 1
        print("[SaveSystem] Unlocked night " .. (night_num + 1))
    end

    -- Save to disk
    return SaveSystem.save(currentSaveData)
end

-- Unlock a specific night
function SaveSystem.unlockNight(night_num)
    if not currentSaveData then
        print("[SaveSystem] Error: No save data loaded")
        return false
    end

    if night_num > currentSaveData.nights_unlocked then
        currentSaveData.nights_unlocked = night_num
        print("[SaveSystem] Unlocked night " .. night_num)
        return SaveSystem.save(currentSaveData)
    end

    return true
end

-- Check if a night is unlocked
function SaveSystem.isNightUnlocked(night_num)
    if not currentSaveData then
        return false
    end

    return night_num <= currentSaveData.nights_unlocked
end

-- Reset all progress (for testing)
function SaveSystem.reset()
    print("[SaveSystem] Resetting all progress...")
    currentSaveData = deepCopy(SaveDataTemplate)
    return SaveSystem.save(currentSaveData)
end

return SaveSystem
