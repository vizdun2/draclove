local L = require("lib/l")

local LM = {}
function LM.setup()
    L.levels[L.active_level_i].setup()
end

function LM.startNewLevel(level)
    L.active_level = level
    if L.active_level.setup then
        L.active_level.setup()
    end
end
function LM.nextLevel()
    local currentIndex = nil
    for i, level in ipairs(L.levels) do
        if level == L.active_level then
            currentIndex = i
            break
        end
    end
    if currentIndex and currentIndex < #L.levels then
        LM.startNewLevel(L.levels[currentIndex + 1])
    else
        L.active_level = nil
        L.printNoBs("Congratulations! You've completed the game!")
    end
end
function LM.restartLevel()
    LM.startNewLevel(L.active_level)
end
function LM.loop(dt)
    if L.active_level and L.active_level.loop then
        L.active_level.loop(dt)
    end
end
return LM