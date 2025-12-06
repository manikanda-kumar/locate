# Locate for Mac - Architecture Plan

## Overview

Build a native macOS file search application inspired by locate32's Windows approach: **database-driven fast file search** using indexed file metadata.

## locate32 Architecture (Reference from Source Code)

Based on analysis of the Windows source code from SourceForge:

### Source Code Structure
```
Locate/
├── Locate32/          # Main GUI application
│   ├── LocateDlg.cpp  # Main search dialog (tabbed interface)
│   ├── LocateDlg_Tabs.cpp    # Tab management (Name, Size/Date, Advanced)
│   ├── LocateDlg_ResultsList.cpp  # Results list view
│   ├── LocateDlg_Menu.cpp    # Context menus & file operations
│   ├── SettingsDlg.cpp       # Settings/preferences dialog
│   ├── TrayIconWnd.cpp       # System tray icon
│   ├── ResultsDialogs.cpp    # Result detail dialogs
│   └── SmallDialogs.cpp      # Presets, delete confirmation, etc.
├── LocateDB/          # Database library
│   ├── Database.cpp          # Core DB read/write
│   ├── DatabaseUpdater.cpp   # Index updating logic
│   ├── DatabaseInfo.cpp      # DB metadata
│   └── DBReference.txt       # DB format specification
├── updatedb/          # CLI database update tool
└── shelldll/          # Shell extension (context menu)
```

### Database Format (from DBReference.txt)
- **Header**: Magic "LOCATEDB" + version + charset (ANSI/Unicode/OEM)
- **Metadata**: Creator, description, creation time, file/dir counts
- **Root directories**: Drive type, path, volume name, serial, filesystem
- **Directory entries**: Attributes, name, timestamps, nested files/dirs
- **File entries**: Attributes, name, extension index, size (lo+hi), timestamps
- **Hierarchical structure**: Files stored nested within directories (tree traversal)

### UI Architecture (3 Tabs)
1. **Name Tab** (`CNameDlg`)
   - File name input with wildcards (*, ?)
   - "Look in" dropdown: Everywhere, Documents, Desktop, Custom paths
   - File type filter (extensions)

2. **Size & Date Tab** (`CSizeDateDlg`)
   - File size: min/max range with units (KB, MB, GB)
   - Date filters: Modified, Created, Accessed
   - Date range: Between dates, Within last N days/weeks/months

3. **Advanced Tab** (`CAdvancedDlg`)
   - Regex search toggle
   - Case sensitivity
   - Include/exclude patterns
   - Search in specific databases
   - "Replace characters" for special handling

### Key UI Features from Source
- **System Tray**: Quick access icon with popup menu
- **Presets**: Save/load search configurations
- **Context Menu**: Full shell integration (Open, Copy, Delete, Properties)
- **Results List**: Sortable columns (Name, Path, Size, Modified, Type)
- **Keyboard Shortcuts**: Customizable hotkeys
- **Two Modes**: Large (with tabs) and Small (compact search only)
- **Tooltips**: On result items for full path display

---

## UX Requirements (Derived from locate32)

### Core UX Principles
1. **Speed First**: Results appear instantly as you type (database-backed)
2. **Lightweight**: Minimal memory footprint, no background indexing daemon
3. **Manual Indexing**: User-triggered "Update Database" (no real-time file watching)
4. **Portable**: Self-contained, no installation required (optional for Mac)

### Required Features (v1)
| Feature | locate32 Equivalent | Mac Implementation |
|---------|--------------------|--------------------|
| Search by name | Wildcards (*, ?) | FTS5 + glob patterns |
| Filter by extension | Type dropdown | Extension chips/tags |
| Filter by size | Min/max range | Slider or presets |
| Filter by date | Date pickers | Date range picker |
| Results list | ListView with columns | SwiftUI List/Table |
| Open file | Double-click → Open | NSWorkspace.open |
| Reveal in Finder | Context menu | NSWorkspace.selectFile |
| Copy path | Context menu | Pasteboard |
| Quick access | System tray | Menu bar popover |
| Presets | Save/load configs | UserDefaults + JSON |

