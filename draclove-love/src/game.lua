local L = require("lib/l")
L.clear_pck_cache()
local gravity = require("src/gravity")
local CB = require("src/chairBoss")

local ground = { x = 0, y = 300, sx = 100, tag = "ground" }
local ground1 = { x = 0, y = -300, sx = 100, tag = "ground" }
local level_1 = {
	boss = { x = 0, y = 0, phase = "start" },
	np_objects = { ground, ground1 }, -- non player objects
}

local hunger_limit = 3

function L.setup()
	CB.newBoss()
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
		if L.player.hunger > hunger_limit then
			L.player.dead = true
			L.printNoBs("You died. Rip bozo.")
		end
	end

	L.level_1 = L.patch({
		boss = { x = 0, y = 0, phase = "start" },
		np_objects = {}, -- non player objects
	}, level_1)
end

local ground = { x = 0, y = 300, sx = 100 }

function level_1.init()

end

local movement_const = 60





function level_1.interact_with(obj)
	-- for the given tag of obj, run the specific interaction
end

local function player_action()
	if L.key_pressed("c") then
		L.player.dodging = true
		L.player.sprite = "player/matrix"
		L.player.sprite_t = 0.05
		L.player.sprite_start = L.time()
	end
	if L.key_pressed("x") then
		L.player.sprite = "player/punch"
		L.player.punching = true
		L.player.sprite_t = 0.05
		L.player.sprite_start = L.time()
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
	end

	if L.player.dodging or not L.player.on_ground then
		return
	end
	local player_speed = L.player.speed
	local jump_speed = -30
	if L.key_down("d") then
		L.player.vel_x = player_speed * movement_const
		L.player.sprite_t = 0.1
		L.player.sx = 1
		L.player.sprite = "player/runnin"
	elseif L.key_down("a") then
		L.player.vel_x = -player_speed * movement_const
		L.player.sprite_t = 0.1
		L.player.sx = -1
		L.player.sprite = "player/runnin"
	else
		if not L.player.punching then
			L.player.sprite = "player/idle"
			L.player.sprite_t = 0.1
		end
		L.player.vel_x = 0
	end

	if L.key_down("space") and L.player.on_ground then
		L.player.vel_y = jump_speed * movement_const
	end

	if L.player.hurt_time and L.pasttime(L.player.hurt_time + 0.4) then
		L.hurt_time = nil
		L.player.c = "#FFFFFF"
	elseif L.player.hurt_time then
		L.player.sprite = "player/damage"
		L.player.c = "#FF4040"
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
	CB.bossLoopLogic(dt, L.player)

	for _, np_obj in ipairs(level_1.np_objects) do
		L.move_vel(np_obj)
		if L.collide(L.player, np_obj) and L.key_pressed("x") then
			level_1.interact_with(np_obj)
		end
		L.draw(np_obj)
	end
	for _, projectile in pairs(L.boss.projectiles) do
		for i, np_obj in ipairs(level_1.np_objects) do
			if L.collide(projectile, np_obj) then
				CB.projectileNPCollision(projectile, np_obj, dt)
				break
			end
		end
		CB.handleWallBounce(projectile, L.width / 2, L.height / 2)
		L.draw(projectile)
	end

	for i = 1, hunger_limit, 1 do
		L.draw({ sprite = "icons/hunger", s = 3, x = -600 + (i - 1) * 60, y = 250, c = (i > L.player.hunger and "FFFFFF" or "606060") })
	end
end

function L.render(dt)
	level_1.loop(dt)
end
