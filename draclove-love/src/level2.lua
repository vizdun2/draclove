local L = require("lib/l")
local gravity = require("src/gravity")
local Player = require("src/player")
local lvl2 = {}

local groundBot = { x = 0, y = 300, sx = 100, tag = "ground" }

local hoverY = 20
local groundY = 220
local scales = { 1, 4 }
local jumpSpeeds = { -15, -35 }

local function newCrack()
    local crack = {
        x=L.boss.x,
        y=L.boss.y+100,
        sprite="particles/crack",
        finalSprite = "particles/crack_last",
        tag="lingerEffect",
        sprite_t=0.3,
        sprite_start = L.time(),
        startTime = L.time(),
        hasSwapped = false,
        lifetime=30,
        s=2,
    }
    table.insert(L.player.particles, crack)
end

local function newImpact()
    local impact = {
        x = L.boss.x,
        y = L.boss.y - 230,
        sprite = "particles/impact",
        tag = "tempEffect",
        sprite_t = 0.1,
        sprite_start = L.time(),
        s = 8,
    }
    table.insert(L.player.particles, impact)
end


function lvl2.setup()
    L.audio_intro("audio/soundtrack/second_ost_intro")
    L.boss = {
        tag = "boss",
        x = L.width / 2 - 100,
        y = hoverY + 150,
        s = 4.5,
        r = 0,
        hp = 5,
        normalSprite = "door/door_normal",
        monsterSprite = "door/door",
        sprite = "door/door_normal",
        pl = -18,
        pr = -24,
        pb = -5,
        pt = -5,
        dead = false,

        state = "intro",
        attackCooldown = 2,
        lastTimeAttacked = 0,
        directionUpdateCooldown = 0.8,
        lastTimeChangedDirection = 0,
        moveSpeed = 300,
        slamThreshold = 50,
        velX = 0,
        velY = 0,
        slamSpeed = 1000,
        riseSpeed = 200,
        groundedDuration = 2.0,
        timeHitGround = 0,
        rotationSpeed = 400,

        introStartTime = L.time(),
        introDuration = 3, -- How long the glitching lasts in seconds
        lastGlitchTime = L.time(),
        nextGlitchDelay = 0.1,

        debris = {},
        cracks = {},

        last_grounded = 0,
    }
    Player.setup()
    L.player.x = -L.width / 2 + 100
    L.player.y = L.height / 2 - 50
    L.player.currentDJSprite = "particles/2/jump_burst"
    lvl2.bossPieces = {"destroyed/door1", "destroyed/door2", "destroyed/door3"}
end

local function updateBossDirection(boss, player)
    local currentTime = L.time()

    if currentTime - boss.lastTimeChangedDirection >= boss.directionUpdateCooldown then
        if player.x > boss.x then
            boss.velX = boss.moveSpeed
        elseif player.x < boss.x then
            boss.velX = -boss.moveSpeed
        else
            boss.velX = 0
        end
        boss.lastTimeChangedDirection = currentTime
    end
end

local function checkForSlam(boss, player)
    local currentTime = L.time()
    local isAttackReady = (currentTime - boss.lastTimeAttacked >= boss.attackCooldown)
    local isUnderneath = math.abs(boss.x - player.x) <= boss.slamThreshold

    if isAttackReady and isUnderneath then
        boss.velX = 0
        boss.lastTimeAttacked = currentTime
        return true
    end
    return false
