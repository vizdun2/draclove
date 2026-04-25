local L = require("lib/l")
local UI = require("src/UI")
local OS = {}

local buttons = {}
function OS.setup()
    UI.newButton(0,-250,40,20,"restart", buttons, "UI/button_idle", 1, "UI/button_hover", "UI/button_click","UI/button_idle")
end
function OS.loop()
    UI.update(buttons)
    if UI.isButtonPressed("restart", buttons) then
        L.active_level_i = L.failedLevel or 1
        L.reset()
        return
    end
    UI.render(buttons)
end

return OS