#!/bin/bash
set -e

# Generate app icon from SVG
# Requires: librsvg (brew install librsvg)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SVG_FILE="$PROJECT_ROOT/icon.svg"
ICONSET_DIR="$PROJECT_ROOT/Locate/AppIcon.iconset"

echo "Generating app icon from icon.svg..."

# Check if rsvg-convert is available
if ! command -v rsvg-convert &> /dev/null; then
    echo "Error: rsvg-convert not found"
    echo "Install with: brew install librsvg"
    exit 1
fi

# Check if SVG exists
if [ ! -f "$SVG_FILE" ]; then
    echo "Error: icon.svg not found at $SVG_FILE"
    exit 1
fi

# Create iconset directory
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Generate all required icon sizes
echo "Generating icon sizes..."

# Function to generate icon
generate_icon() {
    local size=$1
    local name=$2
    echo "  ${size}x${size} -> ${name}"
    rsvg-convert -w $size -h $size "$SVG_FILE" > "$ICONSET_DIR/$name"
}

# macOS required sizes
generate_icon 16 "icon_16x16.png"
generate_icon 32 "icon_16x16@2x.png"
generate_icon 32 "icon_32x32.png"
generate_icon 64 "icon_32x32@2x.png"
generate_icon 128 "icon_128x128.png"
generate_icon 256 "icon_128x128@2x.png"
generate_icon 256 "icon_256x256.png"
generate_icon 512 "icon_256x256@2x.png"
generate_icon 512 "icon_512x512.png"
generate_icon 1024 "icon_512x512@2x.png"

# Convert iconset to icns
echo "Creating .icns file..."
iconutil -c icns "$ICONSET_DIR" -o "$PROJECT_ROOT/Locate/AppIcon.icns"

echo "✅ Icon generated successfully!"
echo "   - Iconset: $ICONSET_DIR"
echo "   - ICNS: $PROJECT_ROOT/Locate/AppIcon.icns"
echo ""
echo "Note: Update Info.plist to reference AppIcon.icns"
