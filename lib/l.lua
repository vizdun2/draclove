local rotated_rect_collision = require("lib/aibs")

local L = {
    width = 1280,
    height = 720,
    cam_x = 0,
    cam_y = 0,
    dt = 0,
    setup = function() end,
    render = function() end,
}

local square_size = 32
local square_canvas = love.graphics.newCanvas(square_size, square_size)
love.graphics.setCanvas(square_canvas)
love.graphics.clear(1,1,1,1)
love.graphics.setCanvas()

function hex_to_rgb(hex)
    local hex = hex:gsub("#","")
    local r = tonumber("0x"..hex:sub(1,2))/255
    local g = tonumber("0x"..hex:sub(3,4))/255
    local b = tonumber("0x"..hex:sub(5,6))/255
    local a = 1
    if #hex == 8 then
        a = tonumber("0x"..hex:sub(7,8))/255
    end
    
    return r,g,b,a
end

function L:set_cam(x,y)
    L.cam_x = x or 0
    L.cam_y = y or 0
end

function L:draw(obj)
    local r,g,b,a = hex_to_rgb(obj.c or "#ffffff")
    love.graphics.setColor(r,g,b,a)
	
    if obj.text then
        local font = love.graphics.getFont()
        font:setFilter("nearest", "nearest")
	    local plainText = love.graphics.newText(font, obj.text)
        local w,h = plainText:getWidth(), plainText:getHeight()

        local align = obj.align or "lt"
        local align_hor = align:sub(1,1)
        local align_ver = align:sub(2,2)

        local margin_x = 0
        if align_hor == "l" then
            margin_x = 0
        elseif align_hor == "m" then
            margin_x = w / 2
        elseif align_hor == "r" then
            margin_x = w
        end

        local margin_y = 0
        if align_hor == "t" then
            margin_y = 0
        elseif align_hor == "m" then
            margin_y = h / 2
        elseif align_hor == "b" then
            margin_y = h
        end

        love.graphics.draw(
            plainText,
            (obj.x or 0) + L.width / 2 - L.cam_x,
            (obj.y or 0) + L.height / 2 - L.cam_y,
            math.rad(obj.r or 0),
            (obj.sx or 1) * (obj.s or 1),
            (obj.sy or 1) * (obj.s or 1),
            margin_x,
            margin_y
        )
    else
        love.graphics.draw(
            square_canvas,
            (obj.x or 0) + L.width / 2 - L.cam_x,
            (obj.y or 0) + L.height / 2 - L.cam_y,
            math.rad(obj.r or 0),
            (obj.sx or 1) * (obj.s or 1),
            (obj.sy or 1) * (obj.s or 1),
            square_size / 2,
            square_size / 2
        )
    end

    love.graphics.setColor(255,255,255,1)
end

local i = 0
function L:collide(a, b)
    local aw = square_size * (a.sx or 1) * (a.s or 1)
    local ah = square_size * (a.sy or 1) * (a.s or 1)
    local bw = square_size * (a.sx or 1) * (a.s or 1)
    local bh = square_size * (a.sy or 1) * (a.s or 1)

    local sa = math.sqrt(aw*aw+ah*ah)
    local sb = math.sqrt(bw*bw+bh*bh)

    local aabb = a.x - sa/2 < b.x + sb/2 and
        a.x + sa/2 > b.x - sb/2 and
        a.y - sa/2 < b.y + sb/2 and
        a.y + sa/2 > b.y - sb/2

    if not aabb then
        return false
    end

    local sat =rotated_rect_collision({x=a.x, y=a.y, w=aw, h=ah, angle=math.rad(a.r or 0)}, {x=b.x, y=b.y, w=bw, h=bh, angle=math.rad(b.r or 0)})

    if not sat then
        return false
    end

    print("collision, collision!", i)
    i = i + 1

    return true
end

function L:angle_look_at(x1, y1, x2, y2)
	return math.deg(math.atan2(y2-y1, x2-x1))
end

function L:angle_vec(angle)
	return math.cos(math.rad(angle)), math.sin(math.rad(angle))
end

function L:getRatio()
	local swidth, sheight = love.graphics.getDimensions()
	local ratioX, ratioY = swidth / L.width, sheight / L.height
	local ratio = ((ratioX <= ratioY) and ratioX) or ratioY

	return ratio
end

function L:getMousePos()
	local nx, ny = love.mouse.getPosition()
	local ratio = L:getRatio()
	local swidth, sheight = love.graphics.getDimensions()
	return (nx - ((swidth - L.width * ratio) / 2)) / ratio - L.width / 2, (ny - ((sheight - L.height * ratio) / 2)) / ratio - L.height / 2
end

function L:time()
    return love.timer.getTime()
end

function L:pasttime(t)
    return L:time() > t
end

function L:reset()
    L.setup()
end

local last_mod_time = nil
function love.update(dt)
	L.dt = dt

    local mod_time = love.filesystem.getInfo("src/game.lua").modtime
    if not last_mod_time or (mod_time > last_mod_time) then
        local status, err = pcall(function () dofile("src/game.lua") end)
        print(mod_time, last_mod_time, status, err)

        if not last_mod_time then
            L.setup()
        end
        
        last_mod_time = mod_time
    end
end

function love.draw()
	local swidth, sheight = love.graphics.getDimensions()
	local canvas = love.graphics.newCanvas(L.width, L.height)
	love.graphics.setCanvas(canvas)
	
    L:set_cam()
	L.render(L.dt)
    L:set_cam()

	love.graphics.setCanvas()
	local ratio = L:getRatio()
	love.graphics.draw(canvas, swidth / 2, sheight / 2, 0, ratio, ratio, L.width / 2, L.height / 2)
end

return L