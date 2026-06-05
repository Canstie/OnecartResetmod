# One Cart Quest Reset Lua

这是一个基于 `eigeen/LuaFramework` 的《怪物猎人：世界 / Iceborne》脚本项目，用来替代之前的 SharpPluginLoader C# 插件方案。

当前稳定版效果：进入任务后，脚本轮询本地玩家血量；如果检测到 HP 小于等于 0，会等待约 7 秒，然后调用游戏自身的 `Quest:AbandonQuest`，让任务回到接任务前状态。

## 重要说明

- 这个项目依赖 `eigeen/LuaFramework`，不是 SharpPluginLoader。
- 稳定版脚本路径是 `lua_framework/scripts/one_cart_quest_reset.lua`。
- 脚本默认关闭；进游戏后按 `F10` 切换启用或停用。
- 当前稳定版使用血量归零检测，不再使用 `PlayerDeath` hook。
- `AbandonQuest` 特征码来自旧 `sudden_reset.dll` 的静态分析；不会安装或执行旧 DLL。
- 建议只在单人或私人房间使用。多人任务中自动放弃任务可能影响其他玩家。

## 你需要自己下载

LuaFramework v0.3.0：

```powershell
Invoke-WebRequest -Uri "https://github.com/eigeen/LuaFramework/releases/download/v0.3.0/lua-framework_v0.3.0.zip" -OutFile ".\lua-framework_v0.3.0.zip"
```

下载后解压，把 LuaFramework release 里的文件放到 `MonsterHunterWorld.exe` 所在目录。

## 安装稳定版

把本项目稳定版脚本复制到 LuaFramework 的脚本目录：

```powershell
$MhwRoot = "D:\Steam\steamapps\common\Monster Hunter World"
New-Item -ItemType Directory -Force "$MhwRoot\lua_framework\scripts"
Copy-Item ".\lua_framework\scripts\one_cart_quest_reset.lua" "$MhwRoot\lua_framework\scripts\" -Force
```

LuaFramework 会自动加载 `lua_framework\scripts` 目录下的根级 `.lua` 文件。

## 实验版：自动重新接取上一任务

实验版脚本路径是：

```text
lua_framework/experimental/one_cart_quest_reset_reaccept_experimental.lua
```

实验版会在猫车后先调用 `Quest:AbandonQuest` 重置任务，然后记录上一任务 ID。等任务退出并回到非任务状态后，它会等待约 10 秒，再尝试通过 LuaFramework 地址库查找 `Quest:AcceptQuest` 并重新接取上一任务。

限制和风险：

- 这是实验功能，需要进游戏实测。
- 默认只重新接取任务，不自动出发。
- 不要同时加载稳定版和实验版，否则两个脚本会一起执行。
- 如果日志出现 `Quest:AcceptQuest is unavailable`，说明当前 LuaFramework 地址库没有这条记录；脚本会跳过自动重新接取，不会猜地址。

安装实验版时，先停用稳定版，再复制实验脚本：

```powershell
$MhwRoot = "D:\Steam\steamapps\common\Monster Hunter World"
New-Item -ItemType Directory -Force "$MhwRoot\lua_framework\scripts"

$StableScript = "$MhwRoot\lua_framework\scripts\one_cart_quest_reset.lua"
$DisabledStableScript = "$MhwRoot\lua_framework\scripts\one_cart_quest_reset.lua.disabled"
if (Test-Path $StableScript) {
    Move-Item $StableScript $DisabledStableScript -Force
}

Copy-Item ".\lua_framework\experimental\one_cart_quest_reset_reaccept_experimental.lua" "$MhwRoot\lua_framework\scripts\" -Force
```

恢复稳定版时，删除实验脚本，然后重新复制稳定版：

```powershell
$MhwRoot = "D:\Steam\steamapps\common\Monster Hunter World"
Remove-Item "$MhwRoot\lua_framework\scripts\one_cart_quest_reset_reaccept_experimental.lua" -ErrorAction SilentlyContinue
Copy-Item ".\lua_framework\scripts\one_cart_quest_reset.lua" "$MhwRoot\lua_framework\scripts\" -Force
```

## 启用和停用

脚本加载后默认不执行自动重置。进入游戏后按 `F10` 启用，再按一次 `F10` 停用。

日志中看到下面内容，说明脚本已启用：

```text
OneCartQuestReset enabled by F10
```

实验版对应日志是：

```text
OneCartQuestResetExperimental enabled by F10
```
