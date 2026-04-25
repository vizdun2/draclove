local L = require("lib/l")
local UI = require("src/UI")
local MM = {}

local buttons = {}
function MM.setup()
    buttons = {}
    if L.failedLevel then
        UI.newButton(-L.width/2+100,-250,40,20,"continueGame", buttons, "UI/button_idle", 1.5, "UI/button_hover", "UI/button_click","UI/button_hovering","Continue Game",200)
        UI.newButton(-L.width/2+100,-130,40,20,"abondonRun", buttons, "UI/button_idle", 1.5, "UI/button_hover", "UI/button_click","UI/button_hovering","AbondonRun",180)
        UI.newButton(-L.width/2+100,-10,40,20,"controls", buttons, "UI/button_idle", 1.5, "UI/button_hover", "UI/button_click","UI/button_hovering","Controls", 150)
    elseif not L.failedLevel then
        UI.newButton(-L.width/2+100,-250,40,20,"startGame", buttons, "UI/button_idle", 1.5, "UI/button_hover", "UI/button_click","UI/button_hovering","Start Game",180)
        UI.newButton(-L.width/2+100,-130,40,20,"controls", buttons, "UI/button_idle", 1.5, "UI/button_hover", "UI/button_click","UI/button_hovering","Controls", 150)
    end
end

-- Converts HSL to RGB. (input and output range: 0 - 1)
function HSL(h, s, l, a)
	if s<=0 then return l,l,l,a end
	h, s, l = h*6, s, l
	local c = (1-math.abs(2*l-1))*s
	local x = (1-math.abs(h%2-1))*c
	local m,r,g,b = (l-.5*c), 0,0,0
	if h < 1     then r,g,b = c,x,0
	elseif h < 2 then r,g,b = x,c,0
	elseif h < 3 then r,g,b = 0,c,x
	elseif h < 4 then r,g,b = 0,x,c
	elseif h < 5 then r,g,b = x,0,c
	else              r,g,b = c,0,x
	end return r+m, g+m, b+m, a
end

function MM.loop()
    UI.update(buttons)
    L.draw({sprite="UI/background_saturated", s=6.66, c="0000FF"})
    L.draw({text="Sylvia Path", font="pixelifysans", font_size=100, align="mm", x=L.width/2-300, y=-L.height/2+80})
    if UI.isButtonPressed("startGame", buttons) then
        L.active_level_i = 1
        L.reset()
        return
    end
    if UI.isButtonPressed("continueGame", buttons) then
        L.active_level_i = L.failedLevel or 1
        L.reset()
        return
    end
    if UI.isButtonPressed("abondonRun", buttons) then
        L.failedLevel = nil
        L.reset()
        return
    end
    if UI.isButtonPressed("controls", buttons) then
        L.active_level_i = L.controls
        L.reset()
        return
    end
    UI.render(buttons)
end

return MM