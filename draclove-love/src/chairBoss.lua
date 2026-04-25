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
        sprite = nil,
        spawnTime = L.time(),
        lifeTime = 10
    }
end

function CB.newBoss()
    L.boss = {
        tag = "boss",
        projectiles = {},
        x = L.width / 2 - 90,
        y = 50,
        sideOffset = 90,
        velocity = 0,
        dead = false,
        dashSpeed = 700,
        inAction = false,
        dashingLeft = false,
        currentCooldown = 0,
        lastActionTime = 0,
        lastAttack = "",
        sprite = "chair/zidle_idle",
        sprite_t = 0.1,
        s = 7,
    }

    L.boss.wheels = {
        wheelm = {
            tag = "wheel",
            x = -10,
            y = 28.5 * L.boss.s,
            s = 1.3,
            dead = false,
            sprite = nil,
            parent = L.boss
        },
        wheell = {
            tag = "wheel",
            x = -18.5 * L.boss.s,
            y = 26.5 * L.boss.s,
            s = 1.3,
            dead = false,
            sprite = nil,
            parent = L.boss
        },
        wheelr = {
            tag = "wheel",
            x = 18.5 * L.boss.s,
            y = 26.5 * L.boss.s,
            s = 1.3,
            dead = false,
            sprite = nil,
            parent = L.boss
        },
    }
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

    return hasBounced
end

local function enterAction(attack, cooldown)
    L.boss.lastAttack = attack
    L.boss.currentCooldown = cooldown
    L.boss.inAction = true
    L.boss.lastActionTime = L.time()
end
local function spawnProjectile(x, y, velX, velY)
    local proj = CB.newProjectile(x, y, velX, velY)
    table.insert(L.boss.projectiles, proj)
end
local function despawnProjectile(proj)
    L.boss.projectiles[proj].dead = true
    table.remove(L.boss.projectiles, proj)
end
local function drawProjectiles()
    for _, proj in pairs(L.boss.projectiles) do
        if not proj.dead then
            L.draw(proj)
        end
    end
end
local function updateProjectiles(dt)
    local xLimit = L.width / 2
    local yLimit = L.height / 2

    for i = #L.boss.projectiles, 1, -1 do
        local proj = L.boss.projectiles[i]
        if not proj.dead then
            L.move_vel(proj)

            if L.collide(L.player, proj) then
                L.player.take_damage()
                despawnProjectile(i)
            elseif L.time() - proj.spawnTime >= proj.lifeTime then
                despawnProjectile(i)
            end
        else
            table.remove(L.boss.projectiles, i)
        end
    end
end

local function dashAttack()
    enterAction("dash", 4)
    if L.boss.x >= 0 then
        L.boss.dashingLeft = true
    else
        L.boss.dashingLeft = false
    end
end
local function resetBoss()
    L.boss.inAction = false
    L.boss.currentCooldown = 0
end
local function handleDashMovement(dt)
    local moveDistance = L.boss.dashSpeed * dt

    if L.boss.dashingLeft then
        L.boss.x = L.boss.x - moveDistance
    else
        L.boss.x = L.boss.x + moveDistance
    end
end
local function projectileAttack(player)
    local speed = 200
    local x, y = L.vec_to(player, L.boss)
    enterAction("projectile", 3)
    spawnProjectile(L.boss.x, L.boss.y, speed * x, speed * y)
end


local function stunPhase()
    local stunCooldown = 3
    enterAction("stun", stunCooldown)
end
-- gets next attack -> the automat logic
local function getNextAttack(player)
    if L.boss.currentCooldown <= 0 and L.boss.lastAttack ~= "dash" and L.boss.lastAttack ~= "stun" then
        dashAttack()
    elseif L.boss.currentCooldown <= 0 and L.boss.lastAttack == "stun" then
        projectileAttack(player)
    elseif L.boss.currentCooldown <= 0 and L.boss.lastAttack == "dash" then
        stunPhase()
    end
end
-- (A and B) or C -> B if A true, otherwise C


function CB.renderBoss()
    L.draw(L.boss)
    for _, wheel in pairs(L.boss.wheels) do
        L.draw(L.patch(wheel, { debug = true }))
    end
end

-- called in each loop
function CB.bossLoopLogic(dt, player)
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
