# Joining a Persistent Empires (Bannerlord 1.4.8) server

You need Bannerlord on the public branch (1.4.8) and the original Persistent Empires Workshop item, which supplies the
game assets: https://steamcommunity.com/sharedfiles/filedetails/?id=2937242207 (Subscribe, let Steam finish downloading).

1. Close Bannerlord.
2. Unzip this package anywhere.
3. Open PowerShell in the unzipped folder and run:

       Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
       .\Install-Overlay.ps1

   It finds your Workshop copy, backs up every file it replaces, and installs the 1.4.8 client over it.
   Run `.\Install-Overlay.ps1 -Restore` to undo. If Steam updates the Workshop item it overwrites our files; run the script again.
4. Launcher > Multiplayer: tick **Native, Multiplayer, PersistentEmpires**, start the game, open the custom server list
   and join. When your character appears press **F** to spawn. Map files download automatically on first join.

Source and build instructions: https://github.com/Davwado/bannerlord-persistent-empires (AGPL-3.0).
