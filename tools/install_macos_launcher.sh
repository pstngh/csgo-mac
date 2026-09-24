#!/bin/zsh
set -euo pipefail

if (( $# != 1 )); then
    print -u2 "Usage: $0 /path/to/game-directory"
    exit 2
fi

launcher_source="${0:A:h}/macos_launcher"
game_directory="${1:A}"
if [[ ! -x "$game_directory/csgo_osx64" || ! -d "$game_directory/csgo/maps" ]]; then
    print -u2 "Expected a playable CS:GO directory at $game_directory"
    exit 1
fi

staging_directory="$(mktemp -d /tmp/csgo-launcher.XXXXXX)"
trap 'rm -rf "$staging_directory"' EXIT
bundle="$staging_directory/CSGO Launcher.app"
mkdir -p "$bundle/Contents/MacOS"
cp "$launcher_source/Info.plist" "$bundle/Contents/Info.plist"
swift_compiler="/Library/Developer/CommandLineTools/usr/bin/swiftc"
macos_sdk="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
if [[ -z "${DEVELOPER_DIR:-}" && -x /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc ]]; then
    swift_compiler="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
    macos_sdk="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
fi
module_cache="${TMPDIR:-/tmp}/csgo-launcher-swift-cache"
"$swift_compiler" -swift-version 5 -parse-as-library -O \
    -target arm64-apple-macosx12.0 -sdk "$macos_sdk" -module-cache-path "$module_cache" \
    "$launcher_source/Launcher.swift" -o "$bundle/Contents/MacOS/CSGOLauncher"
/usr/bin/codesign --force --sign - "$bundle"
/usr/bin/codesign --verify --deep --strict "$bundle"
installed_bundle="$game_directory/CSGO Launcher.app"
if [[ -e "$installed_bundle" ]]; then
    installed_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$installed_bundle/Contents/Info.plist" 2>/dev/null || true)"
    if [[ "$installed_id" != "com.pstn.csgomac.launcher" ]]; then
        print -u2 "Refusing to replace an unrelated app at $installed_bundle"
        exit 1
    fi
    rm -rf "$installed_bundle"
fi
mv "$bundle" "$installed_bundle"
xattr -cr "$installed_bundle"
/usr/bin/codesign --force --deep --sign - "$installed_bundle"
# File Provider can immediately restore FinderInfo after signing an app in Documents.
# FinderInfo is not part of the signature, but codesign's strict verifier rejects it.
xattr -d com.apple.FinderInfo "$installed_bundle" 2>/dev/null || true
/usr/bin/codesign --verify --deep --strict "$installed_bundle"
print "Installed $installed_bundle"
