local L = require("lib/l")
local gravity = require("src/gravity")

-----------------------------------------------------------------------------------------------------------------
-- in your level file, do "local Player = require("src/player")" at the top and then call Player.setup() in setup
-- lastly Player.loop() in loop, remove all previous player related loops!!!!
-- override any function as you please like L.player.take_damage = function() ...
-----------------------------------------------------------------------------------------------------------------

local movement_const = 60
local dodge_cooldown = 0.5
local base_jump_speed = -25

local Player = {}
Player.jump_speed = base_jump_speed -- DO NOT MOVE, IT *WILL* BREAK SHIT


local function newDJEffect(sprite)
    local newDJEffect = {
        x = L.player.x,
        y = L.player.y,
        sprite = sprite,
        sprite_t = 0.1,
        s = 3,
        sprite_start = L.time(),
        tag = "tempEffect",
        currentDJSprite = "particles/1/jump_burst",
    }
    table.insert(L.player.particles, newDJEffect)
end

-- Base Setup
function Player.setup()
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
        sprite = "player/idle",
        particles = {},
        timeStopped = false,
        space = false,
    }
    Player.jump_speed = base_jump_speed
    function L.player.is_dodging()
        return L.player.sprite == "player/matrix_from_air" or L.player.sprite == "player/matrix_from_idle"
    end

    function L.player.is_punching()
        return L.player.sprite == "player/punch_from_idle" or L.player.sprite == "player/punch_from_air"
    end

    function L.player.is_inair()
        return L.player.sprite == "player/in_air"
    end

    function L.player.is_jump_from_idle()
        return L.player.sprite == "player/jump_from_idle"
    end

    function L.player.is_jump_from_air()
        return L.player.sprite == "player/jump_from_air"
    end

    function L.player.take_damage()
        if L.player.is_dodging() then return false end
        if L.player.hurt_time ~= nil and L.time() - L.player.hurt_time < 1 then return false end

        L.play("audio/player/ooh")
        L.player.hurt_time = L.time()
        L.player.hunger = L.player.hunger + 1

        if L.player.hunger >= L.hunger_limit then
            L.player.dead = true
            L.failedLevel = L.active_level_i
            L.active_level_i = L.gameOverScreen
            L.reset()
        end
        return true
    end
end

-- Internal movement logic
local function player_anime(sprite, t)
    L.player.sprite = sprite
    L.player.sprite_t = t
    L.player.sprite_start = L.time()
end

local function player_action()
    if (L.key_pressed("c") or L.key_pressed("m")) and L.time() - L.player.last_dodged > dodge_cooldown then
        if L.player.on_ground then
            player_anime("player/matrix_from_idle", 0.03)
        else
            player_anime("player/matrix_from_air", 0.03)
        end
        L.player.pr, L.player.pl = 0, 0
        L.player.pt = -30
        L.player.last_dodged = L.time()
    elseif L.key_pressed("x") or L.key_pressed("n") then
        L.play("audio/punch", 0.1)
        player_anime(L.player.on_ground and "player/punch_from_idle" or "player/punch_from_air", 0.03)
        L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
    end
end

local function player_state_handler()
    if L.player.is_dodging() and L.sprite_finished(L.player) then
        L.player.sprite = L.player.on_ground and "player/idle" or "player/in_air"
    elseif L.player.is_punching() and L.sprite_finished(L.player) then
        L.player.sprite = L.player.on_ground and "player/idle" or "player/in_air"
    elseif L.player.is_jump_from_idle() and L.sprite_finished(L.player) then
        -- L.print("jumpfromidle")
    elseif L.player.is_jump_from_air() and L.sprite_finished(L.player) then
        L.player.sprite = "player/in_air"
    end
end

