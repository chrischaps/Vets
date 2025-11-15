-- input.lua
-- Input abstraction layer for keyboard and gamepad inputs
-- Maps multiple input devices to game actions

local Input = {}
Input.__index = Input

-- Action definitions with their key/button bindings
-- Each action maps to multiple possible inputs
local ACTION_BINDINGS = {
    left = {
        keyboard = {"a", "left"},
        gamepad = {
            buttons = {"dpleft"},  -- D-pad left
            axis = {name = "leftx", direction = -1}  -- Left stick
        }
    },
    right = {
        keyboard = {"d", "right"},
        gamepad = {
            buttons = {"dpright"},  -- D-pad right
            axis = {name = "leftx", direction = 1}  -- Left stick
        }
    },
    up = {
        keyboard = {"w", "up"},
        gamepad = {
            buttons = {"dpup"},  -- D-pad up
            axis = {name = "lefty", direction = -1}  -- Left stick up
        }
    },
    down = {
        keyboard = {"s", "down"},
        gamepad = {
            buttons = {"dpdown"},  -- D-pad down
            axis = {name = "lefty", direction = 1}  -- Left stick down
        }
    },
    jump = {
        keyboard = {"space"},
        gamepad = {
            buttons = {"a"},  -- A button
            axis = nil
        }
    },
    dash = {
        keyboard = {"lshift", "rshift", "x", "z"},
        gamepad = {
            buttons = {"x", "rightshoulder"},  -- X button or RB
            axis = nil
        }
    },
    deliver = {
        keyboard = {"e"},
        gamepad = {
            buttons = {"b", "y"},  -- B button or Y button
            axis = nil
        }
    },
    pause = {
        keyboard = {"p", "escape"},
        gamepad = {
            buttons = {"start"},
            axis = nil
        }
    }
}

-- Create new input manager
function Input.new()
    local self = setmetatable({}, Input)

    -- Track current state of each action
    self.actions = {}

    -- Track previous state for edge detection (pressed/released)
    self.previous_actions = {}

    -- Initialize all actions to false
    for action, _ in pairs(ACTION_BINDINGS) do
        self.actions[action] = false
        self.previous_actions[action] = false
    end

    -- Connected joysticks
    self.joysticks = {}

    -- Gamepad axis dead zone (to prevent drift)
    self.axis_deadzone = 0.15

    -- Input buffer system (stores action press with frame counter)
    -- Each buffered action stores remaining frames before it expires
    self.buffer = {}

    return self
end

