local L = require("lib/l")
local UI = require("src/UI")
local BS = {}

function BS.setup()
end

function BS.loop()
    
    L.draw({x=0,y=0, sprite="UI/background", rainbow=true, s=6.66})
    L.draw({c="#000000", text="Press esc to continue", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+100 })
    L.draw({c="#000000", text="You scared?", font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+50})
    return true
end
function BS.startScene()
    return false
end
function BS.endScene()
    return false
end
return BS