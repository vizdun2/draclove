local L = require("lib/l")
local gravity = require("src/gravity")
local Player = require("src/player")
local lvl4 = {}

function lvl4.setup()
<<<<<<< HEAD
    
=======
    L.audio_intro("audio/soundtrack/first_ost_intro")
>>>>>>> 0df61390f31a5eb0229f8c824d11079417120ef0
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
        maxHp = 20,
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


    L.boss.x = L.width/2 - 20
    L.boss.introTargetX = L.width / 2 - 150
    L.boss.introSpeed = 150
    L.boss.y=180
    lvl4.introPhase = "walking"

    L.boss.sprite = "mouse_dragon/mouse_runnin"
    L.boss.sprite_t = 0.1
    L.boss.sprite_start = L.time()

    L.boss.introTargetY = 0
    L.boss.ascendSpeed = 100

end

local function draw_hud()
    local totalIcons = math.ceil(L.boss.maxHp / 5)
    
    local activeIcons = math.ceil(L.boss.hp / 5)

    for i = 1, totalIcons do
        L.draw({ 
            sprite = "mouse_dragon/trava",
            s = 3, 
            x = -600 + (i - 1) * 80, 
            y = -L.height / 2 + 60, 
            c = (i <= activeIcons and "FFFFFF" or "606060") 
        })
    end
end

local weed_speed = 500

function lvl4.start_audio_loop()
    Source_path = "audio/soundtrack/first_ost_loop"
    Audio_source = L.play(Source_path)
    Audio_source:setLooping(true)
end

function lvl4.loop(dt)
    if Source_path ~= "audio/soundtrack/first_ost_intro" and not Audio_source:isPlaying() then
        lvl4.start_audio_loop()
    end
    
    if L.boss.hp <= 0 then
        L.boss.dead = true
        return false
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
    draw_hud()
    L.draw_hud()
    return true
end

function lvl4.startScene()
    L.draw({ x = 0, y = 0, sprite = "scenes/4", s = 6.66 })

    if lvl4.introPhase == "walking" then
        
        if L.boss.x > L.boss.introTargetX then
            L.boss.x = L.boss.x - (L.boss.introSpeed * L.dt)
        else
            L.boss.x = L.boss.introTargetX
            
            lvl4.introPhase = "animating"
            
            L.boss.sprite = "mouse_dragon/transformation"
            L.boss.sprite_t = 0.12
            L.boss.sprite_start = L.time() 
        end

    elseif lvl4.introPhase == "animating" then
        
        if L.sprite_finished(L.boss) then
            
            L.boss.sprite = "mouse_dragon/idle"
            L.boss.sprite_start = L.time()
            
            lvl4.introPhase = "ascending"
        end

    elseif lvl4.introPhase == "ascending" then
        
        if L.boss.y > L.boss.introTargetY then
            L.boss.y = L.boss.y - (L.boss.ascendSpeed * L.dt)
        else
            L.boss.y = L.boss.introTargetY
            
            return false 
        end
    end

    L.draw(L.player) 
    L.draw(L.boss)

    return true
end

function lvl4.endScene()
    if not lvl4.endSceneStarted then
        lvl4.endSceneStarted = true
        
        
        L.boss.sprite = "mouse_dragon/transformation"
        
        L.boss.sprite_t = -0.12 
        L.boss.sprite_start = L.time()
    end

    L.draw({ x = 0, y = 0, sprite = "scenes/4", s = 6.66 })
    L.draw(L.player)
    L.draw(L.boss)

    if L.sprite_cycle_count(L.boss) <= -2 then
        
        L.nextLevel = 5 
        L.active_level_i = L.transition
        L.reset()
    end
end
return lvl4
