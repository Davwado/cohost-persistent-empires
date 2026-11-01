# CoHost Persistent Empires - joining a server (Bannerlord 1.4.8)

CoHost Persistent Empires is a community version of [Persistent Empires](https://steamcommunity.com/sharedfiles/filedetails/?id=2937242207)
for Bannerlord 1.4.8. It uses the original mod's game assets, so you need that installed too (subscribe, let Steam finish).
It is a separate module: servers running it only accept this version, and the original mod's servers only accept the original.

1. Be on the public Bannerlord branch (1.4.8). Subscribe to the original Persistent Empires on the Workshop and wait for the download.
2. Download the latest `CoHostPersistentEmpires-<version>.zip` from the [Releases page](https://github.com/Davwado/cohost-persistent-empires/releases/latest),
   close Bannerlord and unzip it.
3. Open PowerShell in the unzipped folder and run:

       Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
       .\Install-Module.ps1

   It creates `Modules\CoHostPersistentEmpires` in your Bannerlord folder (assets are linked from the Workshop copy, no extra disk
   space). Run `.\Install-Module.ps1 -Remove` to uninstall. To update later, run `.\Update-Module.ps1` in the same folder instead: it downloads only the files that changed (usually a few MB)
   and needs no new zip. `.\Update-Module.ps1 -Check` shows what it would download.
4. Launcher > Multiplayer: tick **Native, Multiplayer, CoHost Persistent Empires** (not the original), start, open the custom server
   list and join. Press **F** to spawn when your character appears. Maps download automatically on the first join.

Source: https://github.com/Davwado/cohost-persistent-empires (AGPL-3.0, based on https://github.com/AR-Development/PersistentEmpires-OpenSourced)
