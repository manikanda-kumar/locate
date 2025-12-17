# Locate Documentation

Welcome to the Locate documentation. This directory contains guides for development, testing, and release processes.

## For Users

**Getting Started:**
- Install Locate from the DMG
- Follow the onboarding wizard to select folders to index
- Press ⌥Space anytime to search your files instantly

**Features:**
- Lightning-fast full-text search powered by SQLite FTS5
- Advanced filters: file type, size, date, regex, case sensitivity
- Global hotkey (⌥Space) for instant access
- Menu bar quick search
- Automatic reindexing
- Full Disk Access guidance

## For Developers

### Documentation Files

**Release & Distribution:**
- **[release.md](release.md)** - Complete guide for building, packaging, and distributing Locate
- **[icon-setup.md](icon-setup.md)** - Icon generation from SVG (multiple methods)

**Testing & QA:**
- **[qa-checklist.md](qa-checklist.md)** - Comprehensive QA testing checklist (150+ items)
- **[power-features-tests.md](power-features-tests.md)** - Regression tests for advanced features
- **[performance-tests.md](performance-tests.md)** - Performance and memory testing guide

**Planning & Development:**
- **[ux-improvements.md](ux-improvements.md)** - Phase 5 UX improvements roadmap (filters, columns, hidden files)
- **[swift6-migration-notes.md](swift6-migration-notes.md)** - Swift 6 concurrency fixes and gotchas

### Quick Start Development

```bash
# Clone the repository
git clone <repo-url>
cd locate

# Build the project
cd Locate
swift build

# Run the app
.build/debug/Locate

# Run tests
swift test
```

### Project Structure

```
locate/
├── Locate/
│   ├── Sources/
│   │   ├── Locate/           # Main SwiftUI app
│   │   ├── LocateCore/       # Core engine (database, search, indexing)
│   │   ├── LocateViewModel/  # View models and app state
│   │   └── LocateCLI/        # Command-line tool
│   ├── Tests/
│   ├── Package.swift
│   ├── Info.plist
│   └── Locate.entitlements
├── docs/                      # Documentation
├── scripts/                   # Build and release scripts
└── tasks.md                   # Development task tracking

```

## Building for Release

### Quick Release

```bash
./scripts/release.sh 1.0.0
```

This script handles:
1. Building the release binary
2. Code signing
3. Creating DMG
4. Notarization
5. Stapling the ticket

### Manual Steps

See [release.md](release.md) for detailed manual instructions.

## Testing

### Quick Tests

```bash
# Run unit tests
cd Locate
swift test

# Build and run
swift build
.build/debug/Locate
```

### Full QA Process

1. Follow [qa-checklist.md](qa-checklist.md) for comprehensive testing
2. Run [power-features-tests.md](power-features-tests.md) for regression testing
3. Perform [performance-tests.md](performance-tests.md) with large datasets

### Test Environments

Test on:
- macOS 12.0+ (minimum supported)
- Both Intel and Apple Silicon Macs
- Clean installations (no previous data)
- With Full Disk Access granted and denied

## Architecture Overview

### LocateCore

Core search and indexing engine:
- **DatabaseManager**: SQLite database with FTS5 full-text search
- **FileScanner**: Recursive directory enumeration with exclusions
- **Models**: `Root`, `FileRecord`, `SearchRequest`
- **SQLite**: Thin wrapper over system SQLite

### LocateViewModel

Application state and business logic:
- **SearchViewModel**: Main app state, search execution, indexing
- **AppSettings**: Persistent user settings (folders, exclusions, auto-reindex)
- **PermissionsHelper**: Full Disk Access detection and guidance

### Locate (UI)

SwiftUI interface:
- **ContentView**: Main container, handles onboarding vs main UI
- **SearchView**: Primary search interface
- **ResultsView**: File results table with actions
- **SettingsView**: Settings tabs for configuration
- **OnboardingView**: First-launch wizard
- **MenuBarSearchView**: Menu bar extra popover
- **HotkeyManager**: Global hotkey (⌥Space) registration

## Key Features Implementation

### Search Engine
- FTS5 virtual table for full-text search
- Regex support via NSRegularExpression post-filtering
- Case-sensitive/insensitive modes
- Multi-column indexes for fast filtering

### Indexing
- Streaming async enumeration for memory efficiency
- Batched inserts (500 rows per transaction) for speed
- Exclusion patterns for Library, .git, node_modules, etc.
- Multiple root directories support
- Automatic reindexing on configurable schedule

### UI/UX
- SwiftUI with Observation framework
- Global hotkey using Carbon/AppKit APIs
- Menu bar extra for quick access
- Onboarding wizard for first launch
- Full Disk Access guidance and detection

## Settings & Configuration

### User Settings (UserDefaults)
- `indexedFolders`: Array of paths to index
- `exclusionPatterns`: Array of patterns to exclude
- `autoReindex`: Boolean for automatic reindexing
- `reindexIntervalHours`: Hours between auto-reindex
- `hasCompletedOnboarding`: First-launch state

### Database Location
`~/Library/Application Support/Locate/locate.db`

### App Support Files
- Database: `locate.db`
- Database journal: `locate.db-journal`
- Database WAL: `locate.db-wal`, `locate.db-shm`

## Contributing

1. Check [tasks.md](../tasks.md) for pending work
2. Follow AGENTS.md for Swift/SwiftUI guidelines (if exists)
3. Write tests for new features
4. Update documentation
5. Run QA checklist before submitting PR

## Troubleshooting

### Common Issues

**Build Fails:**
- Ensure Xcode 15+ installed
- Run `swift build` from Locate directory
- Check Package.swift for correct platforms

**App Won't Launch:**
- Check Console.app for errors
- Verify code signing: `codesign -vvv Locate.app`
- Check entitlements: `codesign -d --entitlements - Locate.app`

**Search Not Working:**
- Verify index was built
- Check database exists: `ls ~/Library/Application\ Support/Locate/`
- Try rebuilding index
- Check permissions on indexed folders

**Hotkey Not Working:**
- Check Console for registration message
- Verify no conflicts with other apps
- Try restarting app
- Check Accessibility permissions

## Performance Targets

- **Indexing:** 10k files in < 30 seconds
- **Search:** Results in < 100ms
- **Memory:** < 50MB idle, < 200MB during indexing
- **Responsiveness:** No UI lag during any operation

## Version History

### 1.0.0 (Current)
- Full-text search with FTS5
- Advanced filters (type, size, date)
- Regex and case-sensitive search
- Global hotkey (⌥Space)
- Menu bar quick search
- Automatic reindexing
- First-launch onboarding
- Full Disk Access guidance
- Settings for indexed folders and exclusions

## License

Copyright © 2025. All rights reserved.

## Support

For issues and questions:
- Check documentation in this directory
- Review [qa-checklist.md](qa-checklist.md) for known issues
- See [release.md](release.md) for distribution troubleshooting
