# Locate for Mac

Lightning-fast file search for macOS. Find any file instantly with full-text search, advanced filters, and global hotkey access.

## ✨ Features

**Instant Search**
- Full-text search powered by SQLite FTS5
- Results in under 100ms
- Search as you type with live results

**Advanced Filters**
- Filter by file type (Documents, Images, Code)
- Filter by size (>1MB, >10MB, >100MB)
- Filter by date (Last 24h, 7 days, 30 days)
- Regex pattern matching
- Case-sensitive search

**Always Available**
- Global hotkey: **⌥Space** to search anytime
- Menu bar quick search
- Keyboard-driven interface

**Powerful Indexing**
- Index multiple folders
- Configurable exclusion patterns
- Automatic reindexing (1-24 hour intervals)
- Progress tracking

**Beautiful UI**
- Native SwiftUI interface
- First-launch onboarding wizard
- Full Disk Access guidance
- Comprehensive settings

## 🚀 Quick Start

### For Users

1. Download the latest DMG from [Releases](#)
2. Open DMG and drag Locate to Applications
3. Launch Locate
4. Follow the onboarding wizard to select folders
5. Press ⌥Space anytime to search!

### For Developers

```bash
# Clone and build
git clone <repo-url>
cd locate

# Set up app icon (choose one)
brew install librsvg && ./scripts/generate-icon.sh
# OR: See ICON_SETUP.md for other methods

# Build and run
cd Locate
swift build
.build/debug/Locate
```

## 📋 Requirements

- macOS 12.0 or later
- Swift 6 toolchain (for building from source)
- Full Disk Access (optional, for indexing protected folders)

## 📚 Documentation

- **[ICON_SETUP.md](ICON_SETUP.md)** - Set up the app icon
- **[PHASE4_COMPLETE.md](PHASE4_COMPLETE.md)** - Implementation details
- **[docs/](docs/)** - Complete documentation
  - [Release Guide](docs/release.md) - Build, sign, and distribute
  - [QA Checklist](docs/qa-checklist.md) - Comprehensive testing
  - [Power Features Tests](docs/power-features-tests.md) - Regression testing
  - [Performance Tests](docs/performance-tests.md) - Performance benchmarks

## ⌨️ Keyboard Shortcuts

- **⌥Space** - Show search window (global)
- **⌘F** - Focus search field
- **⌘R** - Rebuild index
- **⌘,** - Open Settings
- **Return** / **⌘O** - Open selected file
- **Escape** / **⌘W** - Close window

## 🛠️ CLI Tool

The included `LocateCLI` provides command-line access:

### Build Index
```bash
swift run LocateCLI build-index /path/to/folder [--db ~/.locate/db.sqlite] [--batch 500]
```

### Search
```bash
swift run LocateCLI search "query" [--ext swift,md] [--limit 50] [--min-size 1024]
```

### Examples
```bash
# Index home directory
swift run LocateCLI build-index ~

# Find Swift files
swift run LocateCLI search Package --ext swift --limit 10

# Find large files
swift run LocateCLI search data --min-size 10485760
```

## 🏗️ Architecture

**LocateCore** - Search & indexing engine
- SQLite database with FTS5 full-text search
- Async file scanning with exclusions
- Batched inserts for performance

**LocateViewModel** - Application state
- Observable search state with @Observable
- Settings persistence via UserDefaults
- Permission management

**Locate** - SwiftUI interface
- Main search interface
- Settings with 4 tabs (Folders, Exclusions, Indexing, Privacy)
- Onboarding wizard
- Menu bar quick search
- Global hotkey manager

## ⚡ Performance

Targets:
- **Indexing:** 10k files in < 30 seconds
- **Search:** Results in < 100ms
- **Memory:** < 50MB idle, < 200MB during indexing
- **UI:** Always responsive, no lag

## 🧪 Development

### Running Tests
```bash
cd Locate
swift test
```

### Building for Release
```bash
./scripts/release.sh 1.0.0
```

See [docs/release.md](docs/release.md) for detailed release process.

## 🎨 Icon

The app icon features a blue glass macOS-style design with folder and magnifying glass elements. To generate the icon:

```bash
brew install librsvg
./scripts/generate-icon.sh
```

See [ICON_SETUP.md](ICON_SETUP.md) for other methods.

## 📄 License

Copyright © 2025. All rights reserved.

## 🙏 Credits

Built with Swift Package Manager, SQLite FTS5, and macOS SDK.
Icon: Custom blue glass design for macOS.

---

**Status:** ✅ v1.0 feature-complete | Ready for testing and release

See [PHASE4_COMPLETE.md](PHASE4_COMPLETE.md) for full details.
