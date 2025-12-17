# Locate Release Process

This document describes the process for building, packaging, and distributing Locate for macOS.

## Prerequisites

- Xcode 15+ installed
- Valid Apple Developer account with signing certificate
- App-specific password for notarization

## Building for Release

### 1. Update Version Numbers

Update version in `Locate/Info.plist`:
```xml
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>CFBundleVersion</key>
<string>1</string>
```

### 2. Build Release Binary

From the `Locate` directory:

```bash
swift build -c release --arch arm64 --arch x86_64
```

Or use Xcode:
1. Open `Package.swift` in Xcode
2. Select Product > Archive
3. Export the app bundle

### 3. Generate Xcode Project (if needed)

```bash
cd Locate
swift package generate-xcodeproj
```

## Creating the DMG

### Option 1: Using create-dmg

Install create-dmg:
```bash
brew install create-dmg
```

Create DMG:
```bash
./scripts/create-dmg.sh
```

### Option 2: Manual DMG Creation

1. Build the app:
```bash
cd Locate
swift build -c release
```

2. Create a temporary directory:
```bash
mkdir -p build/dmg-temp
cp -r .build/release/Locate.app build/dmg-temp/
ln -s /Applications build/dmg-temp/Applications
```

3. Create DMG:
```bash
hdiutil create -volname "Locate" \
  -srcfolder build/dmg-temp \
  -ov -format UDZO \
  build/Locate-1.0.0.dmg
```

4. Clean up:
```bash
rm -rf build/dmg-temp
```

## Code Signing

Sign the app bundle:
```bash
codesign --force --deep --sign "Developer ID Application: Your Name" \
  --options runtime \
  --entitlements Locate.entitlements \
  .build/release/Locate.app
```

Verify signature:
```bash
codesign -vvv --deep --strict .build/release/Locate.app
spctl -a -vvv -t execute .build/release/Locate.app
```

## Notarization

### 1. Store Credentials

Store your app-specific password in Keychain:
```bash
xcrun notarytool store-credentials "notarytool-profile" \
  --apple-id "your-email@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "your-app-specific-password"
```

### 2. Submit for Notarization

```bash
xcrun notarytool submit build/Locate-1.0.0.dmg \
  --keychain-profile "notarytool-profile" \
  --wait
```

### 3. Staple the Notarization

After successful notarization:
```bash
xcrun stapler staple build/Locate-1.0.0.dmg
```

Verify:
```bash
xcrun stapler validate build/Locate-1.0.0.dmg
spctl -a -vvv -t open --context context:primary-signature build/Locate-1.0.0.dmg
```

## Automated Release Script

Use the provided script:
```bash
./scripts/release.sh 1.0.0
```

This script:
1. Builds the release binary
2. Creates a DMG
3. Signs the app
4. Submits for notarization
5. Staples the ticket
6. Verifies the final DMG

## Distribution Checklist

- [ ] Version numbers updated in Info.plist
- [ ] Release notes written
- [ ] App built in release mode
- [ ] DMG created
- [ ] App signed with Developer ID
- [ ] DMG notarized by Apple
- [ ] Notarization ticket stapled
- [ ] DMG verified on clean macOS install
- [ ] Tested on both Intel and Apple Silicon Macs
- [ ] GitHub release created with DMG attached
- [ ] Release notes published

## Testing the Release

Test on a clean Mac:
1. Download the DMG
2. Open it and drag Locate to Applications
3. Launch Locate
4. Verify no security warnings appear
5. Test all core features:
   - Onboarding flow
   - Index building
   - Search functionality
   - Settings persistence
   - Global hotkey (⌥Space)
   - Menu bar extra
   - Full Disk Access prompt

## Troubleshooting

### Notarization Fails

Check the notarization log:
```bash
xcrun notarytool log <submission-id> \
  --keychain-profile "notarytool-profile"
```

Common issues:
- Hardened Runtime not enabled → Add to entitlements
- Invalid signature → Re-sign with correct certificate
- Missing entitlements → Verify entitlements file

### Gatekeeper Blocks App

If users see "App is damaged":
1. Ensure hardened runtime is enabled
2. Verify notarization was successful
3. Check that notarization ticket was stapled

### App Won't Launch

Check signing:
```bash
codesign -dvvv Locate.app
```

Check entitlements:
```bash
codesign -d --entitlements - Locate.app
```

## Version History

- 1.0.0 - Initial release
  - Full-text search with FTS5
  - Advanced filters (type, size, date, regex)
  - Global hotkey (⌥Space)
  - Menu bar quick search
  - Automatic reindexing
