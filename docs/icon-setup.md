# App Icon Setup Guide

Guide for setting up the Locate app icon from the provided `icon.svg` file.

## Quick Start (Recommended)

### Option 1: Using Homebrew & librsvg (Fastest)

```bash
# Install librsvg if not already installed
brew install librsvg

# Generate icon
./scripts/generate-icon.sh
```

This creates:
- `Locate/AppIcon.iconset/` - All PNG sizes
- `Locate/AppIcon.icns` - macOS icon file

### Option 2: Using Python

```bash
# Install dependencies
pip3 install cairosvg pillow

# Generate icon
./scripts/generate-icon-python.py
```

### Option 3: Manual Conversion (Any Tool)

Use any image editor that can export SVG to PNG (Figma, Sketch, Photoshop, GIMP, Inkscape, etc.):

1. Open `icon.svg`
2. Export the following PNG sizes:
   - 16x16 → `icon_16x16.png`
   - 32x32 → `icon_16x16@2x.png` and `icon_32x32.png`
   - 64x64 → `icon_32x32@2x.png`
   - 128x128 → `icon_128x128.png`
   - 256x256 → `icon_128x128@2x.png` and `icon_256x256.png`
   - 512x512 → `icon_256x256@2x.png` and `icon_512x512.png`
   - 1024x1024 → `icon_512x512@2x.png`

3. Put all files in `Locate/AppIcon.iconset/`

4. Create .icns file:
```bash
iconutil -c icns Locate/AppIcon.iconset -o Locate/AppIcon.icns
```

## Integration with Project

### For Swift Package Manager Projects

After generating `AppIcon.icns`:

**Option A: Using Info.plist (Current approach)**

1. The `AppIcon.icns` should be in the `Locate/` directory
2. Info.plist already configured with `CFBundleIconFile` key
3. During build, copy the icon to the app bundle

**Option B: Using Assets Catalog (Xcode Project)**

If you generate an Xcode project:

1. Generate Xcode project:
```bash
cd Locate
swift package generate-xcodeproj
```

2. Open in Xcode
3. Add `AppIcon.icns` to Assets.xcassets
4. Set as app icon in target settings

### Verifying Icon

After building the app:

```bash
# Check if icon is in the app bundle
ls -la .build/debug/Locate.app/Contents/Resources/

# View the icon
qlmanage -p .build/debug/Locate.app/Contents/Resources/AppIcon.icns
```

## Icon Design Notes

The `icon.svg` features:
- **Liquid glass background** - macOS-style translucent rounded square
- **Folder symbol** - Represents file management
- **Magnifying glass** - Represents search functionality
- **Blue spotlight indicator** - macOS Spotlight reference
- **1024x1024** - Optimized for Retina displays

Design elements:
- Follows macOS Big Sur+ design language
- Translucent layers with glassmorphism
- Subtle shadows and strokes
- Recognizable at all sizes

## Troubleshooting

### "rsvg-convert not found"
Install librsvg:
```bash
brew install librsvg
```

### "No module named 'cairosvg'"
Install Python packages:
```bash
pip3 install cairosvg pillow
```

### Icon doesn't appear in built app

1. Check if `AppIcon.icns` exists in `Locate/` directory
2. Verify Info.plist has:
```xml
<key>CFBundleIconFile</key>
<string>AppIcon</string>
```

3. Clean and rebuild:
```bash
swift package clean
swift build
```

4. For release builds, ensure icon is copied to Resources

### Icon looks pixelated

Make sure you generated all required sizes, especially the @2x variants for Retina displays.

### Icon has wrong background color

The SVG uses transparency. Make sure your conversion tool preserves alpha channel.

## Alternative: Using SF Symbols

If you prefer a system icon as placeholder:

1. Use SF Symbols app (free from Apple)
2. Export `magnifyingglass.circle.fill`
3. Follow same process as above

## Icon File Sizes

Approximate file sizes after generation:
- Each PNG: 5-50 KB (varies by size)
- Total iconset: ~200 KB
- Final .icns: ~150 KB

## Platform Requirements

### Required Sizes for macOS
- 16x16 (standard + @2x)
- 32x32 (standard + @2x)
- 128x128 (standard + @2x)
- 256x256 (standard + @2x)
- 512x512 (standard + @2x)

### Optional (but recommended)
- 1024x1024 for App Store

## Next Steps

After generating the icon:

1. ✅ Generate all PNG sizes
2. ✅ Create AppIcon.icns
3. ✅ Verify icon file exists
4. ✅ Build project
5. ✅ Check icon appears in built app
6. ✅ Test at different sizes (Dock, Finder, Spotlight)

## Resources

- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [iconutil man page](https://ss64.com/osx/iconutil.html)
- [librsvg GitHub](https://github.com/GNOME/librsvg)
- [cairosvg PyPI](https://pypi.org/project/CairoSVG/)
