local L = require("lib/l")
local gravity = loadfile("draclove-love/src/gravity.lua")()

local function newWheel(initialX, initialY, offX)
    return {
		tag = "wheel",
        x = initialX,
        y = initialY,
		offsetX = offX,
        dead = false,
		sprite = nil
    }
end

function L.setup()
	L.plane = {x=0, y=0, dead=false, velocity=0}
	
	L.boss = {
		tag = "boss",
		wheels={wheel1 = newWheel(L.width/2-60, 10, -10), 
				wheel2 = newWheel(L.width/2-50, 10, 0), 
				wheel3 = newWheel(L.width/2-40,10, 10)},
		x=L.width/2-50, y=0, sideOffset=50,
		velocity=0, dead=false, 
		dashSpeed=700, inAction=false, dashingLeft=false,
		currentCooldown=0, lastActionTime=0,
		lastAttack="",
		sprite = nil
	}
	L.player = {x=0,y=0, speed = 8, vel_x = 0, vel_y=0, hunger = 0, dodging = false, sprite="idle"}
end

local ground = {x=0, y=300, sx=100}
local level_1 = {
	boss = {x=0,y=0,phase="start"},
	np_objects = {}, -- non player objects
}

function level_1.init()
	
end

local movement_const = 60

function level_1.player_movement(dt)
	if L.player.dodging then
		return
	end
	local player_speed = L.player.speed
	local jump_speed = -30
	if L.key_down("d") then
		L.player.vel_x = player_speed * movement_const
	elseif L.key_down("a") then  
		L.player.vel_x = -player_speed * movement_const
	else
		L.player.vel_x = 0
	end

	if L.key_down("space") and L.player.on_ground then
		L.player.vel_y = jump_speed * movement_const
	end
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


local function renderBoss()
	L.draw(L.boss)
	for _, wheel in pairs(L.boss.wheels) do
		L.draw(wheel)
	end
end
-- called in each loop
local function bossLoopLogic(dt)
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



function obj_live(obj)
	
end


function level_1.interact_with(obj) 
	-- for the given tag of obj, run the specific interaction
	
end


function level_1.player_action()
	if L.key_pressed("c") then
		L.player.dodging = true
		L.player.sprite = "matrix"
		L.player.sprite_t = 0.1
		L.player.sprite_start = L.time()
	end
end

function level_1.player_state_handler()
	if L.player.dodging and L.sprite_finished(L.player) then
		L.player.dodging = false
		L.player.sprite = "idle"
	end
end


function level_1.loop(dt)
	level_1.player_movement(dt)
	level_1.player_action()
	level_1.player_state_handler()
	gravity.change_vel(L.player)
	L.move_vel(L.player)
	L.player.on_ground = gravity.ground_collide(L.player, ground)
	L.draw(L.player)
	L.draw(ground)
	

	renderBoss()
	bossLoopLogic(dt)

	for np_obj in ipairs(level_1.np_objects) do
		L.move_vel(np_obj)
		if L.collide(L.player,np_obj) and L.key_pressed("x") then
			level_1.interact_with(np_obj)
		end
		L.draw(np_obj)
	end
end


function L.render(dt)
	level_1.loop(dt)
end

