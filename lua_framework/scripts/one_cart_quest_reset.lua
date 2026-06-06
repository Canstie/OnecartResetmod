local Common = require("_framework.game.common")
local KeyCode = require("_framework.input.keycode")
local Message = require("_framework.game.message")
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
local pending_chat_messages = {}
local MAX_PENDING_CHAT_MESSAGES = 16
local CHAT_COLOR_BLUE = 0
local CHAT_COLOR_PURPLE = 1

local function can_show_chat()
    local ok, in_scene = pcall(function()
        return Common.is_player_in_scene()
    end)
    return ok and in_scene == true
end

local function show_chat_now(message, color)
    if not can_show_chat() then
        return false
    end

    local ok = pcall(function()
        Message.show_system(message, color)
    end)

    return ok
end

local function chat(message, color)
    if show_chat_now(message, color) then
        return
    end

    if #pending_chat_messages >= MAX_PENDING_CHAT_MESSAGES then
        table.remove(pending_chat_messages, 1)
    end

    table.insert(pending_chat_messages, { message = message, color = color })
end

local function flush_chat()
    if #pending_chat_messages == 0 or not can_show_chat() then
        return
    end

    local messages = pending_chat_messages
    pending_chat_messages = {}

    for _, item in ipairs(messages) do
        show_chat_now(item.message, item.color)
    end
end

local function notify(level, message)
    local color = CHAT_COLOR_BLUE

    if level == "warn" then
        log.warn(message)
        color = CHAT_COLOR_PURPLE
    elseif level == "error" then
        log.error(message)
        color = CHAT_COLOR_PURPLE
    else
        log.info(message)
    end

    chat("[一猫重置] " .. message, color)
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
        notify("info", "已开启")
    else
        notify("warn", "已关闭")
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

        notify("warn", "已重置任务")
    end)
end

notify("info", "已加载，按F10开关")

core.on_update(function()
    flush_chat()
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
        notify("info", "任务已就绪")
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
        notify("warn", "猫车了，准备重置")
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
