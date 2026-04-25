local L = require("lib/l")
local CB = {}
local projectile_speed = 4
function CB.newProjectile(initialX, initialY, velX, velY)
    return {
        tag = "projectile",
        x = initialX,
        y = initialY,
        vel_x = velX * projectile_speed,
        vel_y = velY * projectile_speed,
        dead = false,
        sprite = "chair/wheel_projectile",
        sprite_t = 0.1,
        lifeTime = 4,
        s = 6
    }
end

function CB.resetBossHealth()
    L.boss.dead = false
    L.boss.wheels = {
        wheelm = {
            tag = "wheel",
            x = -25 * L.boss.s,
            y = 0 * L.boss.s,
            s = 1.3,
            dead = false,
            sprite = nil,
            parent = L.boss,
            canBeHit = false
        },
        wheell = {
            tag = "wheel",
            x = -25 * L.boss.s,
            y = 10 * L.boss.s,
            s = 1.3,
            dead = false,
            sprite = nil,
            parent = L.boss,
            canBeHit = false
        },
        wheelr = {
            tag = "wheel",
            x = -25 * L.boss.s,
            y = -10 * L.boss.s,
            s = 1.3,
            dead = false,
            sprite = nil,
            parent = L.boss,
            canBeHit = false
        },
    }
end

-- charge state - player can punch the wheels
-- take damage on collision

CB.oneliners = { { text = "I will crush you like a pringle", audio = "pringle.wav" }, { text = "*Rolls her wheels*", audio = "" }, { text = "Suck my wheels, stoner", audio = "suck.wav" }, { text = "Are you going to the shower? I know you have to.", audio = "shower.wav" } }

function CB.newBoss()
    L.boss = {
        nextBossLineAt = 0 + math.random(5),
        tag = "boss",
        projectiles = {},
        wheels = {},
        x = L.width / 2 - 90,
        y = 50,
        sideOffset = 90,
        velocity = 0,
        dead = false,
        dashSpeed = 1500,
        inAction = false,
        dashingLeft = false,
        chargingUp = false,
        lostWheelThisPhase = false,
        currentCooldown = 0,
        lastActionTime = 0,
        lastAttack = "stun",
        sprite = "chair/zidle_idle",
        sprite_t = 0.1,
        s = 7,
        speedMultiplier = 0.1,
        currentMultiplier = 0.1,
        pl = -10,
        pr = -10,
        dashCount = 0,
        projectileCount = 0,
        deathCount = 0,
    }

    CB.resetBossHealth()
end

-- do NOT touch the logic. Only god could fix it if you do.
function CB.projectileNPCollision(proj, npObj, dt)
    proj.x = proj.x - (proj.vel_x * dt)
    local stillCollidingX = L.collide(proj, npObj)
    proj.x = proj.x + (proj.vel_x * dt)

    proj.y = proj.y - (proj.vel_y * dt)
    local stillCollidingY = L.collide(proj, npObj)
    proj.y = proj.y + (proj.vel_y * dt)

    if not stillCollidingX then
        proj.vel_x = -proj.vel_x
    end

    if not stillCollidingY then
        proj.vel_y = -proj.vel_y
    end
    proj.lifeTime = proj.lifeTime - 1
end

function CB.handleWallBounce(obj, xLimit, yLimit)
    local hasBounced = false

    if obj.x >= xLimit then
        obj.x = xLimit
        obj.vel_x = -obj.vel_x
        hasBounced = true
    elseif obj.x <= -xLimit then
        obj.x = -xLimit
        obj.vel_x = -obj.vel_x
        hasBounced = true
    end

    if obj.y >= yLimit then
        obj.y = yLimit
        obj.vel_y = -obj.vel_y
        hasBounced = true
    elseif obj.y <= -yLimit then
        obj.y = -yLimit
        obj.vel_y = -obj.vel_y
        hasBounced = true
    end
    if hasBounced then
        obj.lifeTime = obj.lifeTime - 1
    end
    return hasBounced
end

local function turnWheelsVulnerable()
    for _, wheel in pairs(L.boss.wheels) do
        wheel.canBeHit = true
    end
end
local function turnWheelsInvulnerable()
    for _, wheel in pairs(L.boss.wheels) do
        wheel.canBeHit = false
    end
