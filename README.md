<p align="center">
  <img src="icon.svg" width="128" height="128" alt="Locate Icon">
</p>

<h1 align="center">Locate for Mac</h1>

<p align="center">
  <strong>Lightning-fast file search for macOS</strong><br>
  Find any file instantly with full-text search, advanced filters, and global hotkey access.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-15.0+-blue?logo=apple" alt="macOS 15.0+">
  <img src="https://img.shields.io/badge/Swift-6-orange?logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/Status-Production%20Ready-brightgreen" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-blue" alt="License">
</p>

---

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
- Graceful handling of unreadable files

**Beautiful UI**
- Native SwiftUI interface
- First-launch onboarding wizard
- Full Disk Access guidance
- Comprehensive settings

**Secure by Design**
- SQL injection protection via parameterized queries
- Protected database directory (700 permissions)
- Concurrent operation guards

---

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
# OR: See docs/icon-setup.md for other methods

# Build and run
cd Locate
swift build
.build/debug/Locate
```

## 📋 Requirements

- macOS 15.0 or later
- Swift 6 toolchain (for building from source)
- Full Disk Access (optional, for indexing protected folders)

## 📚 Documentation

All documentation is in **[docs/](docs/)**:

- **[tasks.md](tasks.md)** - Development task tracking
- **[AGENTS.md](AGENTS.md)** - Swift/SwiftUI coding guidelines

**Release & Distribution:**
- [Release Guide](docs/release.md) - Build, sign, and distribute
- [Icon Setup](docs/icon-setup.md) - Generate app icon from SVG

**Testing & QA:**
- [QA Checklist](docs/qa-checklist.md) - Comprehensive testing (150+ items)
- [Power Features Tests](docs/power-features-tests.md) - Regression testing
- [Performance Tests](docs/performance-tests.md) - Performance benchmarks

**Planning:**
- [UX Improvements](docs/ux-improvements.md) - Phase 5 roadmap

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
swift run LocateCLI build-index /path/to/folder [--batch 500]
# Database defaults to ~/Library/Application Support/Locate/locate.db
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
- Database stored in `~/Library/Application Support/Locate/` (macOS convention)
- Async file scanning with exclusions
- Batched inserts for performance
- Hardened against unreadable files and SQL injection

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

See [docs/icon-setup.md](docs/icon-setup.md) for other methods.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Credits

Built with Swift Package Manager, SQLite FTS5, and macOS SDK.
Icon: Custom blue glass design for macOS.

---

**Status:** ✅ v1.2.0 production-ready | Hardened & tested
