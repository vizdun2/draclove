local L = require("lib/l")
local gravity = require("src/gravity")
local Player = require("src/player")
local lvl5 = {}

function lvl5.setup()
    Player.setup()
end

function lvl5.loop(dt)
    Player.loop()

    L.draw(L.player)
    L.player.on_ground = gravity.ground_collide(L.player, L1.ground)
end

return lvl5