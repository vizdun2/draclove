local L = require("lib/l")
local gravity = require("src/gravity")
local Player = require("src/player")
local lvl3 = {}

local ground_bot = { x = 0, y = 300, sx = 100, tag = "ground" }
-- local ground_top = { x = 0, y = -300, sx = 100, tag = "ground" }

local function generate_pipes()
    local points = {}

    for i = 1, 4 do
        local x = math.random() * 550 * 2 - 550
        local y = math.random() * 160 * 2 - 160
        table.insert(points, { x = x, y = y })
    end

    L.pipes = {}
    for i = 2, #points do
        local prev = points[i - 1]
        local cur = points[i]
        table.insert(L.pipes, { x = (prev.x + cur.x) / 2, y = prev.y, sx = math.abs(prev.x - cur.x) / 32 })
        table.insert(L.pipes, { x = cur.x, y = (prev.y + cur.y) / 2, sy = math.abs(prev.y - cur.y) / 32 })
    end
end

local origin_x = 0
local origin_y = -300

function lvl3.setup()
    L.boss = {
        x = 0,
        y = -300,
        -- sy=3,
        -- sx=2,
        s = 4,
        r = 0,
        -- state = door_states.staying,
        -- state_begin = L.time(),
        -- next_state = 1,
        hp = 3,
        sprite = "idibiks/idle",
        sprite_t = 0.1,
        pl = -12,
        pr = -8,
        pb = 0,
    }
    Player.setup()
    L.pipes = {}
    L.water_projs = {}
end

local toilet_speed = 50
local proj_speed = 200
local pellet_count = 4
local pellet_angle = 30

local function shoot_water()
    local each_angle = pellet_angle / (pellet_count - 1)
    local original_angle = -pellet_angle / 2
    local r = L.angle_look_at(L.boss.x, L.boss.y, L.player.x, L.player.y)
    for i = 0, pellet_count do
        local cr = r + original_angle + i * each_angle
        local vx, vy = L.angle_vec(cr)
        L.water_projs[L.uid()] = {x=L.boss.x, y=L.boss.y, vel_x = vx * proj_speed, vel_y = vy * proj_speed, born = L.time()}
    end
end

local function do_toilet()
    if not L.boss.target then
        L.boss.target = { x = L.boss.x, y = L.boss.y }
        while L.dist(L.boss, L.boss.target) < 200 or math.abs(L.boss.y - L.boss.target.y) < 100 or math.abs(L.boss.x - L.boss.target.x) < 100 do
            L.boss.target = { x = math.random() * 550 * 2 - 550, y = math.random() * 160 * 2 - 160 }
        end
        local vx, vy = L.vec_to(L.boss.target, L.boss)
        L.boss.vel_x = vx * toilet_speed
        L.boss.vel_y = vy * toilet_speed
        if L.boss.vel_x < 0 then
            L.boss.sx = -1
        else
            L.boss.sx = 1
        end
    end

    if L.dist(L.boss, L.boss.target) < 10 then
        L.boss.vel_x, L.boss.vel_y = 0, 0
        L.boss.target = nil
        shoot_water()
    end

    L.move_vel(L.boss)
end

function lvl3.loop(dt)
    Player.loop()
    L.player.on_ground = gravity.ground_collide(L.player, L1.ground)

    for id, proj in pairs(L.water_projs) do
        if L.collide(proj, L.player) then
            L.water_projs[id] = nil
            L.player.take_damage()
        else
            L.move_vel(proj)
        end
    end

    do_toilet()

    for i, pipe in ipairs(L.pipes) do
        L.draw(pipe)
    end

    L.draw({ sprite = "idibiks/pipe", r=90, x = (origin_x + L.boss.x) / 2, y = L.boss.y, sy = math.abs(origin_x - L.boss.x) / 64, sx=L.boss.x > 0 and -1 or 1 })
    L.draw({ sprite = "idibiks/pipe", x = origin_x, y = (origin_y + L.boss.y) / 2, sy = math.abs(origin_y - L.boss.y) / 64 })
    L.draw({ sprite = L.boss.x > 0 and "idibiks/joint_right" or "idibiks/joint_left", x = origin_x, y = L.boss.y })

    L.draw(L.patch(L.boss, {sprite="idibiks/attack", sy=-1}))

    for _, proj in pairs(L.water_projs) do
        L.draw(proj)
    end

    L.draw(L.patch(L.player, { debug = true }))
    L.draw(L.player)
    L.draw(ground_bot)
    -- L.draw(ground_top)
    L.draw_hud()
end

return lvl3
