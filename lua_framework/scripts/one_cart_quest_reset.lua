local Common = require("_framework.game.common")
local KeyCode = require("_framework.input.keycode")
local Player = require("_framework.game.player")
local Quest = require("_framework.game.quest")

core.unsafe_mode(true)

local RESET_DELAY_FRAMES = 420
local TOGGLE_KEY = KeyCode.F10
local ABANDON_QUEST_PATTERN = "F3 0F 2C C0 F3 0F 11 81 A4 31 01 00"
local ABANDON_QUEST_OFFSET = -67

local enabled = false
local queued = false
local countdown = 0
local abandoned = false
local last_quest_id = -1
local abandon_quest = nil
local quest = nil
local toggle_key_was_down = false
local reported_errors = {}

local function chat(message)
    pcall(function()
        if sdk ~= nil and type(sdk.chat) == "function" then
            sdk.chat(message)
        end
    end)
end

local function notify(level, message)
    if level == "warn" then
        log.warn(message)
    elseif level == "error" then
        log.error(message)
    else
        log.info(message)
    end

    chat("[OneCart] " .. message)
end

local function safe_call(name, fn)
    local ok, result = pcall(fn)
    if not ok then
        local message = "OneCartQuestReset " .. name .. " failed: " .. tostring(result)
        if not reported_errors[name] then
            reported_errors[name] = true
            notify("error", message)
        else
            log.error(message)
        end
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

local function set_enabled(value)
    if enabled == value then
        return
    end

    enabled = value
    reset_state()
    toggle_key_was_down = false

    if enabled then
        notify("info", "Enabled by F10")
    else
        notify("warn", "Disabled by F10")
    end
end

local function toggle_enabled_if_requested()
    local pressed = safe_call("toggle_hotkey", function()
        return sdk.Input.keyboard.is_pressed(TOGGLE_KEY)
    end) == true

    if pressed and not toggle_key_was_down then
        set_enabled(not enabled)
    end

    toggle_key_was_down = pressed
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

    notify("info", "Resolved Quest:AbandonQuest")
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

        notify("warn", "Abandoned quest " .. tostring(last_quest_id) .. " after one cart")
    end)
end

notify("info", "Loaded. Press F10 to enable or disable.")

core.on_update(function()
    toggle_enabled_if_requested()

    if not enabled then
        if queued or abandoned or last_quest_id >= 0 then
            reset_state()
        end
        return
    end

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
        notify("info", "Armed for quest " .. tostring(quest_id))
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
        notify("warn", "Cart detected; abandoning after " .. tostring(RESET_DELAY_FRAMES) .. " frames")
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
