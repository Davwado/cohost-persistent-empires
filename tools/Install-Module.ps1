<#
.SYNOPSIS
  Installs CoHost Persistent Empires as its own module (Modules\CoHostPersistentEmpires) in your Bannerlord folder.

.DESCRIPTION
  CoHost Persistent Empires uses the game assets of the original Persistent Empires Workshop item
  (https://steamcommunity.com/sharedfiles/filedetails/?id=2937242207), so subscribe to that first and let Steam download it.
  This script then builds the new module from:
    - our code, GUI and strings (the CoHostPersistentEmpires folder next to this script, or dist\CoHostPersistentEmpires), and
    - the original item's ModuleData and GUI (copied) and its big asset folders (linked, not copied: no extra disk space).
  You do NOT tick the original mod in the launcher - only CoHost Persistent Empires.

.EXAMPLE
  .\Install-Module.ps1             # install, or reinstall after an update
  .\Install-Module.ps1 -Remove     # uninstall
#>
param(
    [string]$GameDir = "",
    [string]$AssetsFrom = "",
    [string]$Source = $(if (Test-Path (Join-Path $PSScriptRoot "CoHostPersistentEmpires\SubModule.xml")) { Join-Path $PSScriptRoot "CoHostPersistentEmpires" } else { Join-Path (Split-Path $PSScriptRoot -Parent) "dist\CoHostPersistentEmpires" }),
    [switch]$Remove
)

$ErrorActionPreference = "Stop"
$ModuleName = "CoHostPersistentEmpires"
$LinkedFolders = @("AssetPackages", "ModuleSounds", "Prefabs", "SceneObj")   # big, read-only: linked from the original item
$CopiedFolders = @("ModuleData", "GUI")                                      # small: copied, then our files go on top

function Get-SteamLibraries {
    $steam = $null
    try { $steam = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath } catch {}
    $libs = @()
    if ($steam) {
        $libs += $steam
        $vdf = Join-Path $steam "steamapps\libraryfolders.vdf"
        if (Test-Path $vdf) {
            foreach ($m in Select-String -Path $vdf -Pattern '"path"\s+"([^"]+)"') {
                $libs += ($m.Matches[0].Groups[1].Value -replace "\\\\", "\")
            }
        }
    }
    return $libs | Select-Object -Unique | Where-Object { Test-Path -LiteralPath $_ }
}

function Remove-ModuleFolder($path) {
    if (-not (Test-Path -LiteralPath $path)) { return }
    # Delete links first so we never recurse into the original item's files.
    foreach ($d in Get-ChildItem -LiteralPath $path -Directory -Force) {
        if ($d.Attributes -band [IO.FileAttributes]::ReparsePoint) { [IO.Directory]::Delete($d.FullName) }
    }
    Remove-Item -LiteralPath $path -Recurse -Force
}

if (-not $GameDir) {
    foreach ($l in Get-SteamLibraries) {
        $c = Join-Path $l "steamapps\common\Mount & Blade II Bannerlord"
        if (Test-Path (Join-Path $c "bin\Win64_Shipping_Client")) { $GameDir = $c; break }
    }
    if (-not $GameDir) { throw "Could not find Bannerlord. Pass -GameDir <folder that contains bin and Modules>." }
}
$dest = Join-Path $GameDir "Modules\$ModuleName"

if ($Remove) {
    Remove-ModuleFolder $dest
    Write-Host "Removed $dest"
    return
}

if (-not $AssetsFrom) {
    foreach ($l in Get-SteamLibraries) {
        $c = Join-Path $l "steamapps\workshop\content\261550\2937242207"
        if (Test-Path (Join-Path $c "SubModule.xml")) { $AssetsFrom = $c; break }
    }
    if (-not $AssetsFrom) { throw "The original Persistent Empires Workshop item was not found. Subscribe to it on Steam (item 2937242207), let it finish downloading, then run this again - or pass -AssetsFrom <folder>." }
}
if (-not (Test-Path (Join-Path $Source "SubModule.xml"))) { throw "Our module files were not found in $Source" }

Write-Host "Game:   $GameDir"
Write-Host "Assets: $AssetsFrom"
Remove-ModuleFolder $dest
New-Item -ItemType Directory -Force $dest | Out-Null

foreach ($f in $CopiedFolders) {
    $from = Join-Path $AssetsFrom $f
    if (Test-Path $from) { Copy-Item $from (Join-Path $dest $f) -Recurse -Force }
}
foreach ($f in $LinkedFolders) {
    $from = Join-Path $AssetsFrom $f
    if (Test-Path $from) { New-Item -ItemType Junction -Path (Join-Path $dest $f) -Target $from | Out-Null }
}
# Our files on top (code, GUI, strings, SubModule.xml).
Copy-Item (Join-Path $Source "*") $dest -Recurse -Force

Write-Host "Installed $dest"
Write-Host "In the launcher tick Native, Multiplayer and CoHost Persistent Empires (not the original)."
Write-Host "Uninstall: .\Install-Module.ps1 -Remove"
