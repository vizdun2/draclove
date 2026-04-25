local L = require("lib/l")
L.clear_pck_cache()
local L1 = require("src/level1")
-- as of now, all levels MUST have a .setup function and a .loop function
L.levels = {L1}
L.hunger_limit = 3

function L.setup()
	L1.setup()
	L.player = {
		x = 0,
		y = 0,
		speed = 8,
		s = 2,
		vel_x = 0,
		vel_y = 0,
		hunger = 0,
		dead = false,
		dodging = false,
		punching = false,
		jumped_midair = false,
		sprite =
		"player/idle"
	}
	function L.player.take_damage()
		L.player.hurt_time = L.time()
		L.player.hunger = L.player.hunger + 1
		if L.player.hunger > L.hunger_limit then
			L.player.dead = true
			--L.printNoBs("You died. Rip bozo.")
		end
	end
	-- set the level variable for this file
	L.level_1 = L1
end


local movement_const = 60







local function player_action()
	if L.key_pressed("c") then
		L.player.dodging = true
		L.player.sprite = "player/matrix"
		L.player.sprite_t = 0.05
		L.player.sprite_start = L.time()
		L.player.pr, L.player.pl = 0, 0
		L.player.pt = -30
	end
	if L.key_pressed("x") then
		L.player.sprite = "player/punch"
		L.player.punching = true
		L.player.sprite_t = 0.05
		L.player.sprite_start = L.time()
		L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
	end
end

local function player_state_handler()
	if L.player.dodging and L.sprite_finished(L.player) then
		L.player.dodging = false
		L.player.sprite = "player/idle"
	elseif L.player.punching and L.sprite_finished(L.player) then
		L.player.sprite = "player/idle"
		L.player.punching = false
	end
end
local function player_movement()
	if not L.player.on_ground and not L.player.punching then
		L.player.sprite = "player/inair"
		L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
	end

	local player_speed = L.player.speed
	local jump_speed = -25

	if L.key_down("space") then
		if L.player.on_ground then
			L.player.vel_y = jump_speed * movement_const
			L.player.jumped_midair = false
			-- reset this
			L.key_pressed("space")
		elseif L.key_pressed("space") and not L.player.jumped_midair then
			L.player.vel_y = jump_speed * movement_const
			L.player.jumped_midair = true
			L.printNoBs("Double jumped")
		end
	end

	if L.player.dodging or not L.player.on_ground then
		return
	end
	
	if L.key_down("d") then
		L.player.vel_x = player_speed * movement_const
		L.player.sprite_t = 0.1
		L.player.sx = 1
		L.player.sprite = "player/runnin"
		L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
	elseif L.key_down("a") then
		L.player.vel_x = -player_speed * movement_const
		L.player.sprite_t = 0.1
		L.player.sx = -1
		L.player.sprite = "player/runnin"
		L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
	else
		if not L.player.punching then
			L.player.sprite = "player/idle"
			L.player.sprite_t = 0.1
			L.player.pr = (L.player.sx == -1) and -30 or -3
			L.player.pl = (L.player.sx == -1) and -3 or -30
			L.player.pt = 0
		end
		L.player.vel_x = 0
	end

	if L.player.hurt_time and L.pasttime(L.player.hurt_time + 0.4) then
		L.hurt_time = nil
		L.player.c = "#FFFFFF"
	elseif L.player.hurt_time then
		L.player.sprite = "player/damage"
		L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
		L.player.c = "#FF4040"
	end
end

function L.base_player_loop()
	player_action()
	player_state_handler()
	player_movement()
end




function L.render(dt)
	L.levels[1].loop(dt)
end
