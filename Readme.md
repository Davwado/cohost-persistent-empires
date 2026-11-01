# CoHost Persistent Empires

A community version of [Persistent Empires](https://steamcommunity.com/sharedfiles/filedetails/?id=2937242207) for Mount & Blade II:
Bannerlord 1.4.8, based on [AR-Development/PersistentEmpires-OpenSourced](https://github.com/AR-Development/PersistentEmpires-OpenSourced).
It is its own module (`CoHostPersistentEmpires`), so it sits next to the original mod; servers running it only accept this version.

## Playing

Download the latest zip from [Releases](../../releases/latest) and follow [PLAYERS.md](PLAYERS.md). You need the original Persistent
Empires Workshop item subscribed too, because this module uses its game assets (the installer links them, no extra disk space).
To update, run `Update-Module.ps1` from the same folder: it downloads only the files that changed.

## What is in this repository

| Folder | What |
|---|---|
| `PersistentEmpiresClient/` | The client module: UI, views, and the module files (`ClientModFiles`). |
| `PersistentEmpiresLib/` | Game code shared by the client and the server. |
| `tools/Install-Module.ps1` | The installer shipped in the release zip. |

The dedicated-server code, server images and hosting eggs are not published here yet.

## Licence

GNU AGPL-3.0, as upstream (`LICENCE.md`). The git history keeps the upstream authors' commits. Game assets belong to their respective
authors and are not part of this repository.
