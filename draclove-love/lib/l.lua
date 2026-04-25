local rotated_rect_collision = require("lib/aibs")
local inspect = require("lib/inspect")

local L = {
    width = 1280,
    height = 720,
    cam_x = 0,
    cam_y = 0,
    cam_s = 0,
    dt = 0,
    setup_done = false,
    released_keys = {},
    pressed_keys = {},
    assets = {},
    fonts = {},
    setup = function() end,
    render = function(dt) end,
    next_uid = 1,
}

local square_size = 32
local square_canvas = love.graphics.newCanvas(square_size, square_size)
square_canvas:setFilter("nearest", "nearest")
love.graphics.setCanvas(square_canvas)
love.graphics.clear(1, 1, 1, 1)
love.graphics.setCanvas()
local square_quad = love.graphics.newQuad(0, 0, square_size, square_size, square_size, square_size)

local function load_assets_rec(dir)
    local files = love.filesystem.getDirectoryItems(dir)
    local dirwithoutassets = string.sub(dir, 8)
    for i, filename in ipairs(files) do
        if love.filesystem.getInfo(dir .. filename).type == "directory" then
            load_assets_rec(dir .. filename .. "/")
        else
            local texture_name, texture_row, texture_col = filename:match("^(.*)_([0-9]+)x([0-9]+)%.png$")
            local audio_name = filename:match("^(.*)%.mp3$") or filename:match("^(.*)%.wav$")
            local font_name = filename:match("^(.*)%.ttf$")

            if texture_name then
                local image = love.graphics.newImage(dir .. filename)
                image:setFilter("nearest", "nearest")
                local w, h = image:getWidth(), image:getHeight()

                local quads = {}
                local r, c = tonumber(texture_row), tonumber(texture_col)
                for j = 0, r - 1 do
                    for i = 0, c - 1 do
                        table.insert(quads, love.graphics.newQuad(w / c * i, h / r * j, w / c, h / r, w, h))
                    end
                end

                L.assets.textures[dirwithoutassets .. texture_name] = {
                    row = r,
                    col = c,
                    quads = quads,
                    image = image,
                }
            elseif audio_name then
                L.assets.sounds[dirwithoutassets .. audio_name] = love.audio.newSource(dir .. filename, "static")
            elseif font_name then
                L.assets.fonts[dirwithoutassets .. font_name] = filename
            end
        end
    end
end

local function load_assets()
    L.assets = {
        textures = {},
        sounds = {},
        fonts = {},
    }

    load_assets_rec("assets/")
end

local function hex_to_rgb(hex)
    local hex = hex:gsub("#", "")
    local r = tonumber("0x" .. hex:sub(1, 2)) / 255
    local g = tonumber("0x" .. hex:sub(3, 4)) / 255
    local b = tonumber("0x" .. hex:sub(5, 6)) / 255
    local a = 1
    if #hex == 8 then
        a = tonumber("0x" .. hex:sub(7, 8)) / 255
    end

    return r, g, b, a
end

function L.set_cam(x, y, s)
    L.cam_x = x or 0
    L.cam_y = y or 0
    L.cam_s = s or 1
end

---@param audio_name string? Audio name
---@param volume number? Volume multiplier eg. 0.75
function L.play(audio_name, volume)
    if audio_name and L.assets.sounds[audio_name] then
        local source = L.assets.sounds[audio_name]:clone()
        source:setVolume(volume or 1)
        source:play()
    end
end

local function get_obj_sprite_stuffs(obj)
    local drawable = (obj.sprite and L.assets.textures[obj.sprite] and L.assets.textures[obj.sprite].image) or
    square_canvas
    local row_count = (obj.sprite and L.assets.textures[obj.sprite] and L.assets.textures[obj.sprite].row) or 1
    local col_count = (obj.sprite and L.assets.textures[obj.sprite] and L.assets.textures[obj.sprite].col) or 1
    local sprite_width = drawable:getWidth() / col_count
    local sprite_height = drawable:getHeight() / row_count
    return drawable, sprite_width, sprite_height, row_count, col_count
end