end

local function enterAction(attack, cooldown)
    L.boss.lastAttack = attack
    L.boss.currentCooldown = cooldown
    L.boss.inAction = true
    L.boss.lastActionTime = L.time()
end
local function chargePhase()
    enterAction("charge", 2.5)
    L.boss.chargingUp = true
    L.boss.sprite = "chair/chair_lift_off"
    L.boss.r = (L.boss.x > 0 and 90) or -90
    turnWheelsVulnerable()
end
local function spawnProjectile(x, y, velX, velY)
    local proj = CB.newProjectile(x, y, velX, velY)
    table.insert(L.boss.projectiles, proj)
end
local function despawnProjectile(proj)
    L.boss.projectiles[proj].dead = true
    table.remove(L.boss.projectiles, proj)
end

local function updateProjectiles(dt)
    local xLimit = L.width / 2
    local yLimit = L.height / 2

    for i = #L.boss.projectiles, 1, -1 do
        local proj = L.boss.projectiles[i]
        if not proj.dead then
            L.move_vel(proj)

            if L.collide(L.player, proj) then
                if L.player.take_damage() then
                    despawnProjectile(i)
                end
            elseif proj.lifeTime <= 0 then
                despawnProjectile(i)
            end
        else
            table.remove(L.boss.projectiles, i)
        end
    end
end

local function dashAttack()
    turnWheelsInvulnerable()
    for _, wheel in pairs(L.boss.wheels) do
        wheel.x = wheel.x * -1
    end
    enterAction("dash", 4)
    L.boss.currentMultiplier = 0.1
    if L.boss.x >= 0 then
        L.boss.dashingLeft = true
    else
        L.boss.dashingLeft = false
    end
end

local function bossLine()
    if L.boss.nextBossLineAt < L.time() then
        local oneliner = L.patch(CB.oneliners[math.random(4)], {})
        oneliner.audio = "audio/chair/" .. oneliner.audio
        oneliner.text = "Chair: " .. oneliner.text
        L.push_dialogue(oneliner)
        L.boss.nextBossLineAt = L.boss.nextBossLineAt + 20 + math.random(10)
    end
end

local function resetBoss()
    L.boss.inAction = false
    L.boss.currentCooldown = 0
    L.boss.chargingUp = false
    L.boss.lostWheelThisPhase = false
    L.boss.sprite = "chair/idle"
    L.boss.r = 0
end
local function handleDashMovement(dt)
    local moveDistance = L.boss.dashSpeed * dt
    L.boss.currentMultiplier = L.boss.currentMultiplier + (L.boss.currentMultiplier * L.boss.speedMultiplier)
    if L.boss.dashingLeft then
        L.boss.x = L.boss.x - moveDistance * L.boss.currentMultiplier
    else
        L.boss.x = L.boss.x + moveDistance * L.boss.currentMultiplier
    end
end
local function projectileAttack(player, extrax, extray)
    local speed = 150
    local x, y = L.vec_to(player, L.boss)
    spawnProjectile(L.boss.x, L.boss.y, speed * -x * extrax, speed * -y * extray)
end
local function stunAttack()
    enterAction("stun", 2)
    L.boss.sprite = "chair/idle"
end

local function projecAttack()
    enterAction("projectile", 1.5)
    L.boss.sprite = "chair/runnin"
    projectileAttack(L.player, 1, 1)
    projectileAttack(L.player, 1, -1)
    projectileAttack(L.player, -1, 1)
end


-- gets next attack -> the automat logic
-- charge -> dash -> stun -> repeat
local function getNextAttack(player)
    -- the boss first sends a string of vicious mockery towards the player


    if L.boss.currentCooldown <= 0 then
        if L.boss.lastAttack == "charge" then
            dashAttack()
        elseif L.boss.lastAttack == "dash" or L.boss.lastAttack == "projectile" then
            stunAttack()
        elseif L.boss.lastAttack == "stun" then
            if L.boss.projectileCount < 2 then
                L.boss.projectileCount = L.boss.projectileCount + 1
                L.boss.dashCount = 0

                projecAttack()
            else
                L.boss.dashCount = L.boss.dashCount + 1
                L.boss.projectileCount = 0

                chargePhase()
            end
        end
    end