### UX Flow
```
┌─────────────────────────────────────────────────────────────┐
│  First Launch                                               │
│  ├── Welcome screen: "No database yet"                      │
│  ├── Select folders to index (Home, specific paths)         │
│  ├── Configure exclusions (Library, node_modules, etc.)     │
│  └── "Build Index" button → Progress dialog                 │
├─────────────────────────────────────────────────────────────┤
│  Normal Usage                                               │
│  ├── Global hotkey (⌥Space) opens main window or popover    │
│  ├── Type to search → Instant results                       │
│  ├── Click filters to refine (extension, size, date)        │
│  ├── Double-click → Open file                               │
│  ├── Right-click → Context menu (Reveal, Copy Path, etc.)   │
│  └── ⌘Enter → Reveal in Finder                              │
├─────────────────────────────────────────────────────────────┤
│  Index Management                                           │
│  ├── Menu: "Update Index" (manual trigger)                  │
│  ├── Status bar: "Last indexed: 2 hours ago"                │
│  ├── Settings: Add/remove indexed folders                   │
│  └── Settings: Edit exclusion patterns                      │
└─────────────────────────────────────────────────────────────┘
```

### Keyboard Shortcuts
| Action | Shortcut |
|--------|----------|
| Open/Focus | ⌥Space (global) |
| Search | ⌘F |
| Open selected | ↩ or ⌘O |
| Reveal in Finder | ⌘⇧R |
| Copy path | ⌘⇧C |
| Preferences | ⌘, |
| Update index | ⌘R |
| Close window | ⌘W / Esc |

---

## Mac App Architecture

### Core Components

```
┌─────────────────────────────────────────────────────┐
│                   Locate.app                        │
├─────────────────────────────────────────────────────┤
│  UI Layer (SwiftUI)                                 │
│  ├── SearchView - Main search interface             │
│  ├── ResultsView - File list with previews          │
│  ├── SettingsView - Database & preferences          │
│  └── MenuBarExtra - Quick access popover            │
├─────────────────────────────────────────────────────┤
│  Core Layer (Swift)                                 │
│  ├── DatabaseManager - SQLite/FTS5 indexing         │
│  ├── SearchEngine - Query parsing & execution       │
│  ├── FileScanner - Directory traversal              │
│  └── Scheduler - Background index updates           │
├─────────────────────────────────────────────────────┤
│  Storage Layer                                      │
│  └── SQLite with FTS5 (Full-Text Search)            │
└─────────────────────────────────────────────────────┘
```

### Technology Choices

| Component | Technology | Rationale |
|-----------|------------|-----------|
| UI Framework | SwiftUI | Native macOS, modern, declarative |
| Database | SQLite + FTS5 | Fast full-text search, embedded, no external deps |
| File System | FileManager + FSEvents | Native APIs, efficient change detection |
| Concurrency | Swift Concurrency (async/await) | Modern, safe parallelism |
| Distribution | App Sandbox + Hardened Runtime | App Store ready |

---

## Implementation Phases

### Phase 1: Core Engine (Week 1-2)
- [ ] SQLite database schema for file metadata
- [ ] FTS5 virtual table for fast name search
- [ ] FileScanner: recursive directory traversal
- [ ] Basic search query execution
- [ ] CLI tool for testing (`locate` command)

### Phase 2: Basic UI (Week 2-3)
- [ ] Main window with search bar
- [ ] Results list with file icons
- [ ] Double-click to open / reveal in Finder
- [ ] Basic filtering (file type, size, date)

### Phase 3: Advanced Features (Week 3-4)
- [ ] Regex search support
- [ ] Multiple database profiles
- [ ] FSEvents for real-time index updates
- [ ] Menu bar quick-search popover
- [ ] Keyboard shortcuts (⌘+Space alternative)

### Phase 4: Polish & Distribution (Week 4-5)
- [ ] Settings/Preferences window
- [ ] Scheduled index updates (LaunchAgent)
- [ ] App Sandbox permissions
- [ ] Notarization & distribution

---

## Database Schema

Inspired by locate32's hierarchical format but using SQLite for simplicity:

