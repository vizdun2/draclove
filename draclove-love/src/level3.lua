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
    chasing = 7,
    shooting = 8,
}

local boss_max_hp = 20

function lvl3.setup()
    lvl3.timer = nil
    lvl3.cooldwon = 2.5
    lvl3.intro = true
    L.audio_intro("audio/soundtrack/third_ost_intro")
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
        hp = 25,
        sprite = "idibiks/idle",
        sprite_t = 0.1,
        pl = -20,
        pr = -28,
        pb = 0,
        last_burped = L.time(),
        last_chased = L.time(),
        chaseCooldown = 10,
        lastState=states.moving_around,
        chaseSpeed = 280,
        chaseDuration = 4.0,
        shootCount = 0,
        spillCount = 0,
        queuedAttack = nil,
        chaseThresholds = {20, 15, 10, 5},
        takeHitCooldown = 0.75,
    }
    Player.setup()
    L.pipes = {}
    L.water_projs = {}
    L.spill = nil
    L.water_level = nil
    L.player.currentDJSprite="particles/3/jump_burst"

    L.introAnimation = {
        x = 0,
        y = 200,
        s = L.boss.s,
        sprite = "idibiks/zachod_transform",
        sprite_t = 0.12,
        sprite_start = L.time(),
		sx = -1,
    }
end

local toilet_speed = 200
local pellet_count = 4
local pellet_angle = 30

local outwardSpeed = 200
local spinSpeed = 100
local pelletsInCircleBase = 5

local function shoot_water(pelletsInCircle)
    local angleStep = 360 / pelletsInCircle
    
    for i = 1, pelletsInCircle do
        local currentAngle = i * angleStep
        
        local vxOut, vyOut = L.angle_vec(currentAngle)
        
        local vxSpin, vySpin = L.angle_vec(currentAngle + 90)
        
        local finalVx = (vxOut * outwardSpeed) + (vxSpin * spinSpeed)
        local finalVy = (vyOut * outwardSpeed) + (vySpin * spinSpeed)
        
        L.water_projs[L.uid()] = { 
            x = L.boss.x, 
            y = L.boss.y, 
            vel_x = finalVx, 
            vel_y = finalVy, 
            born = L.time(), 
            sprite_t = 0.1, 
            sprite = "idibiks/water_projectile" 
        }
    end
end
local prep_rot_speed = 300
local flow_speed = 15
local magic_y = 540 / 2
local desired_water_level = 200

local function changeState(state)
    L.boss.lastState=L.boss.state
    L.boss.state=state
end
local function decideNextAttack()
    if #L.boss.chaseThresholds > 0 and L.boss.hp <= L.boss.chaseThresholds[1] then
        
        while #L.boss.chaseThresholds > 0 and L.boss.hp <= L.boss.chaseThresholds[1] do
            table.remove(L.boss.chaseThresholds, 1)
        end
        
        L.boss.shootCount = 0
        L.boss.spillCount = 0
        return "chase"
    end

    local choice = math.random(1, 2)

    if choice == 1 and L.boss.shootCount >= 2 then
        choice = 2
    elseif choice == 2 and L.boss.spillCount >= 1 then
        choice = 1
    end

    if choice == 1 then
        L.boss.shootCount = L.boss.shootCount + 1
        L.boss.spillCount = 0
        return "shoot"
    else
        L.boss.spillCount = L.boss.spillCount + 1
        L.boss.shootCount = 0
        return "spill"
    end
