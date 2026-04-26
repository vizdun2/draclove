local L = require("lib/l")
local gravity = require("src/gravity")
local Player = require("src/player")
local lvl4 = {}

function lvl4.setup()
    L.boss = {
        x = 0,
        y = -300,
        -- sy=3,
        -- sx=2,
        s = 4,
        r = 0,
        state = states.moving_around,
        -- state_begin = L.time(),
        -- next_state = 1,
        hp = 25,
        sprite = "idibiks/idle",
        sprite_t = 0.1,
        pl = -20,
        pr = -28,
        pb = 0,
        last_burped = L.time(),
        last_chased = L.time(),
        chaseCooldown = 10,
        lastState=states.moving_around,
        chaseSpeed = 280,
        chaseDuration = 4.0,
        shootCount = 0,
        spillCount = 0,
        queuedAttack = nil,
        chaseThresholds = {20, 15, 10, 5},
        takeHitCooldown = 0.6,
    }
    Player.setup()
    L.pipes = {}
    L.water_projs = {}
    L.spill = nil
    L.water_level = nil
    L.player.currentDJSprite="particles/3/jump_burst"
end

return lvl4