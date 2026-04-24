local L = require("lib/l")

function L.setup()
	L.plane = {x=0, y=0, dead=false, velocity=0}
	L.wheel = {x=0, y=0, dead=false}
	L.boss = {
		wheels={L.wheel, L.wheel, L.wheel, L.wheel},
		x=L.width/2, y=0, 
		velocity=0, dead=false, 
		dashSpeed=200, inAction=false, 
		currentCooldown=0, lastActionTime=0,
		lastAttack=""
	}
end

local function change_plane_velocity(dt)
	local downspeed_const = 300
	local upspeed_const = -300
	local down_velocity_min = 1000
	local cap_const_up = 10
	local cap_const_down = -50
	if L.plane.velocity < down_velocity_min then
		if L.plane.velocity > cap_const_down and L.plane.velocity < cap_const_up then
			L.plane.velocity = cap_const_up
		else
			L.plane.velocity = L.plane.velocity + dt * downspeed_const 
		end
	end
	if L.key_pressed("space")  then
		L.plane.velocity = upspeed_const
	end
end

local function move_plane(dt)
	local updated_coords = L.plane.y + L.plane.velocity * dt

	if updated_coords >= -L.height/2 and updated_coords <= L.height/2 then
		L.plane.y = updated_coords
	elseif updated_coords <= -L.height/2 then
		L.plane.y=-L.height/2
	else
		L.plane.y=L.height/2
	end
end

local function dashAttack()
	L.boss.inAction = true
	L.boss.currentCooldown = 2
	L.boss.lastAttack = "dash"
end
local function resetBoss()
	L.boss.inAction = false
	L.boss.currentCooldown = 0
end
local function handleDashMovement(dt)
	L.boss.x = L.boss.x - L.boss.dashSpeed * dt
	if L.boss.x <= 0 then
		resetBoss()
	end
end
local function outOfBounds(x, y, obj)
	return {L.obj.x >= L.width/2 or L.obj.x <= -L.width/2, 
			L.obj.y >= L.height/2 or L.obj.y <= -L.height/2}
end

local function stunPhase()
	local stunCooldown = 5
	L.boss.lastAttack = "stun"
	L.boss.currentCooldown = stunCooldown
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

-- called in each loop
local function bossLoopLogic(dt)
	if L.pasttime(L.boss.lastActionTime + L.boss.currentCooldown and L.boss.inAction) then
		resetBoss()
	end
	if L.boss.inAction then
		if L.boss.lastAttack == "dash" then
			handleDashMovement(dt)
			local boundries = outOfBounds(L.boss.x, L.boss.y, L.boss)
			if boundries[1] then
				L.boss.x = (L.boss.x >= 0 and L.width/2) or -L.width/2
				resetBoss()
			end
			if boundries[2] then
				L.boss.y = (L.boss.y >= 0 and L.height/2) or -L.height/2
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
function L.render(dt)
	change_plane_velocity(dt)
	move_plane(dt)
	L.draw(L.plane)
	L.print(L.plane)
	if L.key_released("backspace") then
		L.reset()
	end
end