local function player_movement()
    if not L.player.on_ground and not L.player.is_inair() and not L.player.is_dodging() and not L.player.is_punching() and not L.player.is_jump_from_air() then
        L.player.sprite = "player/in_air"
        L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
    end

    local player_speed = L.player.speed


    if L.key_down("space") and not L.player.jump_disabled then
        if L.player.on_ground and not L.player.is_jump_from_idle() then
            L.player.jumped_midair = false
            L.player.vel_y = Player.jump_speed * movement_const
            L.player.sprite = "player/in_air" -- reset this
            L.key_pressed("space")
        elseif L.key_pressed("space") and not L.player.jumped_midair then
            L.player.vel_y = Player.jump_speed * movement_const
            L.player.jumped_midair = true
            L.player.sprite = "player/in_air"
            L.play("audio/double_jump", 0.1)
            newDJEffect(L.player.currentDJSprite)
        end
    end


    if (not L.player.roofwalk and L.key_down("d")) or (L.player.roofwalk and L.key_down("a")) then
        L.player.vel_x = player_speed * movement_const
        L.player.sx = not L.player.roofwalk and 1 or -1
        if not L.player.is_jump_from_idle() and L.player.on_ground and not L.player.is_dodging() and not L.player.is_punching() then
            L.player.sprite_t = 0.1
            L.player.sprite = "player/runnin"
            L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
        end
    elseif (not L.player.roofwalk and L.key_down("a")) or (L.player.roofwalk and L.key_down("d")) then
        L.player.vel_x = -player_speed * movement_const
        L.player.sx = not L.player.roofwalk and -1 or 1
        if not L.player.is_jump_from_idle() and L.player.on_ground and not L.player.is_dodging() and not L.player.is_punching() then
            L.player.sprite_t = 0.1
            L.player.sprite = "player/runnin"
            L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
        end
    else
        if not L.player.is_punching() and not L.player.is_dodging() and not L.player.is_jump_from_idle() then
            L.player.sprite = "player/idle"
            L.player.sprite_t = 0.1
            L.player.pr = (L.player.sx == -1) and -15 or -15
            L.player.pl = (L.player.sx == -1) and -15 or -15
            L.player.pt = 0
        end
        L.player.vel_x = 0
    end

    if L.player.hurt_time and L.pasttime(L.player.hurt_time + 0.4) then
        L.hurt_time = nil
        L.player.c = "#FFFFFF"
    elseif L.player.hurt_time then
        -- L.player.sprite = "player/damage"
        -- L.player.pr, L.player.pl, L.player.pt = 0, 0, 0
        L.player.c = "#FF4040"
    end

    if L.player.roofwalk then
        L.player.sy = -1
    else
        L.player.sy = 1
    end
end
local function particleLoop()
    local currentTime = L.time()

    for i = #L.player.particles, 1, -1 do
        local ptc = L.player.particles[i]

        L.draw(ptc)

        if ptc.tag == "tempEffect" then
            if L.sprite_finished(ptc) then
                table.remove(L.player.particles, i)
            end
        elseif ptc.tag == "lingerEffect" then
            if not ptc.hasSwapped and L.sprite_finished(ptc) then
                ptc.sprite = ptc.finalSprite
                ptc.sprite_t = nil
                ptc.hasSwapped = true
            end

            if currentTime - ptc.startTime >= ptc.lifetime then
                table.remove(L.player.particles, i)
            end
        end
    end
end
function Player.physicsOnlyLoop()
    L.player.vel_x = 0

    if not L.player.on_ground then
        L.player.sprite = "player/in_air"
    else
        L.player.sprite = "player/idle"
    end

    L.move_vel(L.player)

    if not L.player.roofwalk and not L.player.off_move then
        gravity.change_vel(L.player)
    end

    particleLoop()

    if L.player.off_move then
        if L.player.x < -610 then
            L.player.roofwalk = not L.player.roofwalk
            L.player.y = not L.player.roofwalk and 220 or -L.height / 2 + 32 * L.player.s
        end
        L.player.x = L.clamp(-610, L.player.x, 610)
    else
        L.player.x, L.player.y = L.getSafeCoordinates(L.player, 15 * L.player.s, 15 * L.player.s)
    end
end

-- The main loop
function Player.loop()
    player_action()
    player_state_handler()
    player_movement()
    L.move_vel(L.player)
    if not L.player.roofwalk and not L.player.off_move then
        gravity.change_vel(L.player)
    end
    particleLoop()
    if L.player.off_move then
        if L.player.x < -610 then
            L.player.roofwalk = not L.player.roofwalk
            L.player.y = not L.player.roofwalk and 220 or -L.height / 2 + 32 * L.player.s
        end
        L.player.x = L.clamp(-610, L.player.x, 610)
    else
        L.player.x, L.player.y = L.getSafeCoordinates(L.player, 15 * L.player.s, 15 * L.player.s) -- 15 is offset used for player too lazy to make it a constant
    end
end

return Player
