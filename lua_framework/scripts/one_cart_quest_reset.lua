local Common = require("_framework.game.common")
local Player = require("_framework.game.player")
local Quest = require("_framework.game.quest")

core.unsafe_mode(true)

local RESET_DELAY_FRAMES = 420
local ABANDON_QUEST_PATTERN = "F3 0F 2C C0 F3 0F 11 81 A4 31 01 00"
local ABANDON_QUEST_OFFSET = -67

local queued = false
local countdown = 0
local abandoned = false
local last_quest_id = -1
local abandon_quest = nil
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
            value = 0
        }}, "void")

        log.warn("OneCartQuestReset abandoned quest " .. tostring(last_quest_id) .. " after one cart")
    end)
end

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

    local hp = current_health()
    if hp == nil then
        return
    end

    if not queued and hp <= 0 then
        queued = true
        countdown = RESET_DELAY_FRAMES
        log.warn("OneCartQuestReset cart detected; abandoning after " .. tostring(RESET_DELAY_FRAMES) .. " frames")
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
