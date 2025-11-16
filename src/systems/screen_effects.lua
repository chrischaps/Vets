-- src/systems/screen_effects.lua
-- Screen transition effects system for success/failure states

local ScreenEffects = {}

--[[
  Creates a fade effect that transitions a colored overlay from transparent to opaque

  Parameters:
    color: {r, g, b} - RGB color values (0-255)
    duration: number - Fade duration in seconds
    callback: function - Called when fade completes (optional)

  Returns:
    Fade effect object with update/draw methods
]]
function ScreenEffects.createFade(color, duration, callback)
  return {
    color = color or {255, 255, 255},
    duration = duration or 1.0,
    elapsed = 0,
    alpha = 0,
    callback = callback,
    completed = false
  }
end

--[[
  Updates a fade effect

  Parameters:
    fade: fade effect object
    dt: delta time in seconds

  Returns:
    boolean - true if fade is still active, false if completed
]]
function ScreenEffects.updateFade(fade, dt)
  if fade.completed then
    return false
  end

  fade.elapsed = fade.elapsed + dt

  -- Calculate alpha progression (0 to 1)
  local progress = math.min(fade.elapsed / fade.duration, 1.0)
  fade.alpha = progress

  -- Check if fade is complete
  if progress >= 1.0 and not fade.completed then
    fade.completed = true
    if fade.callback then
      fade.callback()
    end
    return false
  end

  return true
end

--[[
  Draws a fade overlay on screen

  Parameters:
    fade: fade effect object
    screen_width: screen width in pixels
    screen_height: screen height in pixels
]]
function ScreenEffects.drawFade(fade, screen_width, screen_height)
  if fade.alpha > 0 then
    love.graphics.setColor(fade.color[1]/255, fade.color[2]/255, fade.color[3]/255, fade.alpha)
    love.graphics.rectangle('fill', 0, 0, screen_width, screen_height)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
  end
end

--[[
  Helper to freeze game updates while keeping rendering
  This is meant to be called from GameState

  Parameters:
    game_state: reference to GameState object
]]
function ScreenEffects.freezeGame(game_state)
  -- Set flag to stop updates but continue rendering
  game_state.frozen = true
  game_state.player:freeze()

  -- Pause timer if it exists
  if game_state.timer then
    game_state.timer:pause()
  end
end

--[[
  Unfreezes game (mainly for testing or canceling transitions)

  Parameters:
    game_state: reference to GameState object
]]
function ScreenEffects.unfreezeGame(game_state)
  game_state.frozen = false
  game_state.player:unfreeze()

  if game_state.timer and not game_state.timer.paused then
    game_state.timer:resume()
  end
end

return ScreenEffects
