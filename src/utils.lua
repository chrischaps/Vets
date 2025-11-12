-- src/utils.lua
-- Utility functions for Courier Cat

local utils = {}

-- Math Utilities

-- Clamp a value between min and max
function utils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Linear interpolation between a and b by factor t (0-1)
function utils.lerp(a, b, t)
    return a + (b - a) * t
end

-- Sign function (-1, 0, or 1)
function utils.sign(value)
    if value > 0 then return 1 end
    if value < 0 then return -1 end
    return 0
end

-- Distance between two points
function utils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- Check if rectangles overlap (AABB collision)
function utils.aabb_overlap(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

-- Table Utilities

-- Deep copy a table
function utils.deep_copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end

    local s = seen or {}
    local res = {}
    s[obj] = res

    for k, v in pairs(obj) do
        res[utils.deep_copy(k, s)] = utils.deep_copy(v, s)
    end

    return setmetatable(res, getmetatable(obj))
end

-- Check if table contains value
function utils.table_contains(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- String Utilities

-- Split string by delimiter
function utils.split(str, delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end
    return result
end

-- Random Utilities

-- Random float between min and max
function utils.random_float(min, max)
    return min + (max - min) * math.random()
end

-- Random integer between min and max (inclusive)
function utils.random_int(min, max)
    return math.random(min, max)
end

-- Random choice from table
function utils.random_choice(table)
    return table[math.random(#table)]
end

-- ID Generation

local id_counter = 0
function utils.generate_id()
    id_counter = id_counter + 1
    return id_counter
end

return utils
