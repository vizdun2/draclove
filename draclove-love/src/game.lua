local L = require("lib/l")
L.clear_pck_cache()
local L1 = require("src/level1")
local L2 = require("src/level2")
local L3 = require("src/level3")
local L5 = require("src/level5")
local GO = require("src/ItsJoeverScreen")
local MM = require("src/mainMenu")
local CO = require("src/controls")
local BS = require("src/betweenScenes")
local PS = require("src/pause")
-- as of now, all levels MUST have a .setup function and a .loop function
L.levels = { L1, L2, L3, { setup = function () end, loop = function () end }, L5, BS, CO, MM, GO }
L.hunger_limit = 5
L.failedLevel = nil
L.nextLevel = nil
L.gameOverScreen = L.table_length(L.levels)
L.mainMenu = L.table_length(L.levels)-1
L.controls = L.table_length(L.levels)-2
L.transition = L.table_length(L.levels)-3
L.pauseScreen = PS



function L.setup()
	L.active_level_i = L.active_level_i or L.mainMenu
	L.active_level().setup()

	-- dialogue event = {text="text", audio="path_to_my_audio_file"}
	L.dialogue_manager = { events = { que = {}, next_pop_i = 1, next_add_i = 1 }, next_dialogue_at = nil }
end

local last_dialogue_active_uid = nil

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
	if last_dialogue_active_uid ~= nil and (L.dialogue_manager.next_dialogue_at == nil or L.dialogue_manager.next_dialogue_at < L.time()) then
		L.active_level().lines[last_dialogue_active_uid] = nil
	end
	if (L.dialogue_manager.next_dialogue_at == nil or L.time() > L.dialogue_manager.next_dialogue_at) and L.dialogue_manager.events.next_add_i > L.dialogue_manager.events.next_pop_i then
		local dialogue = L.pop_dialogue()
		if dialogue ~= nil then
			if dialogue.audio ~= "" then
				-- L.play(dialogue.audio)
			end

			local next_at = L.time() + string.len(dialogue.text) * 0.1
			local uid = L.uid()
			L.active_level().lines[uid] =
			{
				x = -5 * string.len(dialogue.text),
				y = 310,
				is_dead_at = next_at,
				text =
					dialogue.text,
				tag = "text",
				font = "pixelifysans",
				font_size = 30
			}
			last_dialogue_active_uid = uid
			L.dialogue_manager.next_dialogue_at = next_at
		end
	end
end

function L.active_level()
	return L.levels[L.active_level_i]
end

function L.getSafeCoordinates(obj, offsetX, offsetY)
	-- Calculate the absolute limits
	local limitX = L.width / 2
	local limitY = L.height / 2

	-- Calculate the exact allowed boundaries
	local maxX = limitX - offsetX
	local minX = -limitX + offsetX
	local maxY = limitY - offsetY
	local minY = -limitY + offsetY

	-- Clamp the X and Y coordinates
	local safeX = math.max(minX, math.min(maxX, obj.x))
	local safeY = math.max(minY, math.min(maxY, obj.y))

	return safeX, safeY
end

function L.base_dialogue_loop()
	L.play_dialogue()
	for k, obj in ipairs(L.active_level().level.np_objects) do
		if obj.tag == "text" then
			if obj.is_dead_at < L.time() then
				L.active_level().level.np_objects[k] = nil
			end
		end
	end
end
local function pauseUnpause()
	if L.player.timeStopped then
		L.pauseScreen.loop()
	end
	if L.key_pressed("escape") then
        if L.player.timeStopped then
            L.start_time()
            L.player.timeStopped = false
        else
            L.stop_time()
			L.pauseScreen.setup()
            L.player.timeStopped = true
        end
    end
end
function L.draw_hud()
	for i = 1, L.hunger_limit, 1 do
		L.draw({ sprite = "icons/hunger", s = 3, x = 600 - (i - 1) * 60, y = -L.height/2+30, c = (i > L.player.hunger and "FFFFFF" or "606060") })
	end
end

function L.render(dt)
	for i = 1, #L.levels do
		if L.key_released(tostring(i)) then
			L.active_level_i = i
			L.reset()
		end
	end
	pauseUnpause()
	if not L.player.timeStopped then
		L.active_level().loop(dt)
	end
end
