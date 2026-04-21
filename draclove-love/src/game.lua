local L = require("lib/l")

function L.setup()
	L.plane = {x=0, y=0, dead=false, velocity=0}
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

function L.render(dt)
	change_plane_velocity(dt)
	move_plane(dt)
	L.draw(L.plane)
	L.print(L.plane)
	if L.key_released("backspace") then
		L.reset()
	end
end

