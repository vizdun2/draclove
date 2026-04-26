local L = require("lib/l")
local UI = require("src/UI")
local BS = {}

local buttons = {}
function BS.setup()
    buttons = {}
    UI.newButton(-L.width/2+100,-250,-L.height/2+200,20,"continue", buttons, "UI/button_idle", 1.5, "UI/button_hover", "UI/button_click","UI/button_hovering","Continue",230)
end

function BS.loop()
    
    UI.update(buttons)
    L.draw({x=0,y=0, sprite="UI/background", rainbow=true, s=6.66})
    L.draw({c="#000000", text="You scared little fuckboy?", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=40})
    if UI.isButtonPressed("continue", buttons) then
        L.start_time()
        return
    end
    UI.render(buttons)
end

return BS