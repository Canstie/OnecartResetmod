local Common = require("_framework.game.common")
local Player = require("_framework.game.player")
local Quest = require("_framework.game.quest")

core.unsafe_mode(true)

local RESET_DELAY_FRAMES = 420
local ABANDON_REASON = 5
local ABANDON_QUEST_PATTERN = "F3 0F 2C C0 F3 0F 11 81 A4 31 01 00"
local ABANDON_QUEST_OFFSET = -67
local PLAYER_DEATH_PATTERN = "48 ?? ?? ?? 65 ?? ?? ?? ?? ?? ?? ?? ?? 48 8B F1 44 ?? ?? ?? ?? ?? ?? 41 0F B6 E8 B9 ?? ?? ?? ?? 4C 63 F2 4E 8B 14 C8 41 8B 04 0A 39"
local PLAYER_DEATH_OFFSET = -5

local queued = false
local countdown = 0
local abandoned = false
local player_death_seen = false
local player_death_hook = nil
local player_death_hook_tried = false
local last_quest_id = -1
local abandon_quest = nil
local player_death = nil
local quest = nil

local function safe_call(name, fn)
    local ok, result = pcall(fn)
    if not ok then
        log.error("OneCartQuestReset " .. name .. " failed: " .. tostring(result))
        return nil
    end

    return result
end

local function get_quest()
    if quest == nil then
        quest = Quest.new()
    end

    return quest
end

local function current_quest_id()
    return safe_call("current_quest_id", function()
        return get_quest().current_id
    end) or -1
end

local function is_player_in_scene()
    return safe_call("is_player_in_scene", function()
        return Common.is_player_in_scene()
    end) == true
end

local function current_health()
    return safe_call("current_health", function()
        local player = Player.get_master_player()
        return player.health.current
    end)
end

local function reset_state()
    queued = false
    countdown = 0
    abandoned = false
    player_death_seen = false
    last_quest_id = -1
end

local function get_abandon_quest()
    if abandon_quest ~= nil then
        return abandon_quest
    end

    abandon_quest = sdk.AddressRepository.get_or_insert(
        "Quest:AbandonQuest",
        ABANDON_QUEST_PATTERN,
        ABANDON_QUEST_OFFSET
    )

    log.info("OneCartQuestReset resolved Quest:AbandonQuest")
    return abandon_quest
end

local function get_player_death()
    if player_death ~= nil then
        return player_death
    end

    player_death = sdk.AddressRepository.get_or_insert(
        "Player:PlayerDeath",
        PLAYER_DEATH_PATTERN,
        PLAYER_DEATH_OFFSET
    )

    log.info("OneCartQuestReset resolved Player:PlayerDeath")
    return player_death
end

local function install_player_death_hook()
    if player_death_hook_tried then
        return
    end

    player_death_hook_tried = true

    safe_call("install_player_death_hook", function()
        player_death_hook = sdk.Interceptor.attach(get_player_death(), {
            on_enter = function(_)
                player_death_seen = true
            end
        })

        log.info("OneCartQuestReset installed PlayerDeath hook")
    end)

    if player_death_hook == nil then
        log.warn("OneCartQuestReset PlayerDeath hook unavailable; health check fallback remains active")
    end
end

local function queue_abandon(reason)
    if queued or abandoned then
        return
    end

    queued = true
    countdown = RESET_DELAY_FRAMES
    log.warn("OneCartQuestReset cart detected by " .. reason .. "; abandoning after " .. tostring(RESET_DELAY_FRAMES) .. " frames")
end

local function abandon_current_quest()
    if abandoned then
        return
    end

    abandoned = true

    safe_call("abandon_current_quest", function()
        local s_quest = sdk.get_singleton("sQuest")
        if s_quest == nil or s_quest:to_integer() == 0 then
            error("sQuest singleton is not available")
        end

        sdk.call_native_function(get_abandon_quest(), {{
            type = "pointer",
            value = s_quest:to_integer()
        }, {
            type = "u32",
            value = ABANDON_REASON
        }}, "void")

        log.warn("OneCartQuestReset abandoned quest " .. tostring(last_quest_id) .. " after one cart")
    end)
end

install_player_death_hook()

core.on_update(function()
    local quest_id = current_quest_id()
    if quest_id < 0 or not is_player_in_scene() then
        if queued or abandoned or last_quest_id >= 0 then
            reset_state()
        end
        return
    end

    if last_quest_id ~= quest_id then
        reset_state()
        last_quest_id = quest_id
        log.info("OneCartQuestReset armed for quest " .. tostring(quest_id))
    end

    if abandoned then
        return
    end

    if player_death_seen then
        player_death_seen = false
        queue_abandon("PlayerDeath hook")
    end

    local hp = current_health()
    if hp == nil then
        return
    end

    if not queued and hp <= 0 then
        queue_abandon("health check")
        return
    end

    if not queued then
        return
    end

    countdown = countdown - 1
    if countdown <= 0 then
        abandon_current_quest()
    end
end)
