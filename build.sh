#!/bin/bash
set -e

APP_NAME="Notepad"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app/Contents"

echo "🔨 Building $APP_NAME..."

rm -rf "$BUILD_DIR/$APP_NAME.app"
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

compgen -G "Sources/*.swift" > /dev/null || { echo "❌ No Swift files in Sources/"; exit 1; }

swiftc Sources/*.swift \
    -o "$APP_DIR/MacOS/$APP_NAME" \
    -framework AppKit \
    -framework Foundation

cp Resources/Info.plist "$APP_DIR/Info.plist"
cp Resources/AppIcon.icns "$APP_DIR/Resources/AppIcon.icns"

echo "🧪 Running tests..."

swiftc Tests/test_scratch_store.swift \
    Sources/ScratchStore.swift \
    -o "$BUILD_DIR/test_scratch" 2>&1
"$BUILD_DIR/test_scratch"

swiftc Tests/test_window_controller.swift \
    Sources/NotepadWindowController.swift \
    Sources/ScratchStore.swift \
    -o "$BUILD_DIR/test_window_controller" \
    -framework AppKit -framework Foundation 2>&1
"$BUILD_DIR/test_window_controller"

echo "✅ Built: $BUILD_DIR/$APP_NAME.app"
echo "   To install: cp -r $BUILD_DIR/$APP_NAME.app /Applications/"
