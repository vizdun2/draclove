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
local origin_y = -720 / 2

---@enum
local states = {
    moving_around = 1,
    spilling_prep = 2,
    spilling = 3,
    spilling_hard = 5,
    spilling_finishing = 6,
    spilling_recover = 4,
}

function lvl3.setup()
    L.boss = {
        x = 0,
        y = -300,
        -- sy=3,
        -- sx=2,
        s = 4,
        r = 0,
        state = states.moving_around,
        -- state_begin = L.time(),
        -- next_state = 1,
        hp = 3,
        sprite = "idibiks/idle",
        sprite_t = 0.1,
        pl = -12,
        pr = -8,
        pb = 0,
        last_burped = L.time(),
    }
    Player.setup()
    L.pipes = {}
    L.water_projs = {}
    L.spill = nil
    L.water_level = nil
end

local toilet_speed = 100
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
        L.water_projs[L.uid()] = { x = L.boss.x, y = L.boss.y, vel_x = vx * proj_speed, vel_y = vy * proj_speed, born = L.time(), sprite_t=0.1, sprite="idibiks/water_projectile" }
    end
end

local prep_rot_speed = 50
local flow_speed = 8
local magic_y = 540 / 2
local desired_water_level = 290

local function do_toilet()
    if L.boss.state == states.moving_around then
        if L.time() > L.boss.last_burped + 4 then
            shoot_water()
            L.boss.last_burped = L.time()
            return
        elseif L.time() > L.boss.last_burped + 3.5 then
            L.boss.sprite = "idibiks/attack"
            return
        elseif L.time() > L.boss.last_burped + 0.5 then
            L.boss.sprite = "idibiks/idle"
        end
        
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
            L.boss.state = states.spilling_prep
        end

        L.move_vel(L.boss)
    end

    local r_mod = L.boss.sx > 0 and 1 or -1
    if L.boss.state == states.spilling_prep then
        L.boss.r = (L.boss.r or 0) + prep_rot_speed * r_mod * L.dt
        if r_mod == 1 and L.boss.r >= 180 or r_mod == -1 and L.boss.r <= -180 then
            L.boss.r = 180 * r_mod
            L.boss.state = states.spilling
            L.boss.state_start = L.time()
            L.boss.sprite = "idibiks/attack"
        end
    end

    local xoff, yoff = L.boss.sx > 0 and -40 or 40,-5
    local spill_mult = 2

    if L.boss.state == states.spilling then
        if not L.spill then
            L.spill = {sprite="idibiks/water_column", sx=3.5}
        end
        local d = L.time() - L.boss.state_start
        L.spill.x = L.boss.x + xoff
        L.spill.y = L.boss.y + 64 * d * flow_speed * spill_mult / 2 + yoff
        L.spill.sy = d * flow_speed * spill_mult
        if L.spill.y >= (L.boss.y + magic_y) / 2 then
            -- L.spill.y = (L.boss.y + magic_y) / 2
            -- L.spill.sy = (L.boss.y + magic_y) / 13
            L.boss.state = states.spilling_hard
            L.boss.state_start = L.time()
        end
    end

    local origin = L.height/2 + 64 * 8 / 2 - 80
    if L.boss.state == states.spilling_hard then
        if not L.water_level then
            L.water_level = {x=0,y=L.height/2, sprite="idibiks/water", sprite_t=0.1, sx=20, sy=8, pt=-18}
        end
        local d = L.time() - L.boss.state_start
        L.water_level.y = origin - d * flow_speed * 32
        if L.water_level.y <= desired_water_level then
            L.water_level.y = L.water_level.desired_water_level
            L.boss.state = states.spilling_finishing
            L.boss.state_start = L.time()
            L.boss.sprite = "idibiks/idle"
        end
    end

    if L.boss.state == states.spilling_finishing then
        local d = L.time() - L.boss.state_start
        L.water_level.y = desired_water_level + d * flow_speed * 32
        L.spill.y = (L.boss.y + magic_y) / 2 + 64 * d * flow_speed * spill_mult / 2 + yoff
        L.spill.sy = math.max((magic_y - L.boss.y) / 64 - d * flow_speed * spill_mult, 0)
        if L.spill.sy <= 0 and L.water_level.y >= origin then
            L.spill.sy = 0
            L.water_level.y = origin
            L.boss.state = states.spilling_recover
            L.boss.state_start = L.time()
        end
    end

    if L.boss.state == states.spilling_recover then
        L.boss.r = (L.boss.r or 0) - prep_rot_speed * r_mod * L.dt
        if (r_mod == 1 and L.boss.r <= 0) or (r_mod == -1 and L.boss.r >= 0) then
            L.boss.r = 0
            L.boss.state = states.moving_around
            L.boss.state_start = nil
            L.boss.last_burped = L.time()
        end
    end
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

    if L.hit_time and L.pasttime(L.hit_time + 1) then
        L.hit_time = nil
    end

    local pipes = {}
    table.insert(pipes,
        { c = L.hit_time and "#FF5050", sprite = "idibiks/pipe", r = 90, x = (origin_x + L.boss.x) / 2, y = L.boss.y, sy =
        math.abs(origin_x - L.boss.x) / 64, sx = L.boss.x > 0 and -1 or 1 })
    table.insert(pipes,
        { c = L.hit_time and "#FF5050", sprite = "idibiks/pipe", x = origin_x, y = (origin_y + L.boss.y) / 2, sy = math
        .abs(origin_y - L.boss.y) / 64 })
    table.insert(pipes,
        { c = L.hit_time and "#FF5050", sprite = L.boss.x > 0 and "idibiks/joint_right" or "idibiks/joint_left", x =
        origin_x, y = L.boss.y })

    if L.player.is_punching() then
        for _i, pipe in ipairs(pipes) do
            if L.collide(L.player, pipe) and not L.hit_time then
                L.hit_time = L.time()
                L.print("hit")
                break
            end
        end
    end

    if L.spill and L.collide(L.spill, L.player) or L.water_level and L.collide(L.water_level, L.player) then
        L.player.take_damage()
    end

    L.draw({ sprite = "scenes/3", s = 6.66 })

    for _i, pipe in ipairs(pipes) do
        L.draw(pipe)
    end

    L.draw(L.boss)

    for _, proj in pairs(L.water_projs) do
        L.draw(proj)
    end

    L.draw(L.patch(L.player, { debug = true }))
    L.draw(L.player)

    if L.spill then
        L.draw(L.spill)
    end
    if L.water_level then
        L.draw(L.patch(L.water_level, {debug=true}))
        L.draw(L.patch(L.water_level, {debug=false}))
    end

    -- L.draw(ground_bot)
    -- L.draw(ground_top)
    L.draw_hud()
end

return lvl3
