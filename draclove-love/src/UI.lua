local L = require("lib/l")

local UI = {}

-- Create the button with width and height
function UI.newButton(xCord, yCord, btnWidth, btnHeight, tag, buttonList)
    local newBtn = {
        x = xCord,
        y = yCord,
        w = btnWidth,
        h = btnHeight,
        tag = tag,
        isHovered = false,
        isPressed = false
    }
    table.insert(buttonList, newBtn)
    
    return newBtn
end

-- Update loop 
function UI.update(buttonList)
    local mouse = L.get_mouse()
    
    local isClicking = love.mouse.isDown(1) 

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
        L.draw(L.patch(btn, { debug = true })) 
    end
end

return UI