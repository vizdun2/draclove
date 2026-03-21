local rotated_rect_collision = require("lib/aibs")

local L = {
    width = 1280,
    height = 720,
    cam_x = 0,
    cam_y = 0,
    dt = 0,
    assets = {},
    playing_sounds = {},
    setup = function() end,
    render = function() end,
}

local square_size = 32
local square_canvas = love.graphics.newCanvas(square_size, square_size)
square_canvas:setFilter("nearest", "nearest")
love.graphics.setCanvas(square_canvas)
love.graphics.clear(1,1,1,1)
love.graphics.setCanvas()
local square_quad = love.graphics.newQuad(0,0,square_size,square_size,square_size,square_size)

local function load_assets()
    L.assets = {
        textures = {},
        sounds = {},
    }

    local files = love.filesystem.getDirectoryItems("assets")
    for i,filename in ipairs(files) do
        local texture_name, texture_row, texture_col = filename:match("^(.*)_([0-9]+)x([0-9]+)%.png$")
        local audio_name = filename:match("^(.*)%.mp3$") or filename:match("^(.*)%.wav$")

        if texture_name then
            local image = love.graphics.newImage("assets/" .. filename)
            image:setFilter("nearest", "nearest")
            local w,h = image:getWidth(),image:getHeight()

            local quads = {}
            local r, c = tonumber(texture_row), tonumber(texture_col)
            for j=0,r-1 do
                for i=0,c-1 do
                    table.insert(quads, love.graphics.newQuad(w/c*i,h/r*j,w/c,h/r,w,h))
                end
            end

            L.assets.textures[texture_name] = {
                row = r,
                col = c,
                quads = quads,
                image = image,
            }
        elseif audio_name then
            L.assets.sounds[audio_name] = love.audio.newSource("assets/" .. filename, "static")
        end
    end
end

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

function L:play(audio_name, volume)
    if audio_name and L.assets.sounds[audio_name] then
        local source = L.assets.sounds[audio_name]:clone()
        source:setVolume(volume or 1)
        source:play()
    end
end

local function get_obj_sprite_stuffs(obj)
    local drawable = (obj.sprite and L.assets.textures[obj.sprite].image) or square_canvas
    local row_count = (obj.sprite and L.assets.textures[obj.sprite].row) or 1
    local col_count = (obj.sprite and L.assets.textures[obj.sprite].col) or 1
    local sprite_width = drawable:getWidth() / col_count
    local sprite_height = drawable:getHeight() / row_count
    return drawable, sprite_width, sprite_height, row_count, col_count
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
        local drawable, sprite_width, sprite_height, r, c = get_obj_sprite_stuffs(obj)
        local sprite_i = (obj.sprite_t and (math.floor(L:time() / obj.sprite_t) % (r*c) + 1)) or 1

        love.graphics.draw(
            drawable,
            (obj.sprite and L.assets.textures[obj.sprite].quads[sprite_i]) or square_quad,
            (obj.x or 0) + L.width / 2 - L.cam_x,
            (obj.y or 0) + L.height / 2 - L.cam_y,
            math.rad(obj.r or 0),
            (obj.sx or 1) * (obj.s or 1),
            (obj.sy or 1) * (obj.s or 1),
            sprite_width / 2,
            sprite_height / 2
        )
    end

    love.graphics.setColor(255,255,255,1)
end

local i = 0
function L:collide(a, b)
    local _, uaw, uah = get_obj_sprite_stuffs(a)
    local _, ubw, ubh = get_obj_sprite_stuffs(b)
    local aw = uaw * (a.sx or 1) * (a.s or 1)
    local ah = uah * (a.sy or 1) * (a.s or 1)
    local bw = ubw * (a.sx or 1) * (a.s or 1)
    local bh = ubh * (a.sy or 1) * (a.s or 1)

    local sa = math.sqrt(aw*aw+ah*ah)
    local sb = math.sqrt(bw*bw+bh*bh)

    local aabb = a.x - sa/2 < b.x + sb/2 and
        a.x + sa/2 > b.x - sb/2 and
        a.y - sa/2 < b.y + sb/2 and
        a.y + sa/2 > b.y - sb/2

    if not aabb then
        return false
    end

    local sat = rotated_rect_collision({x=a.x, y=a.y, w=aw, h=ah, angle=math.rad(a.r or 0)}, {x=b.x, y=b.y, w=bw, h=bh, angle=math.rad(b.r or 0)})

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

        load_assets()

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