end
-- (A and B) or C -> B if A true, otherwise C
local function playerWheelCollision()
    for wheelKey, wheel in pairs(L.boss.wheels) do
        if L.collide(L.player, wheel) then
            return wheelKey
        end
    end
    return nil
end
local function loseAWheel(wheel)
    local wheelKey = wheel
    if not wheelKey then
        return
    end
    L.boss.wheels[wheelKey] = nil

    L.boss.lostWheelThisPhase = true

    if L.table_length(L.boss.wheels) <= 0 then
        L.boss.dead = true
        return
    end

    projectileAttack(L.player, 1, 1)
    L.player.vel_y = -1500
end
function L.onCollisionWithPlayer()
    --L.printNoBs("Collided " .. L.boss.lastAttack .. " " .. tostring(L.boss.chargingUp) .. " " .. tostring(L.boss.lostWheelThisPhase))
    if L.boss.chargingUp and L.player.is_punching() and not L.boss.lostWheelThisPhase then
        local colidedWheel = playerWheelCollision()
        if colidedWheel then
            loseAWheel(colidedWheel)
        end
    elseif L.boss.inAction and L.boss.lastAttack == "dash" then
        L.player.take_damage()
    end
end

local function whatWheelToUse()
    if L.boss.lastAttack == "dash" then
        return
    elseif L.boss.lastAttack == "stun" then
        if L.boss.wheels.wheell then
            L.draw(L.patch(L.boss, { sprite = "chair/wheel_left" }))
        end
        if L.boss.wheels.wheelr then
            L.draw(L.patch(L.boss, { sprite = "chair/wheel_right" }))
        end
        if L.boss.wheels.wheelm then
            L.draw(L.patch(L.boss, { sprite = "chair/wheel_middle" }))
        end
    elseif L.boss.lastAttack == "charge" then
        if L.boss.wheels.wheell then
            L.draw(L.patch(L.boss, { sprite = "chair/wheel_left_lift_off" }))
        end
        if L.boss.wheels.wheelr then
            L.draw(L.patch(L.boss, { sprite = "chair/wheel_right_lift_off" }))
        end
        if L.boss.wheels.wheelm then
            L.draw(L.patch(L.boss, { sprite = "chair/wheel_middle_lift_off" }))
        end
    end
end
function CB.renderBoss()
    --L.draw(L.patch(L.boss, { debug = true }))
    L.draw(L.boss)
    whatWheelToUse()
    for _, wheel in pairs(L.boss.wheels) do
        --L.draw(L.patch(wheel, { debug = true }))
        --L.draw(wheel)
    end
end

-- called in each loop
function CB.bossLoopLogic(dt, player)
    --L.printNoBs("iblis",L.boss.lastAttack)
    playerWheelCollision()
    bossLine()
    if L.pasttime(L.boss.lastActionTime + L.boss.currentCooldown) and L.boss.inAction then
        resetBoss()
    end

    if L.boss.inAction then
        if true and L.boss.lastAttack == "dash" then
            L.boss.sprite = "chair/flight"
            L.boss.sx = L.boss.dashingLeft and -1 or 1
            L.boss.r = L.boss.dashingLeft and 90 or -90
            handleDashMovement(dt)
            local xLimit = (L.width / 2) - L.boss.sideOffset
            local yLimit = L.height / 2

            if math.abs(L.boss.x) >= xLimit then
                local isRight = L.boss.x >= 0

                L.move(L.boss, isRight and xLimit - L.boss.x or -xLimit - L.boss.x, 0)
                resetBoss()
            end

            if math.abs(L.boss.y) >= yLimit then
                local isBottom = L.boss.y >= 0
                L.boss.y = isBottom and yLimit or -yLimit

                resetBoss()
            end
            if L.boss.lastAttack == "stun" then
                -- play anim ..
            end
            if L.boss.lastAttack == "projectile" then
                -- play anim ..
            end
        end
    else
        L.boss.sprite = "chair/zidle_idle"
        L.boss.sx = L.boss.dashingLeft and 1 or -1
        L.boss.r = 0
        getNextAttack(player)
        L.boss.lastActionTime = L.time()
    end
    updateProjectiles(dt)
end

return CB
