local L = require("lib/l")
local CB = require("src/chairBoss")
local gravity = require("src/gravity")
local Player = require("src/player")

local L1 = {}

L1.ground = { x = 0, y = 300, sx = 100, tag = "ground" }
L1.level = {
	np_objects = { L1.ground }, -- non player objects
}
L1.lines = {}
-- L1.player_lines = { { text = "Stoner: She got a screw loose brother!", audio = "audio/chair/screw_loose.wav" }, { text = "Stoner: That girl falling head over wheels for me!", audio = "" }, { text = "Stoner: I need to take the her wheels man, maybe they edible, like them gummy bears or smth" } }

L1.finished_intro = false

function L1.setup()
	L.audio_intro("audio/soundtrack/first_ost_intro")
	CB.newBoss()
	Player.setup()
	L.player.currentDJSprite = "particles/1/jump_burst"
	L.introAnimation = {
        x = L.boss.x,
        y = L.boss.y,
        s = L.boss.s,
        sprite = "chair/transform",
        sprite_t = 0.12,
        sprite_start = L.time(),
		sx = -1,
    }
end

function L1.interact_with(obj)
	-- for the given tag of obj, run the specific interaction
end

local function isGrounded()
	for _, np_obj in ipairs(L1.level.np_objects) do
		if np_obj.tag == "ground" then
			if gravity.ground_collide(L.player, np_obj) then
				return true
			end
		end
	end
	return false
end
local function draw_hud()
	for i = 1, L.boss.maxHealth, 1 do
		L.draw({ sprite = "chair/wheel", s = 5, x = -600 + (i - 1) * 60, y = -L.height / 2 + 30, c = (i <= L.boss.health and "FFFFFF" or "606060") })
	end
end

function L1.start_playing_audio_loop()
	Audio_source = L.play("audio/soundtrack/first_ost_loop",0.70)
	Source_path = "audio/soundtrack/first_ost_loop"
	Audio_source:setLooping(true)
end

function L1.loop(dt)
	L.draw({ x = 0, y = 0, sprite = "scenes/1", s = 6.66, sprite_t = 0.1 })
	if L.boss.dead then
		return false
	end
	Player.loop()
	draw_hud()
	L.base_dialogue_loop()

	if Source_path == "audio/soundtrack/first_ost_intro" and not Audio_source:isPlaying() then
		Audio_source:stop()
		L1.start_playing_audio_loop()
	end



	L.player.on_ground = isGrounded() -- not IN PLAYER BECAUSE OF isGROUNDED BEING LOCAL
	-- idle right
	-- L.draw(L.patch(L.player, {debug=true, pl=-30, pr=-3}))
	-- idle left
	-- L.draw(L.patch(L.player, {debug=true, pr=-30, pl=-3}))
	-- L.draw(L.patch(L.player, {debug=true, pt=-30}))

	--L.draw(L.patch(L.player, {debug=true}))
	L.draw(L.player)

	if L.collide(L.player, L.boss) then
		L.onCollisionWithPlayer()
	end

	CB.renderBoss()
	CB.bossLoopLogic(dt, L.player)

	for _, np_obj in ipairs(L1.level.np_objects) do
		L.move_vel(np_obj)
		if L.collide(L.player, np_obj) and L.player.is_punching() then
			L1.interact_with(np_obj)
		end
		if np_obj.tag ~= "ground" and np_obj.tag ~= "ceiling" then
			L.draw(np_obj)
		end
	end
	for _, projectile in pairs(L.boss.projectiles) do
		for i, np_obj in ipairs(L1.level.np_objects) do
			if L.collide(projectile, np_obj) then
				CB.projectileNPCollision(projectile, np_obj, dt)
				break
			end
		end
		CB.handleWallBounce(projectile, L.width / 2, L.height / 2)
		L.draw(projectile)
	end
	for _, line in pairs(L1.lines) do
		L.draw(line)
	end
	L.draw_hud()
	return true
end

function L1.startScene()
    if L.sprite_finished(L.introAnimation) then
        return false
    end
	L.draw(L.introAnimation)
	return true
end
function L1.endScene()
	L.nextLevel = 2
	L.active_level_i = L.transition
	L.reset()
    return false
end
return L1
