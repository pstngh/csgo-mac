# Native macOS arm64 build

This branch ports the Kisak-Strike client, listen server, renderer, VGUI, VScript, and Kisak physics implementation to native Apple Silicon. It does not use Rosetta.

## Current scope

- Native arm64 Mach-O executables and dynamic libraries
- Cocoa/SDL video and Apple's legacy OpenGL compatibility layer
- Offline and LAN listen-server play with `-insecure`
- Startup without the Steam desktop client
- No Steam matchmaking, VAC, inventory, achievements, or other online Steam services in standalone mode

## Requirements

- An Apple Silicon Mac
- macOS Command Line Tools
- CMake and Ninja
- Homebrew's SDL 2 compatibility package
- Legally acquired CS:GO game content

Install the build dependencies with Homebrew:

```sh
brew install cmake ninja sdl2-compat
```

## Configure and build

Kisak-Strike writes runtime binaries to a sibling `game` directory. Clone this repository inside a parent working directory, then configure from the repository root:

```sh
cmake -S . -B ../build-macos-arm64 -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/cmake/toolchains/macos-arm64.cmake" \
  -DCMAKE_BUILD_TYPE=Release \
  -DDEDICATED=OFF \
  -DUSE_KISAK_PHYSICS=ON \
  -DUSE_ROCKETUI=ON \
  -DUSE_SCALEFORM=OFF

cmake --build ../build-macos-arm64
```

The build compiles an offline Steam API shim from source and places it beside the game modules. The Steam desktop client and its `libsteam_api.dylib` are not required for this standalone build.

