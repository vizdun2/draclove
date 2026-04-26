local L = require("lib/l")
local UI = require("src/UI")
local OS = {}

local buttons = {}
function OS.setup()
    buttons = {}
    UI.newButton(-L.width/2+100,-250,40,20,"mainMenu", buttons, "UI/button_idle", 1.5, "UI/button_hover", "UI/button_click","UI/button_hovering","Go back",140)
end

function OS.loop()
    UI.update(buttons)
    L.draw({x=0,y=0, sprite="UI/background", rainbow=true, s=6.66})
    L.draw({c="#000000", text="Controls", font="pixelifysans", font_size=100, align="mm", x=L.width/2-300, y=-L.height/2+80})
    if UI.isButtonPressed("mainMenu", buttons) then
        L.active_level_i = L.mainMenu
        L.reset()
        return true
    end
    L.draw({c="#000000", text="[a][d]", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+200})
    L.draw({c="#000000", text="'movement'", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+600, y=-L.height/2+200})
    L.draw({c="#000000", text="[space]", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+250})
    L.draw({c="#000000", text="'jump'", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+600, y=-L.height/2+250})
    L.draw({c="#000000", text="[space mid air]", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+300})
    L.draw({c="#000000", text="'double jump'", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+600, y=-L.height/2+300})
    L.draw({c="#000000", text="[x]/[n]", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+350})
    L.draw({c="#000000", text="'attack'", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+600, y=-L.height/2+350})
    L.draw({c="#000000", text="[c]/[m]", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+400})
    L.draw({c="#000000", text="'dodge'", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+600, y=-L.height/2+400})
    UI.render(buttons)
    return true
end
function OS.startScene()
    return false
end
function OS.endScene()
    return false
end

return OS