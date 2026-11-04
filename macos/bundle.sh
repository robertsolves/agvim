#!/usr/bin/env bash
# Builds AgentNV.app and AgentNV.dmg, to download and install, in dist/ (gitignored).
# The app holds a copy of this repo; its first launch installs from that.
#
#   macos/bundle.sh             the app and the .dmg
#   macos/bundle.sh --app-only  just the app (install.sh uses this)
#
# Signed for this Mac alone by default, so people who download it must allow it once:
# System Settings > Privacy & Security > Open Anyway. To avoid that, set
# AGENTNV_SIGN_IDENTITY to a Developer ID certificate, then notarize the .dmg.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
APP="$DIST/AgentNV.app"
PAYLOAD="$APP/Contents/Resources/agentnv"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$PAYLOAD"
cp "$ROOT/macos/app/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/macos/app/launcher" "$APP/Contents/MacOS/AgentNV"
cp "$ROOT/macos/finder/AppIcon.icns" "$APP/Contents/Resources/"
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$ROOT" ls-files -co --exclude-standard -z | while IFS= read -r -d '' file; do
    [ -e "$ROOT/$file" ] || continue
    mkdir -p "$PAYLOAD/$(dirname "$file")"
    cp -pR "$ROOT/$file" "$PAYLOAD/$file" # -R keeps links as links
  done
else
  # A copy made from this app: no git yet, and nothing here to leave out.
  (cd "$ROOT" && tar --exclude ./dist --exclude ./saved-projects -cf - .) | tar -xf - -C "$PAYLOAD"
fi
codesign --force --sign "${AGENTNV_SIGN_IDENTITY:--}" "$APP" 2>/dev/null
echo "$APP"

[ "${1:-}" = --app-only ] && exit 0

STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DIST/AgentNV.dmg"
hdiutil create -quiet -volname AgentNV -srcfolder "$STAGE" -format UDZO "$DIST/AgentNV.dmg"
rm -rf "$STAGE"
echo "$DIST/AgentNV.dmg"
