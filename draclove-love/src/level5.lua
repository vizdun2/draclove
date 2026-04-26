local L = require("lib/l")
local gravity = require("src/gravity")
local Player = require("src/player")
local lvl5 = {}

function lvl5.setup()
    L.player = {x=-500, y=0, sprite="chips/honza_citron_idle", s=0.15, vel_x = 0, vel_y = 0, dash_mult = 1, last_used_dash = 0}
    L.chips = {sprite="chips/normal", s=2,x=500, y=0,spawned=L.time()}
    L.chip_projs = {}
    L.deads = {}
end

local move_const = 500
local move_cap = 100
local size = 0.2 * 1120
local cam_bound_x, cam_bound_y = L.width / 2 * 0.09, L.height / 2 * 0.95

local function move_player()
    if L.key_down("a") then L.player.vel_x = L.player.vel_x - move_const * L.dt end
    if L.key_down("d") then L.player.vel_x = L.player.vel_x + move_const * L.dt end
    if L.key_down("w") then L.player.vel_y = L.player.vel_y - move_const * L.dt end
    if L.key_down("s") then L.player.vel_y = L.player.vel_y + move_const * L.dt end
    
    if L.key_down("space") and L.pasttime(L.player.last_used_dash + 0.8) then
        L.player.last_used_dash = L.time()
    end

    if L.time() - L.player.last_used_dash <= 0.4 then
        L.player.dash_mult = 5
    end
    if L.time() - L.player.last_used_dash >= 0.4 then
        L.player.dash_mult = 1
    end

    L.player.vel_x = L.clamp(-move_cap, L.player.vel_x, move_cap)
    L.player.vel_y = L.clamp(-move_cap, L.player.vel_y, move_cap)

    if L.player.x > L.width / 2 - size / 2 or L.player.x < -L.width / 2 + size / 2 then
        L.player.vel_x = -L.player.vel_x
    end
    if L.player.y > L.height / 2 - size / 2 or L.player.y < -L.height / 2 + size / 2 then
        L.player.vel_y = -L.player.vel_y
    end

    L.move_vel(L.player, L.player.dash_mult)

end

local proj_speed = 200
local pellet_count = 4
local pellet_angle = 30

local function shoot_chips()
    local each_angle = pellet_angle / (pellet_count - 1)
    local original_angle = -pellet_angle / 2
    local r = L.angle_look_at(L.chips.x, L.chips.y, L.player.x, L.player.y)
    for i = 0, pellet_count do
        local cr = r + original_angle + i * each_angle
        local vx, vy = L.angle_vec(cr)
        L.chip_projs[L.uid()] = { x = L.chips.x, y = L.chips.y, vel_x = vx * proj_speed, vel_y = vy * proj_speed, born = L
        .time(), sprite_t = 0.1, sprite = "chips/chip_idle" }
    end
end

function lvl5.loop(dt)
    move_player()

    for id, dead in pairs(L.deads) do
        if L.sprite_finished(dead) then
            L.deads[id] = nil
        end
    end

    local about_to_eat = false
    for id, chip in pairs(L.chip_projs) do
        L.move_vel(chip)
        if L.collide(chip, L.player) then
            L.print("ate a chip (and lied)")
            L.chip_projs[id] = nil
            L.deads[L.uid()] = {x=chip.x,y=chip.y,sprite="particles/chip_destroayed",sprite_t=0.1,sprite_start=L.time()}
        elseif L.pasttime(chip.born + 5) then
            L.chip_projs[id] = nil
        elseif L.collide(chip, L.patch(L.player, {s=L.player.s * 1.2})) then
            about_to_eat = true
        end
    end
    L.player.sprite = about_to_eat and "chips/honza_citron_eating" or "chips/honza_citron_idle"

    if L.pasttime(L.chips.spawned + 2) then
        shoot_chips()
        L.chips.spawned = L.time()
    end

    L.set_cam(L.clamp(-cam_bound_x, L.player.x / 8, cam_bound_x), L.clamp(-cam_bound_y, L.player.y / 8, cam_bound_y), 1.1)
    L.draw({sprite="scenes/5", s=6.66})
    L.draw(L.chips)
    L.draw(L.player)

    for _, chip in pairs(L.chip_projs) do
        L.draw(chip)
    end

    for _, dead in pairs(L.deads) do
        L.draw(dead)
    end
end

return lvl5