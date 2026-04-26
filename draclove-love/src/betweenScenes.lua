local L = require("lib/l")
local UI = require("src/UI")
local BS = {}

local buttons = {}

local cutsceneMap = {
    [1] = "assets/cutscene.ogv", -- before initial level
    [2] = "assets/cutscene1",
    [3] = "assets/cutscene2",
    [4] = "assets/cutscene3",
    [5] = "assets/cutscene4",
    [6] = nil, -- after last elvel
}
local voiclineMap = {
    [1] = "WHerE iS MY mINd", -- before initial level
    [2] = "Munchies are far away still.",
    [3] = "Did you really just struggle to open the door?",
    [4] = "Godspeed you, black emperor",
    [5] = "Kitchen, my kitchen, far over the misty mountains rolled",
    [6] = "Lemon.", -- after last elvel
}

function BS.setup()
    buttons = {}
    UI.newButton(-L.width/2+100,-250,40,20,"goNext", buttons, "UI/button_idle", 1.5, "UI/button_hover", "UI/button_click","UI/button_hovering","Let the trip go on",230)

    local videoPath = cutsceneMap[L.nextLevel]
    BS.video = nil
    
    if videoPath and love.filesystem.getInfo(videoPath) then
        BS.video = love.graphics.newVideo(videoPath)
        BS.video:play()
    else
        L.printNoBs("No cutscene found or mapped for transition to level " .. tostring(L.nextLevel))
    end
end

function BS.loop()
    if BS.video and BS.video:isPlaying() then
        local vw, vh = BS.video:getDimensions()
        local sx, sy = L.width / vw, L.height / vh
        
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(BS.video, 0, 0, 0, sx, sy)
        
        if L.key_pressed("space") or L.key_pressed("escape") then
            BS.video:pause()
        end
        
        return true
    end
    
    UI.update(buttons)
    L.draw({x=0,y=0, sprite="UI/background", rainbow=true, s=6.66})
    L.draw({c="#000000", text=voiclineMap[L.nextLevel], font="pixelifysans", font_size=38, align="lm", x=-L.width/2+100, y=-L.height/2+200})
    
    if UI.isButtonPressed("goNext", buttons) then
        L.active_level_i = L.nextLevel or 1
        
        if BS.video then BS.video:pause(); BS.video = nil end 
        
        L.reset()
        return true
    end
    
    UI.render(buttons)
    return true
end

function BS.startScene()
    return false
end

function BS.endScene()
    return false
end

return BS