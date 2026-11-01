<#
.SYNOPSIS
  Updates an installed CoHost Persistent Empires module by downloading only the files that changed.

.DESCRIPTION
  Reads release-manifest (manifest.json) of the latest GitHub release, compares the SHA-256 of every file with the copy in
  Modules\CoHostPersistentEmpires and downloads just the ones that differ. The big game assets are not touched: they are linked from
  the original Persistent Empires Workshop item and are not part of the manifest.
  Run Install-Module.ps1 first (once). Run this whenever a new version is announced.

  It lists the files it will download and asks before it downloads anything. It only talks to github.com/<Repo>, checks every file's
  SHA-256 against the release manifest before it replaces anything, and only writes inside the module's GUI, ModuleData, bin folders
  and SubModule.xml. A record of what it did is written to update-log.txt next to the script.

.EXAMPLE
  .\Update-Module.ps1            # show what changed, ask, then update
  .\Update-Module.ps1 -Check     # only say what would be downloaded
  .\Update-Module.ps1 -Yes       # do not ask (for scripts)
#>
param(
    [string]$GameDir = "",
    [string]$Repo = "Davwado/cohost-persistent-empires",
    [switch]$Check,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"
if (-not $GameDir -and $env:COHOST_GAME) { $GameDir = $env:COHOST_GAME }      # passed on by CoHost PE Mod Installer.bat
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ModuleName = "CoHostPersistentEmpires"
$AllowedTop = @("GUI", "ModuleData", "bin", "SubModule.xml")          # the only places this script ever writes
$UrlPrefix = "https://github.com/$Repo/releases/download/"
$LogDir = if ($env:COHOST_LOGDIR -and (Test-Path -LiteralPath $env:COHOST_LOGDIR)) { $env:COHOST_LOGDIR } else { $PSScriptRoot }
$LogFile = Join-Path $LogDir "update-log.txt"

function Say($text, $color = "") {
    if ($color) { Write-Host $text -ForegroundColor $color } else { Write-Host $text }
    try { Add-Content -LiteralPath $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $text) } catch {}
}
trap {
    Say ""
    Say "Could not finish: $($_.Exception.Message)" "Red"
    Say "Nothing was replaced unless it says so above. Details: $LogFile - paste that file in the Discord for help."
    exit 1
}
function Ask($question) {
    if ($Yes) { return $true }
    $a = Read-Host "$question [Y/n]"
    return ([string]::IsNullOrWhiteSpace($a) -or $a -match '^[Yy]')
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

function Get-Web($url, $outFile) {   # GitHub sometimes drops a connection or briefly serves a stale copy: retry a few times
    for ($try = 1; ; $try++) {
        try {
            if ($outFile) { Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing; return }
            return ,((Invoke-WebRequest -Uri $url -UseBasicParsing).Content)      # the comma keeps a byte[] from being unrolled into the pipeline
        } catch {
            if ($try -ge 4) { throw }
            Start-Sleep -Seconds (2 * $try)
        }
    }
}
function Get-Json($url) {       # the release file is served as raw bytes, which Windows PowerShell 5.1 hands back as byte[]
    $c = Get-Web $url $null
    if ($c -is [byte[]]) { $c = [Text.Encoding]::UTF8.GetString($c) }
    return ($c.TrimStart([char]0xFEFF) | ConvertFrom-Json)
}

if (-not $GameDir) {
    foreach ($l in Get-SteamLibraries) {
        $c = Join-Path $l "steamapps\common\Mount & Blade II Bannerlord"
        if (Test-Path (Join-Path $c "bin\Win64_Shipping_Client")) { $GameDir = $c; break }
    }
    if (-not $GameDir) { throw "Could not find Bannerlord. Pass -GameDir <folder that contains bin and Modules>." }
}
$dest = Join-Path $GameDir "Modules\$ModuleName"
if (-not (Test-Path (Join-Path $dest "SubModule.xml"))) {
    $workshop = ""
    foreach ($l in Get-SteamLibraries) { $c = Join-Path $l "steamapps\workshop\content\261550\3827536748"; if (Test-Path (Join-Path $c "SubModule.xml")) { $workshop = $c; break } }
    if ($workshop) {
        Say "CoHost Persistent Empires is installed on this PC from the Steam Workshop ($workshop)."
        Say "Steam updates that copy by itself (it checks when Steam or Bannerlord starts), so there is nothing for this updater to do."
        Say "This updater is only for the copy installed from GitHub with CoHost PE Mod Installer.bat."
        return
    }
    throw "$ModuleName is not installed in $GameDir. Run CoHost PE Mod Installer.bat and choose 1 first."
}

Say "---- update ----"
Say "Checking the latest release of $Repo (the only address this script talks to) ..."
# (Invoke-RestMethod gets a 404 from this address on Windows PowerShell 5.1; Invoke-WebRequest works.)
$manifest = Get-Json "https://github.com/$Repo/releases/latest/download/manifest.json"
if (-not $manifest.files -or -not $manifest.version) { throw "The release manifest is not valid." }

# Never trust the manifest blindly: only known folders, no path tricks, only this repository's release downloads, no links.
$todo = @()
foreach ($f in $manifest.files) {
    $rel = [string]$f.path
    $parts = $rel -split "/"
    if ($rel.StartsWith("/") -or $rel.Contains("\") -or $rel.Contains(":") -or ($parts -contains "..") -or ($parts -contains ".") -or ($AllowedTop -notcontains $parts[0])) { throw "Refusing manifest path: $rel" }
    if (-not ([string]$f.url).StartsWith($UrlPrefix)) { throw "Refusing download address for $rel" }
    if ([string]$f.sha256 -notmatch '^[0-9a-f]{64}$') { throw "Bad hash for $rel" }
    $target = Join-Path $dest ($rel -replace "/", "\")
    $dir = $dest
    foreach ($p in $parts[0..($parts.Count - 2)]) {                      # a link inside the module must never be written through
        $dir = Join-Path $dir $p
        if ((Test-Path -LiteralPath $dir) -and ((Get-Item -LiteralPath $dir -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Refusing to write through a link: $dir" }
    }
    $have = $null
    if (Test-Path -LiteralPath $target) { $have = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() }
    if ($have -ne [string]$f.sha256) { $todo += [pscustomobject]@{ Rel = $rel; Target = $target; Url = [string]$f.url; Sha = [string]$f.sha256; Size = [long]$f.size } }
}

$installed = ""
try { $installed = ([xml](Get-Content -LiteralPath (Join-Path $dest "SubModule.xml") -Raw)).Module.Version.value } catch {}
$mb = [math]::Round((($todo | Measure-Object Size -Sum).Sum) / 1MB, 1)
if ($todo.Count -eq 0) { Say "Already up to date ($($manifest.version))."; return }
Say "Installed: $installed   Latest: $($manifest.version)   Files to download: $($todo.Count) ($mb MB)   Game folder: $GameDir"
$todo | ForEach-Object { Say ("  {0}  ({1:N1} MB)" -f $_.Rel, ($_.Size / 1MB)) }
Say "Each file is downloaded from $UrlPrefix..., checked against its SHA-256 from the manifest, and only then replaces the old one."
Say "Nothing outside $dest is changed, and the original Persistent Empires item is never touched."
if (@(Get-Process -Name "Bannerlord", "Bannerlord.Native", "TaleWorlds.MountAndBlade.Launcher" -ErrorAction SilentlyContinue).Count -gt 0) { Say "Warning: Bannerlord looks like it is running. Close it first, or files may be locked." "Yellow" }
if ($Check) { Say "Check only: nothing was changed."; return }
if (-not (Ask "Download and apply these files?")) { Say "Cancelled. Nothing was changed."; return }

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("cohost-update-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory $tmp | Out-Null
try {
    $staged = @()
    foreach ($t in $todo) {
        $part = Join-Path $tmp ([guid]::NewGuid().ToString("N"))
        Say "  downloading $($t.Rel)"
        Get-Web $t.Url $part
        $got = (Get-FileHash -LiteralPath $part -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($got -ne $t.Sha) { throw "Download of $($t.Rel) is damaged (hash mismatch). Nothing was changed. Try again." }
        $staged += [pscustomobject]@{ Part = $part; Target = $t.Target }
    }
    # Everything arrived and checked out: now replace the files (the game must be closed).
    foreach ($s in $staged) {
        New-Item -ItemType Directory -Force (Split-Path $s.Target) | Out-Null
        Move-Item -LiteralPath $s.Part -Destination $s.Target -Force
    }
    # Files that an earlier update installed and this version no longer has.
    $old = Join-Path $dest ".cohost-files.txt"
    $now = @($manifest.files | ForEach-Object { $_.path })
    if (Test-Path -LiteralPath $old) {
        foreach ($r in Get-Content -LiteralPath $old) {
            if ($r -and ($now -notcontains $r) -and ($AllowedTop -contains ($r -split "/")[0])) { Remove-Item -LiteralPath (Join-Path $dest ($r -replace "/", "\")) -Force -ErrorAction SilentlyContinue }
        }
    }
    Set-Content -LiteralPath $old -Value $now -Encoding ASCII
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Say "Updated to $($manifest.version). Start the game launcher and tick CoHost Persistent Empires as before." "Green"
Say "Something wrong? Run CoHost PE Mod Installer.bat and choose 3. Log: $LogFile"
