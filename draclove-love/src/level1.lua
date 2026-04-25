local L = require("lib/l")
local CB = require("src/chairBoss")
local gravity = require("src/gravity")

L1 = {}
L1.ground = { x = 0, y = 300, sx = 100, tag = "ground" }
L1.ground1 = { x = 0, y = -300, sx = 100, tag = "ground" }
L1.level = {
	np_objects = { L1.ground, L1.ground1 }, -- non player objects
}
function L1.setup()
    CB.newBoss()
end

function L1.interact_with(obj)
	-- for the given tag of obj, run the specific interaction
end

function L1.loop(dt)
	L.base_player_loop()
	L.base_dialogue_loop()
	gravity.change_vel(L.player)
	L.move_vel(L.player)
	L.player.on_ground = gravity.ground_collide(L.player, L1.ground)
	-- idle right
	-- L.draw(L.patch(L.player, {debug=true, pl=-30, pr=-3}))
	-- idle left
	-- L.draw(L.patch(L.player, {debug=true, pr=-30, pl=-3}))
	-- L.draw(L.patch(L.player, {debug=true, pt=-30}))
	L.draw(L.patch(L.player, {debug=true}))
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
		L.draw(np_obj)
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

	for i = 1, L.hunger_limit, 1 do
		L.draw({ sprite = "icons/hunger", s = 3, x = -600 + (i - 1) * 60, y = 250, c = (i > L.player.hunger and "FFFFFF" or "606060") })
	end
end







return L1