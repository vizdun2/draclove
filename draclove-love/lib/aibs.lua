-- Vector helpers
local function dot(a, b)
    return a.x * b.x + a.y * b.y
end

local function subtract(a, b)
    return {x = a.x - b.x, y = a.y - b.y}
end

local function normalize(v)
    local len = math.sqrt(v.x * v.x + v.y * v.y)
    return {x = v.x / len, y = v.y / len}
end

-- Get rectangle corners
local function getCorners(rect)
    local cx, cy = rect.x, rect.y
    local w, h = rect.w / 2, rect.h / 2
    local angle = rect.angle

    local cosA = math.cos(angle)
    local sinA = math.sin(angle)

    local corners = {
        {x = -w, y = -h},
        {x =  w, y = -h},
        {x =  w, y =  h},
        {x = -w, y =  h}
    }

    for i, p in ipairs(corners) do
        local x = p.x * cosA - p.y * sinA + cx
        local y = p.x * sinA + p.y * cosA + cy
        corners[i] = {x = x, y = y}
    end

    return corners
end

-- Project points onto axis
local function project(points, axis)
    local min = dot(points[1], axis)
    local max = min

    for i = 2, #points do
        local p = dot(points[i], axis)
        if p < min then min = p end
        if p > max then max = p end
    end

    return min, max
end

-- Check overlap
local function overlap(minA, maxA, minB, maxB)
    return maxA >= minB and maxB >= minA
end

-- Main collision function
local function rotatedRectCollision(a, b)
    local cornersA = getCorners(a)
    local cornersB = getCorners(b)

    local axes = {}

    -- Get axes (edge normals)
    local function addAxes(corners)
        for i = 1, 4 do
            local p1 = corners[i]
            local p2 = corners[i % 4 + 1]
            local edge = subtract(p2, p1)
            local normal = normalize({x = -edge.y, y = edge.x})
            table.insert(axes, normal)
        end
    end

    addAxes(cornersA)
    addAxes(cornersB)

    -- SAT test
    for _, axis in ipairs(axes) do
        local minA, maxA = project(cornersA, axis)
        local minB, maxB = project(cornersB, axis)

        if not overlap(minA, maxA, minB, maxB) then
            return false -- Separating axis found
        end
    end
    
    return true -- No separating axis → collision
end

return rotatedRectCollision