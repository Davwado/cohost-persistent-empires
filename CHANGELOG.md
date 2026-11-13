# Changelog

CoHost Persistent Empires for Bannerlord 1.4.8. Every release that changes the client gets its own version number, and an existing
version is never published again. Server-only fixes go out in the server image and are listed under "Server" with the version that was
current when they shipped.

Servers only accept clients on the same version: after an update, if a server says *"Not all players' modules match"*, you and the
server are on different versions.

## Next client release: v1.9.3.0

Nothing here yet.

## v1.9.2.0 (first published 1 Nov 2026, final build 8 Nov 2026)

This version number was used for many builds while the Workshop item and the servers were being brought in line. The notes below cover
all of them; the last build is the one in the Steam Workshop and on the GitHub release.

**Players**
- **Lord polls work.** The accept and decline keys (F10 and F11) were set to keys the game does not have, so nobody could vote and
  every poll ran out. A faction with no lord can nominate one of its own members, and the poll fee is only taken when the poll opens.
- **Faction menus work again.** The Vote, Go Back and Kick buttons in the player-picker menus did nothing on 1.4.8. This also fixes
  Assign Marshall, door and chest key management and Transfer Lordship.
- **Change Faction Banner** now shows the real error ("Invalid Banner Code", "Cannot be empty") and no longer lets long pasted text spill
  over the buttons.
- **Store stock numbers** update on screen after every purchase or sale.
- **TAB menu and message log** text is styled again (it used brushes that no longer exist in 1.4.8).
- **Welcome screen** credits Davwado and Coalition Hosting.
- **New installer** for the GitHub download: `CoHost PE Mod Installer.bat` checks Steam, Bannerlord, the original Persistent Empires and any
  existing CoHost install, says what to do next, and asks before it changes anything.

**Server**
- Dropping an item, dropping money, dying with loot and the prefab spawner no longer crash the server (the game was handed an empty
  callback it does not check).
- The hosting panel can read the player list and moderate with signed requests; owners can opt out with `PANEL_API_ACCESS=0`.
  `GET /api/v1/query` returns the player list and server info in one call.
- Lord poll requests, votes and refusals are logged (`*PE* poll:`), door open and close are logged, and when the game aborts the panel
  console now prints the end of the full log with the stack.
- The game's own code is compiled at start-up (about 3 seconds) so it is not compiled in the middle of a match.

## v1.9.1.0 (31 Oct 2026)

- Wounded indicator on screen; wounded players are slowed from the moment they spawn; respawning ends a wound; the wounding time is
  set in seconds (`WoundingTimeSeconds`).
- The Voice Chat Options button works.
- The server checks client requests for chests, crafting, machines and trading.
- Crash mitigation on the server: the mod is compiled at start-up and tiered compilation is off.

## Before v1.9.1.0 (26 to 31 Oct 2026)

The first CoHost builds. The mod was ported to Bannerlord 1.4.8 (client, shared library and a Linux dedicated server) with its own module
id (`CoHostPersistentEmpires`), plus: admin colour change with a whitelist, invisible admins, saving players on class change and on
stop, bank and market fixes, item image fixes, chat fixes, and the Pterodactyl egg and Docker image.

Based on [Persistent Empires](https://github.com/AR-Development/PersistentEmpires-OpenSourced) by AR-Development and contributors.
