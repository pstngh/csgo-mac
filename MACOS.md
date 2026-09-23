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

Backtick opens the developer console. The Mac gameplay preset locks the normal world FOV to 80, the saved Desktop-preset weapon viewmodel FOV of 60, mouse sensitivity to 1.029863, and `m_pitch` to 0.018. The persistent in-game HUD is crosshair-only; the sniper scope overlay and deliberately opened buy/team menus remain available. On-screen gameplay hints and objective lessons are disabled. Sniper rifles keep a static crosshair while unscoped; the scope uses its own reticle. Click right mouse once to use the AWP's first zoom and again to unscope, even during a shot cooldown. The AWP scope reticle stays sharp while walking (shot accuracy is unchanged). The scroll wheel cycles weapons without showing a selection HUD. The default CT M4 slot uses the silenced M4A1-S from the legally acquired game content.

Use `cg_drawviewmodel 0` to hide the first-person weapon and hands, `cg_drawviewmodel 1` to show only the weapon, or `cg_drawviewmodel 2` for the normal weapon-and-hands view. K cycles through all three values. The default is 2, and the setting is saved. K replaces the previous voice-record binding.

For the local listen-server host, the preset keeps `sv_cheats` enabled, god mode active, hit-tagging slowdown disabled, the account at the server's maximum balance, and the active weapon's clip full. While alive, the host can open the buy menu and buy anywhere throughout the round, regardless of buy zones, buy time, warmup or mode-specific buy locks. Ordinary inventory limits still apply to individual items. Bots on the local server retain vest armor but receive no helmet protection. These server-side benefits do not override a remote server's rules or apply to other human players. A remote server may also impose its own mouse-pitch limit. The preset is compiled into this Mac build rather than stored in `config.cfg`; editing that file will not change the local locked values.

## Status

The port is experimental. On an Apple Silicon Mac, the native client has loaded `de_dust2`, shown the RocketUI team menu, joined a local match, and run combat with bots without Steam. Some legacy assets and features are still incomplete. This client build does not support headless map loading; without a display, SDL/OpenGL initialization fails.
