-- src/data/save_data.lua
-- SaveData structure definition for persisting player progress
--
-- This module defines the default save data structure used by the SaveSystem.
-- The data includes progression, high scores, settings, and stats.

local SaveData = {
    version = 1,  -- Save format version for future migrations

    -- Progression tracking
    nights_unlocked = 1,  -- Number of nights unlocked (1-3+)
    nights_completed = {  -- Boolean flags for completed nights
        night1 = false,
        night2 = false,
        night3 = false
    },

    -- High score tracking
    best_ranks = {  -- Best rank achieved per night ("D", "C", "B", "A", "S")
        night1 = nil,
        night2 = nil,
        night3 = nil
    },
    best_scores = {  -- Highest score achieved per night
        night1 = 0,
        night2 = 0,
        night3 = 0
    },

    -- Settings (for future use)
    settings = {
        music_volume = 0.7,
        sfx_volume = 0.8
    },

    -- Statistics (for future use)
    stats = {
        total_deliveries = 0,
        total_playtime = 0,
        deaths = 0
    }
}

return SaveData
