local L = require("lib/l")

local UI = {}

function UI.newButton(xCord, yCord, btnWidth, btnHeight, tag, buttonList, sprite, scale, hoverAnim, pressAnim, hoveredAnim, buttonText, xOffset)
    local newBtn = {
        x = xCord,
        y = yCord,
        w = btnWidth,
        h = btnHeight,
        tag = tag,
        isPressed = false,
        sprite = sprite,
        originalSprite = sprite, -- Remember the base sprite to return to
        s = scale or 1,
        hoverAnimation = hoverAnim,
        pressAnim = pressAnim,
        hoveredAnim = hoveredAnim,
        state = "idle",
        buttonText = buttonText,
        xOffset = xOffset or 50,
    }

    if newBtn.sprite then
        local realWidth, realHeight = L.obj_dims(newBtn)
        newBtn.w = realWidth
        newBtn.h = realHeight
    end

    table.insert(buttonList, newBtn)
    
    return newBtn
end

local function buttonAnime(sprite, t, btn)
    if not sprite then return end
    btn.sprite = sprite
    btn.sprite_t = t
    btn.sprite_start = L.time()
end

local function isAnimFinished(btn)
    if not btn.sprite_t then return true end
    
    if btn.sprite_t > 0 then
        return L.sprite_finished(btn)
    else
        -- When playing backwards, L.sprite_cycle_count drops to -2
        return L.sprite_cycle_count(btn) <= -2 
    end
end

function UI.update(buttonList)
    local mouse = L.get_mouse()
    local isClicking = L.mouse_pressed(1)

    for _, btn in ipairs(buttonList) do
        local leftEdge = btn.x - (btn.w / 2)
        local rightEdge = btn.x + (btn.w / 2)
        local topEdge = btn.y - (btn.h / 2)
        local bottomEdge = btn.y + (btn.h / 2)

        -- Determine physical hover
        local currentlyHovered = mouse.x >= leftEdge and mouse.x <= rightEdge and mouse.y >= topEdge and mouse.y <= bottomEdge
        
        btn.isPressed = currentlyHovered and isClicking
        if btn.isPressed then
            btn.sprite = btn.pressAnim
        end
        -- State Machine Logic
        if currentlyHovered then
            -- If we just entered the button (or are retreating from an unhover)
            if btn.state == "idle" or btn.state == "unhovering" then
                btn.state = "hovering"
                buttonAnime(btn.hoverAnimation, 0.1, btn)
                
            -- If we are currently playing the enter animation
            elseif btn.state == "hovering" then
                if isAnimFinished(btn) then
                    btn.state = "hovered"
                    btn.sprite = btn.hoveredAnim
                    btn.sprite_t = nil -- Stop the animation frame timer
                end
            end
            
        else
            -- If we just left the button
            if btn.state == "hovered" or btn.state == "hovering" then
                btn.state = "unhovering"
                buttonAnime(btn.hoverAnimation, -0.1, btn) -- Play backwards
                
            -- If we are waiting for the exit animation to finish
            elseif btn.state == "unhovering" then
                if isAnimFinished(btn) then
                    btn.state = "idle"
                    btn.sprite = btn.originalSprite
                    btn.sprite_t = nil
                end
            end
        end
    end
end

function UI.isButtonPressed(buttonTag, buttonList)
    for _, btn in ipairs(buttonList) do
        if btn.tag == buttonTag then
            return btn.isPressed
        end
    end
    return false
end

function UI.render(buttonList)
    for _, btn in ipairs(buttonList) do
        if not btn.sprite then
            L.draw(L.patch(btn, { debug = true })) 
        else
            L.draw(btn)
            L.draw({c="#000000", text=btn.buttonText, font="pixelifysans", font_size=36, align="mm", x=btn.x+btn.xOffset, y=btn.y})
        end
    end
end

return UI