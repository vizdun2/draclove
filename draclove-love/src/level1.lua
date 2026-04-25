local L = require("lib/l")
local CB = require("src/chairBoss")
local gravity = require("src/gravity")
local Player = require("src/player")

L1 = {}

L1.ground = { x = 0, y = 300, sx = 100, tag = "ground" }
L1.level = {
	np_objects = { L1.ground}, -- non player objects
}
L1.lines = {}
L1.player_lines = { { text = "Stoner: She got a screw loose brother!", audio = "audio/chair/screw_loose.wav" }, {text="Stoner: That girl falling head over wheels for me!",audio=""}, {text="Stoner: I need to take the her wheels man, maybe they edible, like them gummy bears or smth"}}


local player_next_line_offset = 10
L1.player_next_line = player_next_line_offset + math.random(5)

function L1.setup()
	CB.newBoss()
	Player.setup()
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
function L1.loop(dt)
	L.draw({ x = 0, y = 0, sprite = "scenes/1", s = 6.66, sprite_t = 0.1 })
	if L.boss.dead and L.boss.deathCount == 1 then
		L.active_level_i = 2
		L.reset()
		return
	elseif L.boss.dead then
		L.boss.deathCount = L.boss.deathCount + 1
		CB.resetBossHealth()
		L.push_dialogue({ text = "Chair: That is what I call, regeneration!", audio = "audio/chair/regeneration.wav" })
	end
	Player.loop()
	L.base_dialogue_loop()

	if L1.player_next_line < L.time() then
		L.push_dialogue(L1.player_lines[math.random(#L1.player_lines)])
		L1.player_next_line  = L1.player_next_line + player_next_line_offset + math.random(10)
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
end

return L1
