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
- An arm64 `libsteam_api.dylib` from your own Steam installation for linking and local runtime use
- Legally acquired CS:GO game content

Install the build dependencies with Homebrew:

```sh
brew install cmake ninja sdl2-compat
```

## Configure and build

Kisak-Strike writes runtime binaries to a sibling `game` directory. Clone this repository inside a parent working directory, then configure from the repository root:

```sh
cmake -S . -B ../build-macos-arm64 -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/macos-arm64.cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DDEDICATED=OFF \
  -DUSE_KISAK_PHYSICS=ON \
  -DUSE_ROCKETUI=OFF \
  -DUSE_SCALEFORM=OFF \
  -DSTEAM_API_LIBRARY="/absolute/path/to/arm64/libsteam_api.dylib"

cmake --build ../build-macos-arm64
```

The library passed as `STEAM_API_LIBRARY` must contain an arm64 slice. The build copies it into the two local runtime module directories. It is not included in this repository, and the Steam desktop client does not need to run when launching standalone.

The port vendors the MIT-licensed [sse2neon](https://github.com/DLTcollab/sse2neon) compatibility headers used to translate Source's SSE intrinsics to ARM NEON.

## Game content

This repository does not contain Valve game assets. Follow the upstream acquisition instructions for app 730, depot 731, manifest `7043469183016184477`, and place that content in the sibling `game` directory. You must have the legal right to use the content.

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

## Status

The port is experimental. The native client reaches the main menu, loads `de_dust2`, and starts an insecure LAN listen server. Additional hardware and macOS-version testing is welcome.
