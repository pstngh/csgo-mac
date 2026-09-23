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
arch -arm64 ./csgo_osx64 -insecure -novid -windowed -console
```

To start a local map directly:

```sh
arch -arm64 ./csgo_osx64 -insecure -novid -windowed -console +map de_dust2
```

Standalone listen servers intentionally fall back to LAN mode when Steam services are unavailable. Console messages from failed Steam API initialization may still appear; they are non-fatal in this mode.

The experimental square radar and idle chat feed are hidden by default. You can turn the radar back on with `rocket_hud_radar_enable 1` or show idle chat with `rocket_hud_chat_idle_opacity 0.2` in the console. If debug messages appear at the lower left, enter `developer 0` (the launch commands above do not enable developer mode).

## Status

The port is experimental. On an Apple Silicon Mac, the native client has loaded `de_dust2`, shown the RocketUI team menu, joined a local match, and run combat with bots without Steam. Some legacy assets and features are still incomplete. This client build does not support headless map loading; without a display, SDL/OpenGL initialization fails.
