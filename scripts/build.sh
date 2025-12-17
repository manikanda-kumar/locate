#!/bin/bash
set -e

# Complete build script for Locate
# Builds the app and creates a proper macOS app bundle

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔨 Building Locate..."
cd "$PROJECT_ROOT/Locate"
swift build

echo ""
echo "📦 Creating app bundle..."
"$SCRIPT_DIR/create-app-bundle.sh"

echo ""
echo "✅ Build complete!"
echo ""
echo "Run the app with:"
echo "  open Locate/.build/debug/Locate.app"