end
local function getUniqueRandoms(maxNumber, drawCount)
    local numberPool = {}
    for i = 1, maxNumber do
        table.insert(numberPool, i)
    end

    local drawnResults = {}
    
    for i = 1, drawCount do
        local randomIndex = math.random(1, #numberPool)
        
        table.insert(drawnResults, table.remove(numberPool, randomIndex))
    end

    return drawnResults
end
local function spawnDebris(originX, originY)
    local sprites = {
        "door/projectile1",
        "door/projectile2",
        "door/projectile3",
        "door/projectile4",
        "door/projectile5",
        "door/projectile6",
    }
    local indexes = getUniqueRandoms(6,4)

    for i = 1, 4 do
        local direction = (i % 2 == 0) and 1 or -1

        local speedX = math.random(150, 400) * direction
        local speedY = -math.random(600, 1400)

        table.insert(L.boss.debris, {
            tag = "debris",
            x = originX,
            y = originY,
            sx = 0.8,
            sy = 0.8,
            s = 2,
            sprite = sprites[indexes[i]],
            sprite_t = 0.2,
            velX = speedX,
            velY = speedY,
            bounces = 0,
            dead = false,
            debug = false
        })
    end
end

local function updateDebris(dt)
    local gravityPull = 1500

    for i = #L.boss.debris, 1, -1 do
        local d = L.boss.debris[i]

        d.velY = d.velY + (gravityPull * dt)
        d.x = d.x + (d.velX * dt)
        d.y = d.y + (d.velY * dt)

        if d.y >= groundY then
            d.y = groundY
            if d.bounces == 0 then
                d.velY = -d.velY * 0.5
                d.bounces = 1
            else
                d.dead = true
            end
        end

        if not d.dead and L.collide(L.player, d) then
            if L.player.is_punching() then

            else
                L.player.take_damage()
            end
            d.dead = true
        end

        if d.dead then
            table.remove(L.boss.debris, i)
        else
            L.draw(d)
        end
    end
end

local function calculatePlayerScale(currentX, minX, maxX, scaleRange)
    local minScale = scaleRange[1]
    local maxScale = scaleRange[2]
    local progress = (currentX - minX) / (maxX - minX)
    progress = math.max(0, math.min(1, progress))
    return minScale + ((maxScale - minScale) * progress)
end

local function calculateJumpSpeed(currentX, minX, maxX, jumpRange)
    local minJump = jumpRange[1]
    local maxJump = jumpRange[2]
    local progress = (currentX - minX) / (maxX - minX)
    progress = math.max(0, math.min(1, progress))
    return minJump + ((maxJump - minJump) * progress)
end
local function bossStateMachine(dt)
    if L.boss.state == "tracking" then
        updateBossDirection(L.boss, L.player)
        L.boss.x = L.boss.x + (L.boss.velX * dt)

        if checkForSlam(L.boss, L.player) then
            L.boss.state = "prepSlam"
            L.boss.velX = 0
        end
    elseif L.boss.state == "prepSlam" then
        L.boss.r = L.boss.r + (L.boss.rotationSpeed * dt)

        if L.boss.r >= 90 then
            L.boss.r = 90
            L.boss.state = "slamming"
            L.boss.velY = L.boss.slamSpeed
        end
    elseif L.boss.state == "slamming" then
        L.boss.y = L.boss.y + (L.boss.velY * dt)

        if L.boss.y >= groundY then
            L.boss.y = groundY
            L.boss.velY = 0
            L.boss.state = "grounded"
            L.boss.timeHitGround = L.time()

            newImpact()
            newCrack()
            spawnDebris(L.boss.x, groundY)
            L.play("audio/door_slam", 0.4)
        end
    elseif L.boss.state == "grounded" then
        if L.time() - L.boss.timeHitGround >= L.boss.groundedDuration and L.sprite_finished(L.boss) then
            L.boss.last_grounded = L.time()
            L.boss.state = "rising"
            L.boss.sprite = "door/door"
            L.boss.velY = -L.boss.riseSpeed
        end
    elseif L.boss.state == "rising" then
        L.boss.y = L.boss.y + (L.boss.velY * dt * 0.5)
        
        if L.boss.r > 0 then
            L.boss.r = math.max(0, L.boss.r - (L.boss.rotationSpeed * dt))
        end

        if L.boss.y <= hoverY then
            L.boss.y = hoverY
            L.boss.velY = 0
            L.boss.r = 0
            L.boss.state = "tracking"
            L.boss.lastTimeAttacked = L.time()
        end
    end
end


function lvl2.start_playing_audio_loop()
    Audio_source = L.play("audio/soundtrack/second_ost_loop", 0.80)
    Source_path = "audio/soundtrack/second_ost_loop"
    Audio_source:setLooping(true)
end

function lvl2.loop(dt)
    if Source_path == "audio/soundtrack/second_ost_intro" and not Audio_source:isPlaying() then
        Audio_source:stop()
        print("Started playing sountrack")
        lvl2.start_playing_audio_loop()
    end
        if L.boss.hp <= 0 then
            L.spawnDeathDebris(L.boss.x, L.boss.y, lvl2.bossPieces, 4)
            L.boss.timeOfDeath = L.time()
            L.boss.dead = true
        end
        if L.boss.dead == true then
            return false
        end
        L.draw({ x = 0, y = 0, sprite = "scenes/2", s = 6.66, sprite_t = 0.1 })
        local leftEdge = -L.width / 2
        local rightEdge = L.width / 2

        -- Player Lerp Updates
        L.player.s = calculatePlayerScale(L.player.x, leftEdge, rightEdge, scales)
        Player.jump_speed = calculateJumpSpeed(L.player.x, leftEdge, rightEdge, jumpSpeeds)

        Player.loop()
        L.player.on_ground = gravity.ground_collide(L.player, groundBot)

        -- Boss State Machine
        bossStateMachine(dt)

        -- Collision & Damage Logic
        local collide, fromAbove, _ = gravity.check_collide(L.player, L.boss)
        if collide then
            if (L.boss.state == "grounded" or not L.pasttime(L.boss.last_grounded + 0.5)) and fromAbove then
                if L.boss.sprite ~= "door/door_damaga" then
                    L.player.vel_y = -2000
                    L.boss.hp = L.boss.hp - 1
                    L.boss.sprite = "door/door_damaga"
                    L.boss.sprite_t = 0.1
                    L.boss.sprite_start = L.time()
                    L.print("Boss Hit! HP:", L.boss.hp)


                    L.boss.timeHitGround = 0
                    L.play("audio/door_cracked", 0.6)
                end
            elseif L.boss.state ~= "grounded" then
                L.player.take_damage()
            end
        end

        updateDebris(dt)
        --L.draw(L.patch(L.boss, {debug=true}))
        L.draw(L.boss)
        L.draw(L.player)
        --L.draw(groundBot)
        L.draw_hud()
    
    return true
end
function lvl2.startScene()
    if L.boss.state == "intro" then
        local currentTime = L.time()
        L.draw({ x = 0, y = 0, sprite = "scenes/1", s = 6.66 })
        L.draw(L.boss)
        L.draw(L.player)
        L.draw_hud()
        if currentTime - L.boss.lastGlitchTime >= L.boss.nextGlitchDelay then
            if L.boss.sprite == L.boss.normalSprite then
                L.boss.sprite = L.boss.monsterSprite
            else
                L.boss.sprite = L.boss.normalSprite
            end

            L.boss.nextGlitchDelay = math.random(5, 25) / 100
            L.boss.lastGlitchTime = currentTime
        end

        if currentTime - L.boss.introStartTime >= L.boss.introDuration then
            L.boss.state = "tracking"
            L.boss.sprite = L.boss.monsterSprite

            L.boss.y = hoverY
            L.boss.lastTimeChangedDirection = currentTime
            L.boss.lastTimeAttacked = currentTime
        end
        return true
    end
    return false
end
function lvl2.endScene(dt)
	L.draw({ x = 0, y = 0, sprite = "scenes/2", s = 6.66, sprite_t = 0.1 })
	L.draw(L.player)
    Player.physicsOnlyLoop()
	L.updateDeathDebris(dt, 220)
	if L.time() - L.boss.timeOfDeath >= 3.5 then
		L.nextLevel = 3
		L.active_level_i = L.transition
		L.reset()
		return false
	end
	return true
end
return lvl2