function L.padding_adjusted(obj)
    local drawable, sw, sh, _r, _c = get_obj_sprite_stuffs(obj)
    local x = (obj.x or 0) + ((obj.pr or 0) - (obj.pl or 0))
    local y = (obj.y or 0) + ((obj.pb or 0) - (obj.pt or 0))
    local dx = (sw + (obj.pl or 0) + (obj.pr or 0)) / sw
    local dy = (sh + (obj.pt or 0) + (obj.pb or 0)) / sh
    return x, y, dx, dy
end

local default_font = love.graphics.getFont()
default_font:setFilter("nearest", "nearest")
local function lazy_get_font(name, size)
    local font_id = (name or "") .. size

    if not name then
        return default_font
    elseif L.fonts[font_id] then
        return L.fonts[font_id]
    else
        local new_font = love.graphics.newFont("assets/" .. L.assets.fonts[name], size)
        new_font:setFilter("nearest", "nearest")
        L.fonts[font_id] = new_font
        return new_font
    end
end

---@alias Alignment
---| '"lt"' Left, top
---| '"lm"' Left, middle
---| '"lb"' Left, bottom
---| '"mt"' Center, top
---| '"mm"' Center, middle
---| '"mb"' Center, bottom
---| '"rt"' Right, top
---| '"rm"' Right, middle
---| '"rb"' Right, bottom

---@class Obj
---@field c string? Hex color eg. "#ffffff"
---@field text string? Text
---@field font string? Font
---@field font_size number? Font/text size
---@field align Alignment? Text alignment
---@field x number? X position
---@field y number? Y position
---@field pt number? Top side padding
---@field pb number? Bottom side padding
---@field pl number? Left side padding
---@field pr number? Right side padding
---@field r number? Rotation in degrees
---@field s number? Scale
---@field sx number? Scale across the X axis
---@field sy number? Scale across the Y axis
---@field debug boolean? Draw a white rectangle of the same size as sprite instead of a sprite
---@field sprite string? Sprite
---@field sprite_t number? Sprite animation frame duration
---@field sprite_start number? Sprite animation start timestamp
---@field parent Obj? Parent, works for position and nothing else rn

---@param obj Obj
function L.draw(obj)
    local r, g, b, a = hex_to_rgb(obj.c or "#ffffff")
    love.graphics.setColor(r, g, b, a)

    if obj.text then
        local font = lazy_get_font(obj.font, obj.font_size or 13)
        local plainText = love.graphics.newText(font, obj.text)
        local w, h = plainText:getWidth(), plainText:getHeight()

        local align = obj.align or "lt"
        local align_hor = align:sub(1, 1)
        local align_ver = align:sub(2, 2)

        local margin_x = 0
        if align_hor == "l" then
            margin_x = 0
        elseif align_hor == "m" then
            margin_x = w / 2
        elseif align_hor == "r" then
            margin_x = w
        end

        local margin_y = 0
        if align_ver == "t" then
            margin_y = 0
        elseif align_ver == "m" then
            margin_y = h / 2
        elseif align_ver == "b" then
            margin_y = h
        end

        love.graphics.draw(
            plainText,
            (((obj.x or 0) - L.cam_x) * L.cam_s) + L.width / 2,
            (((obj.y or 0) - L.cam_y) * L.cam_s) + L.height / 2,
            math.rad(obj.r or 0),
            (obj.sx or 1) * (obj.s or 1) * L.cam_s,
            (obj.sy or 1) * (obj.s or 1) * L.cam_s,
            margin_x,
            margin_y
        )
    else
        local drawable, sprite_width, sprite_height, r, c = get_obj_sprite_stuffs(obj)
        local sprite_i = (obj.sprite_t and (math.floor((L.time() - (obj.sprite_start or 0)) / obj.sprite_t) % (r * c) + 1)) or
        1

        local x, y, dx, dy = L.padding_adjusted(obj)

        local debug_x = (not obj.debug and obj.x) or x
        local debug_y = (not obj.debug and obj.y) or y
        local debug_sx = (not obj.debug and 1) or (sprite_width / square_size * dx)
        local debug_sy = (not obj.debug and 1) or (sprite_height / square_size * dy)

        local parent_x = (obj.parent and obj.parent.x) or 0
        local parent_y = (obj.parent and obj.parent.y) or 0

        -- if obj.debug then
        --     L.print(debug_x, parent_x)
        -- end

        love.graphics.draw(
            (not obj.debug and drawable) or square_canvas,
            (obj.debug and square_quad) or
            ((obj.sprite and L.assets.textures[obj.sprite] and L.assets.textures[obj.sprite].quads[sprite_i]) or square_quad),
            ((debug_x + parent_x - L.cam_x) * L.cam_s) + L.width / 2,
            ((debug_y + parent_y - L.cam_y) * L.cam_s) + L.height / 2,
            math.rad(obj.r or 0),
            debug_sx * (obj.sx or 1) * (obj.s or 1) * L.cam_s,
            debug_sy * (obj.sy or 1) * (obj.s or 1) * L.cam_s,
            (not obj.debug and sprite_width / 2) or (square_size / 2),
            (not obj.debug and sprite_height / 2) or (square_size / 2)
        )
    end

    love.graphics.setColor(255, 255, 255, 1)