end
local function do_toilet()
    if L.boss.state == states.moving_around then
        
        if not L.boss.queuedAttack then
            L.boss.queuedAttack = decideNextAttack()
            L.boss.target = nil
        end

        if L.boss.queuedAttack == "chase" then
            changeState(states.chasing)
            L.boss.state_start = L.time()
            L.boss.sprite = "idibiks/attack"
            L.boss.queuedAttack = nil
            return
        end

        if not L.boss.target then
            L.boss.target = { x = L.boss.x, y = L.boss.y }
            while L.dist(L.boss, L.boss.target) < 200 or math.abs(L.boss.y - L.boss.target.y) < 100 or math.abs(L.boss.x - L.boss.target.x) < 100 do
                L.boss.target = { x = math.random() * 550 * 2 - 550, y = math.random() * 160 * 2 - 160 }
            end
            local vx, vy = L.vec_to(L.boss.target, L.boss)
            L.boss.vel_x = vx * toilet_speed
            L.boss.vel_y = vy * toilet_speed
            
            L.boss.sx = L.boss.vel_x < 0 and -1 or 1
        end

        if L.dist(L.boss, L.boss.target) < 10 then
            L.boss.vel_x, L.boss.vel_y = 0, 0
            L.boss.target = nil
            
            if L.boss.queuedAttack == "spill" then
                changeState(states.spilling_prep)
            elseif L.boss.queuedAttack == "shoot" then
                shoot_water(pelletsInCircleBase)
                changeState(states.shooting)
                L.boss.state_start = L.time()
                L.boss.sprite = "idibiks/attack"
            end
            
            L.boss.queuedAttack = nil
        end

        L.move_vel(L.boss)
    end

    if L.boss.state == states.shooting then
        if L.time() > L.boss.state_start + 0.5 then
            shoot_water(pelletsInCircleBase+2)
            L.boss.sprite = "idibiks/idle"
            changeState(states.moving_around)
        end
    end
    if L.boss.state == states.chasing then
        local timeInChase = L.time() - L.boss.state_start
        
        if timeInChase <= L.boss.chaseDuration then
            local vx, vy = L.vec_to(L.player, L.boss)
            
            L.boss.vel_x = vx * L.boss.chaseSpeed
            L.boss.vel_y = vy * L.boss.chaseSpeed
            
            L.boss.sx = L.boss.vel_x < 0 and -1 or 1
            
            L.move_vel(L.boss)
        else
            L.boss.last_chased = L.time()
            L.boss.sprite = "idibiks/idle"
            L.boss.target = nil
            changeState(states.moving_around)
        end
    end
    local r_mod = L.boss.sx > 0 and 1 or -1
    if L.boss.state == states.spilling_prep then
        L.boss.r = (L.boss.r or 0) + prep_rot_speed * r_mod * L.dt
        if r_mod == 1 and L.boss.r >= 180 or r_mod == -1 and L.boss.r <= -180 then
            L.boss.r = 180 * r_mod
            changeState(states.spilling)
            L.boss.state_start = L.time()
            L.boss.sprite = "idibiks/attack"
        end
    end

    local xoff, yoff = L.boss.sx > 0 and -40 or 40, -5
    local spill_mult = 2

    if L.boss.state == states.spilling then
        if not L.spill then
            L.spill = { sprite = "idibiks/water_column", sx = 3.5 }
        end
        local d = L.time() - L.boss.state_start
        L.spill.x = L.boss.x + xoff
        L.spill.y = L.boss.y + 64 * d * flow_speed * spill_mult / 2 + yoff
        L.spill.sy = d * flow_speed * spill_mult
        if L.spill.y >= (L.boss.y + magic_y) / 2 then
            -- L.spill.y = (L.boss.y + magic_y) / 2
            -- L.spill.sy = (L.boss.y + magic_y) / 13
            changeState(states.spilling_hard)
            L.boss.state_start = L.time()
        end
    end

    local origin = L.height / 2 + 64 * 8 / 2 - 80
    if L.boss.state == states.spilling_hard then
        if not L.water_level then
            L.water_level = { x = 0, y = L.height / 2, sprite = "idibiks/water", sprite_t = 0.1, sx = 20, sy = 8, pt = -18 }
        end
        local d = L.time() - L.boss.state_start
        L.water_level.y = origin - d * flow_speed * 32
        if L.water_level.y <= desired_water_level then
            L.water_level.y = L.water_level.desired_water_level
            changeState(states.spilling_finishing)
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
            changeState(states.spilling_recover)
            L.boss.state_start = L.time()
        end
    end

    if L.boss.state == states.spilling_recover then
        L.boss.r = (L.boss.r or 0) - prep_rot_speed * r_mod * L.dt
        if (r_mod == 1 and L.boss.r <= 0) or (r_mod == -1 and L.boss.r >= 0) then
            L.boss.r = 0
            changeState(states.moving_around)
            L.boss.state_start = nil
            L.boss.last_burped = L.time()
        end
    end
end

local function spawn_scars()
    L.scars = {}

    local y_size = math.abs(L.boss.y - origin_y)
    local x_size = math.abs(L.boss.x)
    local sum = y_size + x_size
    local x_ratio = x_size / sum
    local rn = L.time()

    for _ = 1, boss_max_hp - L.boss.hp do
        local on_x = math.random() <= x_ratio
        local x, y = on_x and math.random() * L.boss.x or 0,
            on_x and L.boss.y or math.random() * (L.boss.y - origin_y) + origin_y
        table.insert(L.scars, { x = x, y = y, sprite = "particles/water_sprinkle", sprite_t = 0.05, sprite_start = rn })
    end
end


local audio_loop = "audio/soundtrack/third_ost_loop"
local audio_intro = "audio/soundtrack/third_ost_intro"


