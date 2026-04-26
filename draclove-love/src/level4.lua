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
        hp = 10,
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
    }
    Player.setup()
    L.fire_projs = {}
    L.player.currentDJSprite="particles/4/jump_burst"
    L.player.jump_disabled = true
    L.player.off_move = true
    L.player.y = 220
    L.weed = {}
    L.last_weed_gen = 0
end

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
        if L.collide(proj, L.player) then
            if L.player.is_punching()then
                L.fire_projs[id] = nil
            elseif L.pasttime(proj.born + 5) then
                L.fire_projs[id] = nil
            else
                if(L.player.take_damage())then
                    L.fire_projs[id] = nil
                end
            end
        end
        L.move_vel(proj)
    end

    if L.hit_time and L.pasttime(L.hit_time + L.boss.takeHitCooldown) then
        L.hit_time = nil
    end

    if L.boss.burp_i < 3 and L.pasttime(L.boss.last_burped + 0.1) or L.boss.burp_i >= 3 and L.pasttime(L.boss.last_burped + 1) then
        L.boss.last_burped = L.time()
        if L.boss.burp_i >= 3 then
            L.boss.burp_i = 0
        end

        local speed = 800
        local vx, vy = L.vec_to(L.player, L.boss)
        L.fire_projs[L.uid()] = {x=L.boss.x, y=L.boss.y, vel_x = vx * speed, vel_y = vy * speed, born = L.time() }
        L.boss.burp_i = L.boss.burp_i + 1
    end

    if L.pasttime(L.last_weed_gen + 1) then
        L.last_weed_gen = L.time()
        local on_roof = math.random() <= 0.5
        L.weed[L.uid()] = {x=math.random() * L.height - L.height / 2, y=on_roof and -L.height / 2 + 25 or 220 + 32, sy=on_roof and -1 or 1, sprite="mouse_dragon/trava", s = 2}
    end

    L.draw({ sprite = "scenes/4", s = 6.66 })

    L.draw(L.patch(L.boss, {debug=true}))
    L.draw(L.boss)

    for _, proj in pairs(L.fire_projs) do
        L.draw(proj)
    end
    
    for _, weed in pairs(L.weed) do
        L.draw(weed)
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