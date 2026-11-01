# CoHost Persistent Empires

![CoHost Persistent Empires](images/banner.png)

A multiplayer roleplay and strategy mod for **Mount & Blade II: Bannerlord 1.4.8**. You join a persistent medieval world on a
community server, pick a class, and play alongside everyone else: gather, craft, trade, build, form factions and fight wars.

**[Download the latest release](../../releases/latest)** · [Discord](https://discord.gg/X3g7GrBZjv) · [Installation](#installation)

## How it works

You play on a server that is always running. Your character, gold, inventory and faction are saved, so you come back to the same
world each time. Join from **Multiplayer > Custom Server List**, wait for your character to appear, and press **F** to spawn.

- **Classes.** Pick a class to set how you start and what you can do; classes can be customised further.
- **Factions and diplomacy.** Players form factions with a lord, declare wars, and fight field battles and sieges. A faction elects
  its lord with a poll: press the **accept** or **decline** key shown on screen to vote.
- **Player-led economy.** Shops, stockpile markets and trading centres are run by players. Store screens show the live stock and
  update as items are bought and sold.
- **Gathering and crafting.** Collect resources, then turn them into goods at crafting stations and machines.
- **Building and destruction.** Upgrade buildings, and tear structures down in sieges and raids.
- **Wounding (when the server enables it).** Wounded players move slowly and are limited in what they can fight with until the timer
  runs out or a medic heals them. A red **WOUNDED** indicator on your status panel shows when it applies.
- **Roleplay options.** Optional immersion systems (such as voice chat, instruments and colour changes) that servers can turn on.

Each server decides its own rules, so details such as wounding time or prices vary from server to server.

## Installation

You need Windows, Bannerlord **1.4.8** (the public branch) and the original **Persistent Empires** Workshop item. This mod uses
that item's game assets and installs next to it as a separate module.

1. Subscribe to the original on the Steam Workshop and let it finish downloading:
   [Persistent Empires](https://steamcommunity.com/sharedfiles/filedetails/?id=2937242207). Do not tick it in the launcher.
2. Close Bannerlord. Download `CoHostPersistentEmpires-<version>.zip` from the
   [latest release](../../releases/latest) and unzip it.
3. Open PowerShell in the unzipped folder and run:

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
   .\Install-Module.ps1
   ```

   This creates `Modules\CoHostPersistentEmpires` in your Bannerlord folder. The assets are linked from the Workshop copy, so it
   uses almost no extra disk space.
4. In the launcher choose **Multiplayer** and tick **Native**, **Multiplayer** and **CoHost Persistent Empires**. Start the game,
   open the custom server list and join a server running this mod.

Servers running this mod only accept this version, and servers running the original only accept the original.

### Updating

When a new version is announced, open PowerShell in the same folder and run:

```powershell
.\Update-Module.ps1
```

It downloads only the files that changed, usually a few MB. `.\Update-Module.ps1 -Check` shows what it would download first.
If a server refuses you with *"Not all players' modules match"*, you are on a different version from the server: update, or ask
the server owner which version it runs.

### Uninstalling

```powershell
.\Install-Module.ps1 -Remove
```

## Reporting problems

Join the [Discord](https://discord.gg/X3g7GrBZjv). For a crash or an error message, attach
`%ProgramData%\Mount and Blade II Bannerlord\logs\CoHostPE_exceptions.txt`.

## Source and licence

The client and shared-library source are in this repository. Licensed under **AGPL-3.0** (`LICENCE.md`).

Based on [Persistent Empires](https://github.com/AR-Development/PersistentEmpires-OpenSourced) by AR-Development and contributors,
who handed the mod over for community maintenance. Game assets belong to their authors and are not part of this repository; third-party
credits are in `Credits.txt` inside the module. This version is maintained by Davwado and [Coalition Hosting](https://cohost.au).
