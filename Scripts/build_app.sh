#!/bin/bash
# Builds a release binary and assembles it into a double-clickable .app
# bundle under ./build. Usage: Scripts/build_app.sh [AppName]
# Defaults to JSONViewer, whose packaging assets live directly under
# Packaging/; every other app's assets live under Packaging/<AppName>/.
set -euo pipefail

APP_NAME="${1:-JSONViewer}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

if [ "$APP_NAME" = "JSONViewer" ]; then
    PACKAGING_DIR="$ROOT_DIR/Packaging"
else
    PACKAGING_DIR="$ROOT_DIR/Packaging/$APP_NAME"
fi

cd "$ROOT_DIR"

echo "Building release binary for $APP_NAME..."
swift build -c release --product "$APP_NAME"

BIN_PATH="$(swift build -c release --show-bin-path)/$APP_NAME"

echo "Assembling $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$PACKAGING_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$PACKAGING_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

echo "Ad-hoc code signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Built $APP_BUNDLE"
echo "Run it with: open \"$APP_BUNDLE\""
