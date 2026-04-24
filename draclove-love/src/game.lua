local L = require("lib/l")
local gravity = loadfile("draclove-love/src/gravity.lua")()
local CB = loadfile("draclove-love/src/chairBoss.lua")()



function L.setup()
	L.plane = {x=0, y=0, dead=false, velocity=0}
	CB.newBoss()
	L.player = {x=0,y=0, speed = 8, vel_x = 0, vel_y=0, hunger = 0, dodging = true}
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

function obj_live(obj)
	
end


function level_1.interact_with(obj) 
	-- for the given tag of obj, run the specific interaction
	
end

local function player_dodge(obj)
	
end


local function player_action()
	if L.key_pressed("c") then
		player_dodge()
	end
end

local function player_state()

end

function level_1.loop(dt)
	level_1.player_movement(dt)
	
	gravity.change_vel(L.player)
	L.move_vel(L.player)
	L.player.on_ground = gravity.ground_collide(L.player, ground)
	L.draw(L.player)
	L.draw(ground)

	CB.renderBoss()
	CB.bossLoopLogic(dt)

	for np_obj in ipairs(level_1.np_objects) do
		L.move_vel(np_obj)
		if L.collide(L.player,np_obj) and L.player.interacting then
			level_1.interact_with(np_obj)
		end
		L.draw(np_obj)
	end
end


function L.render(dt)
	level_1.loop(dt)
end

