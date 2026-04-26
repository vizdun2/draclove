local L = require("lib/l")
local UI = require("src/UI")
local MM = {}

local buttons = {}
function MM.setup()
    buttons = {}
    if Audio_source ~= nil and Source_path ~= "audio/soundtrack/menu_music" then
        Audio_source:stop()
    elseif Audio_source == nil then
        Source_path = "audio/soundtrack/menu_music"
        Audio_source = L.play(Source_path,0.7)
        Audio_source:setLooping(true)
    end

    if L.failedLevel then
        UI.newButton(-L.width / 2 + 100, -250, 40, 20, "continueGame", buttons, "UI/button_idle", 1.5, "UI/button_hover",
            "UI/button_click", "UI/button_hovering", "Continue Game", 200)
        UI.newButton(-L.width / 2 + 100, -130, 40, 20, "abondonRun", buttons, "UI/button_idle", 1.5, "UI/button_hover",
            "UI/button_click", "UI/button_hovering", "AbondonRun", 180)
        UI.newButton(-L.width / 2 + 100, -10, 40, 20, "controls", buttons, "UI/button_idle", 1.5, "UI/button_hover",
            "UI/button_click", "UI/button_hovering", "Controls", 150)
    elseif not L.failedLevel then
        UI.newButton(-L.width / 2 + 100, -250, 40, 20, "startGame", buttons, "UI/button_idle", 1.5, "UI/button_hover",
            "UI/button_click", "UI/button_hovering", "Start Game", 180)
        UI.newButton(-L.width / 2 + 100, -130, 40, 20, "controls", buttons, "UI/button_idle", 1.5, "UI/button_hover",
            "UI/button_click", "UI/button_hovering", "Controls", 150)
    end
end

function MM.loop()
    UI.update(buttons)
    L.draw({ x = 0, y = 0, sprite = "UI/background", rainbow = true, s = 6.66 })
    L.draw({
        c = "#000000",
        text = "Sylvia Path",
        font = "pixelifysans",
        font_size = 100,
        align = "mm",
        x = L.width / 2 -
            300,
        y = -L.height / 2 + 80
    })
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
