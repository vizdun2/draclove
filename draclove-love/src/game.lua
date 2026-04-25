local L = require("lib/l")
local LM = require("src/levelManager")
L.clear_pck_cache()
local L1 = require("src/level1")
-- as of now, all levels MUST have a .setup function and a .loop function
L.levels = { L1 }
L.hunger_limit = 3


function L.setup()
	L1.setup()
	
	-- dialogue event = {text="text", audio="path_to_my_audio_file"}
	L.dialogue_manager = { events = { que = {}, next_pop_i = 1, next_add_i = 1 }, next_dialogue_at = nil }
	function L.player.take_damage()
		if L.player.is_dodging() then
			return false
		end
		if L.player.hurt_time ~= nil and L.time() - L.player.hurt_time < 0.2 then
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

	-- set the level variable for this file
	L.active_level = L1
	L.push_dialogue({ text = "Hello idiot, how are you doing??", audio = nil })
end

function L.push_dialogue(dialogue_event)
	local add = L.dialogue_manager.events.next_add_i
	L.dialogue_manager.events.que[add] = dialogue_event
	L.dialogue_manager.events.next_add_i = L.dialogue_manager.events.next_add_i + 1
end

function L.pop_dialogue()
	local pop = L.dialogue_manager.events.next_pop_i
	local to_pop = L.dialogue_manager.events.que[pop]
	L.dialogue_manager.events.next_pop_i = L.dialogue_manager.events.next_pop_i + 1
	L.dialogue_manager.events.que[pop] = nil
	return to_pop
end

function L.play_dialogue()
	if L.dialogue_manager.next_dialogue_at == nil or L.time() < L.dialogue_manager.next_dialogue_at then
		local dialogue = L.pop_dialogue()
		if dialogue ~= nil then
			-- L.play(dialogue.audio)
			table.insert(L.active_level.level.np_objects,
				{
					x = -5 * string.len(dialogue.text),
					y = 310,
					is_dead_at = L.time() + string.len(dialogue.text) * 0.05,
					text =
						dialogue.text,
					tag = "text",
					font = "pixelifysans",
					font_size = 30
				})
		end
	end
end

local function player_anime(sprite, t)
	L.player.sprite = sprite
	L.player.sprite_t = t
	L.player.sprite_start = L.time()
end

local movement_const = 60
local dodge_cooldown = 0.5
local function player_action()
	if L.key_pressed("c") and L.time() - L.player.last_dodged > dodge_cooldown then
		if L.player.on_ground then
			player_anime("player/matrix_from_idle", 0.06)
		else
			player_anime("player/matrix_from_air", 0.05)
		end
		L.player.pr, L.player.pl = 0, 0
		L.player.pt = -30
		L.player.last_dodged = L.time()
	elseif L.key_pressed("x") then
		print("punched")
		if L.player.on_ground then
			player_anime("player/punch_from_idle", 0.1)
		else
			player_anime("player/punch_from_air", 0.1)
		end
		L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
	end
end

local jump_speed = -25

local function player_state_handler()
	if L.player.is_dodging() and L.sprite_finished(L.player) then
		if L.player.on_ground then
			L.player.sprite = "player/idle"
		else
			L.player.sprite = "player/in_air"
		end
	elseif L.player.is_punching() and L.sprite_finished(L.player) then
		if L.player.on_ground then
			L.player.sprite = "player/idle"
		else
			L.player.sprite = "player/in_air"
		end
	elseif L.player.is_jump_from_idle() and L.sprite_finished(L.player) then
		L.print("jumpfromidle")
		L.player.jumped_midair = false
		L.player.vel_y = jump_speed * movement_const
		L.player.sprite = "player/in_air"
	elseif L.player.is_jump_from_air() and L.sprite_finished(L.player) then
		L.player.sprite = "player/in_air"
	end
end

local function player_movement()
	if not L.player.on_ground and not L.player.is_inair() and not L.player.is_dodging() and not L.player.is_punching() and not L.player.is_jump_from_air() then
		L.player.sprite = "player/in_air"
		L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
	end

	local player_speed = L.player.speed


	if L.key_down("space") then
		if L.player.on_ground and not L.player.is_jump_from_idle() then
			player_anime("player/jump_from_idle", 0.03)
			-- reset this
		elseif L.key_pressed("space") and not L.player.jumped_midair then
			player_anime("player/jump_from_air", 0.03)
			L.player.vel_y = jump_speed * movement_const
			L.player.jumped_midair = true
		end
	end


	if L.key_down("d") then
		L.player.vel_x = player_speed * movement_const
		L.player.sx = 1
		if not L.player.is_jump_from_idle() and L.player.on_ground and not L.player.is_dodging() and not L.player.is_punching() then
			L.player.sprite_t = 0.1
			L.player.sprite = "player/runnin"
			L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
		end
	elseif L.key_down("a") then
		L.player.vel_x = -player_speed * movement_const
		L.player.sx = -1
		if not L.player.is_jump_from_idle() and L.player.on_ground and not L.player.is_dodging() and not L.player.is_punching() then
			L.player.sprite_t = 0.1
			L.player.sprite = "player/runnin"
			L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
		end
	else
		if not L.player.is_punching() and not L.player.is_dodging() and not L.player.is_jump_from_idle() then
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

function L.base_dialogue_loop()
	L.play_dialogue()
	for k, obj in ipairs(L.active_level.level.np_objects) do
		if obj.tag == "text" then
			if obj.is_dead_at < L.time() then
				L.active_level.level.np_objects[k] = nil
			end
		end
	end
end

function L.render(dt)
	L.levels[1].loop(dt)
end
