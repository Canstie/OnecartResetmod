# One Cart Quest Reset Lua

这是一个基于 `eigeen/LuaFramework` 的《怪物猎人：世界 / Iceborne》脚本项目，用来替代之前的 SharpPluginLoader C# 插件方案。

目标效果：进入任务后，如果本地玩家触发猫车死亡事件，脚本等待约 7 秒，然后调用游戏自身的 `Abandon Quest` 函数，让任务回到接任务前状态。

## 重要说明

- 这个版本依赖 `eigeen/LuaFramework`，不是 SharpPluginLoader。
- 脚本优先 hook `PlayerDeath`，如果 hook 失败，会继续使用血量归零检测作为兜底。
- `AbandonQuest` 和 `PlayerDeath` 的特征码来自旧 `sudden_reset.dll` 的静态分析；不会安装或执行旧 DLL。
- 建议只在单人或私人房间使用。多人任务中自动放弃任务可能影响其他玩家。

## 你需要自己下载

LuaFramework v0.3.0：

```powershell
Invoke-WebRequest -Uri "https://github.com/eigeen/LuaFramework/releases/download/v0.3.0/lua-framework_v0.3.0.zip" -OutFile ".\lua-framework_v0.3.0.zip"
```

下载后解压，把 LuaFramework release 里的文件放到 `MonsterHunterWorld.exe` 所在目录。

## 安装脚本

把本项目脚本复制到 LuaFramework 的脚本目录：

```powershell
$MhwRoot = "D:\Steam\steamapps\common\Monster Hunter World"
New-Item -ItemType Directory -Force "$MhwRoot\lua_framework\scripts"
Copy-Item ".\lua_framework\scripts\one_cart_quest_reset.lua" "$MhwRoot\lua_framework\scripts\" -Force
```

LuaFramework 会自动加载 `lua_framework\scripts` 目录下的根级 `.lua` 文件。

