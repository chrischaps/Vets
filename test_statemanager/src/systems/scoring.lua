-- scoring.lua
-- Scoring system for tracking player score

local Scoring = {}
Scoring.__index = Scoring

-- Score constants
Scoring.BASE_DELIVERY_SCORE = 100  -- Points per delivery
Scoring.TIME_BONUS_MULTIPLIER = 10  -- Points per second remaining
Scoring.COMPLETION_BONUS = 500     -- Bonus for completing all deliveries

-- Create a new scoring system
function Scoring.new()
    local self = setmetatable({}, Scoring)

    -- Score tracking
    self.total_score = 0
    self.deliveries = 0
    self.delivery_score = 0  -- Running total of delivery points
    self.time_bonus = 0      -- Time bonus (calculated at completion)
    self.completion_bonus = 0  -- Completion bonus (awarded at win)

    -- Combo tracking (VETS-28)
    self.combo_count = 0  -- Current consecutive deliveries without ground touch
    self.current_multiplier = 1  -- Current combo multiplier

    return self
end

-- Reset score to initial state
function Scoring:reset()
    self.total_score = 0
    self.deliveries = 0
    self.delivery_score = 0
    self.time_bonus = 0
    self.completion_bonus = 0
    self.combo_count = 0
    self.current_multiplier = 1
end

-- Award points for a delivery with combo multiplier (VETS-28)
-- @param combo_count: Number of consecutive deliveries without ground touch
-- @return: Points awarded for this delivery
function Scoring:addDelivery(combo_count)
    self.deliveries = self.deliveries + 1

    -- Update combo count
    self.combo_count = combo_count or 0

    -- Calculate combo multiplier: floor(consecutive_deliveries / 2) + 1
    -- Examples: 1→1x, 2-3→2x, 4-5→3x, 6-7→4x, 8+→5x
    self.current_multiplier = math.floor(self.combo_count / 2) + 1

    -- Cap multiplier at 5x
    self.current_multiplier = math.min(self.current_multiplier, 5)

    -- Calculate score with multiplier
    local points = Scoring.BASE_DELIVERY_SCORE * self.current_multiplier
    self.delivery_score = self.delivery_score + points
    self:updateTotal()

    return points
end

-- Calculate and add time bonus based on remaining seconds
function Scoring:calculateTimeBonus(seconds_remaining)
    -- Time bonus is only awarded at completion
    -- Calculate: remaining seconds × 10
    self.time_bonus = math.floor(seconds_remaining * Scoring.TIME_BONUS_MULTIPLIER)
    self:updateTotal()

    return self.time_bonus
end

-- Award completion bonus for finishing all deliveries
function Scoring:awardCompletionBonus()
    self.completion_bonus = Scoring.COMPLETION_BONUS
    self:updateTotal()

    return self.completion_bonus
end

-- Update total score from all components
function Scoring:updateTotal()
    self.total_score = self.delivery_score + self.time_bonus + self.completion_bonus
end

-- Get total score
function Scoring:getTotal()
    return self.total_score
end

-- Get delivery count
function Scoring:getDeliveries()
    return self.deliveries
end

-- Get current combo count (VETS-28)
function Scoring:getComboCount()
    return self.combo_count
end

-- Get current combo multiplier (VETS-28)
function Scoring:getComboMultiplier()
    return self.current_multiplier
end

-- Reset combo (called when player touches ground) (VETS-28)
function Scoring:resetCombo()
    self.combo_count = 0
    self.current_multiplier = 1
end

-- Get score breakdown for display
function Scoring:getBreakdown()
    return {
        deliveries = self.deliveries,
        delivery_score = self.delivery_score,
        time_bonus = self.time_bonus,
        completion_bonus = self.completion_bonus,
        total = self.total_score,
        combo_count = self.combo_count,
        combo_multiplier = self.current_multiplier
    }
end

-- Display score information (for debugging)
function Scoring:printBreakdown()
    print("\n=== SCORE BREAKDOWN ===")
    print(string.format("Deliveries: %d", self.deliveries))
    print(string.format("Delivery Score: %d points", self.delivery_score))

    if self.combo_count > 0 then
        print(string.format("Current Combo: %dx (multiplier: %dx)",
            self.combo_count, self.current_multiplier))
    end

    if self.time_bonus > 0 then
        local seconds = self.time_bonus / Scoring.TIME_BONUS_MULTIPLIER
        print(string.format("Time Bonus: %.1f seconds × %d = %d points",
            seconds, Scoring.TIME_BONUS_MULTIPLIER, self.time_bonus))
    end

    if self.completion_bonus > 0 then
        print(string.format("Completion Bonus: %d points", self.completion_bonus))
    end

    print(string.format("TOTAL SCORE: %d points", self.total_score))
    print("======================\n")
end

return Scoring
