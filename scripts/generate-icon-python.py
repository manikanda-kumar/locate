#!/usr/bin/env python3
"""
Generate macOS app icon from SVG
Requires: pip install cairosvg pillow
"""

import os
import sys
from pathlib import Path

try:
    import cairosvg
    from PIL import Image
    import io
except ImportError:
    print("Error: Required packages not installed")
    print("Install with: pip3 install cairosvg pillow")
    sys.exit(1)

# Paths
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
SVG_FILE = PROJECT_ROOT / "icon.svg"
ICONSET_DIR = PROJECT_ROOT / "Locate" / "AppIcon.iconset"
ICNS_FILE = PROJECT_ROOT / "Locate" / "AppIcon.icns"

# Icon sizes for macOS
ICON_SIZES = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

def generate_png(svg_path, size, output_path):
    """Generate PNG from SVG at specified size"""
    png_data = cairosvg.svg2png(
        url=str(svg_path),
        output_width=size,
        output_height=size
    )

    # Optimize with Pillow
    img = Image.open(io.BytesIO(png_data))
    img.save(output_path, "PNG", optimize=True)

def main():
    print("Generating app icon from icon.svg...")

    # Check if SVG exists
    if not SVG_FILE.exists():
        print(f"Error: icon.svg not found at {SVG_FILE}")
        sys.exit(1)

    # Create iconset directory
    if ICONSET_DIR.exists():
        import shutil
        shutil.rmtree(ICONSET_DIR)
    ICONSET_DIR.mkdir(parents=True)

    # Generate all sizes
    print("Generating icon sizes...")
    for size, filename in ICON_SIZES:
        output_path = ICONSET_DIR / filename
        print(f"  {size}x{size} -> {filename}")
        generate_png(SVG_FILE, size, output_path)

    # Convert to .icns using iconutil
    print("Creating .icns file...")
    os.system(f"iconutil -c icns '{ICONSET_DIR}' -o '{ICNS_FILE}'")

    print("\n✅ Icon generated successfully!")
    print(f"   - Iconset: {ICONSET_DIR}")
    print(f"   - ICNS: {ICNS_FILE}")
    print("\nNext: Update Info.plist to reference AppIcon.icns")

if __name__ == "__main__":
    main()
