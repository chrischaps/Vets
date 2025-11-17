-- state_manager.lua
-- State management system for handling game flow between different screens/states
-- Supports state registration, switching with enter/exit callbacks, and state stacking

local StateManager = {}
StateManager.__index = StateManager

-- Create new state manager
function StateManager.new()
    local self = setmetatable({}, StateManager)

    -- State storage
    self.states = {}  -- Registered states by name
    self.current_state = nil  -- Currently active state
    self.previous_state = nil  -- Previous state (for back navigation)

    -- State stack (for pause/overlay states)
    self.state_stack = {}  -- Stack of states for pause functionality
    self.use_stack = false  -- Whether to use stack mode

    print("[StateManager] Initialized")

    return self
end

-- Register a state by name
-- @param name: String name for the state
-- @param state: State table with optional enter(), exit(), update(dt), draw() methods
function StateManager:register(name, state)
    if not name then
        error("[StateManager] Cannot register state: name is required")
    end

    if not state then
        error("[StateManager] Cannot register state '" .. name .. "': state is required")
    end

    -- Store the state
    self.states[name] = state

    print("[StateManager] Registered state: " .. name)
end

-- Switch to a different state
-- Calls exit() on current state and enter() on new state
-- @param name: Name of the state to switch to
-- @param ...: Optional parameters to pass to the new state's enter() method
function StateManager:switch(name, ...)
    if not name then
        error("[StateManager] Cannot switch state: name is required")
    end

    local new_state = self.states[name]
    if not new_state then
        error("[StateManager] Cannot switch to unregistered state: " .. name)
    end

    -- Call exit on current state if it exists
    if self.current_state then
        if self.current_state.exit then
            self.current_state:exit()
        end

        -- Store as previous state
        self.previous_state = self.current_state
    end

    -- Switch to new state
    self.current_state = new_state

    -- Call enter on new state if it exists
    if self.current_state.enter then
        self.current_state:enter(...)
    end

    print("[StateManager] Switched to state: " .. name)
end

-- Push a state onto the stack (for pause/overlay functionality)
-- The current state remains in memory but is not updated/drawn
-- @param name: Name of the state to push
-- @param ...: Optional parameters to pass to the new state's enter() method
function StateManager:push(name, ...)
    if not name then
        error("[StateManager] Cannot push state: name is required")
    end

    local new_state = self.states[name]
    if not new_state then
        error("[StateManager] Cannot push unregistered state: " .. name)
    end

    -- Push current state onto stack if it exists
    if self.current_state then
        table.insert(self.state_stack, self.current_state)
    end

    -- Switch to new state
    self.current_state = new_state

    -- Call enter on new state if it exists
    if self.current_state.enter then
        self.current_state:enter(...)
    end

    self.use_stack = true

    print("[StateManager] Pushed state: " .. name .. " (stack size: " .. #self.state_stack .. ")")
end

-- Pop the top state from the stack and return to previous state
-- Calls exit() on current state but does NOT call enter() on restored state
-- (The restored state was never exited, so it doesn't need to be re-entered)
function StateManager:pop()
    if #self.state_stack == 0 then
        print("[StateManager] Warning: Cannot pop state, stack is empty")
        return
    end

    -- Call exit on current state if it exists
    if self.current_state and self.current_state.exit then
        self.current_state:exit()
    end

    -- Pop previous state from stack
    self.current_state = table.remove(self.state_stack)

    -- NOTE: Do NOT call enter() on restored state
    -- The state was never exited when pushed, so it shouldn't be re-entered
    -- This prevents the state from being re-initialized

    -- Disable stack mode if stack is empty
    if #self.state_stack == 0 then
        self.use_stack = false
    end

    print("[StateManager] Popped state (stack size: " .. #self.state_stack .. ")")
end

-- Update the current state
-- @param dt: Delta time in seconds
function StateManager:update(dt)
    if self.current_state and self.current_state.update then
        self.current_state:update(dt)
    end
end

-- Draw the current state
function StateManager:draw()
    if self.current_state and self.current_state.draw then
        self.current_state:draw()
    end
end

-- Get the current state
-- @return: Current state table or nil
function StateManager:current()
    return self.current_state
end

-- Get the previous state
-- @return: Previous state table or nil
function StateManager:previous()
    return self.previous_state
end

-- Check if a state is registered
-- @param name: Name of the state to check
-- @return: Boolean indicating if state is registered
function StateManager:hasState(name)
    return self.states[name] ~= nil
end

-- Get the current state stack size
-- @return: Number of states in the stack
function StateManager:getStackSize()
    return #self.state_stack
end

-- Check if the state manager is using stack mode
-- @return: Boolean indicating if stack mode is active
function StateManager:isUsingStack()
    return self.use_stack
end

return StateManager
