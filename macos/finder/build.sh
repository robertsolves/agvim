#!/usr/bin/env bash
# Builds agentnv's Finder extension from this folder, installs it to ~/Applications and
# turns it on. It needs only the Xcode Command Line Tools, which Homebrew needs too,
# and is signed for this Mac alone (no developer account). install.sh runs this.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
EXTENSION_ID=io.github.robertsolves.agentnv.finder.extension
INSTALLED="$HOME/Applications/agentnv Finder.app"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
SDK="$(xcrun --show-sdk-path)"
TARGET="$(uname -m)-apple-macos13.0"
BUILD="$(mktemp -d)/agentnv Finder.app"
APPEX="$BUILD/Contents/PlugIns/agentnv-extension.appex"

mkdir -p "$BUILD/Contents/MacOS" "$APPEX/Contents/MacOS"
cp App-Info.plist "$BUILD/Contents/Info.plist"
cp Extension-Info.plist "$APPEX/Contents/Info.plist"
mkdir -p "$BUILD/Contents/Resources" "$APPEX/Contents/Resources"
cp AppIcon.icns "$BUILD/Contents/Resources/"
cp AppIcon.icns menu-icon.png "$APPEX/Contents/Resources/"
swiftc -O -target "$TARGET" -sdk "$SDK" -module-name main App.swift -o "$BUILD/Contents/MacOS/agentnv-finder"
swiftc -O -target "$TARGET" -sdk "$SDK" -parse-as-library -application-extension \
  -module-name agentnv_extension Extension.swift \
  -Xlinker -e -Xlinker _NSExtensionMain \
  -o "$APPEX/Contents/MacOS/agentnv-extension"
codesign --force --sign - --entitlements Extension.entitlements "$APPEX"
codesign --force --sign - "$BUILD"

pkill -f agentnv-extension || true
rm -rf "$INSTALLED"
mkdir -p "$(dirname "$INSTALLED")"
cp -R "$BUILD" "$INSTALLED"
# A second copy left behind could be picked up in place of the installed one.
rm -rf "$(dirname "$BUILD")"

# What the sandboxed extension runs. zsh -lic loads your shell setup, so tmux, nvim
# and the rest are on PATH.
scripts="$HOME/Library/Application Scripts/$EXTENSION_ID"
mkdir -p "$scripts"
cat >"$scripts/run" <<'SCRIPT'
#!/bin/zsh
action="$1"
shift
exec /bin/zsh -lic '"$HOME/.local/bin/agentnv" _project "$@"' agentnv "finder-$action" "$@" >/dev/null 2>&1
SCRIPT
chmod +x "$scripts/run"

"$LSREGISTER" -f -R -trusted "$INSTALLED"
pluginkit -a "$INSTALLED/Contents/PlugIns/agentnv-extension.appex"
pluginkit -e use -i "$EXTENSION_ID"
