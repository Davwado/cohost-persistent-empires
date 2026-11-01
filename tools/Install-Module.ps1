<#
.SYNOPSIS
  Installs CoHost Persistent Empires as its own module (Modules\CoHostPersistentEmpires) in your Bannerlord folder.

.DESCRIPTION
  CoHost Persistent Empires uses the game assets of the original Persistent Empires Workshop item
  (https://steamcommunity.com/sharedfiles/filedetails/?id=2937242207), so subscribe to that first and let Steam download it.
  This script builds the new module from:
    - our code, GUI and strings (the CoHostPersistentEmpires folder next to this script, or dist\CoHostPersistentEmpires), and
    - the original item's ModuleData and GUI (copied) and its big asset folders (linked, not copied: no extra disk space).
  You do NOT tick the original mod in the launcher - only CoHost Persistent Empires.

  It shows what it is going to do and asks before it does anything. It never needs administrator rights, never changes the original
  item or Bannerlord's own files, and never uses the internet. Everything it does is written to install-log.txt next to the script.

.EXAMPLE
  .\Install-Module.ps1             # show the plan, ask, then install (or reinstall after an update)
  .\Install-Module.ps1 -Check      # only show the plan; change nothing
  .\Install-Module.ps1 -Verify     # check an existing install and say what is wrong and how to fix it
  .\Install-Module.ps1 -Remove     # uninstall
  .\Install-Module.ps1 -Yes        # do not ask (for scripts)
#>
param(
    [string]$GameDir = "",
    [string]$AssetsFrom = "",
    [string]$Source = "",
    [switch]$Remove,
    [switch]$Check,
    [switch]$Verify,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"
# CoHost PE Mod Installer.bat has already looked around and passes what it found through these variables, so both always agree.
if (-not $GameDir -and $env:COHOST_GAME) { $GameDir = $env:COHOST_GAME }
if (-not $AssetsFrom -and $env:COHOST_ASSETS) { $AssetsFrom = $env:COHOST_ASSETS }
if (-not $Source -and $env:COHOST_SOURCE) { $Source = $env:COHOST_SOURCE }
if (-not $Source) {
    foreach ($c in @((Join-Path $PSScriptRoot "..\CoHostPersistentEmpires"), (Join-Path $PSScriptRoot "CoHostPersistentEmpires"), (Join-Path $PSScriptRoot "..\dist\CoHostPersistentEmpires"))) {
        if (Test-Path (Join-Path $c "SubModule.xml")) { $Source = (Resolve-Path $c).Path; break }
    }
}
if (-not $Source) { $Source = Join-Path $PSScriptRoot "CoHostPersistentEmpires" }
$ModuleName = "CoHostPersistentEmpires"
$GameVersionWanted = "v1.4.8"
$LinkedFolders = @("AssetPackages", "ModuleSounds", "Prefabs", "SceneObj")   # big, read-only: linked from the original item
$CopiedFolders = @("ModuleData", "GUI")                                      # small: copied, then our files go on top
$LogDir = if ($env:COHOST_LOGDIR -and (Test-Path -LiteralPath $env:COHOST_LOGDIR)) { $env:COHOST_LOGDIR } else { $PSScriptRoot }
$LogFile = Join-Path $LogDir "install-log.txt"

function Say($text, $color = "") {
    if ($color) { Write-Host $text -ForegroundColor $color } else { Write-Host $text }
    try { Add-Content -LiteralPath $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $text) } catch {}
}
function Size-Text($bytes) {
    if ($bytes -ge 1GB) { return ("{0:N1} GB" -f ($bytes / 1GB)) }
    return ("{0:N1} MB" -f ($bytes / 1MB))
}
function Folder-Bytes($path) {
    $s = (Get-ChildItem -LiteralPath $path -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    if ($s) { return [long]$s } else { return 0 }
}
function Ask($question, [bool]$default = $true) {
    if ($Yes) { return $true }
    $hint = if ($default) { "[Y/n]" } else { "[y/N]" }
    $a = Read-Host "$question $hint"
    if ([string]::IsNullOrWhiteSpace($a)) { return $default }
    return ($a -match '^[Yy]')
}
function Get-SteamLibraries {
    $steam = $null
    if ($env:COHOST_STEAM) { $steam = $env:COHOST_STEAM }      # support override, same as in CoHost PE Mod Installer.bat
    else { try { $steam = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath } catch {} }
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
function Get-ModuleVersion($folder) {
    try { return ([xml](Get-Content -LiteralPath (Join-Path $folder "SubModule.xml") -Raw)).Module.Version.value } catch { return "unknown" }
}
function Game-Running { return @(Get-Process -Name "Bannerlord", "Bannerlord.Native", "TaleWorlds.MountAndBlade.Launcher" -ErrorAction SilentlyContinue).Count -gt 0 }
function Remove-ModuleFolder($path) {
    if (-not (Test-Path -LiteralPath $path)) { return }
    # Delete links first so we never recurse into the original item's files.
    foreach ($d in Get-ChildItem -LiteralPath $path -Directory -Force) {
        if ($d.Attributes -band [IO.FileAttributes]::ReparsePoint) { [IO.Directory]::Delete($d.FullName) }
    }
    Remove-Item -LiteralPath $path -Recurse -Force
}
function Find-Game {
    foreach ($l in Get-SteamLibraries) {
        $c = Join-Path $l "steamapps\common\Mount & Blade II Bannerlord"
        if (Test-Path (Join-Path $c "bin\Win64_Shipping_Client")) { return $c }
    }
    return ""
}
function Find-WorkshopCoHost {      # the Steam Workshop version of this mod (it brings its own assets and updates itself)
    foreach ($l in Get-SteamLibraries) {
        $c = Join-Path $l "steamapps\workshop\content\261550\3827536748"
        if (Test-Path (Join-Path $c "SubModule.xml")) { return $c }
    }
    return ""
}
function Find-Assets {
    foreach ($l in Get-SteamLibraries) {
        $c = Join-Path $l "steamapps\workshop\content\261550\2937242207"
        if (Test-Path (Join-Path $c "SubModule.xml")) { return $c }
    }
    return ""
}

try {
    Say "---- $(if ($Verify) { 'verify' } elseif ($Remove) { 'remove' } elseif ($Check) { 'check' } else { 'install' }) ----"
    if (-not $GameDir) { $GameDir = Find-Game }
    if (-not $GameDir) { throw "Could not find Bannerlord. Make sure it is installed through Steam, or run this again with -GameDir <folder that contains bin and Modules>." }
    $dest = Join-Path $GameDir "Modules\$ModuleName"
    $gameVersion = Get-ModuleVersion (Join-Path $GameDir "Modules\Native")

    # ---------------------------------------------------------------------------------------------------- verify
    if ($Verify) {
        $problems = 0
        function Pass($t) { Say "  [ OK ] $t" "Green" }
        function Warn($t) { Say "  [WARN] $t" "Yellow" }
        function Bad($t)  { Say "  [FAIL] $t" "Red"; $script:problems++ }
        Say "Checking the install of CoHost Persistent Empires."
        Pass "Bannerlord found: $GameDir"
        if ($gameVersion -eq $GameVersionWanted) { Pass "Game version is $gameVersion" } else { Warn "Game version is $gameVersion but this mod is built for $GameVersionWanted. Switch Bannerlord to the public branch (Steam > Bannerlord > Properties > Betas)." }
        if (-not $AssetsFrom) { $AssetsFrom = Find-Assets }
        if ($AssetsFrom) { Pass "Original Persistent Empires Workshop item found: $AssetsFrom" } else { Bad "The original Persistent Empires Workshop item is not downloaded. Subscribe to it (item 2937242207), let Steam finish, then run Install again." }
        if (-not (Test-Path (Join-Path $dest "SubModule.xml"))) {
            Bad "CoHost Persistent Empires is not installed in $dest. Run CoHost PE Mod Installer.bat and choose 1."
        } else {
            $have = Get-ModuleVersion $dest
            if ($have -eq "unknown") { Bad "The installed SubModule.xml cannot be read, so the module is damaged. Run Install again." } else { Pass "Module installed, version $have" }
            foreach ($f in $LinkedFolders) {
                $p = Join-Path $dest $f
                $item = Get-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
                $readable = $false
                try { $readable = @([IO.Directory]::GetFileSystemEntries($p)).Count -gt 0 } catch {}     # a link whose target is gone cannot be listed
                if (-not $item) { Bad "$f is missing from the module. Run Install again." }
                elseif (-not $readable) { Bad "$f is a link to a folder that no longer exists or is empty (the original Workshop item was unsubscribed, moved or is still downloading). Let Steam finish downloading it, then run Install again." }
                elseif (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { Warn "$f is a copy, not a link. It works, but uses disk space; Install again to link it." }
                else { Pass "$f is linked to the original item" }
            }
            if (Test-Path (Join-Path $Source "SubModule.xml")) {
                $want = Get-ModuleVersion $Source
                if ($want -ne $have) { Warn "The files next to this script are version $want but the installed module is $have. Run Install again to update from them." }
                $bad = @()
                $srcRoot = (Resolve-Path -LiteralPath $Source).Path
                foreach ($f in Get-ChildItem -LiteralPath $srcRoot -Recurse -File -Force) {
                    $rel = $f.FullName.Substring($srcRoot.Length).TrimStart("\")
                    $t = Join-Path $dest $rel
                    if (-not (Test-Path -LiteralPath $t) -or (Get-FileHash -LiteralPath $t -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash) { $bad += $rel }
                }
                if ($bad.Count -eq 0) { Pass "Every mod file matches the ones in the download (checked by SHA-256)" }
                else { Bad ("{0} mod file(s) differ from the download, for example: {1}. Run Install again (or Update-Module.ps1)." -f $bad.Count, (($bad | Select-Object -First 3) -join ", ")) }
            } else {
                Warn "The downloaded mod files are not next to this script, so the files could not be compared. Run this from the unzipped folder."
            }
        }
        if (Game-Running) { Warn "Bannerlord is running. Close it before installing or updating." }
        $ws = Find-WorkshopCoHost
        if ($ws -and (Test-Path (Join-Path $dest "SubModule.xml"))) { Warn "You have two copies of this mod: the one in $dest and the Steam Workshop one ($ws). The game may list the module twice or load the wrong one. Keep one: unsubscribe from the Workshop item, or choose 4 in CoHost PE Mod Installer.bat." }
        elseif ($ws) { Say "  [INFO] CoHost Persistent Empires is installed from the Steam Workshop on this PC. Steam updates that copy itself; this installer is only for the GitHub version." }
        Say "  [INFO] The launcher selection cannot be checked from here: in the launcher choose Multiplayer and tick Native, Multiplayer and CoHost Persistent Empires (not the original)."
        if ($problems -eq 0) { Say "Everything checks out." "Green" } else { Say "$problems problem(s) found. The lines marked FAIL say how to fix them." "Red" }
        Say "Log: $LogFile"
        if ($problems -gt 0) { exit 1 } else { return }
    }

    # ---------------------------------------------------------------------------------------------------- remove
    if ($Remove) {
        if (-not (Test-Path -LiteralPath $dest)) { Say "Nothing to remove: $dest does not exist."; return }
        Say "This removes $dest. The links to the original Persistent Empires item are deleted first, so its files are never touched."
        if (-not (Ask "Remove it?")) { Say "Cancelled. Nothing was changed."; return }
        Remove-ModuleFolder $dest
        Say "Removed $dest" "Green"
        return
    }

    # ---------------------------------------------------------------------------------------------------- install / check
    if (-not $AssetsFrom) { $AssetsFrom = Find-Assets }
    if (-not $AssetsFrom) { throw "The original Persistent Empires Workshop item was not found. Subscribe to it on Steam (item 2937242207), let it finish downloading, then run this again - or pass -AssetsFrom <folder>." }
    if (-not (Test-Path (Join-Path $Source "SubModule.xml"))) { throw "The mod files were not found in $Source. Run this from the unzipped download (the folder that contains CoHostPersistentEmpires)." }

    $ver = Get-ModuleVersion $Source
    $srcFiles = @(Get-ChildItem -LiteralPath $Source -Recurse -File -Force)
    $srcBytes = ($srcFiles | Measure-Object Length -Sum).Sum
    Say ""
    Say "CoHost Persistent Empires $ver - installer" "Cyan"
    Say "  Bannerlord:                 $GameDir   (game version $gameVersion)"
    Say "  Original Persistent Empires: $AssetsFrom"
    Say "  Mod files (from this download): $Source   ($($srcFiles.Count) files, $(Size-Text $srcBytes))"
    Say ""
    Say "What it will do:"
    if (Test-Path -LiteralPath $dest) { Say "  1. Delete the existing $dest (links are removed first; the original item's files are never deleted)." }
    else { Say "  1. Create $dest." }
    $copyBytes = 0
    foreach ($f in $CopiedFolders) { $from = Join-Path $AssetsFrom $f; if (Test-Path $from) { $copyBytes += Folder-Bytes $from } }
    Say ("  2. Copy {0} from the original item ({1})." -f ($CopiedFolders -join " and "), (Size-Text $copyBytes))
    Say ("  3. Link (no copy, no extra disk space) {0} from the original item." -f ($LinkedFolders -join ", "))
    Say "  4. Copy the mod's own files on top (code, screens, text, SubModule.xml)."
    Say "It will not: change the original item or Bannerlord's own files, need administrator rights, or use the internet."
    Say "A record of what it did is written to $LogFile"
    Say ""
    if ($gameVersion -ne $GameVersionWanted) {
        Say "Warning: Bannerlord is $gameVersion but this mod is built for $GameVersionWanted. Servers running the mod will refuse you and the game may not start." "Yellow"
    }
    if (Game-Running) { Say "Warning: Bannerlord looks like it is running. Close it first, or files may be locked." "Yellow" }
    $workshopCopy = Find-WorkshopCoHost
    if ($workshopCopy) {
        Say "Warning: you already have CoHost Persistent Empires from the Steam Workshop ($workshopCopy)." "Yellow"
        Say "         Steam keeps that copy up to date by itself and it needs none of this. Installing this one as well gives the game two copies of the same mod." "Yellow"
        Say "         Use one or the other: unsubscribe from the Workshop item first if you want the GitHub version." "Yellow"
    }

    if ($Check) { Say "Check only: nothing was changed."; return }
    if ($workshopCopy -and -not (Ask "Install this second copy anyway?" $false)) { Say "Cancelled. Nothing was changed."; return }
    if ($gameVersion -ne $GameVersionWanted) { if (-not (Ask "Install anyway?" $false)) { Say "Cancelled. Nothing was changed."; return } }
    elseif (-not (Ask "Go ahead and install?")) { Say "Cancelled. Nothing was changed."; return }

    Remove-ModuleFolder $dest
    New-Item -ItemType Directory -Force $dest | Out-Null
    foreach ($f in $CopiedFolders) {
        $from = Join-Path $AssetsFrom $f
        if (Test-Path $from) { Copy-Item $from (Join-Path $dest $f) -Recurse -Force; Say "  copied $f" }
    }
    foreach ($f in $LinkedFolders) {
        $from = Join-Path $AssetsFrom $f
        if (Test-Path $from) { New-Item -ItemType Junction -Path (Join-Path $dest $f) -Target $from | Out-Null; Say "  linked $f" }
        else { Say "  (the original item has no $f, skipped)" "Yellow" }
    }
    Copy-Item (Join-Path $Source "*") $dest -Recurse -Force
    Say "  copied the mod's own files"
    Say ""
    Say "Installed $dest" "Green"
    Say "Next: in the launcher choose Multiplayer and tick Native, Multiplayer and CoHost Persistent Empires (not the original)."
    Say "Something wrong? Run CoHost PE Mod Installer.bat and choose 3. Uninstall: choose 4."
}
catch {
    Say ""
    Say "Could not finish: $($_.Exception.Message)" "Red"
    Say "Nothing else was changed after that point. The details are in $LogFile - paste that file in the Discord for help."
    exit 1
}
