-- Audio Manager System
-- Handles music and sound effects playback with volume controls
-- Music is streamed (for long tracks), SFX are static (for short sounds)

local Audio = {
    music = {},           -- Loaded music tracks (streamed)
    sfx = {},            -- Loaded sound effects (static)
    current_music = nil, -- Currently playing music source
    current_music_name = nil, -- Name of current music track
    music_volume = 1.0,  -- Music volume (0.0 to 1.0)
    sfx_volume = 1.0,    -- SFX volume (0.0 to 1.0)
    master_volume = 1.0, -- Master volume (0.0 to 1.0)
    fade_time = 0,       -- Current fade time
    fade_duration = 0,   -- Total fade duration
    fade_direction = 0,  -- 1 for fade in, -1 for fade out
    target_volume = 1.0, -- Target volume after fade
}

-- Load a music file (streamed for memory efficiency)
-- @param name: string - identifier for the music track
-- @param path: string - file path to the music file (OGG recommended)
function Audio:load_music(name, path)
    if love.filesystem.getInfo(path) then
        -- Load as stream for memory efficiency
        self.music[name] = love.audio.newSource(path, "stream")
        self.music[name]:setLooping(true) -- Music should loop by default
        print("Audio: Loaded music '" .. name .. "' from " .. path)
    else
        print("Audio: WARNING - Music file not found: " .. path)
    end
end

-- Load a sound effect file (static for quick playback)
-- @param name: string - identifier for the sound effect
-- @param path: string - file path to the SFX file (WAV/OGG)
function Audio:load_sfx(name, path)
    if love.filesystem.getInfo(path) then
        -- Load as static for quick playback
        self.sfx[name] = love.audio.newSource(path, "static")
        print("Audio: Loaded SFX '" .. name .. "' from " .. path)
    else
        print("Audio: WARNING - SFX file not found: " .. path)
    end
end

-- Play a music track with optional fade in
-- @param name: string - name of the music track to play
-- @param fade_in: number (optional) - fade in duration in seconds
function Audio:play_music(name, fade_in)
    fade_in = fade_in or 0

    if not self.music[name] then
        print("Audio: ERROR - Music '" .. name .. "' not loaded")
        return
    end

    -- Stop current music if playing
    if self.current_music then
        self.current_music:stop()
    end

    self.current_music = self.music[name]
    self.current_music_name = name

    -- Set initial volume
    if fade_in > 0 then
        -- Start at 0 volume and fade in
        self.fade_time = 0
        self.fade_duration = fade_in
        self.fade_direction = 1
        self.target_volume = self.music_volume
        self.current_music:setVolume(0)
    else
        -- Play at full volume immediately
        self.current_music:setVolume(self.music_volume * self.master_volume)
    end

    self.current_music:play()
    print("Audio: Playing music '" .. name .. "'" .. (fade_in > 0 and " with " .. fade_in .. "s fade in" or ""))
end

-- Stop the currently playing music with optional fade out
-- @param fade_out: number (optional) - fade out duration in seconds
function Audio:stop_music(fade_out)
    fade_out = fade_out or 0

    if not self.current_music then
        return
    end

    if fade_out > 0 then
        -- Fade out before stopping
        self.fade_time = 0
        self.fade_duration = fade_out
        self.fade_direction = -1
        self.target_volume = 0
        print("Audio: Stopping music with " .. fade_out .. "s fade out")
    else
        -- Stop immediately
        self.current_music:stop()
        self.current_music = nil
        self.current_music_name = nil
        print("Audio: Stopped music")
    end
end

-- Play a sound effect
-- @param name: string - name of the SFX to play
-- @param pitch: number (optional) - pitch multiplier (default 1.0)
-- @param volume: number (optional) - volume override (0.0-1.0, default uses sfx_volume)
function Audio:play_sfx(name, pitch, volume)
    if not self.sfx[name] then
        print("Audio: ERROR - SFX '" .. name .. "' not loaded")
        return
    end

    pitch = pitch or 1.0
    volume = volume or self.sfx_volume

    -- Clone the source to allow multiple simultaneous playback
    local sfx_instance = self.sfx[name]:clone()
    sfx_instance:setPitch(pitch)
    sfx_instance:setVolume(volume * self.master_volume)
    sfx_instance:play()

    -- Note: The clone will be garbage collected after it finishes playing
end

-- Set volume for a specific audio type
-- @param volume_type: string - "master", "music", or "sfx"
-- @param value: number - volume level (0.0 to 1.0)
function Audio:set_volume(volume_type, value)
    value = math.max(0, math.min(1, value)) -- Clamp to 0-1

    if volume_type == "master" then
        self.master_volume = value
        -- Update currently playing music volume
        if self.current_music then
            self.current_music:setVolume(self.music_volume * self.master_volume)
        end
    elseif volume_type == "music" then
        self.music_volume = value
        -- Update currently playing music volume
        if self.current_music then
            self.current_music:setVolume(self.music_volume * self.master_volume)
        end
    elseif volume_type == "sfx" then
        self.sfx_volume = value
        -- SFX volume will be applied to new sounds when they play
    else
        print("Audio: ERROR - Invalid volume type '" .. volume_type .. "' (use 'master', 'music', or 'sfx')")
    end

    print("Audio: Set " .. volume_type .. " volume to " .. value)
end

-- Get current volume for a specific audio type
-- @param volume_type: string - "master", "music", or "sfx"
-- @return number - current volume level (0.0 to 1.0)
function Audio:get_volume(volume_type)
    if volume_type == "master" then
        return self.master_volume
    elseif volume_type == "music" then
        return self.music_volume
    elseif volume_type == "sfx" then
        return self.sfx_volume
    else
        print("Audio: ERROR - Invalid volume type '" .. volume_type .. "'")
        return 0
    end
end

-- Update fade effects (call from love.update)
-- @param dt: number - delta time in seconds
function Audio:update(dt)
    if self.fade_duration > 0 and self.current_music then
        self.fade_time = self.fade_time + dt

        if self.fade_time >= self.fade_duration then
            -- Fade complete
            if self.fade_direction == -1 then
                -- Fade out complete - stop the music
                self.current_music:stop()
                self.current_music = nil
                self.current_music_name = nil
            else
                -- Fade in complete - set to target volume
                self.current_music:setVolume(self.target_volume * self.master_volume)
            end
            self.fade_duration = 0
            self.fade_time = 0
        else
            -- Apply fade
            local fade_progress = self.fade_time / self.fade_duration
            local current_vol

            if self.fade_direction == 1 then
                -- Fade in: 0 -> target_volume
                current_vol = fade_progress * self.target_volume
            else
                -- Fade out: current -> 0
                current_vol = (1 - fade_progress) * self.music_volume
            end

            self.current_music:setVolume(current_vol * self.master_volume)
        end
    end
end

-- Clean up all audio sources
function Audio:cleanup()
    -- Stop current music
    if self.current_music then
        self.current_music:stop()
        self.current_music = nil
        self.current_music_name = nil
    end

    -- Release all music sources
    for name, source in pairs(self.music) do
        source:stop()
        source:release()
    end
    self.music = {}

    -- Release all SFX sources
    for name, source in pairs(self.sfx) do
        source:stop()
        source:release()
    end
    self.sfx = {}

    print("Audio: Cleanup complete")
end

return Audio
