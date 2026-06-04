param(
    [string]$Configuration = "Release"
)

$ErrorActionPreference = "Stop"

dotnet publish "$PSScriptRoot\src\OneCartQuestReset\OneCartQuestReset.csproj" -c $Configuration
