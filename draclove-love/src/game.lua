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

local function player_movement()
	if L.player.dodging then
		return
	end
	local player_speed = L.player.speed
	local jump_speed = -30
	if L.key_down("d") then
		L.player.vel_x = player_speed * movement_const
		L.player.sprite_t = 0.1
		L.player.sx = 1
		L.player.sprite = "runnin"
	elseif L.key_down("a") then  
		L.player.vel_x = -player_speed * movement_const
		L.player.sprite_t = 0.1
		L.player.sx = -1
		L.player.sprite = "runnin"
	else
		L.player.sprite = "idle"
		L.player.vel_x = 0
	end

	if L.key_down("space") and L.player.on_ground then
		L.player.vel_y = jump_speed * movement_const
	end

	if not L.player.on_ground then
		L.player.sprite = "inair"
	end
end

function obj_live(obj)
	
end


function level_1.interact_with(obj) 
	-- for the given tag of obj, run the specific interaction
	
end


local function player_action()
	if L.key_pressed("c") then
		L.player.dodging = true
		L.player.sprite = "matrix"
		L.player.sprite_t = 0.05
		L.player.sprite_start = L.time()
	end
end

local function player_state_handler()
	if L.player.dodging and L.sprite_finished(L.player) then
		L.player.dodging = false
		L.player.sprite = "idle"
	end
end
local function player_movement()
	if L.player.dodging then
		return
	end
	local player_speed = L.player.speed
	local jump_speed = -30
	if L.key_down("d") then
		L.player.vel_x = player_speed * movement_const
		L.player.sprite_t = 0.1
		L.player.sx = 1
		L.player.sprite = "runnin"
	elseif L.key_down("a") then  
		L.player.vel_x = -player_speed * movement_const
		L.player.sprite_t = 0.1
		L.player.sx = -1
		L.player.sprite = "runnin"
	else
		L.player.sprite = "idle"
		L.player.vel_x = 0
	end

	if L.key_down("space") and L.player.on_ground then
		L.player.vel_y = jump_speed * movement_const
	end

	if not L.player.on_ground then
		L.player.sprite = "inair"
	end
end

local function base_player_loop()
	player_movement()
	player_action()
	player_state_handler()
end

function level_1.loop(dt)
	base_player_loop()
	gravity.change_vel(L.player)
	L.move_vel(L.player)
	L.player.on_ground = gravity.ground_collide(L.player, ground)
	L.draw(L.player)
	L.draw(ground)
	

	CB.renderBoss()
	CB.bossLoopLogic(dt)

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

