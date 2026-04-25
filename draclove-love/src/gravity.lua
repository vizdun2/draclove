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

function gravity.check_collide(obj, ground)
    if L.collide(ground, obj) then
        L.move(obj, 0, -obj.vel_y * L.dt)
        local from_above = obj.vel_y > 0 and not L.collide(ground, obj)
        L.move(obj, 0, obj.vel_y * L.dt)
        L.move_vel(obj, -1)
        local new = not L.collide(ground, obj)
        L.move_vel(obj, 1)
        return true, from_above, new
    else
        return false, false, false
    end
end

function gravity.ground_collide(obj, ground)
    local collided, from_above, new = gravity.check_collide(obj, ground)
    if collided then
        if from_above then
            local _, oh = L.obj_dims(obj)
            local _, gh = L.obj_dims(ground)
            obj.y = ground.y - gh / 2 - oh / 2 - (obj.pb or 0)
            obj.vel_y = 0
        elseif new then
            L.move_vel(L.player, -1)
        else
            L.move(L.player, 0, -obj.vel_y * L.dt)
            L.player.vel_y = 0
        end
    end

    return collided, from_above, new
end

return gravity
