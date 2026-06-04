# One Cart Quest Reset

这是一个用于《怪物猎人：世界 / Iceborne》的 SharpPluginLoader C# 插件。

效果：进入任务后，如果本地玩家血量归零，插件会等待一小段时间，然后调用游戏自身的 `Abandon Quest` 逻辑，让任务回到接任务前的状态。适合单人练习、竞速重开，以及不想手动打开菜单重置任务的场景。

## 重要说明

- 这是运行时插件，不是普通的 `nativePC` 资源替换。
- 建议只在单人或私人房间使用。多人任务里，本地放弃任务通常只会让你自己离开任务，可能影响其他玩家体验。
- 插件执行的是“放弃当前任务”。它不会自动重新接取并出发同一个任务，因为这需要驱动任务板和 UI 状态，强行自动操作更容易软锁。
- 默认在检测到死亡后等待 7 秒再放弃任务。

## 你需要自己下载

请自行下载下面内容：

1. SharpPluginLoader 最新 release：
   `https://github.com/Fexty12573/SharpPluginLoader/releases`
2. .NET 8 SDK：
   `https://dotnet.microsoft.com/download/dotnet/8.0`
3. .NET 8 Desktop Runtime：
   `https://dotnet.microsoft.com/download/dotnet/8.0`

把 SharpPluginLoader 解压到 `MonsterHunterWorld.exe` 所在目录。

## 构建

在本仓库根目录执行：

```powershell
dotnet restore .\src\OneCartQuestReset\OneCartQuestReset.csproj
dotnet publish .\src\OneCartQuestReset\OneCartQuestReset.csproj -c Release
```

## 安装

把发布后的 DLL 复制到 MHW 根目录下的 `nativePC\plugins\CSharp\OneCartQuestReset\`：

```powershell
$MhwRoot = "D:\SteamLibrary\steamapps\common\Monster Hunter World"
New-Item -ItemType Directory -Force "$MhwRoot\nativePC\plugins\CSharp\OneCartQuestReset"
Copy-Item ".\src\OneCartQuestReset\bin\Release\net8.0\publish\OneCartQuestReset.dll" "$MhwRoot\nativePC\plugins\CSharp\OneCartQuestReset\" -Force
```

如果你的游戏安装目录不同，请修改 `$MhwRoot`。

## 修改延迟

打开 `src\OneCartQuestReset\Plugin.cs`，修改这一行：

```csharp
private const float ResetDelaySeconds = 7.0f;
```

改完后重新执行 `dotnet publish`，再复制 DLL。

## 还原卡住怎么办

如果 `dotnet restore` 长时间卡住，或者报错正在下载 `Microsoft.AspNetCore.App.Ref.8.0.x`，通常是因为本机没有安装 .NET 8 SDK，只有更新版本的 SDK。构建这个插件建议安装 .NET 8 SDK。

安装后先确认：

```powershell
dotnet --list-sdks
dotnet --list-runtimes
```

如果能看到 `8.0.x`，再清理 NuGet 缓存并重试：

```powershell
dotnet nuget locals http-cache --clear
dotnet nuget locals temp --clear
dotnet restore .\src\OneCartQuestReset\OneCartQuestReset.csproj --source https://api.nuget.org/v3/index.json --disable-parallel --no-cache -v normal
```
