#!/bin/bash
set -e

# Locate Release Script
# Full build, sign, notarize, and package workflow
# Usage: ./scripts/release.sh [version] [--skip-notarize]

VERSION=${1:-"1.0.0"}
SKIP_NOTARIZE=false

if [ "$2" == "--skip-notarize" ]; then
    SKIP_NOTARIZE=true
fi

APP_NAME="Locate"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="build"
DMG_TEMP="$BUILD_DIR/dmg-temp"
FINAL_DMG="$BUILD_DIR/$DMG_NAME"
KEYCHAIN_PROFILE="notarytool-profile"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_step() {
    echo -e "${GREEN}➜${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo_error() {
    echo -e "${RED}✗${NC} $1"
}

echo_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Check if Developer ID is configured
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo_warning "No Developer ID Application certificate found"
    echo_warning "Continuing without code signing..."
    SKIP_SIGNING=true
else
    SKIP_SIGNING=false
    DEVELOPER_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)"/\1/')
    echo_success "Found Developer ID: $DEVELOPER_ID"
fi

echo ""
echo "================================================"
echo "   Locate Release Build"
echo "   Version: $VERSION"
echo "================================================"
echo ""

# Step 1: Clean previous builds
echo_step "Cleaning previous builds..."
rm -rf "$DMG_TEMP"
rm -f "$FINAL_DMG"
mkdir -p "$BUILD_DIR"

# Step 2: Build the app
echo_step "Building release binary..."
cd Locate
swift build -c release
cd ..

# Step 2.5: Create app bundle
echo_step "Creating app bundle..."
BUILD_DIR_RELEASE="Locate/.build/release"
APP_BUNDLE="$BUILD_DIR_RELEASE/${APP_NAME}.app"

# Create bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp "$BUILD_DIR_RELEASE/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "Locate/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy icon
if [ -f "Locate/AppIcon.icns" ]; then
    cp "Locate/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# Copy entitlements
if [ -f "Locate/Locate.entitlements" ]; then
    cp "Locate/Locate.entitlements" "$APP_BUNDLE/Contents/Resources/"
fi

if [ ! -d "$APP_BUNDLE" ]; then
    echo_error "${APP_NAME}.app not found!"
    exit 1
fi

echo_success "Build complete"

# Step 3: Code signing
if [ "$SKIP_SIGNING" == "false" ]; then
    echo_step "Signing app bundle..."

    codesign --force --deep \
        --sign "$DEVELOPER_ID" \
        --options runtime \
        --entitlements "Locate/Locate.entitlements" \
        --timestamp \
        "Locate/.build/release/${APP_NAME}.app"

    # Verify signature
    if codesign -vvv --deep --strict "Locate/.build/release/${APP_NAME}.app" 2>&1 | grep -q "valid on disk"; then
        echo_success "Code signing successful"
    else
        echo_error "Code signing failed"
        exit 1
    fi
else
    echo_warning "Skipping code signing"
fi

# Step 4: Create DMG
echo_step "Creating DMG..."
mkdir -p "$DMG_TEMP"
cp -r "Locate/.build/release/${APP_NAME}.app" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$FINAL_DMG"

rm -rf "$DMG_TEMP"
echo_success "DMG created: $FINAL_DMG"

# Step 5: Notarization
if [ "$SKIP_NOTARIZE" == "true" ] || [ "$SKIP_SIGNING" == "true" ]; then
    echo_warning "Skipping notarization"
else
    echo_step "Submitting for notarization..."

    # Check if keychain profile exists
    if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" 2>&1 | grep -q "history"; then
        echo_warning "Notarytool profile '$KEYCHAIN_PROFILE' not found"
        echo "To set up notarization, run:"
        echo "  xcrun notarytool store-credentials \"$KEYCHAIN_PROFILE\" \\"
        echo "    --apple-id \"your-email@example.com\" \\"
        echo "    --team-id \"YOUR_TEAM_ID\" \\"
        echo "    --password \"your-app-specific-password\""
        echo ""
        echo "For now, skipping notarization..."
    else
        # Submit for notarization
        SUBMISSION_ID=$(xcrun notarytool submit "$FINAL_DMG" \
            --keychain-profile "$KEYCHAIN_PROFILE" \
            --wait \
            --output-format json | jq -r '.id')

        # Check status
        STATUS=$(xcrun notarytool info "$SUBMISSION_ID" \
            --keychain-profile "$KEYCHAIN_PROFILE" \
            --output-format json | jq -r '.status')

        if [ "$STATUS" == "Accepted" ]; then
            echo_success "Notarization successful"

            # Staple the ticket
            echo_step "Stapling notarization ticket..."
            xcrun stapler staple "$FINAL_DMG"
            echo_success "Ticket stapled"
        else
            echo_error "Notarization failed with status: $STATUS"
            echo "View log with: xcrun notarytool log $SUBMISSION_ID --keychain-profile \"$KEYCHAIN_PROFILE\""
            exit 1
        fi
    fi
fi

# Step 6: Verify the final DMG
echo_step "Verifying DMG..."
if xcrun stapler validate "$FINAL_DMG" 2>&1 | grep -q "is not signed"; then
    echo_warning "DMG is not notarized (expected if notarization was skipped)"
else
    echo_success "DMG verification passed"
fi

# Final summary
echo ""
echo "================================================"
echo "   Release Complete!"
echo "================================================"
echo ""
echo "📦 Package: $FINAL_DMG"
echo "📏 Size: $(du -h "$FINAL_DMG" | cut -f1)"
echo ""

if [ "$SKIP_SIGNING" == "false" ] && [ "$SKIP_NOTARIZE" == "false" ]; then
    echo_success "Ready for distribution!"
    echo ""
    echo "Next steps:"
    echo "1. Test on a clean macOS installation"
    echo "2. Create GitHub release"
    echo "3. Upload $DMG_NAME"
    echo "4. Update release notes"
else
    echo_warning "Remember to sign and notarize before distributing!"
fi
