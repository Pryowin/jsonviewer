#!/bin/bash
# Builds a release binary and assembles it into a double-clickable
# JSONViewer.app bundle under ./build.
set -euo pipefail

APP_NAME="JSONViewer"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

cd "$ROOT_DIR"

echo "Building release binary..."
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/$APP_NAME"

echo "Assembling $APP_NAME.app..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "Ad-hoc code signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Built $APP_BUNDLE"
echo "Run it with: open \"$APP_BUNDLE\""
