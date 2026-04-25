local L = require("lib/l")
local gravity = require("src/gravity")
local lvl2 = {}

local ground_bot = { x = 0, y = 300, sx = 100, tag = "ground" }
local ground_top = { x = 0, y = -300, sx = 100, tag = "ground" }

---@enum
local door_states = {
    going = 0,
    staying = 1,
    waiting_middle = 4,
    slam_prep = 5,
    about_to_slam = 7,
    slam = 6,
    slammed = 8,
    unslam = 9,
    unrot_prep = 11,
    unrot = 10,
};

local normal_y = 60

function lvl2.setup()
    L.boss = {
        x=0,
        y=normal_y,
        -- sy=3,
        -- sx=2,
        s=4.5,
        r=0,
        state = door_states.staying,
        state_begin = L.time(),
        next_state = 1,
        hp = 3,
        sprite = "door/door",
    }
    L.player = {
		debug=true,
		x = 0,
		y = 0,
		speed = 15,
		s = 2,
		vel_x = 0,
		vel_y = 0,
		hunger = 0,
		last_dodged = 0,
		dead = false,
		jumped_midair = true,
		sprite =
		"player/idle"
	}
    function L.player.is_dodging()
		return L.player.sprite == "player/matrix_from_air" or L.player.sprite =="player/matrix_from_idle"
	end

	function L.player.is_punching()
		return L.player.sprite == "player/punch_from_idle" or L.player.sprite=="player/punch_from_air"
	end

	function L.player.is_inair()
		return L.player.sprite == "player/in_air"
	end

	function L.player.is_jump_from_idle()
		return L.player.sprite=="player/jump_from_idle"
	end

	function L.player.is_jump_from_air()
		return L.player.sprite == "player/jump_from_air"
	end

    function L.player.take_damage()
		if L.player.is_dodging() then
			return false
		end
		if L.player.hurt_time ~= nil and L.time() - L.player.hurt_time < 1 then
			return false
		end
		L.player.hurt_time = L.time()
		L.player.hunger = L.player.hunger + 1
		if L.player.hunger > L.hunger_limit then
			L.player.dead = true
			--L.printNoBs("You died. Rip bozo.")
		end
		return true
	end
end

local x_limit = 550
local x_speed = 800
local r_speed = 60
local slam_speed = 1000
local unslam_speed = -500
local y_limit = 220

local function door_move()
    local dir_states = {1, -1, -1, 1}
    local target_states = {1, 0, -1, 0}
    local speed_mult = 1

    if L.boss.hp == 2 then
        speed_mult = 1.5
    elseif L.boss.hp <= 1 then
        speed_mult = 2
    end

    if L.boss.state == door_states.going then
        L.move_vel(L.boss)

        if L.boss.vel_x < 0 and L.boss.x <= L.boss.target_x or L.boss.vel_x >= 0 and L.boss.x >= L.boss.target_x then
            L.boss.state = L.boss.target_x == 0 and door_states.waiting_middle or door_states.staying
            L.boss.state_begin = L.time()
        end
    end

    if L.boss.state == door_states.waiting_middle and L.pasttime(L.boss.state_begin + 1 / speed_mult) then
        L.boss.state = door_states.slam_prep
    end

    if L.boss.state == door_states.slam_prep then
        L.boss.r = L.boss.r + r_speed * L.dt * speed_mult
        if L.boss.r >= 90 then
            L.boss.r = 90
            L.boss.state = door_states.about_to_slam
            L.boss.state_begin = L.time()
        end
    end

    if L.boss.state == door_states.about_to_slam and L.pasttime(L.boss.state_begin + 2 / speed_mult) then
        L.boss.state = door_states.slam
    end

    if L.boss.state == door_states.slam then
        L.boss.vel_x = 0
        L.boss.vel_y = slam_speed * speed_mult
        L.move_vel(L.boss)
        if L.boss.y >= y_limit then
           L.boss.y = y_limit
           L.boss.state = door_states.slammed
           L.boss.state_begin = L.time()
        end
    end

    if L.boss.state == door_states.slammed and L.pasttime(L.boss.state_begin + 1 / speed_mult) then
        L.boss.state = door_states.unslam
    end

    if L.boss.state == door_states.unslam then
        L.boss.vel_x = 0
        L.boss.vel_y = unslam_speed * speed_mult
        L.move_vel(L.boss)
        if L.boss.y <= normal_y then
           L.boss.y = normal_y
           L.boss.state = door_states.unrot_prep
        end
    end

    if L.boss.state == door_states.unrot_prep and L.pasttime(L.boss.state_begin + 1 / speed_mult) then
        L.boss.state = door_states.unrot
    end

    if L.boss.state == door_states.unrot then
        L.boss.r = L.boss.r - r_speed * L.dt * speed_mult
        if L.boss.r <= 0 then
            L.boss.r = 0
            L.boss.state = door_states.staying
            L.boss.state_begin = L.time()
        end
    end

    if L.boss.state == door_states.staying and L.pasttime(L.boss.state_begin + 1 / speed_mult) then
        L.boss.state = door_states.going
        local dir_mult = dir_states[((L.boss.next_state - 1) % #dir_states) + 1]
        local target_mult = target_states[((L.boss.next_state - 1) % #target_states) + 1]
        L.boss.vel_x = x_speed * dir_mult * speed_mult
        L.boss.vel_y = 0
        L.boss.target_x = x_limit * target_mult
        L.boss.next_state = L.boss.next_state + 1
    end
end

function lvl2.loop(dt)
    L.base_player_loop()
    gravity.change_vel(L.player)
	L.move_vel(L.player)
	L.player.on_ground = gravity.ground_collide(L.player, L1.ground)

    local collide, from_above, _ = gravity.check_collide(L.player, L.boss)
    if collide then
        if from_above then
            L.boss.hp = L.boss.hp - 1
            L.print("jumped on", L.boss.hp)
        else
            L.player.take_damage()
        end
    end

    door_move()

    L.draw(L.patch(L.boss, {debug=true, pl=-13, pr=-23, pb=-40}))
    L.draw(L.boss)
    L.draw(L.player)
    L.draw(ground_bot)
    L.draw(ground_top)
    L.draw_hud()
end

return lvl2