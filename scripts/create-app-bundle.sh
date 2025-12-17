#!/bin/bash
set -e

# Create macOS .app bundle from Swift Package Manager build
# This is needed because SPM builds executables, not app bundles

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/Locate/.build/debug"
APP_NAME="Locate"
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"

echo "Creating app bundle: $APP_BUNDLE"

# Create bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
echo "Copying executable..."
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
echo "Copying Info.plist..."
cp "$PROJECT_ROOT/Locate/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy icon
if [ -f "$PROJECT_ROOT/Locate/AppIcon.icns" ]; then
    echo "Copying icon..."
    cp "$PROJECT_ROOT/Locate/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "Warning: AppIcon.icns not found, skipping icon"
fi

# Copy entitlements (for reference, not used at runtime)
if [ -f "$PROJECT_ROOT/Locate/Locate.entitlements" ]; then
    cp "$PROJECT_ROOT/Locate/Locate.entitlements" "$APP_BUNDLE/Contents/Resources/"
fi

echo "✅ App bundle created successfully!"
echo "   Location: $APP_BUNDLE"
echo ""
echo "To run:"
echo "  open '$APP_BUNDLE'"
echo ""
echo "To view icon:"
echo "  qlmanage -p '$APP_BUNDLE'"