-- Initialize input system and detect joysticks
function Input:init()
    -- Get all connected joysticks
    self.joysticks = love.joystick.getJoysticks()

    if #self.joysticks > 0 then
        print("Input system initialized:")
        print("  - " .. #self.joysticks .. " gamepad(s) connected")
        for i, joystick in ipairs(self.joysticks) do
            print("    " .. i .. ": " .. joystick:getName())
            if joystick:isGamepad() then
                print("      Type: Gamepad (supports standard mapping)")
            else
                print("      Type: Joystick (no standard mapping)")
            end
        end
        print("  - Axis deadzone: " .. self.axis_deadzone)
    else
        print("Input system initialized:")
        print("  - No gamepads connected")
        print("  - Axis deadzone: " .. self.axis_deadzone)
        print("  - Gamepads will be detected on hot-plug")
    end
end

-- Update input state (call once per frame)
function Input:update()
    -- Save previous state for edge detection
    for action, state in pairs(self.actions) do
        self.previous_actions[action] = state
    end

    -- Update all action states
    for action, bindings in pairs(ACTION_BINDINGS) do
        self.actions[action] = self:checkAction(action, bindings)
    end

    -- Update input buffer (decay frame counters)
    self:update_buffer()
end

-- Check if an action is currently active (keyboard OR gamepad)
function Input:checkAction(action, bindings)
    -- Check keyboard inputs
    for _, key in ipairs(bindings.keyboard) do
        if love.keyboard.isDown(key) then
            return true
        end
    end

    -- Check gamepad inputs (if any joystick is connected)
    if #self.joysticks > 0 then
        local joystick = self.joysticks[1]  -- Use first connected gamepad

        -- Check gamepad buttons (now supports multiple buttons per action)
        if bindings.gamepad.buttons then
            for _, button in ipairs(bindings.gamepad.buttons) do
                if joystick:isGamepadDown(button) then
                    return true
                end
            end
        end

        -- Check gamepad axis (analog stick)
        if bindings.gamepad.axis then
            local axis_name = bindings.gamepad.axis.name
            local axis_direction = bindings.gamepad.axis.direction
            local axis_value = joystick:getGamepadAxis(axis_name)

            -- Apply deadzone
            if math.abs(axis_value) > self.axis_deadzone then
                -- Check if axis is in the correct direction
                if (axis_direction > 0 and axis_value > self.axis_deadzone) or
                   (axis_direction < 0 and axis_value < -self.axis_deadzone) then
                    return true
                end
            end
        end
    end

    return false
end

-- Check if an action is currently held down
function Input:is_down(action)
    return self.actions[action] or false
end

-- Check if an action was just pressed this frame (rising edge)
function Input:is_pressed(action)
    return self.actions[action] and not self.previous_actions[action]
end

-- Check if an action was just released this frame (falling edge)
function Input:is_released(action)
    return not self.actions[action] and self.previous_actions[action]
end

-- Get horizontal axis value (-1 for left, 1 for right, 0 for neutral)
-- This is a convenience function for movement
function Input:get_horizontal_axis()
    local left = self:is_down("left")
    local right = self:is_down("right")

    if left and not right then
        return -1
    elseif right and not left then
        return 1
    else
        return 0
    end
end

-- Get raw axis value from gamepad (for more granular control if needed)
-- Returns value in range [-1, 1] with deadzone applied
function Input:get_gamepad_axis(axis_name)
    if #self.joysticks > 0 then
        local joystick = self.joysticks[1]
        local value = joystick:getGamepadAxis(axis_name)

        -- Apply deadzone
        if math.abs(value) < self.axis_deadzone then
            return 0
        end

        return value
    end

    return 0
end

-- Add a new action binding (for extensibility)
-- Example: Input:add_action("crouch", {"lctrl", "c"}, {"y"})
function Input:add_action(action_name, keyboard_keys, gamepad_buttons, gamepad_axis)
    ACTION_BINDINGS[action_name] = {
        keyboard = keyboard_keys or {},
        gamepad = {
            buttons = gamepad_buttons or {},
            axis = gamepad_axis
        }
    }

    self.actions[action_name] = false
    self.previous_actions[action_name] = false

    print("Input: Added new action '" .. action_name .. "'")
end

-- Remove an action binding
function Input:remove_action(action_name)
    ACTION_BINDINGS[action_name] = nil
    self.actions[action_name] = nil
    self.previous_actions[action_name] = nil

    print("Input: Removed action '" .. action_name .. "'")
end

-- Handle joystick connection (call from love.joystickadded)
function Input:joystick_added(joystick)
    table.insert(self.joysticks, joystick)
    print("Input: Gamepad connected - " .. joystick:getName())
end

-- Handle joystick disconnection (call from love.joystickremoved)
function Input:joystick_removed(joystick)
    for i, j in ipairs(self.joysticks) do
        if j == joystick then
            table.remove(self.joysticks, i)
            print("Input: Gamepad disconnected - " .. joystick:getName())
            break
        end
    end
end

-- Set axis deadzone (default is 0.3)
function Input:set_deadzone(deadzone)
    self.axis_deadzone = math.max(0, math.min(1, deadzone))
    print("Input: Deadzone set to " .. self.axis_deadzone)
end

-- Get list of all available actions
function Input:get_actions()
    local action_list = {}
    for action, _ in pairs(ACTION_BINDINGS) do
        table.insert(action_list, action)
    end
    return action_list
end

-- Debug: Print current input state
function Input:debug_print()
    print("\n=== Input State ===")
    for action, state in pairs(self.actions) do
        if state then
            print("  " .. action .. ": " .. (state and "DOWN" or "UP"))
        end
    end
    print("  Horizontal axis: " .. self:get_horizontal_axis())
    print("==================\n")
end

-- Input Buffering System
-- Allows storing an input press for a number of frames to make controls more forgiving

-- Buffer an action press for a specified number of frames
-- This stores the action input so it can be consumed later
-- Used for jump buffering (pressing jump before landing)
function Input:buffer_action(action, frames)
    self.buffer[action] = frames or 8
end

-- Check if a buffered action is available and consume it
-- Returns true if the action was buffered, false otherwise
-- This clears the buffer for the action
function Input:consume_buffer(action)
    if self.buffer[action] and self.buffer[action] > 0 then
        self.buffer[action] = 0
        return true
    end
    return false
end

-- Update buffer state (decay frame counters each frame)
-- This is called automatically in Input:update()
function Input:update_buffer()
    for action, frames in pairs(self.buffer) do
        if frames > 0 then
            self.buffer[action] = frames - 1
        end
    end
end

-- Check if an action is currently buffered
-- Returns true if the action has remaining buffer frames
function Input:is_buffered(action)
    return self.buffer[action] and self.buffer[action] > 0
end

return Input