end

---@param obj Obj
function L.sprite_cycle_count(obj)
    local drawable, sprite_width, sprite_height, r, c = get_obj_sprite_stuffs(obj)
    return obj.sprite_t and (math.floor(((L.time() - (obj.sprite_start or 0)) / obj.sprite_t) / (r * c))) or 0
end

---@param obj Obj
function L.sprite_finished(obj)
    return L.sprite_cycle_count(obj) > 0
end

function L.obj_dims(obj)
    local drawable, sprite_width, sprite_height, _r, _c = get_obj_sprite_stuffs(obj)
    return sprite_width * (obj.sx or 1) * (obj.s or 1), sprite_height * (obj.sy or 1) * (obj.s or 1)
end

local i = 0
---@param a Obj
---@param b Obj
function L.collide(a, b)
    local aw, ah = L.obj_dims(a)
    local bw, bh = L.obj_dims(b)
    local ax, ay, adx, ady = L.padding_adjusted(a)
    local bx, by, bdx, bdy = L.padding_adjusted(b)
    local a_parent_x = (a.parent and a.parent.x) or 0
    local a_parent_y = (a.parent and a.parent.y) or 0
    local b_parent_x = (b.parent and b.parent.x) or 0
    local b_parent_y = (b.parent and b.parent.y) or 0
    ax,ay = ax + a_parent_x, ay + a_parent_y
    bx,by = bx + b_parent_x, by + b_parent_y
    aw, ah = aw * adx, ah * ady
    bw, bh = bw * bdx, bh * bdy

    local sa = math.sqrt(aw * aw + ah * ah)
    local sb = math.sqrt(bw * bw + bh * bh)

    local aabb = ax - sa / 2 < bx + sb / 2 and
        ax + sa / 2 > bx - sb / 2 and
        ay - sa / 2 < by + sb / 2 and
        ay + sa / 2 > by - sb / 2

    if not aabb then
        return false
    end

    local sat = rotated_rect_collision({ x = ax, y = ay, w = aw, h = ah, angle = math.rad(a.r or 0) },
        { x = bx, y = by, w = bw, h = bh, angle = math.rad(b.r or 0) })

    if not sat then
        return false
    end

    i = i + 1

    return true
end

function L.vec_to(a, b)
    local x = (a.x or 0) - (b.x or 0)
    local y = (a.y or 0) - (b.y or 0)
    local max = math.max(math.abs(x), math.abs(y))
    return x / max, y / max
end

function L.angle_look_at(x1, y1, x2, y2)
    return math.deg(math.atan2(y2 - y1, x2 - x1))
end

function L.angle_vec(angle)
    return math.cos(math.rad(angle)), math.sin(math.rad(angle))
end

function L.get_ratio()
    local swidth, sheight = love.graphics.getDimensions()
    local ratioX, ratioY = swidth / L.width, sheight / L.height
    local ratio = ((ratioX <= ratioY) and ratioX) or ratioY

    return ratio
end

function L.get_mouse_pos()
    local nx, ny = love.mouse.getPosition()
    local ratio = L.get_ratio()
    local swidth, sheight = love.graphics.getDimensions()
    return (((nx - ((swidth - L.width * ratio) / 2)) / ratio) - L.width / 2),
        (((ny - ((sheight - L.height * ratio) / 2)) / ratio) - L.height / 2)
end