```sql
-- Database metadata (like locate32 header)
CREATE TABLE db_info (
    key TEXT PRIMARY KEY,
    value TEXT
);
-- Keys: version, created_at, file_count, dir_count, indexed_roots

-- Indexed root directories (like locate32 root entries)
CREATE TABLE roots (
    id INTEGER PRIMARY KEY,
    path TEXT NOT NULL UNIQUE,
    volume_name TEXT,
    file_count INTEGER DEFAULT 0,
    dir_count INTEGER DEFAULT 0,
    last_indexed INTEGER
);

-- Main file index (combining locate32's file + directory entries)
CREATE TABLE files (
    id INTEGER PRIMARY KEY,
    root_id INTEGER NOT NULL REFERENCES roots(id),
    parent_id INTEGER REFERENCES files(id),  -- NULL for root entries
    name TEXT NOT NULL,
    name_lower TEXT NOT NULL,  -- For case-insensitive search
    path TEXT NOT NULL,        -- Full path for quick access
    is_directory INTEGER NOT NULL DEFAULT 0,
    size INTEGER,              -- NULL for directories
    extension TEXT,            -- Extracted from name
    modified_at INTEGER,       -- Unix timestamp
    created_at INTEGER,
    accessed_at INTEGER,
    attributes INTEGER DEFAULT 0  -- Hidden, readonly, etc.
);

-- Indexes for fast filtering
CREATE INDEX idx_files_parent ON files(parent_id);
CREATE INDEX idx_files_root ON files(root_id);
CREATE INDEX idx_files_extension ON files(extension);
CREATE INDEX idx_files_modified ON files(modified_at);
CREATE INDEX idx_files_size ON files(size);
CREATE INDEX idx_files_name_lower ON files(name_lower);

-- FTS5 for instant name search
CREATE VIRTUAL TABLE files_fts USING fts5(
    name,
    content='files',
    content_rowid='id',
    tokenize='unicode61'
);

-- Triggers to sync FTS
CREATE TRIGGER files_ai AFTER INSERT ON files BEGIN
    INSERT INTO files_fts(rowid, name) VALUES (new.id, new.name);
END;

CREATE TRIGGER files_ad AFTER DELETE ON files BEGIN
    DELETE FROM files_fts WHERE rowid = old.id;
END;

CREATE TRIGGER files_au AFTER UPDATE OF name ON files BEGIN
    UPDATE files_fts SET name = new.name WHERE rowid = old.id;
END;
```

### Database Size Estimates
| Files Indexed | DB Size (approx) |
|---------------|------------------|
| 100,000 | ~15 MB |
| 500,000 | ~75 MB |
| 1,000,000 | ~150 MB |

---

## UI Design (locate32-inspired)

### Main Window
```
┌─────────────────────────────────────────────────┐
│ 🔍 [Search: ________________] [⚙️]              │
├─────────────────────────────────────────────────┤
│ Filters: [All ▾] [Any Size ▾] [Any Date ▾]     │
├─────────────────────────────────────────────────┤
│ Results (1,234 files)                           │
│ ┌─────────────────────────────────────────────┐ │
│ │ 📄 project.swift     ~/Dev/App/...    2.1KB│ │
│ │ 📁 Projects          ~/Documents/     --   │ │
│ │ 📄 project.json      ~/Config/...     1.2KB│ │
│ │ ...                                         │ │
│ └─────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────┤
│ Status: Index updated 5 minutes ago            │
└─────────────────────────────────────────────────┘
```

### Menu Bar Popover (Quick Access)
```
┌──────────────────────────┐
│ 🔍 [Quick search...]     │
├──────────────────────────┤
│ Recent:                  │
│  📄 notes.md             │
│  📁 Downloads            │
├──────────────────────────┤
│ ⚡ Update Index          │
│ ⚙️ Open Locate...        │
└──────────────────────────┘
```

---

## Key Differences from locate32

