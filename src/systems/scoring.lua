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

    return self
end

-- Reset score to initial state
function Scoring:reset()
    self.total_score = 0
    self.deliveries = 0
    self.delivery_score = 0
    self.time_bonus = 0
    self.completion_bonus = 0
end

-- Award points for a delivery
function Scoring:addDelivery()
    self.deliveries = self.deliveries + 1
    self.delivery_score = self.delivery_score + Scoring.BASE_DELIVERY_SCORE
    self:updateTotal()

    return Scoring.BASE_DELIVERY_SCORE
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

-- Get score breakdown for display
function Scoring:getBreakdown()
    return {
        deliveries = self.deliveries,
        delivery_score = self.delivery_score,
        time_bonus = self.time_bonus,
        completion_bonus = self.completion_bonus,
        total = self.total_score
    }
end

-- Display score information (for debugging)
function Scoring:printBreakdown()
    print("\n=== SCORE BREAKDOWN ===")
    print(string.format("Deliveries: %d × %d = %d points",
        self.deliveries, Scoring.BASE_DELIVERY_SCORE, self.delivery_score))

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
