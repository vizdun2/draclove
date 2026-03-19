local L = require("l")

local playerX, playerY = 0, 0
local speed = 350
local blob_size = 20
local arena_size = 750

function love.load()
	triImage = love.graphics.newImage("tri.png")
end

local enemies = {}

for i=1,10 do
	local enemy = {
		x = math.random(-arena_size + blob_size, arena_size - blob_size),
		y = math.random(-arena_size + blob_size, arena_size - blob_size),
	};

	table.insert(enemies, enemy)
end

function love.keyreleased(key)
	if key == "escape" then
		love.event.quit()
	end
end

local rot = 0

function love.update(dt)
	local mx, my = L:getMousePos()

	if love.keyboard.isDown("w") then
		playerY = playerY - speed * dt
	end
	if love.keyboard.isDown("s") then
		playerY = playerY + speed * dt
	end
	if love.keyboard.isDown("a") then
		playerX = playerX - speed * dt
	end
	if love.keyboard.isDown("d") then
		playerX = playerX + speed * dt
	end
	if love.keyboard.isDown("r") then
		rot = rot + speed * dt
	end
end

L.render = function ()
	local mx, my = L:getMousePos()
	local a = L:angle_look_at(0, 0, mx, my) + 90
	L:draw({ x = 0, y = 0, r = a})

	for i,enemy in ipairs(enemies) do
		L:draw({ x =  enemy.x - playerX, y = enemy.y - playerY })
		-- love.graphics.circle("fill", width / 2 + enemy.x - playerX, height / 2 + enemy.y - playerY, blob_size)
	end
end