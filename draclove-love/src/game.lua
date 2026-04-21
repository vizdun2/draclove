local L = require("lib/l")

function L.setup()
	L.plane = {x=0, y=0, dead=false, velocity=0}

end

local function move_plane(dt)
	local speed_const = 1
	local upspeed_const = 10
	local down_velocity_min = -10
	if L.plane.velocity > down_velocity_min then
		L.plane.velocity = L.plane.velocity - dt * speed_const 
	end
	if L.key_released("space")  then
		L.plane.velocity = upspeed_const
	end
end

function L.render(dt)
	move_plane(dt)
	L.draw({text="Dt: " .. dt, font="pixelifysans",font_size=42,align="mm",x=0,y=0})
	L.draw(L.plane)
end

