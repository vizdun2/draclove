local L = require("lib/l")

local gravity = {}

function gravity.change_vel(obj)
    if not obj.vel_y then
        return
    end
    
	local downspeed_const = 80
	local down_velocity_min = 1000*20
	local cap_const_down = 20 * 50

	if obj.vel_y < down_velocity_min then
        obj.vel_y = obj.vel_y + downspeed_const
        if obj.vel_y > cap_const_down then
            obj.vel_y = cap_const_down
        end
	end
end

function gravity.ground_collide(obj, ground)
    if L.collide(obj, ground) then
		local _, oh = L.obj_dims(obj)
		local _, gh = L.obj_dims(ground)
		obj.y = ground.y - gh / 2 - oh / 2 - (obj.pb or 0)
        obj.vel_y = 0
        return true
	end

    return false
end

return gravity