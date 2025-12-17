# 🎨 Setting Up the App Icon

Your custom icon is ready at `icon.svg`. Follow these quick steps to integrate it:

## Quick Setup (Choose One Method)

### Method 1: Homebrew (Recommended - Fastest)
```bash
# Install tool if needed
brew install librsvg

# Generate icon (takes 2 seconds)
./scripts/generate-icon.sh
```

### Method 2: Python
```bash
# Install dependencies once
pip3 install cairosvg pillow

# Generate icon
./scripts/generate-icon-python.py
```

### Method 3: ImageMagick
```bash
# Install tool if needed
brew install imagemagick

# Quick script
cd Locate
mkdir -p AppIcon.iconset
for size in 16 32 64 128 256 512 1024; do
  convert ../icon.svg -resize ${size}x${size} AppIcon.iconset/icon_${size}x${size}.png
done
iconutil -c icns AppIcon.iconset -o AppIcon.icns
```

### Method 4: Online Tool (No Install)
1. Visit https://cloudconvert.com/svg-to-png
2. Upload `icon.svg`
3. Download PNG at 1024x1024
4. Use macOS Preview to create other sizes
5. Follow manual steps in `docs/icon-setup.md`

### Method 5: Manual (Any Image Editor)
Use Figma, Sketch, Photoshop, or any tool:
1. Open `icon.svg`
2. Export as PNG at sizes: 16, 32, 64, 128, 256, 512, 1024
3. Follow structure in `docs/icon-setup.md`

## Verify Installation

After running any method above:

```bash
# Check if icon was created
ls -la Locate/AppIcon.icns

# Build and test
cd Locate && swift build
open .build/debug/Locate.app
```

The icon should appear in the Dock!

## Detailed Guide

See `docs/icon-setup.md` for:
- Complete installation steps
- Troubleshooting
- Manual process details
- Icon design notes

## What This Does

Your icon features:
- 🪟 Liquid glass macOS-style background
- 📁 Folder symbol (file management)
- 🔍 Magnifying glass (search)
- 🔵 Blue Spotlight indicator

Perfect for a file search utility!

## Need Help?

1. Check `docs/icon-setup.md` for detailed troubleshooting
2. Verify dependencies are installed
3. Make sure you're in the project root directory

## Icon Already Generated?

If `Locate/AppIcon.icns` exists, you're all set! Just build the project:
```bash
cd Locate
swift build
```

---

**Next:** After icon setup, see `PHASE4_COMPLETE.md` for final release steps.
