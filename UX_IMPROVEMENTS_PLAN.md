# Locate UX Improvements Plan

> Inspired by [Locate32](https://www.makeuseof.com/tag/search-for-files-lightning-fast-with-locate32/) for Windows - bringing advanced file search UX to macOS

## Overview

This plan outlines UX improvements to make Locate more powerful and flexible, focusing on:
1. Enhanced search filters (extensions, size, folder scoping)
2. Customizable results table with more columns
3. Hidden files support
4. Better visual design and user experience

---

## Phase 5A: Enhanced Search Filters

### P5A-T01 — Add extension filter input field
**Priority:** HIGH

**Description:**
Add a dedicated extension filter field in the search bar area that accepts comma-separated extensions (e.g., `.swift,.md,.txt` or `swift,md,txt`).

**Current state:**
- File type filter exists but uses presets (Documents, Images, Code, etc.)
- No way to specify custom extensions directly

**Proposed UI:**
```
┌─────────────────────────────────────────────────────────┐
│ Search: [____________________] 🔍                       │
│ Extension: [.swift,.md]  Folder: [Browse...] [Clear]   │
│ Size: [Any ▼]  Date: [Any ▼]  ☐ Regex  ☐ Case        │
└─────────────────────────────────────────────────────────┘
```

**Acceptance criteria:**
- [ ] Extension text field accepts comma-separated values
- [ ] Both `.ext` and `ext` formats work
- [ ] Filter combines with other filters (folder, size, date)
- [ ] Clear/reset button for extension filter
- [ ] Validation shows error for invalid extensions

**Effort:** M
**Dependencies:** P2-T07 (existing filters)

---

### P5A-T02 — Add folder scope filter
**Priority:** HIGH

**Description:**
Allow users to scope search to a specific folder/directory within the indexed locations.

**Current state:**
- Searches across all indexed folders
- No way to limit to specific subdirectory

**Proposed UI:**
- "Folder" field with Browse button to select directory
- Shows relative path if within indexed folders
- Clear button to remove folder scope
- Optional: Dropdown of recent folder scopes

**Acceptance criteria:**
- [ ] Browse button opens `NSOpenPanel` for folder selection
- [ ] Selected folder path displayed in UI
- [ ] Search results limited to files within selected folder (recursive)
- [ ] Works with non-indexed folders (searches database for paths matching)
- [ ] Clear button removes folder scope

**Effort:** M
**Dependencies:** None

---

### P5A-T03 — Add minimum/maximum file size inputs
**Priority:** MEDIUM

**Description:**
Replace size presets with custom min/max size inputs with unit selector.

**Current state:**
- Size filter uses presets: Any, >1MB, >10MB, >100MB
- No way to specify exact ranges

**Proposed UI:**
```
Size: Min [___] [KB ▼]  Max [___] [MB ▼]
```

**Units:** Bytes, KB, MB, GB

**Acceptance criteria:**
- [ ] Min and max size input fields with number validation
- [ ] Unit dropdown for each field (Bytes, KB, MB, GB)
- [ ] Leave blank for no limit on that side
- [ ] Presets menu for quick access (>1MB, >10MB, etc.)
- [ ] Validation: min ≤ max

**Effort:** M
**Dependencies:** P2-T07

---

### P5A-T04 — Add custom date range picker
**Priority:** MEDIUM

**Description:**
Replace date presets with custom date range picker.

**Current state:**
- Date filter uses presets: Any, Last 24h, Last 7 days, Last 30 days
- No way to specify exact date ranges

**Proposed UI:**
```
Modified: From [Date picker] To [Date picker]
```

**Acceptance criteria:**
- [ ] Two date pickers (From/To)
- [ ] Leave blank for no limit on that side
- [ ] Presets menu for quick access (Last 24h, Last 7 days, etc.)
- [ ] Validation: from ≤ to
- [ ] Clear button for each date field

**Effort:** M
**Dependencies:** P2-T07

---

## Phase 5B: Customizable Results Table

### P5B-T01 — Expand results columns
**Priority:** HIGH

**Description:**
Add more informative columns to results table, following Locate32's approach.

**Current columns:**
- Name (with icon)
- Path
- Size
- Modified date

**New columns to add:**
- **Created Date** - When file was created
- **File Type** - Extension or UTI description (e.g., "Swift Source File")
- **Folder** - Parent directory name only
- **Full Path** - Complete absolute path (vs current path which may be truncated)
- **Permissions** - Unix permissions (e.g., `rwxr-xr-x`)
- **Owner** - File owner username
- **Hidden** - Whether file is hidden (• indicator)

**Acceptance criteria:**
- [ ] All new columns defined in results table
- [ ] Data fetched efficiently (cached per result)
- [ ] Columns sortable (click header to sort)
- [ ] Performance acceptable with 1000+ results

**Effort:** L
**Dependencies:** P2-T04

---

### P5B-T02 — Implement column visibility toggle
**Priority:** HIGH

**Description:**
Allow users to show/hide columns and save preferences.

**Proposed UI:**
- Right-click on table header → "Columns..." menu
- Shows checklist of all available columns
- Check/uncheck to show/hide
- "Reset to Default" option

**Alternative UI:**
- Gear icon (⚙️) in table header bar
- Opens popover with column checkboxes

**Acceptance criteria:**
- [ ] UI to toggle column visibility
- [ ] Column visibility preferences persisted in `AppSettings`
- [ ] Default visible columns: Name, Path, Size, Modified, File Type
- [ ] Hidden columns: Created, Folder, Permissions, Owner, Hidden
- [ ] Changes apply immediately to results table

**Effort:** M
**Dependencies:** P5B-T01

---

### P5B-T03 — Implement column reordering
**Priority:** MEDIUM

**Description:**
Allow users to drag column headers to reorder them.

**Acceptance criteria:**
- [ ] Drag column headers to reorder
- [ ] Visual feedback during drag (ghost image)
- [ ] Column order persisted in `AppSettings`
- [ ] Name column always stays first (locked)

**Effort:** M
**Dependencies:** P5B-T02

---

### P5B-T04 — Implement column width adjustment
**Priority:** LOW

**Description:**
Allow users to resize columns by dragging column dividers.

**Acceptance criteria:**
- [ ] Drag column divider to resize
- [ ] Double-click divider to auto-fit content
- [ ] Column widths persisted in `AppSettings`
- [ ] Minimum column width enforced (50pt)

**Effort:** M
**Dependencies:** P5B-T02

---

## Phase 5C: Hidden Files Support

### P5C-T01 — Add hidden files toggle to Settings
**Priority:** HIGH

**Description:**
Add setting to control whether hidden files are indexed and shown in results.

**Location:** Settings → Indexing tab

**Proposed UI:**
```
☐ Index hidden files and folders
  (Files/folders starting with . or marked as hidden)
```

**Acceptance criteria:**
- [ ] Toggle added to Settings → Indexing tab
- [ ] Setting persisted in `AppSettings.indexHiddenFiles: Bool`
- [ ] Default: `false` (don't index hidden files)
- [ ] Changing setting requires index rebuild (show warning)

**Effort:** S
**Dependencies:** P4-T01 (Settings window)

---

### P5C-T02 — Update FileScanner to respect hidden files setting
**Priority:** HIGH

**Description:**
Modify `FileScanner` to check hidden files setting and skip/include accordingly.

**Implementation:**
```swift
// In FileScanner.swift
private func shouldSkipFile(_ url: URL) -> Bool {
    let fileName = url.lastPathComponent

    // Check exclusion patterns
    if isExcluded(url) { return true }

    // Check hidden files if setting is disabled
    if !AppSettings.shared.indexHiddenFiles {
        // Skip if filename starts with .
        if fileName.hasPrefix(".") { return true }

        // Skip if file has hidden flag
        if let resourceValues = try? url.resourceValues(forKeys: [.isHiddenKey]),
           resourceValues.isHidden == true {
            return true
        }
    }

    return false
}
```

**Acceptance criteria:**
- [ ] `FileScanner` checks `AppSettings.shared.indexHiddenFiles`
- [ ] When `false`, skips files starting with `.`
- [ ] When `false`, skips files with `isHidden` flag set
- [ ] When `true`, indexes all files (respecting other exclusions)
- [ ] Unit tests for hidden file filtering

**Effort:** M
**Dependencies:** P5C-T01, P1-T06 (FileScanner)

---

### P5C-T03 — Add hidden file indicator in results
**Priority:** MEDIUM

**Description:**
Show visual indicator for hidden files in results table.

**Proposed UI:**
- Add "Hidden" column (optional, hidden by default)
- Shows bullet (•) or eye icon (👁) for hidden files
- Alternatively: dim/grey out hidden file names slightly

**Acceptance criteria:**
- [ ] "Hidden" column available in column picker
- [ ] Shows indicator for files starting with `.` or having hidden flag
- [ ] Hidden files have subtle visual treatment (opacity 0.7?)
- [ ] Tooltip explains what makes file "hidden"

**Effort:** S
**Dependencies:** P5B-T01 (columns), P5C-T02

---

### P5C-T04 — Add "Show hidden files" quick toggle
**Priority:** LOW

**Description:**
Add toggle in search UI to temporarily show/hide hidden files in results (filter, not re-index).

**Proposed UI:**
```
☐ Show hidden files  (next to Regex/Case toggles)
```

**Note:** This filters results display only, doesn't trigger re-index.

**Acceptance criteria:**
- [ ] Toggle in search bar area
- [ ] When unchecked, filters out hidden files from results
- [ ] When checked, shows all results including hidden
- [ ] Works independently of indexing setting
- [ ] State preserved for session only (not persisted)

**Effort:** M
**Dependencies:** P5C-T03

---

## Phase 5D: Advanced Features

### P5D-T01 — Add "Find as you type" delay setting
**Priority:** LOW

**Description:**
Allow users to configure search delay (currently hardcoded debounce).

**Location:** Settings → Search tab (new)

**Proposed UI:**
```
Search delay: [150] ms (100-1000)
☐ Search while typing
```

**Acceptance criteria:**
- [ ] Slider or text field for delay (100-1000ms)
- [ ] Toggle to disable auto-search (require Enter key)
- [ ] Default: 200ms with auto-search enabled
- [ ] Setting persisted in `AppSettings`

**Effort:** S
**Dependencies:** P2-T02

---

### P5D-T02 — Add result limit setting
**Priority:** LOW

**Description:**
Allow users to configure max results displayed (currently 200).

**Proposed UI:**
```
Results limit: [200] (50-10000)
```

**Acceptance criteria:**
- [ ] Setting in Settings → Search
- [ ] Range: 50-10000
- [ ] Default: 200
- [ ] Applied to search queries
- [ ] Show "Showing X of Y results" in status bar

**Effort:** S
**Dependencies:** P2-T08

---

### P5D-T03 — Add file content search (future)
**Priority:** LOW (Phase 6)

**Description:**
Search within file contents, not just names. Would require indexing file contents into FTS5.

**Note:** This is a major feature for future consideration.

---

## Phase 5E: Visual Polish

### P5E-T01 — Improve filter layout and grouping
**Priority:** MEDIUM

**Description:**
Better organize filters into logical groups with clear visual hierarchy.

**Current layout:**
```
Search: [___________]
Type: [▼] Size: [▼] Date: [▼] ☐ Regex ☐ Case
```

**Proposed layout:**
```
┌─ Search ─────────────────────────────────────────┐
│ Query: [________________] ☐ Regex ☐ Case       │
├─ Filters ────────────────────────────────────────┤
│ Extension: [.swift,.md]  Folder: [Browse...]    │
│ Size: Min[__][KB▼] Max[__][MB▼]  Clear         │
│ Date: From[📅] To[📅]  [Presets ▼]             │
└──────────────────────────────────────────────────┘
```

**Acceptance criteria:**
- [ ] Filters grouped with section headers
- [ ] Clear visual separation between search and filters
- [ ] Collapsible filter sections (optional)
- [ ] "Clear all filters" button

**Effort:** M
**Dependencies:** P5A tasks

---

### P5E-T02 — Add results count and selection info
**Priority:** LOW

**Description:**
Show more detailed information in status bar.

**Current:**
```
Last indexed 2 hours ago • 45,231 files
```

**Proposed:**
```
Last indexed 2 hours ago • 45,231 total files • Showing 147 results • 3 selected
```

**Acceptance criteria:**
- [ ] Shows result count from current search
- [ ] Shows selection count when items selected
- [ ] Updates in real-time as selection changes

**Effort:** S
**Dependencies:** P2-T08

---

### P5E-T03 — Add keyboard shortcuts reference
**Priority:** LOW

**Description:**
Add "Keyboard Shortcuts" window (⌘?) showing all shortcuts.

**Content:**
- Search: ⌘F
- New search: ⌘N
- Rebuild index: ⌘R
- Open file: Return or ⌘O
- Reveal in Finder: ⌘⇧R
- Copy path: ⌘⇧C
- Show main window: ⌥Space
- Settings: ⌘,
- Close window: ⌘W

**Acceptance criteria:**
- [ ] Menu item: Help → Keyboard Shortcuts (⌘?)
- [ ] Shows modal window with categorized shortcuts
- [ ] Printable/exportable list

**Effort:** S
**Dependencies:** None

---

## Implementation Priority

### Phase 5A (Week 1)
**Critical UX improvements:**
1. P5A-T01: Extension filter (HIGH) - M effort
2. P5A-T02: Folder scope filter (HIGH) - M effort
3. P5C-T01: Hidden files setting (HIGH) - S effort
4. P5C-T02: FileScanner hidden files support (HIGH) - M effort

**Week 1 Total:** ~8-10 hours

### Phase 5B (Week 2)
**Results table improvements:**
1. P5B-T01: Expand columns (HIGH) - L effort
2. P5B-T02: Column visibility toggle (HIGH) - M effort
3. P5C-T03: Hidden file indicator (MEDIUM) - S effort

**Week 2 Total:** ~8-10 hours

### Phase 5C (Week 3)
**Additional filters and polish:**
1. P5A-T03: Min/max file size (MEDIUM) - M effort
2. P5A-T04: Date range picker (MEDIUM) - M effort
3. P5E-T01: Improve filter layout (MEDIUM) - M effort

**Week 3 Total:** ~6-8 hours

### Phase 5D (Week 4 - Optional)
**Advanced features:**
1. P5B-T03: Column reordering (MEDIUM) - M effort
2. P5B-T04: Column width adjustment (LOW) - M effort
3. P5C-T04: Show hidden toggle (LOW) - M effort
4. P5D-T01: Search delay setting (LOW) - S effort
5. P5D-T02: Result limit setting (LOW) - S effort
6. P5E-T02: Results count info (LOW) - S effort
7. P5E-T03: Keyboard shortcuts window (LOW) - S effort

**Week 4 Total:** ~8-10 hours

---

## Database Schema Updates

### New columns needed in `files` table:

```sql
-- Add to existing schema (migration v2)
ALTER TABLE files ADD COLUMN created_at INTEGER;  -- Unix timestamp
ALTER TABLE files ADD COLUMN file_type TEXT;       -- UTI or extension description
ALTER TABLE files ADD COLUMN permissions TEXT;     -- Unix permissions string
ALTER TABLE files ADD COLUMN owner TEXT;           -- Owner username
ALTER TABLE files ADD COLUMN is_hidden INTEGER DEFAULT 0;  -- Boolean flag

-- Index for hidden files filter
CREATE INDEX IF NOT EXISTS idx_files_is_hidden ON files(is_hidden);
```

### New AppSettings properties:

```swift
// In AppSettings.swift
public var indexHiddenFiles: Bool = false
public var searchDelay: Int = 200  // milliseconds
public var resultsLimit: Int = 200
public var visibleColumns: [String] = ["name", "path", "size", "modified", "fileType"]
public var columnOrder: [String] = ["name", "path", "size", "modified", "fileType"]
public var columnWidths: [String: CGFloat] = [:]
```

---

## UI Mockups Needed

Before implementation, create mockups for:
1. Enhanced filter bar with all new controls
2. Results table with all columns visible
3. Column picker/configuration UI
4. Hidden files indicator in results
5. Settings → Indexing tab with hidden files toggle

---

## Testing Considerations

### Performance tests:
- [ ] Search with 10+ filters applied
- [ ] Results table with all columns visible (1000+ rows)
- [ ] Hidden file filtering with 100k+ indexed files
- [ ] Column reordering performance

### Edge cases:
- [ ] Empty extension filter
- [ ] Invalid extension format (handle gracefully)
- [ ] Folder scope pointing to unindexed location
- [ ] Min > Max in size/date filters
- [ ] All columns hidden (must keep Name visible)
- [ ] Very long file paths in table

### UX validation:
- [ ] Filter combinations work correctly (AND logic)
- [ ] Clear buttons reset correctly
- [ ] Validation errors are clear and helpful
- [ ] Column customization intuitive and discoverable

---

## Success Metrics

After implementation, Locate should:
1. ✅ Support all Locate32-style filtering (extensions, size range, date range, folder)
2. ✅ Provide 10+ customizable result columns
3. ✅ Handle hidden files correctly (index and display control)
4. ✅ Maintain sub-100ms search performance with all filters
5. ✅ Provide intuitive, discoverable UX for all features

---

## Notes

- Maintain backward compatibility with existing database
- Use migration system for schema changes
- All new features should have corresponding tests
- Update `docs/qa-checklist.md` with new test cases
- Update user documentation when complete

---

**Status:** DRAFT - Ready for review and implementation

**Next Step:** Review plan, create mockups, then begin Phase 5A implementation.