The port vendors the MIT-licensed [sse2neon](https://github.com/DLTcollab/sse2neon) compatibility headers used to translate Source's SSE intrinsics to ARM NEON.

## Game content

This repository does not contain Valve game assets. Follow the upstream acquisition instructions for app 730, depot 731, manifest `7043469183016184477`, and place that content in the sibling `game` directory. You must have the legal right to use the content.

RocketUI also needs the separate [Kisak-Strike-Files](https://github.com/SwagSoftware/Kisak-Strike-Files) GUI files. Copy that repository's `csgo/rocketui` directory into `../game/csgo/rocketui` before launching. Without it, the team-selection and pause menus cannot render.

To use the AK-47 Asiimov finish, supply its `ak47_asiimov.vtf` from legally acquired CS:GO content and run:

```sh
python3 tools/install_ak_asiimov.py /path/to/ak47_asiimov.vtf ../game
```

To use the original Allied Assault sniper scope graphic, supply `textures/hud/zoomoverlay.tga` from a legally acquired MOHAA installation and run:

```sh
python3 tools/install_mohaa_scope.py /path/to/zoomoverlay.tga ../game
```

These scripts install assets only in the local game directory. Neither game's texture files are committed to this source repository.

## Launch standalone

Run from the game directory:

```sh
arch -arm64 ./csgo_osx64 -insecure -novid -windowed
```

To start a local map directly:

```sh
arch -arm64 ./csgo_osx64 -insecure -novid -windowed +map de_dust2
```

Standalone listen servers intentionally fall back to LAN mode when Steam services are unavailable. Console messages from failed Steam API initialization may still appear; they are non-fatal in this mode.

## Native Mac launcher

Build the launcher app in a playable game directory:

```sh
./tools/install_macos_launcher.sh /Users/pstn/Documents/Games/csgo
```

Open `CSGO Launcher.app` in that directory to choose an installed map, bot count
and difficulty, windowed or fullscreen resolution, and crosshair color, size,
gap, thickness, opacity, dot, and outline. The overall Quality menu offers Low, Medium, High, and Very High presets; Custom
appears when individual graphics choices differ from a preset. Graphics Settings
still offers texture detail, texture filtering, anti-aliasing, shadows, shader
detail, and VSync, and the saved individual choices remain authoritative.
Graphics choices apply on the next launch; anti-aliasing and VSync are also
passed at startup so the video mode uses them immediately. The launcher previews
the crosshair, saves the choices, writes `csgo/cfg/mac_launcher.cfg`, and starts
the game with that config after the map loads. Game output goes to
`launcher-game.log`. If the game crashes, macOS writes a report in
`~/Library/Logs/DiagnosticReports`. The launcher keeps the original gameplay bindings and
free-for-all defaults. The game directory in this checkout is at
`/Users/pstn/Documents/Games/csgo`; its former sibling `../game` is a symlink
so the existing CMake build still updates the installed game.

Backtick opens the developer console. The Mac gameplay preset locks the normal world FOV to 80, the saved Desktop-preset weapon viewmodel FOV of 60, mouse sensitivity to 1.029863, and `m_pitch` to 0.018. The persistent in-game HUD is crosshair-only; the sniper scope overlay and deliberately opened buy/team menus remain available. On-screen gameplay hints, objective lessons, and local weapon-drop messages are disabled. Every unscoped weapon uses the same fixed four-bar crosshair, white by default and configurable through the launcher. The AWP uses Allied Assault's 20-degree sniper FOV, one-step right-click toggle, immediate FOV change, and original zoom overlay when installed with the script above. The scroll wheel cycles weapons without showing a selection HUD.

Use `cg_drawviewmodel 0` to hide the first-person weapon and hands, `cg_drawviewmodel 1` to show only the weapon, or `cg_drawviewmodel 2` for the normal weapon-and-hands view. K cycles through all three values. The default is 2, and the setting is saved. K replaces the previous voice-record binding.

Left Shift leans left, Space leans right, and F jumps. Lean uses OpenMoHAA's
Allied Assault multiplayer timing, 40-degree limit, camera pivot, and roll.
Left or right Control toggles crouch; C toggles walk.
W/S and A/D use nullbind-style SOCD: the most recently pressed direction wins
while both are held, and releasing it resumes the other held direction.
The Mac local preset uses Allied Assault deathmatch's 275 run speed, 0.6 walk
and crouch modifiers (165 each), and a combined 99 crouch-walk speed. Backward
input is 0.8 of forward and strafe input is 0.85, as in AA. The AWP uses AA's
0.8 sniper movement multiplier, giving 220 while running and 132 while walking
or crouching. Other local weapons use the full movement speed.

All grenade types, including flashbangs, and all knives are unavailable in this
build: they cannot be bought, granted, picked up, or spawned on maps. C4 cannot be granted or picked
up, and bomb sites do not become objectives. Local matches start in free-for-all
deathmatch, with respawns enabled and every player a valid target. Set
`mp_teammates_are_enemies 0` in the console for team deathmatch. Weapon inaccuracy
uses each weapon's first-shot standing or crouching baseline while running,
jumping, climbing, or spraying. Shots retain their normal random first-shot
spread. Recoil remains visible and affects aim, but each automatic shot samples
a different recoil table entry instead of following a fixed spray sequence.
The view tracks recoil so the crosshair remains centered on the recoil-adjusted
shot direction.

For the local listen-server host, the preset keeps `sv_cheats` enabled, god mode active, hit-tagging slowdown disabled, the account at the server's maximum balance, and the active weapon's clip full. In classic and deathmatch games, each CT spawn gives a USP-S, silenced M4A1-S and AWP; each T spawn gives a USP-S, AK-47 and AWP. Other players on either team also spawn with a USP-S by default. The AWP is an extra primary weapon and has a separate scroll-wheel position. While alive, the host can open the buy menu and buy anywhere throughout the round, regardless of buy zones, buy time or mode-specific buy locks. Ordinary inventory limits still apply to individual items. Bots on the local server retain vest armor but receive no helmet protection. These server-side benefits do not override a remote server's rules or apply to other human players. A remote server may also impose its own mouse-pitch limit. The preset is compiled into this Mac build rather than stored in `config.cfg`; editing that file will not change the local locked values.

The AWP uses its native Asiimov paint kit, and the AK-47 uses its official
model-specific Asiimov texture and paint kit when installed from the acquired
content. The M4A1-S uses its native Mecha Industries finish and the USP-S uses
its native Cyrex finish. Chickens are suppressed on local maps, and the warmup
period is disabled by default. Once a map finishes loading,
the team menu appears without a Continue button and stays open until a team is
chosen; choosing CT or T switches teams immediately and spawns the player.

Deathmatch's automatic random buy and automatic rebuy are disabled on Mac so
they cannot replace the fixed spawn loadout after it is granted.

## Status

The port is experimental. On an Apple Silicon Mac, the native client has loaded `de_dust2`, shown the RocketUI team menu, joined a local match, and run combat with bots without Steam. Some legacy assets and features are still incomplete. This client build does not support headless map loading; without a display, SDL/OpenGL initialization fails.

Virtual mesh collision hulls use a zero node offset to represent the absence of
a ledge tree. The prior code truncated a 64-bit pointer into that 32-bit field,
causing a SIGBUS in physics simulation on Apple Silicon.
