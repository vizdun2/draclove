local L = require("lib/l")
local UI = require("src/UI")
local OS = {}

local buttons = {}
function OS.setup()
    if Audio_source ~=nil then
        Audio_source:stop()
    end
    buttons = {}
    UI.newButton(-L.width/2+100,-250,40,20,"restart", buttons, "UI/button_idle", 1.5, "UI/button_hover", "UI/button_click","UI/button_hovering","Restart",140)
    UI.newButton(-L.width/2+100,-130,40,20,"mainMenu", buttons, "UI/button_idle", 1.5, "UI/button_hover", "UI/button_click","UI/button_hovering","Main menu", 150)
end

function OS.loop()
    UI.update(buttons)
    L.draw({x=0,y=0, sprite="UI/background", rainbow=true, s=6.66})
    L.draw({c="#000000", text="Game Over", font="pixelifysans", font_size=100, align="mm", x=L.width/2-300, y=-L.height/2+80})
    if UI.isButtonPressed("restart", buttons) then
        L.nextLevel = L.failedLevel or 1
		L.active_level_i = L.transition
        L.reset()
        return true
    end
    if UI.isButtonPressed("mainMenu", buttons) then
        L.active_level_i = L.mainMenu
        L.reset()
        return true
    end
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