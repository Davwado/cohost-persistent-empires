# CoHost Persistent Empires - joining a server (Bannerlord 1.4.8)

CoHost Persistent Empires is a community version of [Persistent Empires](https://steamcommunity.com/sharedfiles/filedetails/?id=2937242207)
for Bannerlord 1.4.8. It is a separate module: servers running it only accept this version, and the original mod's servers only
accept the original.

**Using the Steam Workshop version?** Then you do not need any of this: Steam installs and updates it. This page is for the GitHub
download. If you have both, keep one (the setup file warns you).

## Install

1. Be on the public Bannerlord branch (1.4.8). Close Bannerlord.
2. Download the latest `CoHostPersistentEmpires-<version>.zip` from the [Releases page](https://github.com/Davwado/cohost-persistent-empires/releases/latest).
   Right-click the zip, choose **Extract All** (do not run anything from inside the zip).
3. Double-click **CoHost PE Mod Installer.bat**. It looks at your PC and shows what it found:
   - Steam and Bannerlord (and that Bannerlord is version 1.4.8),
   - the original Persistent Empires Workshop item, which the GitHub version needs for its game assets,
   - an existing CoHost install, either from the Steam Workshop or from GitHub,
   - the mod files next to it.

   Then it tells you what to do next. If the original Persistent Empires is missing it says so and can open its Steam page: click
   Subscribe, let Steam finish, and run the file again.
4. Choose **1** to install. It shows exactly what it will do and asks *Go ahead and install? [Y/n]* before it changes anything.
5. Launcher > Multiplayer: tick **Native, Multiplayer, CoHost Persistent Empires** (not the original), start, open the custom server
   list and join. Press **F** to spawn when your character appears. Maps download automatically on the first join.

## Update, check, uninstall

Run **CoHost PE Mod Installer.bat** again and choose:

- **2 Update**: lists the files that changed (usually a few MB), asks, downloads only those and checks each one before replacing the
  old one. It only talks to this project's GitHub releases.
- **3 Check**: checks the game version, that the original mod is downloaded, that the links are intact and that every mod file matches
  the download, and says how to fix anything it finds.
- **4 Uninstall**: removes only `Modules\CoHostPersistentEmpires`. The links to the original mod are deleted first, so the original's
  files are never touched.

If you ask for help, paste `install-log.txt` (and `update-log.txt`, if it exists) from the folder you extracted.

## What the installer does (and does not do)

It builds `Modules\CoHostPersistentEmpires` inside your Bannerlord folder from two places on your own PC:

- **This download:** the mod's code, screens and text (about 13 MB).
- **The original Persistent Empires Workshop item:** its `ModuleData` and `GUI` folders are copied (small); its big folders
  (`AssetPackages`, `ModuleSounds`, `Prefabs`, `SceneObj`) are **linked**, not copied, so there is no extra disk space.

It does not change the original mod or any of Bannerlord's own files, does not need administrator rights, and the installer does not
use the internet. `CoHost PE Mod Installer.bat` is plain text: open it in Notepad to read every step. It only looks around until you choose an
option, then starts the PowerShell files in the `scripts` folder for that one run with the script policy bypassed. It changes no
setting on your computer.

Windows may show a *Windows protected your PC* warning because the files came from the internet. Right-click the zip,
**Properties**, tick **Unblock**, then extract it, or choose **More info > Run anyway**.

To check your download: compare `Get-FileHash .\CoHostPersistentEmpires-<version>.zip` (PowerShell) with the SHA-256 printed in the release notes.

Source: https://github.com/Davwado/cohost-persistent-empires (AGPL-3.0, based on https://github.com/AR-Development/PersistentEmpires-OpenSourced)
