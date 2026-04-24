local L = require("lib/l")
local CB = {}

function CB.newWheel(initialX, initialY, offX)
    return {
		tag = "wheel",
        x = initialX,
        y = initialY,
		offsetX = offX,
        dead = false,
		sprite = nil
    }
end
function CB.newBoss()
    L.boss = {
		tag = "boss",
		wheels={wheel1 = CB.newWheel(L.width/2-60, 10, -10), 
				wheel2 = CB.newWheel(L.width/2-50, 10, 0), 
				wheel3 = CB.newWheel(L.width/2-40,10, 10)},
		x=L.width/2-50, y=0, sideOffset=50,
		velocity=0, dead=false, 
		dashSpeed=700, inAction=false, dashingLeft=false,
		currentCooldown=0, lastActionTime=0,
		lastAttack="",
		sprite = nil
	}
end

local function dashAttack()
	L.boss.inAction = true
	L.boss.currentCooldown = 4
	L.boss.lastAttack = "dash"
	L.boss.lastActionTime = L.time()
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
        for _, wheel in pairs(L.boss.wheels) do
			L.move(wheel, -moveDistance, 0)
        end
    else
        L.boss.x = L.boss.x + moveDistance
        for _, wheel in pairs(L.boss.wheels) do
			L.move(wheel, moveDistance, 0)
        end
    end
end
-- returns list where [1] is whether x is out of bounds, [2] is whether y is out of bounds
local function outOfBounds(x, y, obj)
	return {obj.x >= L.width/2 or obj.x <= -L.width/2, 
			obj.y >= L.height/2 or obj.y <= -L.height/2}
end

local function stunPhase()
	local stunCooldown = 3
	L.boss.lastAttack = "stun"
	L.boss.currentCooldown = stunCooldown
	L.boss.inAction = true
	L.boss.lastActionTime = L.time()
end
-- gets next attack -> the automat logic
local function getNextAttack()
	if L.boss.currentCooldown <= 0 and L.boss.lastAttack ~= "dash" then
		dashAttack()
	elseif L.boss.currentCooldown <= 0 and L.boss.lastAttack == "dash" then
		stunPhase()
	end
end
-- (A and B) or C -> B if A true, otherwise C


function CB.renderBoss()
	L.draw(L.boss)
	for _, wheel in pairs(L.boss.wheels) do
		L.draw(wheel)
	end
end
-- called in each loop
function CB.bossLoopLogic(dt)
	if L.pasttime(L.boss.lastActionTime + L.boss.currentCooldown ) and L.boss.inAction then
		resetBoss()
	end
	if L.boss.inAction then
		if L.boss.lastAttack == "dash" then
			handleDashMovement(dt)
			local xLimit = (L.width / 2) - L.boss.sideOffset
			local yLimit = L.height / 2

			if math.abs(L.boss.x) >= xLimit then
				local isRight = L.boss.x >= 0 
				
				L.move(L.boss, isRight and xLimit - L.boss.x or -xLimit - L.boss.x, 0)
				
				
				for _, wheel in pairs(L.boss.wheels) do
					wheel.x = L.boss.x - wheel.offsetX
				end
				resetBoss()
			end

			if math.abs(L.boss.y) >= yLimit then
				local isBottom = L.boss.y >= 0
				L.boss.y = isBottom and yLimit or -yLimit
				
				for _, wheel in pairs(L.boss.wheels) do
					wheel.y = L.boss.y
				end
				
				resetBoss()
			end
		if L.boss.lastAttack == "stun" then
			-- play anim .. 
		end 
	end
	else
			getNextAttack()
			L.boss.lastActionTime = L.time()
		end
end

return CB