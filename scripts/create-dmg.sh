#!/bin/bash
set -e

# Locate DMG Creation Script
# Usage: ./scripts/create-dmg.sh [version]

VERSION=${1:-"1.0.0"}
APP_NAME="Locate"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="build"
DMG_TEMP="$BUILD_DIR/dmg-temp"
FINAL_DMG="$BUILD_DIR/$DMG_NAME"

echo "Creating DMG for $APP_NAME version $VERSION..."

# Clean previous build
rm -rf "$DMG_TEMP"
rm -f "$FINAL_DMG"
mkdir -p "$BUILD_DIR"

# Build the app in release mode
echo "Building release binary..."
cd Locate
swift build -c release
cd ..

# Create app bundle
echo "Creating app bundle..."
BUILD_DIR_RELEASE="Locate/.build/release"
APP_BUNDLE="$BUILD_DIR_RELEASE/${APP_NAME}.app"

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR_RELEASE/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cp "Locate/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -f "Locate/AppIcon.icns" ]; then
    cp "Locate/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

if [ -f "Locate/Locate.entitlements" ]; then
    cp "Locate/Locate.entitlements" "$APP_BUNDLE/Contents/Resources/"
fi

# Check if app was built
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: ${APP_NAME}.app not found"
    exit 1
fi

# Create temp directory for DMG contents
mkdir -p "$DMG_TEMP"

# Copy app to temp directory
echo "Copying app bundle..."
cp -r "Locate/.build/release/${APP_NAME}.app" "$DMG_TEMP/"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG
echo "Creating DMG..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$FINAL_DMG"

# Clean up temp directory
rm -rf "$DMG_TEMP"

echo "✅ DMG created successfully: $FINAL_DMG"
echo ""
echo "Next steps:"
echo "1. Sign the app: codesign --force --deep --sign \"Developer ID\" --options runtime $APP_NAME.app"
echo "2. Notarize the DMG: xcrun notarytool submit $FINAL_DMG"
echo "3. Staple the ticket: xcrun stapler staple $FINAL_DMG"
