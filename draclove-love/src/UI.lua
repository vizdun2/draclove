local L = require("lib/l")

local UI = {}

-- Create the button with width and height
function UI.newButton(xCord, yCord, btnWidth, btnHeight, tag, buttonList, sprite, scale, hoverAnim, pressAnim, hoveredAnim)
    local newBtn = {
        x = xCord,
        y = yCord,
        w = btnWidth,
        h = btnHeight,
        tag = tag,
        isHovered = false,
        isPressed = false,
        sprite = sprite,
        s = scale or 1,
        hoverAnimation = hoverAnim,
        pressAnim = pressAnim,
        hoveredAnim = hoveredAnim,
        isAnimating = false,
    }

    if newBtn.sprite then
        local realWidth, realHeight = L.obj_dims(newBtn)
        newBtn.w = realWidth
        newBtn.h = realHeight
    end

    table.insert(buttonList, newBtn)
    
    return newBtn
end
local function button_anime(sprite, t, btn)
    btn.sprite = sprite
    btn.sprite_t = t
    btn.sprite_start = L.time()
    btn.isAnimating = true
end

-- Update loop 
function UI.update(buttonList)
    local mouse = L.get_mouse()
    
    local isClicking = L.mouse_down(1) 

    for _, btn in ipairs(buttonList) do
        local leftEdge = btn.x - (btn.w / 2)
        local rightEdge = btn.x + (btn.w / 2)
        local topEdge = btn.y - (btn.h / 2)
        local bottomEdge = btn.y + (btn.h / 2)

        if mouse.x >= leftEdge and mouse.x <= rightEdge and mouse.y >= topEdge and mouse.y <= bottomEdge then
            btn.isHovered = true
            btn.isPressed = isClicking
        else
            btn.isHovered = false
            btn.isPressed = false
        end
        if btn.isHovered and not btn.isAnimating then
            button_anime(btn.hoverAnimation, 0.1, btn)
        end
    end
end

-- Check if a specific button is pressed
function UI.isButtonPressed(buttonTag, buttonList)
    for _, btn in ipairs(buttonList) do
        if btn.tag == buttonTag then
            return btn.isPressed
        end
    end
    return false
end

-- debug draw
function UI.render(buttonList)
    for _, btn in ipairs(buttonList) do
        if not btn.sprite then
        L.draw(L.patch(btn, { debug = true })) 
        else
            L.draw(btn)
        end
    end
end

return UI