--- @param scale number?
--- @return Obj
function L.get_mouse(scale)
    local x, y = L.get_mouse_pos()
    local wx, wy = L.cam_x + x, L.cam_y + y
    return { x = wx, y = wy, s = (scale or 1) }
end

function L.key_down(key)
    return love.keyboard.isDown(key)
end

function L.key_released(key)
    local res = L.released_keys[key] or false
    L.released_keys[key] = nil
    return res
end

function L.key_pressed(key)
    local res = L.pressed_keys[key] or false
    L.pressed_keys[key] = nil
    return res
end

function love.keyreleased(key)
    L.released_keys[key] = true
end

function love.keypressed(key)
    L.pressed_keys[key] = true
end

function L.time()
    return love.timer.getTime()
end

function L.pasttime(t)
    return L.time() > t
end

function L.reset()
    L.prev_text = nil
    local status, err = xpcall(function() L.setup() end, debug.traceback)
    if err then
        L.print("Error setuping:", err)
    else
        L.setup_done = true
    end
end

local function time_fmt(s)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local s = s % 60
    return string.format("%02d:%02d:%06.3f", h, m, s)
end

function L.printF(f, g, ...)
    local text = ""
    local print_text = time_fmt(L.time()) .. ":"

    for i = 1, select("#", ...) do
        local v = select(i, ...)
        print_text = print_text .. " " .. f(v)
        text = text .. g(v) .. "\n"
    end

    print(print_text)
    L.prev_text = text
end

function L.print(...)
    return L.printF(function(v)
        return inspect(v, { newline = "", indent = "" })
    end, function(v)
        return inspect(v)
    end, ...)
end

function L.printNoBs(...)
    return L.printF(function(v)
        return v
    end, function(v)
        return v
    end, ...)
end

function L.patch(a, b)
    local c = {}

    for key, value in pairs(a) do
        c[key] = value
    end

    for key, value in pairs(b) do
        c[key] = value
    end

    return c
end

function L.uid()
    local uid = L.next_uid
    L.next_uid = L.next_uid + 1
    return tostring(uid)
end

function L.move(obj, x, y, mult)
    obj.x = obj.x + (x or 0) * (mult or 1)
    obj.y = obj.y + (y or 0) * (mult or 1)
    return obj
end

function L.move_vel(obj, mult)
    return L.move(obj, (obj.vel_x or 0) * L.dt, (obj.vel_y or 0) * L.dt, mult)
end

function L.clear_pck_cache()
    for pck, _ in pairs(package.loaded) do
        if pck:match("^src/") then
            package.loaded[pck] = nil
        end
    end
end

local last_mod_time = nil
function love.update(dt)
    L.dt = math.min(dt, 1 / 30)

    local newest_mod_time = 0
    for _, file in ipairs(love.filesystem.getDirectoryItems("src")) do
        local mod_time = love.filesystem.getInfo("src/" .. file).modtime
        if newest_mod_time < mod_time then
            newest_mod_time = mod_time
        end
    end
    if not last_mod_time or (newest_mod_time > last_mod_time) then
        local contents, _size = love.filesystem.read("src/game.lua")
        local status, err = xpcall(function() loadstring(contents)() end, debug.traceback)
        print("Reloaded, new:", newest_mod_time, "old:", last_mod_time)

        if err then
            L.printNoBs("Error reloading:", err)
        end

        load_assets()

        if not L.setup_done then
            L.reset()
        end

        last_mod_time = newest_mod_time
    end
end

function love.draw()
    if L.key_released("backspace") then
        L.reset()
    end

    local swidth, sheight = love.graphics.getDimensions()
    local canvas = love.graphics.newCanvas(L.width, L.height)
    love.graphics.setCanvas(canvas)

    L.set_cam()
    local status, err = xpcall(function() L.render(L.dt) end, debug.traceback)
    if err then
        L.printNoBs("Error rendering/updating:", err)
    end
    L.set_cam()
    if L.prev_text then
        L.draw({ text = L.prev_text, c = "#FF0000", x = -L.width / 2, y = -L.height / 2, s = 2 })
    end

    love.graphics.setCanvas()
    local ratio = L.get_ratio()
    love.graphics.draw(canvas, swidth / 2, sheight / 2, 0, ratio, ratio, L.width / 2, L.height / 2)
end

return L
