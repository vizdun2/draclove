local L = require("lib/l")
local CB = require("src/chairBoss")
local gravity = require("src/gravity")

L1 = {}
L1.platform = { x = 0, y = 0, sx = 10, tag = "ground" }
L1.ground = { x = 0, y = 300, sx = 100, tag = "ground" }
-- L1.ground1 = { x = 0, y = -300, sx = 100, tag = "ground" }
L1.level = {
	np_objects = { L1.ground }, -- non player objects
}
function L1.setup()
    CB.newBoss()
    L.player = {
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

function L1.interact_with(obj)
	-- for the given tag of obj, run the specific interaction
end
local function isGrounded()
    for _, np_obj in ipairs(L1.level.np_objects) do
        if np_obj.tag=="ground" then
            if gravity.ground_collide(L.player, np_obj) then
                return true
            end
        end
    end
    return false
end
function L1.loop(dt)
	L.base_player_loop()
	L.base_dialogue_loop()
	gravity.change_vel(L.player)
	L.move_vel(L.player)

	L.player.on_ground = isGrounded()
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
end







return L1