# One Cart Quest Reset Lua

这是一个基于 `eigeen/LuaFramework` 的《怪物猎人：世界 / Iceborne》脚本项目，用来替代之前的 SharpPluginLoader C# 插件方案。

目标效果：进入任务后，如果本地玩家血量归零，脚本等待约 7 秒，然后调用游戏自身的 `Abandon Quest` 函数，让任务回到接任务前状态。

## 重要说明

- 这个版本不依赖 .NET 8 / .NET 10。
- 这个版本依赖 `eigeen/LuaFramework`，不是 SharpPluginLoader。
- 目前 `AbandonQuest` 仍然是原生函数调用，地址特征码来自 SharpPluginLoader 的 `Quest:AbandonQuest` 记录。
- 建议只在单人或私人房间使用。多人任务中自动放弃任务可能影响其他玩家。

## 你需要自己下载

LuaFramework v0.3.0：

```powershell
Invoke-WebRequest -Uri "https://github.com/eigeen/LuaFramework/releases/download/v0.3.0/lua-framework_v0.3.0.zip" -OutFile ".\lua-framework_v0.3.0.zip"
```

下载后解压，把 LuaFramework release 里的文件放到 `MonsterHunterWorld.exe` 所在目录。

## 移除旧 C# 方案

如果之前安装过 SharpPluginLoader / C# 插件，先移除旧插件目录：

```powershell
$MhwRoot = "D:\Steam\steamapps\common\Monster Hunter World"
Rename-Item "$MhwRoot\nativePC\plugins\CSharp\OneCartQuestReset" "OneCartQuestReset.disabled" -ErrorAction SilentlyContinue
```

如果不再使用 SharpPluginLoader，也可以移除或改名整个 `nativePC\plugins\CSharp` 目录。先改名测试，不建议直接删除。

## 安装脚本

把本项目脚本复制到 LuaFramework 的脚本目录：

```powershell
$MhwRoot = "D:\Steam\steamapps\common\Monster Hunter World"
New-Item -ItemType Directory -Force "$MhwRoot\lua_framework\scripts"
Copy-Item ".\lua_framework\scripts\one_cart_quest_reset.lua" "$MhwRoot\lua_framework\scripts\" -Force
```

LuaFramework 会自动加载 `lua_framework\scripts` 目录下的根级 `.lua` 文件。

## 调整等待时间

打开 `lua_framework\scripts\one_cart_quest_reset.lua`，修改：

```lua
local RESET_DELAY_FRAMES = 420
```

LuaFramework 的 `core.on_update` 没有传入 delta time，所以这里用帧数近似。420 帧大约是 60 FPS 下的 7 秒。

## 卸载 .NET

确认 LuaFramework 能正常进游戏后，再卸载 .NET。建议通过 Windows 的“应用和功能”卸载：

- Microsoft .NET SDK 8.x
- Microsoft .NET Runtime 8.x
- Microsoft Windows Desktop Runtime 8.x
- Microsoft .NET SDK 10.x
- Microsoft .NET Runtime 10.x
- Microsoft Windows Desktop Runtime 10.x

不要直接删除 `C:\Program Files\dotnet` 或 `D:\Dotnet`，除非你确认没有其他程序依赖它们。
