local L = require("lib/l")
local gravity = require("src/gravity")
local Player = require("src/player")
local lvl5 = {}

local X = 8
local Y = 5
local proj_speed = 50

local function spawn_a_chip()
    -- for yi = 0, Y do
    --     for xi = 0, X do
    --         local vx, vy = L.angle_vec(math.random() * 360)
    --         L.chip_projs[L.uid()] = {
    --             x = L.width / (X + 1) * xi - L.width / 2 + math.random() * L.height / (X + 1),
    --             y = L.height / (Y + 1) * yi - L.height / 2 + math.random() * L.height / (Y + 1),
    --             vel_x = vx * proj_speed,
    --             vel_y = vy * proj_speed,
    --             born = L
    --                 .time(),
    --             sprite_t = 0.1,
    --             sprite = "chips/chip_idle",
    --             s = 2,
    --         }
    --     end
    -- end
    local vx, vy = L.angle_vec(180 + math.random() * 70 * 2 - 70)
    L.chip_projs[L.uid()] = {
        x = L.width / 2,
        y = L.height * math.random() - L.height / 2,
        vel_x = vx * proj_speed,
        vel_y = vy * proj_speed,
        born = L
            .time(),
        sprite_t = 0.1,
        sprite = "chips/chip_idle",
        s = 2,
    }
end

function lvl5.setup()
    L.audio_intro("audio/soundtrack/menu_music")
    L.player = { x = 0, y = 0, sprite = "chips/honza_citron_idle", s = 0.075, vel_x = 0, vel_y = 0, dash_mult = 1, last_used_dash = 0 }
    L.chips = { sprite = "chips/normal", s = 2, x = 500, y = 0, spawned = L.time() }
    L.chip_projs = {}
    L.deads = {}
end

local function bounce_me(obj)
    local width, height = L.obj_dims(obj)
     if obj.x < -L.width / 2 + height / 2 then
        obj.vel_x = math.abs(obj.vel_x)
    end
     if obj.x > L.width / 2 - width / 2 then
        obj.vel_x = -math.abs(obj.vel_x)
    end
    if obj.y < -L.height / 2 + height / 2 then
        obj.vel_y = math.abs(obj.vel_y)
    end
    if obj.y > L.height / 2 - width / 2 then
        obj.vel_y = -math.abs(obj.vel_y)
    end
end

local move_const = 250
local move_cap = 50
local size = 0.2 * 1120
local cam_bound_x, cam_bound_y = L.width / 2 - 290, L.height / 2 - 175

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

    bounce_me(L.player)

    L.move_vel(L.player, L.player.dash_mult)
end

-- local pellet_count = 4
-- local pellet_angle = 30

function lvl5.loop(dt)
    move_player()

    for id, dead in pairs(L.deads) do
        if L.sprite_finished(dead) then
            L.deads[id] = nil
        end
    end

    local about_to_eat = false
    for id, chip in pairs(L.chip_projs) do
        -- bounce_me(chip)
        L.move_vel(chip)
        if L.collide(chip, L.player) then
            -- L.print("ate a chip (and lied)")
            L.chip_projs[id] = nil
            L.deads[L.uid()] = { x = chip.x, y = chip.y, sprite = "particles/chip_destroyed", sprite_t = 0.1, sprite_start =
            L.time(), s=2 }
            L.player.ate = L.time()
        elseif L.pasttime(chip.born + 20) then
            L.chip_projs[id] = nil
        elseif L.collide(chip, L.patch(L.player, { s = L.player.s * 1.2 })) then
            about_to_eat = true
        end
    end
    about_to_eat = L.player.ate and not L.pasttime(L.player.ate + 0.5)
    L.player.sprite = about_to_eat and "chips/honza_citron_eating" or "chips/honza_citron_idle"

    if L.pasttime(L.chips.spawned + 0.5) then
        spawn_a_chip()
        L.chips.spawned = L.time()
    end

    L.set_cam(L.clamp(-cam_bound_x, L.player.x, cam_bound_x), L.clamp(-cam_bound_y, L.player.y, cam_bound_y), 2.2)
    L.draw({ sprite = "scenes/5", s = 6.66 / 2, sprite_t=0.1 })
    -- L.draw(L.chips)
    L.draw(L.player)

    for _, chip in pairs(L.chip_projs) do
        L.draw(chip)
    end

    for _, dead in pairs(L.deads) do
        L.draw(dead)
    end
end

return lvl5
