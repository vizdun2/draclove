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
    L.draw({text="Controls", font="pixelifysans", font_size=100, align="mm", x=L.width/2-300, y=-L.height/2+80})
    if UI.isButtonPressed("mainMenu", buttons) then
        L.active_level_i = L.mainMenu
        L.reset()
        return
    end
    L.draw({text="[a][d]", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+200})
    L.draw({text="'movement'", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+600, y=-L.height/2+200})
    L.draw({text="[space]", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+250})
    L.draw({text="'jump'", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+600, y=-L.height/2+250})
    L.draw({text="[space mid air]", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+300})
    L.draw({text="'double jump'", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+600, y=-L.height/2+300})
    L.draw({text="[x]/[n]", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+350})
    L.draw({text="'attack'", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+600, y=-L.height/2+350})
    L.draw({text="[c]/[m]", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+400})
    L.draw({text="'dodge'", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+600, y=-L.height/2+400})
    UI.render(buttons)
end

return OS