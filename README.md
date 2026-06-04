# One Cart Quest Reset

A SharpPluginLoader C# plugin for Monster Hunter: World / Iceborne.

Behavior: after you enter a quest, if the local player's health reaches zero, the plugin waits a short delay and then calls the game's own `Abandon Quest` routine. This resets the quest to its pre-quest state.

## Notes

- This is a runtime plugin, not a regular `nativePC` asset replacement.
- Use it in solo play or private sessions. In multiplayer, abandoning a quest usually removes only your local player from that quest and can disrupt other players.
- The plugin abandons the current quest. It does not automatically post and depart the same quest again, because that requires driving the quest board/UI state and is much easier to soft-lock.
- The default delay is 7 seconds after the detected cart.

## Downloads You Need

Download these yourself:

1. SharpPluginLoader latest release:
   `https://github.com/Fexty12573/SharpPluginLoader/releases`
2. .NET 8 Desktop Runtime:
   `https://dotnet.microsoft.com/download/dotnet/8.0`

Extract SharpPluginLoader into the directory that contains `MonsterHunterWorld.exe`.

## Build

From this repository root:

```powershell
dotnet restore .\src\OneCartQuestReset\OneCartQuestReset.csproj
dotnet publish .\src\OneCartQuestReset\OneCartQuestReset.csproj -c Release
```

## Install

Copy the published DLL to `nativePC\plugins\CSharp\OneCartQuestReset\` under your MHW root:

```powershell
$MhwRoot = "D:\SteamLibrary\steamapps\common\Monster Hunter World"
New-Item -ItemType Directory -Force "$MhwRoot\nativePC\plugins\CSharp\OneCartQuestReset"
Copy-Item ".\src\OneCartQuestReset\bin\Release\net8.0\publish\OneCartQuestReset.dll" "$MhwRoot\nativePC\plugins\CSharp\OneCartQuestReset\" -Force
```

Change `$MhwRoot` if your game is installed elsewhere.

## Change Delay

Edit `src\OneCartQuestReset\Plugin.cs`:

```csharp
private const float ResetDelaySeconds = 7.0f;
```

Then publish and copy the DLL again.
