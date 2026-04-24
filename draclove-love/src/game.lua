local L = require("lib/l")

function L.setup()
	L.player = {x=0,y=0, speed = 8, vel_x = 0, vel_y=0, hunger = 0, dodging = true}
end



local level_1 = {
	boss = {x=0,y=0,phase="start"},
	np_objects = {}, -- non player objects
}

function level_1.init()
	
end

local function change_player_vel(dt)
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



function level_1.player_movement(dt)
	local player_speed = L.player.speed
	if L.key_down("d") then
		L.player.vel_x = player_speed
	elseif L.key_down("a") then
		L.player.vel_x = -player_speed
	else
		L.player.vel_x = 0
	end
	change_player_vel(dt)
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
	
	L.move_vel(L.player)
	L.draw(L.player)
	for np_obj in ipairs(level_1.np_objects) do
		L.move_vel(np_obj)
		if L.collide(L.player,np_obj) and L.player.interacting then
			level_1.interact_with(np_obj)
		end
		L.draw(np_obj)
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

function L.render(dt)
	level_1.loop(dt)
	if L.key_released("backspace") then
		L.reset()
	end
end

