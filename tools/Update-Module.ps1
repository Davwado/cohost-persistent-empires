<#
.SYNOPSIS
  Updates an installed CoHost Persistent Empires module by downloading only the files that changed.

.DESCRIPTION
  Reads release-manifest (manifest.json) of the latest GitHub release, compares the SHA-256 of every file with the copy in
  Modules\CoHostPersistentEmpires and downloads just the ones that differ. The big game assets are not touched: they are linked from
  the original Persistent Empires Workshop item and are not part of the manifest.
  Run Install-Module.ps1 first (once). Run this whenever a new version is announced.

.EXAMPLE
  .\Update-Module.ps1            # update
  .\Update-Module.ps1 -Check     # only say what would be downloaded
#>
param(
    [string]$GameDir = "",
    [string]$Repo = "Davwado/cohost-persistent-empires",
    [switch]$Check
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ModuleName = "CoHostPersistentEmpires"
$AllowedTop = @("GUI", "ModuleData", "bin", "SubModule.xml")          # the only places this script ever writes
$UrlPrefix = "https://github.com/$Repo/releases/download/"

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

function Get-Json($url) {       # the release file is served as raw bytes, which Windows PowerShell 5.1 hands back as byte[]
    $c = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
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
if (-not (Test-Path (Join-Path $dest "SubModule.xml"))) { throw "$ModuleName is not installed in $GameDir. Run Install-Module.ps1 first." }

Write-Host "Checking the latest release of $Repo ..."
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
if ($todo.Count -eq 0) { Write-Host "Already up to date ($($manifest.version))."; return }
Write-Host "Installed: $installed   Latest: $($manifest.version)   Files to download: $($todo.Count) ($mb MB)"
if ($Check) { $todo | ForEach-Object { Write-Host "  $($_.Rel)" }; return }

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("cohost-update-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory $tmp | Out-Null
try {
    $staged = @()
    foreach ($t in $todo) {
        $part = Join-Path $tmp ([guid]::NewGuid().ToString("N"))
        Write-Host "  downloading $($t.Rel)"
        Invoke-WebRequest -Uri $t.Url -OutFile $part -UseBasicParsing
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
Write-Host "Updated to $($manifest.version). Start the game launcher and tick CoHost Persistent Empires as before."
