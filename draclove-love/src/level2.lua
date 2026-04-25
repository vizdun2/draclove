local L = require("lib/l")
local gravity = require("src/gravity")
local Player = require("src/player")
local lvl2 = {}

local groundBot = { x = 0, y = 300, sx = 100, tag = "ground" }

local hoverY = 20
local groundY = 220
local scales = {1, 4}
local jumpSpeeds = {-15, -35}

local function newCrack()
    local crack = {
        x=L.boss.x,
        y=L.boss.y+50,
        spawnTime=L.time(),
        lifeTime=10,
        sprite=""
    }
    table.insert(L.boss.cracks, crack)
    
end

function lvl2.setup()
    L.boss = {
        tag = "boss",
        x = 0,
        y = hoverY,
        s = 4.5,
        r = 0,
        hp = 5,
        sprite = "door/door",
        pl = -14,
        pr = -19,
        pb = 0,
        dead=false,
        
        state = "tracking", 
        attackCooldown = 3,
        lastTimeAttacked = 0,
        directionUpdateCooldown = 1.0,
        lastTimeChangedDirection = 0,
        moveSpeed = 300,
        slamThreshold = 50,
        velX = 0,
        velY = 0,
        slamSpeed = 1000,
        riseSpeed = 500,
        groundedDuration = 2.0,
        timeHitGround = 0,
        rotationSpeed = 400,

        debris = {},
        cracks = {},
    }
    Player.setup()
    L.player.x=-L.width/2+100   
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
local function spawnDebris(originX, originY)
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
            s = 1,
            velX = speedX,
            velY = speedY,
            bounces = 0,
            dead = false,
            debug = true
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
local function updateCracks()
    for _,crack in ipairs(L.boss.cracks) do
        if L.time - crack.spawnTime > crack.lifeTime then
            table.remove(L.boss.cracks, _)
        end
    end
end
function lvl2.loop(dt)
    L.draw({ x = 0, y = 0, sprite = "scenes/2", s = 6.66, sprite_t = 0.1 })
    local leftEdge = -L.width / 2
    local rightEdge = L.width / 2
    
    -- Player Lerp Updates
    L.player.s = calculatePlayerScale(L.player.x, leftEdge, rightEdge, scales)
    Player.jump_speed = calculateJumpSpeed(L.player.x, leftEdge, rightEdge, jumpSpeeds)
    
    Player.loop()
    L.player.on_ground = gravity.ground_collide(L.player, groundBot)

    -- Boss State Machine
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
            
            newCrack()
            spawnDebris(L.boss.x, groundY)
        end

    elseif L.boss.state == "grounded" then
        if L.time() - L.boss.timeHitGround >= L.boss.groundedDuration then
            L.boss.state = "rising"
            L.boss.velY = -L.boss.riseSpeed
        end

    elseif L.boss.state == "rising" then
        L.boss.y = L.boss.y + (L.boss.velY * dt)
        
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

    -- Collision & Damage Logic
    local collide, fromAbove, _ = gravity.check_collide(L.player, L.boss)
    if collide then
        if L.boss.state == "grounded" and fromAbove then
            L.player.vel_y = -2000
            L.boss.hp = L.boss.hp - 1
            L.print("Boss Hit! HP:", L.boss.hp)
            
            
            
            L.boss.state = "rising"
            L.boss.velY = -L.boss.riseSpeed
        elseif L.boss.state ~= "grounded" then
            L.player.take_damage()
        end
    end

    updateDebris(dt)
    updateCracks()
    --L.draw(L.patch(L.boss, {debug=true}))
    L.draw(L.boss)
    L.draw(L.player)
    L.draw(groundBot)
    L.draw_hud()
end

return lvl2