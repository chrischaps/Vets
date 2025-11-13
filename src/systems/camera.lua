-- camera.lua
-- Camera system using hump.camera for smooth player following

local Camera = require("libraries.camera")

local CameraSystem = {}
CameraSystem.__index = CameraSystem

-- Create a new camera system
function CameraSystem.new(x, y)
    local self = setmetatable({}, CameraSystem)

    -- Initialize hump camera
    self.camera = Camera(x or 0, y or 0)

    -- Camera target (entity to follow)
    self.target = nil

    -- Camera smoothing factor (0-1, lower = smoother/slower)
    -- 0.1 means camera moves 10% of the distance each frame
    self.smoothing = 0.1

    -- Camera offset from target (for look-ahead, etc.)
    self.offset_x = 0
    self.offset_y = 0

    -- Camera bounds (optional, nil = no bounds)
    self.min_x = nil
    self.max_x = nil
    self.min_y = nil
    self.max_y = nil

    -- Camera shake (future feature)
    self.shake_x = 0
    self.shake_y = 0

    return self
end

-- Set the camera target (entity with transform component)
function CameraSystem:setTarget(target)
    self.target = target
end

-- Set camera smoothing factor (0-1)
function CameraSystem:setSmoothing(smoothing)
    self.smoothing = math.max(0, math.min(1, smoothing))
end

-- Set camera offset from target
function CameraSystem:setOffset(offset_x, offset_y)
    self.offset_x = offset_x or 0
    self.offset_y = offset_y or 0
end

-- Set camera bounds (restricts camera movement)
function CameraSystem:setBounds(min_x, min_y, max_x, max_y)
    self.min_x = min_x
    self.min_y = min_y
    self.max_x = max_x
    self.max_y = max_y
end

-- Update camera position (smooth following)
function CameraSystem:update(dt)
    if not self.target or not self.target.transform then
        return
    end

    -- Get target position
    local target_x = self.target.transform.x + self.offset_x
    local target_y = self.target.transform.y + self.offset_y

    -- Get current camera position
    local cam_x, cam_y = self.camera:position()

    -- Smooth lerp to target position
    -- Higher smoothing = faster following
    -- Lower smoothing = smoother/slower following
    local new_x = cam_x + (target_x - cam_x) * self.smoothing
    local new_y = cam_y + (target_y - cam_y) * self.smoothing

    -- Apply camera shake (if any)
    new_x = new_x + self.shake_x
    new_y = new_y + self.shake_y

    -- Apply camera bounds (if set)
    if self.min_x and new_x < self.min_x then
        new_x = self.min_x
    end
    if self.max_x and new_x > self.max_x then
        new_x = self.max_x
    end
    if self.min_y and new_y < self.min_y then
        new_y = self.min_y
    end
    if self.max_y and new_y > self.max_y then
        new_y = self.max_y
    end

    -- Update camera position
    self.camera:lookAt(new_x, new_y)

    -- Decay shake over time
    self.shake_x = self.shake_x * 0.9
    self.shake_y = self.shake_y * 0.9

    -- Clear shake when very small
    if math.abs(self.shake_x) < 0.01 then self.shake_x = 0 end
    if math.abs(self.shake_y) < 0.01 then self.shake_y = 0 end
end

-- Begin camera transform (call before drawing world)
function CameraSystem:attach()
    self.camera:attach()
end

-- End camera transform (call after drawing world)
function CameraSystem:detach()
    self.camera:detach()
end

-- Get camera position
function CameraSystem:getPosition()
    return self.camera:position()
end

-- Set camera position directly (no smoothing)
function CameraSystem:setPosition(x, y)
    self.camera:lookAt(x, y)
end

-- Zoom camera
function CameraSystem:setZoom(zoom)
    self.camera:zoom(zoom)
end

-- Rotate camera
function CameraSystem:setRotation(rotation)
    self.camera:rotate(rotation)
end

-- Shake camera (for effects like explosions)
function CameraSystem:shake(intensity)
    self.shake_x = (math.random() - 0.5) * intensity
    self.shake_y = (math.random() - 0.5) * intensity
end

-- Convert screen coordinates to world coordinates
function CameraSystem:screenToWorld(x, y)
    return self.camera:worldCoords(x, y)
end

-- Convert world coordinates to screen coordinates
function CameraSystem:worldToScreen(x, y)
    return self.camera:cameraCoords(x, y)
end

return CameraSystem
