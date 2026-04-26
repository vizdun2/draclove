local L = require("lib/l")
local gravity = require("src/gravity")
local Player = require("src/player")
local lvl4 = {}

function lvl4.setup()
    L.boss = {
        x = L.width / 2 - 150,
        y = 0,
        -- sy=3,
        -- sx=2,
        s = 4,
        r = 0,
        -- state_begin = L.time(),
        -- next_state = 1,
        hp = 20,
        sprite = "mouse_dragon/idle",
        -- sprite = "mouse_dragon/dragon_flight",
        sprite_t = 0.1,
        -- pl = -20,
        -- pr = -28,
        -- pb = 0,
        pt = -10,
        last_burped = L.time(),
        burp_i = 0,
        takeHitCooldown = 0.6,
        fucktuts = false,
    }
    Player.setup()
    L.fire_projs = {}
    L.player.currentDJSprite = "particles/4/jump_burst"
    L.player.jump_disabled = true
    L.player.off_move = true
    L.player.y = 220
    L.player.x = -600
    L.weed = {}
    L.last_weed_gen = 0
end

local weed_speed = 500

function lvl4.loop(dt)
    if L.boss.hp <= 0 then
        L.boss.dead = true
    end
    if L.boss.dead == true then
        L.nextLevel = 5
        L.active_level_i = L.transition
        L.reset()
    end

    L.player.on_ground = true

    for id, proj in pairs(L.fire_projs) do
        if L.pasttime(proj.born + 5) then
            L.fire_projs[id] = nil
        end

        if L.collide(proj, L.player) then
            if (L.player.take_damage()) then
                L.fire_projs[id] = nil
            end
        end
        L.move_vel(proj)
    end

    for id, w in pairs(L.weed) do
        if L.collide(w, L.player) and L.player.is_punching() then
            local vx, vy = L.vec_to(L.boss, w)
            w.vel_x = vx * weed_speed
            w.vel_y = vy * weed_speed
            w.r = L.angle_look_at(w.x, w.y, L.boss.x, L.boss.y) + (w.y > 0 and 90 or -90)
            w.sprite_t = 0.1
            w.sprite = "mouse_dragon/trava_projectile"
        end

        if L.collide(w, L.patch(L.boss, { s = 0.8 })) then
            L.weed[id] = nil
            L.boss.hp = L.boss.hp - 1
            L.boss.fucktuts = true
        end

        L.move_vel(w)
    end

    if L.hit_time and L.pasttime(L.hit_time + L.boss.takeHitCooldown) then
        L.hit_time = nil
    end

    if L.pasttime(L.boss.last_burped + 4) then
        L.boss.sprite = "mouse_dragon/dragon_flight"
    end

    local burst = 3
    if L.boss.burp_i < burst and L.pasttime(L.boss.last_burped + 0.5) or L.boss.burp_i >= burst and L.pasttime(L.boss.last_burped + 5) then
        L.boss.last_burped = L.time()
        if L.boss.burp_i >= burst then
            L.boss.burp_i = 0
        end

        L.boss.sprite = "mouse_dragon/dragon_flight"

        local speed = 800
        local vx, vy = L.vec_to(L.player, L.boss)
        local r = L.angle_look_at(L.boss.x, L.boss.y, L.player.x, L.player.y)
        L.fire_projs[L.uid()] = { r = r+180, s = 1.5, sprite = "mouse_dragon/fireball", sprite_t = 0.1, x = L.boss.x, y = L
        .boss.y, vel_x = vx * speed, vel_y = vy * speed, born = L.time() }
        L.boss.burp_i = L.boss.burp_i + 1

        if L.boss.burp_i >= burst then
            L.boss.sprite = "mouse_dragon/idle"
        end
    end

    if L.pasttime(L.last_weed_gen + 1) then
        L.last_weed_gen = L.time()
        local on_roof = math.random() <= 0.5
        local nw =  { x = math.random() * L.height - L.height / 2, y = on_roof and -L.height / 2 + 25 or 220 + 32, sy =
        on_roof and -1 or 1, sprite = "mouse_dragon/trava", s = 4 }

        local okay = not L.collide(nw, L.patch(L.player, {s=3}))
        for oid, ow in pairs(L.weed) do
            okay = okay and not L.collide(nw, ow)
        end

        if okay then
            L.weed[L.uid()] = nw
        end
    end

    L.draw({ sprite = "scenes/4", s = 6.66 })

    L.draw(L.boss)

    for _, proj in pairs(L.fire_projs) do
        L.draw(proj)
    end

    for _, weed in pairs(L.weed) do
        L.draw(weed)
        if weed.sprite == "mouse_dragon/trava" and not L.boss.fucktuts then
            L.draw({r=(weed.y > 0 and 90 or -90), sprite="UI/hand", x = weed.x, y = weed.y + (weed.y > 0 and -75 or 75), sx = L.boss.x > 0 and 1 or -1, sprite_t = 0.08})
        end
    end

    Player.loop()
    L.draw(L.player)
    L.draw_hud()
    return true
end

function lvl4.startScene()
    return false
end

function lvl4.endScene()
    return false
end

return lvl4
