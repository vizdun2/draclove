local L = {
    width = 1280,
    height = 720,
    render = function() end,
}

function L:draw(obj)
	love.graphics.draw(
		triImage,
		(obj.x or 0) + L.width / 2,
		(obj.y or 0) + L.height / 2,
		math.rad(obj.r or 0),
		(obj.sx or 1) * (obj.s or 1),
		(obj.sy or 1) * (obj.s or 1),
		triImage:getWidth() / 2,
		triImage:getHeight() / 2
	)
end

function L:angle_look_at(x1, y1, x2, y2)
	return math.deg(math.atan2(y2-y1, x2-x1))
end

function L:getRatio()
	local swidth, sheight = love.graphics.getDimensions()
	local ratioX, ratioY = swidth / L.width, sheight / L.height
	local ratio = ((ratioX <= ratioY) and ratioX) or ratioY

	return ratio
end

function L:getMousePos()
	local nx, ny = love.mouse.getPosition()
	local ratio = L:getRatio()
	local swidth, sheight = love.graphics.getDimensions()
	return (nx - ((swidth - L.width * ratio) / 2)) / ratio - L.width / 2, (ny - ((sheight - L.height * ratio) / 2)) / ratio - L.height
end

function love.draw()
	local swidth, sheight = love.graphics.getDimensions()
	local canvas = love.graphics.newCanvas(width, height)
	love.graphics.setCanvas(canvas)
	
	L.render()

	love.graphics.setCanvas()
	local ratio = L:getRatio()
	love.graphics.draw(canvas, swidth / 2, sheight / 2, 0, ratio, ratio, L.width / 2, L.height / 2)
end

return L