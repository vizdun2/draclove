local L = require("lib/l")

local ship_speed = 200
local bullet_speed = 500
local blob_size = 20
local arena_size = 1200

function love.keyreleased(key)
	if key == "escape" then
		love.event.quit()
	end

	if key == "space" then
		local mx, my = L:getMousePos()
		local dx,dy = L:angle_vec(L:angle_look_at(0, 0, mx, my))
		table.insert(L.bullets, {expire=L:time()+2, dx=dx, dy=dy, x=L.player.x, y=L.player.y, r=L:angle_look_at(0, 0, dx, dy) + 90, s=0.4, c="#af1e1eff"})
	end

	if key == "backspace" then
		L:reset()
	end
end

function L.setup()
	L.player = {x=0, y=0,}
	L.enemies = {}
	L.bullets = {}
	L.hp = 5
	L.enemy_count = 15
	L.red_screen = nil
	L.dead = false
	L.won = false
	
	for i=1,L.enemy_count do
		local enemy = {
			x = math.random(-arena_size + blob_size, arena_size - blob_size),
			y = math.random(-arena_size + blob_size, arena_size - blob_size),
			c = "#1360b8ff",
		};

		table.insert(L.enemies, enemy)
	end
end

local function update_enemies(dt)
	for k,enemy in pairs(L.enemies) do
		if not enemy.readjust_timer or L:pasttime(enemy.readjust_timer) then
			enemy.r = L:angle_look_at(enemy.x, enemy.y, L.player.x, L.player.y) + (math.random() * 30 - 15)
			enemy.dx, enemy.dy = L:angle_vec(enemy.r)
			enemy.readjust_timer = L:time() + math.random() * 0.5
		end

		local oldx, oldy = enemy.x, enemy.y
		enemy.x = enemy.x + enemy.dx * ship_speed * dt
		enemy.y = enemy.y + enemy.dy * ship_speed * dt
		
		for jk,jenemy in pairs(L.enemies) do
			if k ~= jk and L:collide(enemy, jenemy) then
				enemy.x, enemy.y = oldx, oldy
				enemy.dx = enemy.dx * -1
				enemy.dy = enemy.dy * -1
			end
		end

		if L:collide(L.player, enemy) then
			L.hp = L.hp - 1
			L.enemy_count = L.enemy_count - 1
			L.enemies[k] = nil

			if L.hp > 0 then
				L.red_screen = L:time() + 0.3
			else
				L.dead = true
			end
		end
	end
end

local function update_player(dt)
	if love.keyboard.isDown("w") then L.player.y = L.player.y - ship_speed * dt end
	if love.keyboard.isDown("s") then L.player.y = L.player.y + ship_speed * dt end
	if love.keyboard.isDown("a") then L.player.x = L.player.x - ship_speed * dt end
	if love.keyboard.isDown("d") then L.player.x = L.player.x + ship_speed * dt end

	local mx, my = L:getMousePos()
	L.player.r = L:angle_look_at(0, 0, mx, my) + 90
end

local function update_bullets(dt)
	for kb,bullet in pairs(L.bullets) do
		if L:pasttime(bullet.expire) then
			L.bullets[kb] = nil
		else
			for ke,enemy in pairs(L.enemies) do
				if L:collide(bullet, enemy) then
					L.enemy_count = L.enemy_count - 1
					L.enemies[ke] = nil
					L.bullets[kb] = nil
				end
			end
		end
	end
end

function L.render(dt)
	for i,bullet in pairs(L.bullets) do
		bullet.x = bullet.x + bullet.dx * dt * bullet_speed
		bullet.y = bullet.y + bullet.dy * dt * bullet_speed
	end

	if not L.dead and not L.won then
		update_player(dt)
		update_enemies(dt)
		update_bullets(dt)
	end

	if L.enemy_count == 0 then
		L.won = true
	end
	
	love.graphics.clear(0.2,0.2,0.2,1)
	L:set_cam(L.player.x, L.player.y)

	for k,bullet in pairs(L.bullets) do
		L:draw(bullet)
	end

	for k,enemy in pairs(L.enemies) do
		L:draw(enemy)
	end

	L:draw(L.player)

	L:set_cam()
	L:draw({text="Health: " .. L.hp,align="lt",x=-640 + 20,y=-360 + 20,s=3})
	L:draw({text="Enemies: " .. L.enemy_count,align="lt",x=-640 + 20,y=-360 + 50,s=3})
	if L.dead then
		L:draw({x=0,y=0,sx=40,sy=25,c="#700000ab"})
		L:draw({text="You died.",align="mt",x=0,y=-200,s=3})
	elseif L.won then
		L:draw({x=0,y=0,sx=40,sy=25,c="#007000ab"})
		L:draw({text="You won.",align="mt",x=0,y=-200,s=3})
	elseif L.red_screen and not L:pasttime(L.red_screen) then
		L:draw({x=0,y=0,sx=40,sy=25,c="#ff000040"})
	end
end