function lvl3.start_playing_audio_loop()
    Audio_source = L.play(audio_loop, 1)
    Source_path = audio_loop
    Audio_source:setLooping(true)
end

function lvl3.loop(dt)

    if Source_path == audio_intro and not Audio_source:isPlaying() then
        Audio_source:stop()
        lvl3.start_playing_audio_loop()
    end

    if L.boss.hp <= 0 then
        L.boss.dead = true
        return false
    end
    
    L.player.on_ground = gravity.ground_collide(L.player, ground_bot)

    for id, proj in pairs(L.water_projs) do
        if L.collide(proj, L.player) then
            if(L.player.take_damage())then
                L.water_projs[id] = nil
            end
        end
        L.move_vel(proj)
    end

    do_toilet()

    if L.hit_time and L.pasttime(L.hit_time + L.boss.takeHitCooldown) then
        L.hit_time = nil
    end

    local pipes = {}
    table.insert(pipes,
        {
            c = L.hit_time and "#FF5050",
            sprite = "idibiks/pipe",
            r = 90,
            x = (origin_x + L.boss.x) / 2,
            y = L.boss.y,
            sy =
                math.abs(origin_x - L.boss.x) / 64,
            sx = L.boss.x > 0 and -1 or 1
        })
    table.insert(pipes,
        {
            c = L.hit_time and "#FF5050",
            sprite = "idibiks/pipe",
            x = origin_x,
            y = (origin_y + L.boss.y) / 2,
            sy = math
                .abs(origin_y - L.boss.y) / 64
        })
    table.insert(pipes,
        {
            c = L.hit_time and "#FF5050",
            sprite = L.boss.x > 0 and "idibiks/joint_right" or "idibiks/joint_left",
            x =
                origin_x,
            y = L.boss.y
        })

    if L.player.is_punching() then
        for _i, pipe in ipairs(pipes) do
            if L.collide(L.player, pipe) and not L.hit_time then
                L.hit_time = L.time()
                L.boss.hp = L.boss.hp - 1
                L.player.vel_y = -1000
                if #L.scars == 0 then
                    L.scars = nil
                end
                --L.print("hit")
                break
            end
        end
    end

    if L.spill and L.collide(L.spill, L.player) or L.water_level and L.collide(L.water_level, L.player) then
       L.player.take_damage()
    end
    if L.collide(L.boss, L.player) then
        if L.boss.state == states.chasing then
            if L.player.take_damage() then
                L.player.vel_x = 1000
                L.player.vel_y = -1000
            end
        end
    end
    if not L.scars or #L.scars > 0 and L.sprite_finished(L.scars[1]) then
        spawn_scars()
    end

    L.draw({ sprite = "scenes/3", s = 6.66, sprite_t = 0.1 })

    for _i, pipe in ipairs(pipes) do
        L.draw(pipe)
    end
    Player.loop()

    for _i, scar in pairs(L.scars) do
        --L.print(scar)
        scar.x = L.boss.x < 0 and math.max(scar.x, L.boss.x) or math.min(scar.x, L.boss.x)
        scar.y = L.boss.y < 0 and math.max(scar.y, L.boss.y) or math.min(scar.y, L.boss.y)
        L.draw(scar)
    end
    --L.draw(L.patch(L.boss, {debug=true}))
    L.draw(L.boss)

    for _, proj in pairs(L.water_projs) do
        L.draw(proj)
    end

    --L.draw(L.patch(L.player, { debug = true }))
    L.draw(L.player)

    if L.spill then
        L.draw(L.spill)
    end
    if L.water_level then
        L.draw(L.patch(L.water_level, { debug = true }))
        L.draw(L.patch(L.water_level, { debug = false }))
    end

    -- L.draw(ground_bot)
    -- L.draw(ground_top)
    L.draw_hud()
    return true
end

function lvl3.startScene()
    if not lvl3.intro then
        return false
    end
	L.draw({ x = 0, y = 0, sprite = "scenes/3", s = 6.66 })
    if L.sprite_finished(L.introAnimation) and lvl3.timer ~= nil then
        L.draw({ x = 0, y = 0, sprite = "scenes/blackout", s = 6.66})
        if L.time() > lvl3.timer + lvl3.cooldwon then
        lvl3.intro = false
        end
    end
    if L.sprite_finished(L.introAnimation) and lvl3.timer == nil then
        lvl3.timer = L.time()
    end
    if not L.sprite_finished(L.introAnimation) then
        L.draw(L.introAnimation)
    end
	
	return true
end
function lvl3.endScene()
    L.nextLevel = 4
    L.active_level_i = L.transition
    L.reset()
end
return lvl3