| Aspect | locate32 (Windows) | Locate (Mac) |
|--------|-------------------|--------------|
| UI Framework | Win32 Dialog | SwiftUI |
| Database | Custom binary format | SQLite + FTS5 |
| Regex Engine | PCRE | NSRegularExpression |
| File Monitoring | Manual refresh | FSEvents (real-time) |
| Quick Access | System tray | Menu bar + Spotlight-like |
| Distribution | Standalone EXE | App Store / DMG |

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Full disk access permission | Clear onboarding, graceful degradation |
| Large index sizes | Compress paths, exclude system dirs |
| Index update performance | Background threading, incremental updates |
| Spotlight competition | Focus on speed, simplicity, regex support |

---

## Success Criteria

1. **Speed**: Search results appear in <100ms for 1M+ files
2. **Index size**: <100MB for typical Mac (500K files)
3. **Memory**: <50MB resident during idle
4. **UX**: Faster than Spotlight for filename-based searches

---

## Oracle Review - Key Recommendations

### ✅ Architecture Validated
- SwiftUI + SQLite/FTS5 + FSEvents stack is solid and idiomatic for macOS

### ⚠️ Critical Adjustments

1. **Distribution: Start with DMG, not App Store**
   - App Sandbox cannot index full disk without user-granted Full Disk Access
   - v1: Non-sandboxed DMG + notarization
   - v2+: Consider App Store with limited "home folder only" mode

2. **Defer FSEvents to Phase 4+**
   - FSEvents is complex (coalescing, overflow handling, symlinks)
   - v1: Manual "Rebuild Index" + optional "rescan every X hours while open"
   - Add live monitoring later as optimization

3. **De-scope Phase 3**
   - Keep: Regex, menu bar, global hotkey
   - Defer: Multiple DB profiles, FSEvents

4. **Database Schema Improvements**
   - Use `parent_id INTEGER` instead of `parent_path TEXT` for compactness
   - Add missing UPDATE/DELETE triggers for FTS sync
   - Normalize `name` to lowercase for case-insensitive search
   - Add indexes on `extension`, `modified_at`, `parent_id`

5. **Use Actor for DB Access**
   - Wrap SQLite in `actor DatabaseManager` for thread safety
   - Batch inserts in transactions (commit every N files)

### 🎯 Competitive Positioning vs Spotlight/Alfred
- **Your niche**: Fast, deterministic filename-first search with regex/glob
- Spotlight: Content + metadata, opaque ranking, perceived latency
- Alfred/Raycast: Workflow-focused, limited filename control
- **Differentiate on**: Speed, transparency, power-user query semantics

---

## Revised Phasing

### Phase 1: Core Engine (Week 1-2) ✅ Keep as-is
- SQLite schema with FTS5
- FileScanner (single root, basic exclusions)
- CLI tool for testing
- Actor-based DatabaseManager

### Phase 2: Basic UI (Week 2-3) ✅ Keep as-is
- Main window, search bar, results
- Open/Reveal in Finder
- Simple filters (type, size preset, date preset)

### Phase 3: Power Features (Week 3-4) 🔄 Adjusted
- [x] Regex search mode
- [x] Menu bar popover
- [x] Global keyboard shortcut
- [ ] ~~Multiple DB profiles~~ → v2
- [ ] ~~FSEvents~~ → Phase 4

### Phase 4: Polish (Week 4-5)
- Settings window (roots, exclusions)
- Manual + timed re-indexing
- DMG packaging + notarization
- Instructions for Full Disk Access

### Phase 5: Advanced (Future)
- FSEvents incremental updates
- Multiple DB profiles
- App Store sandboxed version

---

## Next Steps

1. Set up Xcode project with SwiftUI (macOS 12+ target)
2. Create `LocateCore` Swift module (shared by GUI + CLI)
3. Implement `actor DatabaseManager` with SQLite/FTS5
4. Build FileScanner with exclusion patterns
5. Create basic search UI
6. Package as DMG with notarization

---

## References

- [locate32 Source](https://github.com/Locate32/Locate32) - Windows implementation
- [SQLite FTS5](https://www.sqlite.org/fts5.html) - Full-text search extension
- [FSEvents Programming Guide](https://developer.apple.com/library/archive/documentation/Darwin/Conceptual/FSEvents_ProgGuide/) - File system monitoring
