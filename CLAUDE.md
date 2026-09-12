# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A **documentation repository**: a step-by-step guide for hosting a Project Zomboid dedicated
server on Ubuntu (SteamCMD, UFW, RAM tuning, mods, `screen`, troubleshooting), plus the real
config files and two hand-written Lua mods used by the author's own server ("Olimpo").

There is no build, no package manager, no test suite and no CI. The deliverable is the
Markdown, so "quality" here means: commands that actually work when pasted, and the two
language versions staying in agreement.

## Repository layout

- `README.md` / `README.pt-BR.md` · the guide, English and Brazilian Portuguese. Cross-linked
  at the top of each file.
- `CONTRIBUTING.md` · contribution rules (also the style guide for the READMEs).
- `.github/ISSUE_TEMPLATE/` · bug_report / improvement / question.
- `misc/TryToCreateSshKey.md` · side note on giving a friend chroot SFTP-only access to
  `/home/steam`.
- `misc/zomboid.service` · the systemd unit from the "Auto-start on Boot" section. It runs
  the server *inside* `screen -DmS` so the console survives, and its `ExecStop` types `quit`
  and then blocks until the server exits. Both halves are load-bearing: see the comments in
  the file before changing anything there.
- `misc/test-zomboid-service.sh` · the only executable test in the repo. Verifies the unit
  against a real server: startup, ports, console, graceful save on `systemctl stop`, world
  persistence, crash recovery, boot enablement. Needs root and a server with no players.
- `Zomboid/` · mirror of the server's `/home/steam/Zomboid` directory (see below).

## The `Zomboid/` tree

This is not source code to build, it is a snapshot of live server state. On the VPS the same
files live at `/home/steam/Zomboid/`, and the game binaries live separately at
`/home/steam/pzsteam/` (App ID `380870`).

- `Zomboid/Server/pzServerOlimpo.ini` · server config. Key fields: `Mods=GPS;PlayersOnMap`,
  `WorkshopItems=830118004;2879960936`, `DefaultPort=16261`, `UDPPort=16262`,
  `Map=Muldraugh, KY`, `SpawnPoint=6450,5450,0`.
- `Zomboid/Server/pzServerOlimpo_SandboxVars.lua` · sandbox difficulty (`SandboxVars` table,
  ~600 lines of numbered enum options with the legend in comments above each key).
- `Zomboid/Server/pzServerOlimpo_spawnregions.lua` · the four spawn towns.
- `Zomboid/mods/<ModID>/` · local mods, in the game's expected layout:
  `mod.info` + `poster.png` + `media/lua/{client,server,shared}/`.

The server name `pzServerOlimpo` is the `-servername` argument; all three config files must
share that prefix. `Mods=` takes the `id=` from `mod.info` (which here equals the folder
name), not the display name. Adding a mod means touching all of: the folder under
`Zomboid/mods/`, `Mods=`, and, for workshop mods, `WorkshopItems=`.

### The two mods

**GPS** (`media/lua/client/GPS.lua`) · client-only. Derives an `ISCollapsableWindow` showing
the local player's rounded X,Y, refreshed on `OnPlayerUpdate`.

**PlayersOnMap** · the non-obvious one, split across all three scopes:

- `shared/` defines the `pom_*` helpers (`pom_getPlayer` serializes a player into a plain
  table, preferring the vehicle's coordinates when mounted; `pom_getPlayers` reads the cache).
- `client/` runs on a ~100 ms throttle: each tick it `sendClientCommand("PlayersOnMap",
  "player", ...)` with its own position, and it monkey-patches `ISWorldMap:render` and
  `ISMiniMapOuter:render` to draw everyone's dot. `OnPreUIDraw`/`OnPostUIDraw` toggle the
  vanilla `"Players"` map flag off and back on around the frame so the base game's own markers
  do not double-draw.
- `server/` caches the positions clients report and re-broadcasts the whole set with
  `sendServerCommand` on its own ~100 ms throttle; the cache entry is only trusted for 500 ms.
- Visibility rules (invisible players, dead players, faction-only, max distance, name display)
  are all sandbox options, declared in `media/sandbox-options.txt` and labelled in
  `media/lua/shared/Translate/EN/Sandbox_EN.txt`. Adding an option means editing **both**
  files, and reading it in `client/` as `SandboxVars.PlayersOnMap.<Name>`. Admins bypass every
  visibility restriction on purpose.

There is no way to run these Lua files outside the game; verification means starting the
server and connecting a client.

## Working rules

- **Edit both READMEs or neither.** Any change to a command, path, port or section in
  `README.md` needs the mirrored change in `README.pt-BR.md`, including the Table of Contents
  entry. A fix landing in only one language is a regression.
- **Commands are copy-paste contracts.** Write them in fenced blocks exactly as they should be
  typed, with `<placeholders>` in angle brackets, and explain the *why* when it is not obvious
  (for example why 32-bit support is needed for SteamCMD).
- **`.gitattributes` is deliberate.** `*.lua linguist-documentation=true` and
  `*.md linguist-documentation=false` force GitHub to report this repo as Markdown rather than
  Lua. Do not "fix" it.
- **The `Zomboid/Server/` files are CRLF** (they were authored on Windows by the game). Keep
  the line endings when editing; do not normalize the whole file.
- The server config is committed as-is, welcome message and all. `AdminPassword` and player
  whitelists are not in the repo and must never be committed.
- Ports `16261/udp` and `16262/udp` are the values used throughout the guide. If one changes,
  it appears in the UFW section, the `.ini`, the troubleshooting section and both languages.
- **The systemd unit exists in three places**: `misc/zomboid.service` and the fenced `ini`
  block in each README. A change to one is a change to all three. `misc/zomboid.service` is
  the copy the test script is written against, so treat it as the source of truth.
- Two facts about `start-server.sh` drive the unit's design and were measured, not assumed:
  it ends with `exit 0` even when the game is killed (so `Restart=on-failure` never fires),
  and an `ExecStop` that only injects `quit` returns instantly, which makes systemd signal
  the server in the middle of the world save. Do not "simplify" either away.
