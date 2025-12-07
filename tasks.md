# Locate for Mac - Implementation Tasks

Effort estimates:
- **S** ≈ 1 hour
- **M** ≈ 2–3 hours
- **L** ≈ 3–4 hours

> **Note:** Before starting any task, review `AGENTS.md` for Swift/SwiftUI coding guidelines and project structure rules.

---

## Getting Started

### GS-T01 — Initialize repo and Xcode workspace ✅

- **Description:**
  Create a new Git repository and Xcode project for a macOS SwiftUI app. Configure the main app target named `Locate` with a minimum macOS deployment target of 12.0 or later. Ensure the project uses Swift Concurrency (Enable "Strict Concurrency Checking" as appropriate). Add a `.gitignore` suitable for Xcode/Swift projects.
- **Acceptance criteria:**
  - [x] `Locate.xcodeproj` (or `.xcworkspace`) committed to Git. *(Using Swift Package with `Package.swift` - can generate xcodeproj via `swift package generate-xcodeproj`)*
  - [x] App target `Locate` created, builds and runs a default SwiftUI "Hello, World" window.
  - [x] `.gitignore` includes standard Xcode/macOS entries.
- **Effort:** S
- **Dependencies:** None
- **Status:** COMPLETE

---

### GS-T02 — Create shared core module (`LocateCore`) ✅

- **Description:**
  Add a Swift package or framework target named `LocateCore` to host shared non-UI code (DatabaseManager, FileScanner, SearchEngine, models). Configure the main app target and a future CLI target to depend on this module.
- **Acceptance criteria:**
  - [x] `LocateCore` target created (Swift package or framework).
  - [x] `Locate` app target depends on `LocateCore` and builds successfully.
  - [x] Placeholder `public struct CoreVersion { ... }` or similar exists and is referenced from the app to verify linkage.
- **Effort:** S
- **Dependencies:** GS-T01
- **Status:** COMPLETE

---

### GS-T03 — Configure signing, hardened runtime, and deployment settings ✅

- **Description:**
  Configure code signing for development builds using a valid Apple Developer certificate. Enable Hardened Runtime on the app target in preparation for notarization. Set the correct bundle identifier and minimum macOS version.
- **Acceptance criteria:**
  - [x] App builds and runs on a local machine without signing warnings.
  - [x] Hardened Runtime enabled in target settings. *(Entitlements file created: `Locate.entitlements`)*
  - [x] Bundle identifier finalized (`com.locate.app` in `Info.plist`).
- **Effort:** S
- **Dependencies:** GS-T01
- **Status:** COMPLETE

---

### GS-T04 — Add basic app scaffolding (SwiftUI entry point) ✅

- **Description:**
  Implement the `@main` SwiftUI app struct and a placeholder `ContentView` with a simple label. Ensure the app window opens correctly and uses SwiftUI lifecycle (no storyboard).
- **Acceptance criteria:**
  - [x] `LocateApp` (or similar) exists and uses `WindowGroup`.
  - [x] App launches to a simple window titled "Locate".
- **Effort:** S
- **Dependencies:** GS-T01
- **Status:** COMPLETE

---

### GS-T05 — Decide and configure SQLite access strategy ✅

- **Description:**
  Decide whether to use system SQLite via C APIs directly or a lightweight wrapper library (prefer direct system SQLite for v1 to avoid extra deps). Add any necessary bridging header or module imports. Verify FTS5 availability.
- **Acceptance criteria:**
  - [x] Chosen approach documented in comments or a short `docs/notes.md`.
  - [x] Project builds with SQLite headers available and importable into `LocateCore`.
  - [x] Simple "open in-memory DB and run SELECT 1" test runs in a unit test or temporary function.
- **Effort:** M
- **Dependencies:** GS-T02
- **Status:** COMPLETE

---

## Phase 1: Core Engine (Week 1–2)

### P1-T01 — Implement SQLite schema and migration logic

- **Description:**  
  In `LocateCore`, define SQL schema (tables, indexes, FTS5 virtual table, triggers) based on `plan.md`. Implement a migration helper that creates the schema when the DB file is missing or empty and stores schema version in `db_info`. Provide a `func migrateIfNeeded()` that runs inside a transaction.
- **Acceptance criteria:**
  - [ ] SQL strings for `db_info`, `roots`, `files`, `files_fts`, indexes, and triggers match the plan.
  - [ ] Calling `migrateIfNeeded()` on a new DB file creates all tables and indexes without errors.
  - [ ] Schema version stored in `db_info` and readable.
- **Effort:** M  
- **Dependencies:** GS-T02, GS-T05

---

### P1-T02 — Implement minimal SQLite wrapper utilities

- **Description:**  
  Implement a small Swift wrapper over C SQLite APIs in `LocateCore` (e.g., `DatabaseHandle`, `Statement`) to handle open/close, prepared statements, parameter binding, stepping, and error handling. Focus on read/write operations, not ORM features.
- **Acceptance criteria:**
  - [ ] Utility types or functions exist for opening DB, preparing statements, binding params, stepping results.
  - [ ] Unit test successfully inserts and selects a row in a temporary table.
- **Effort:** M  
- **Dependencies:** GS-T05

---

### P1-T03 — Implement `DatabaseManager` actor skeleton

- **Description:**  
  Create `actor DatabaseManager` in `LocateCore` responsible for:
  - Opening the database file at a given path.
  - Ensuring `migrateIfNeeded()` is called once.
  - Providing basic query execution methods that use the SQLite wrapper.
- **Acceptance criteria:**
  - [ ] `DatabaseManager` can be initialized with a file URL/path.
  - [ ] On first initialization, schema is created/migrated.
  - [ ] Simple test call can insert and select a row via `DatabaseManager`.
- **Effort:** M  
- **Dependencies:** P1-T01, P1-T02

---

### P1-T04 — Define core data models (`Root`, `FileRecord`)

- **Description:**  
  Define Swift structs in `LocateCore` to represent rows from `roots` and `files` tables, including fields like `id`, `rootID`, `path`, `name`, `isDirectory`, `size`, timestamps, and `extension`. Implement mapping from SQLite row to these structs.
- **Acceptance criteria:**
  - [ ] `Root` and `FileRecord` structs defined with appropriate field types.
  - [ ] Helper initializers or factories map a `Statement`/row to each struct.
  - [ ] Unit tests verify mapping for at least one synthetic row per struct.
- **Effort:** S  
- **Dependencies:** P1-T02

---

### P1-T05 — Add CRUD methods to `DatabaseManager` for roots

- **Description:**  
  Implement methods on `DatabaseManager` to:
  - Insert or upsert a root directory into `roots`.
  - Query all roots.
  - Update `file_count`, `dir_count`, and `last_indexed`.
- **Acceptance criteria:**
  - [ ] Methods like `addOrUpdateRoot(path:)`, `fetchRoots()`, `updateRootStats(id: ...)` exist.
  - [ ] Unit test: add a root, update stats, read back and verify.
- **Effort:** M  
- **Dependencies:** P1-T03, P1-T04

---

### P1-T06 — Implement `FileScanner` for recursive directory traversal

- **Description:**  
  Implement a `FileScanner` type in `LocateCore` that, given a root path and a set of exclusion rules (initially a hard-coded list like `Library`, `.git`, `node_modules`), recursively enumerates files and directories using `FileManager`. It should yield `FileRecord`-like data suitable for insertion.
- **Acceptance criteria:**
  - [ ] `FileScanner.scan(rootPath:)` returns a sequence/array of file/directory entries with name, path, size, timestamps, extension, and `isDirectory`.
  - [ ] Basic exclusions applied (e.g., skip `~/Library`, hidden system dirs).
  - [ ] Test run on a sample directory logs or returns correct entries without crashing.
- **Effort:** L  
- **Dependencies:** GS-T02

---

### P1-T07 — Implement batched insert pipeline for indexing

- **Description:**  
  Implement a function on `DatabaseManager` (or a separate `IndexingService`) that:
  - Takes a root path.
  - Uses `FileScanner` to enumerate entries.
  - Inserts root row into `roots`.
  - Deletes old `files` rows for that root.
  - Inserts new `files` rows in batches (e.g., 500–1000 per transaction).
  - Updates `file_count` and `dir_count`.
- **Acceptance criteria:**
  - [ ] Single public API like `func rebuildIndex(for rootPath: String, progress: (IndexProgress) -> Void)` exists.
  - [ ] Running this on a test directory creates corresponding `roots` and `files` rows.
  - [ ] Indexing runs in batches with transactions (verified by code / logs).
- **Effort:** L  
- **Dependencies:** P1-T03, P1-T05, P1-T06

---

### P1-T08 — Implement FTS5-backed name search query

- **Description:**  
  Add a search method to `DatabaseManager` that:
  - Accepts a search string and optional limit.
  - Uses `files_fts` virtual table to search by file name quickly.
  - Joins back to `files` table to obtain full metadata.
  - Supports basic wildcard behavior by converting user input into an FTS5 query.
- **Acceptance criteria:**
  - [ ] `searchByName(_ query: String, limit: Int) async throws -> [FileRecord]` implemented.
  - [ ] Query uses FTS5 (verified by SQL string).
  - [ ] Unit test: inserting a few known files and querying by partial name returns expected results.
- **Effort:** M  
- **Dependencies:** P1-T01, P1-T03, P1-T04

---

### P1-T09 — Implement basic filter-capable search API (extension, size, date)

- **Description:**  
  Extend the search method with a `SearchRequest` struct (name, optional extension(s), size range, modified date range) and update the SQL query to apply filters using indexes.
- **Acceptance criteria:**
  - [ ] `SearchRequest` struct defined; search API accepts it.
  - [ ] SQL query includes `WHERE` clauses for provided filters.
  - [ ] Unit tests cover filter by extension, size, and date.
- **Effort:** M  
- **Dependencies:** P1-T08

---

### P1-T10 — Implement CLI tool target (`locate`)

- **Description:**  
  Add a macOS CLI target (e.g., `LocateCLI`) that links against `LocateCore`. Implement subcommands:
  - `build-index <rootPath>` to trigger `rebuildIndex`.
  - `search <query>` with optional flags for extension, limit, etc.
- **Acceptance criteria:**
  - [ ] `locate` executable builds and runs from Xcode or command line.
  - [ ] `locate build-index ~/SomeDir` creates a DB and index without crashing.
  - [ ] `locate search foo` prints matching file paths.
- **Effort:** M  
- **Dependencies:** GS-T02, P1-T07, P1-T09

---

### P1-T11 — Add basic logging and error reporting in core

- **Description:**  
  Implement a lightweight logging utility in `LocateCore` (e.g., wrapper around `os_log`). Ensure `DatabaseManager`, `FileScanner`, and indexing pipeline use consistent error logging.
- **Acceptance criteria:**
  - [ ] Logging helper available and used in core components.
  - [ ] On index or search failure, an error with useful message is produced and logged.
- **Effort:** S  
- **Dependencies:** P1-T03, P1-T06, P1-T07

---

### P1-T12 — Core engine smoke tests and performance sanity check

- **Description:**  
  Create a test harness that:
  - Indexes a directory with at least a few thousand files.
  - Runs multiple searches.
  - Logs basic timings.
- **Acceptance criteria:**
  - [ ] Automated or semi-automated test that can be re-run easily.
  - [ ] For a sample directory (~10k files): Index completes, search completes under 100ms.
- **Effort:** M  
- **Dependencies:** P1-T07, P1-T09

---

## Phase 2: Basic UI (Week 2–3)

### P2-T01 — Implement main window layout (Search + Results)

- **Description:**  
  Create `SearchView` and `ResultsView` SwiftUI components. Layout: search bar on top, filter row, results table, status bar at bottom.
- **Acceptance criteria:**
  - [ ] App launches to a window with search field, filter controls row, results area, status bar.
- **Effort:** M  
- **Dependencies:** GS-T04

---

### P2-T02 — Implement `SearchViewModel` bridging UI to core

- **Description:**  
  Add an `ObservableObject` (e.g., `SearchViewModel`) that holds search text, filter state, and results. Integrate with `DatabaseManager` via async calls with debouncing.
- **Acceptance criteria:**
  - [ ] `SearchViewModel` exposes `@Published` properties for text and filters.
  - [ ] Search triggers on text changes with debounce (150–300ms).
  - [ ] Calls to `DatabaseManager` update `results` on main thread.
- **Effort:** M  
- **Dependencies:** P1-T09, P1-T03

---

### P2-T03 — Implement search bar behavior

- **Description:**  
  Wire the search text field to `SearchViewModel`. Typing triggers search, clearing clears results.
- **Acceptance criteria:**
  - [ ] Typing in search field causes search calls.
  - [ ] Clearing the search field clears results.
- **Effort:** S  
- **Dependencies:** P2-T02

---

### P2-T04 — Implement results table with file icons and metadata

- **Description:**  
  Implement `ResultsView` as a `Table` or `List` with columns: Name (with icon), Path, Size, Modified date. Use `NSWorkspace` for file icons.
- **Acceptance criteria:**
  - [ ] Results appear in a scrolling list/table with icon, name, path, size, date.
  - [ ] No obvious performance issues with a few thousand rows.
- **Effort:** L  
- **Dependencies:** P2-T02

---

### P2-T05 — Implement "Open file" (double-click / Return)

- **Description:**  
  Double-clicking or pressing Return/⌘O opens the selected file using `NSWorkspace.open`.
- **Acceptance criteria:**
  - [ ] Double-click on result opens the file or directory.
  - [ ] Return key with selection opens the file.
  - [ ] Errors handled gracefully with alert/toast.
- **Effort:** M  
- **Dependencies:** P2-T04

---

### P2-T06 — Implement "Reveal in Finder" and "Copy Path" actions

- **Description:**  
  Add context menu with "Reveal in Finder" and "Copy Path" using `NSWorkspace.selectFile` and `NSPasteboard`.
- **Acceptance criteria:**
  - [ ] Right-click shows context menu with both actions.
  - [ ] "Reveal in Finder" opens Finder with item selected.
  - [ ] "Copy Path" places absolute path on clipboard.
- **Effort:** M  
- **Dependencies:** P2-T04

---

### P2-T07 — Implement basic filters UI (file type, size preset, date preset)

- **Description:**  
  Implement filter controls:
  - File type: dropdown (All, Documents, Images, Code, Custom).
  - Size: presets (Any, >1MB, >10MB, >100MB).
  - Date: presets (Any, Last 24h, Last 7 days, Last 30 days).
- **Acceptance criteria:**
  - [ ] Changing any filter updates results via `SearchViewModel`.
  - [ ] At least one preset for each category works correctly.
- **Effort:** L  
- **Dependencies:** P1-T09, P2-T02, P2-T04

---

### P2-T08 — Display index status (last indexed, total files)

- **Description:**  
  Display in status bar: "Index updated X minutes ago" and file count from `db_info`/`roots`.
- **Acceptance criteria:**
  - [ ] Status bar shows "Last indexed …" and file count after indexing.
  - [ ] If no index exists, shows "No index yet" or similar.
- **Effort:** S  
- **Dependencies:** P1-T07, P2-T02, P2-T01

---

### P2-T09 — Implement "Update Index" command in UI

- **Description:**  
  Add menu item and/or button to trigger indexing for configured root(s).
- **Acceptance criteria:**
  - [ ] "Update Index" command exists in menu bar and/or UI button.
  - [ ] Triggering runs `rebuildIndex` asynchronously and disables button while running.
  - [ ] Status bar updates after completion.
- **Effort:** M  
- **Dependencies:** P1-T07, P2-T02

---

### P2-T10 — Implement basic keyboard shortcuts (local to app)

- **Description:**  
  Implement shortcuts: ⌘F (focus search), ⌘R (update index), ⌘W/Esc (close window).
- **Acceptance criteria:**
  - [ ] All shortcuts work when app is focused.
  - [ ] Menu items show correct key equivalents.
- **Effort:** M  
- **Dependencies:** P2-T01, P2-T09

---

### P2-T11 — Handle "no index" and error states in UI

- **Description:**  
  Implement states for: first launch (no database), indexing in progress, errors.
- **Acceptance criteria:**
  - [ ] Clean install shows "No database yet" messaging.
  - [ ] During indexing, spinner or banner is shown.
  - [ ] Simulated error shows error message instead of crashing.
- **Effort:** M  
- **Dependencies:** P1-T07, P2-T02, P2-T01

---

## Phase 3: Power Features (Week 3–4)

### P3-T01 — Extend search engine with regex mode

- **Description:**  
  Extend `SearchRequest` with `useRegex` flag. Implement regex search by filtering candidates with `NSRegularExpression`. Handle invalid patterns gracefully.
- **Acceptance criteria:**
  - [ ] Search API accepts `useRegex`.
  - [ ] Valid regex patterns filter results correctly.
  - [ ] Invalid regex returns error, doesn't crash.
- **Effort:** L  
- **Dependencies:** P1-T09

---

### P3-T02 — Add regex toggle and validation feedback in UI

- **Description:**  
  Add toggle to enable "Regex" mode. Display inline error for invalid regex.
- **Acceptance criteria:**
  - [ ] Regex toggle visible and changes `SearchViewModel` state.
  - [ ] Invalid regex shows clear error text.
  - [ ] Turning regex off returns to normal FTS search.
- **Effort:** M  
- **Dependencies:** P3-T01, P2-T02

---

### P3-T03 — Implement optional case sensitivity toggle

- **Description:**  
  Add "Case sensitive" toggle affecting both normal and regex searches.
- **Acceptance criteria:**
  - [ ] Toggle present and persists for session.
  - [ ] Different results when toggling case sensitivity (verified with mixed-case files).
- **Effort:** M  
- **Dependencies:** P3-T01, P2-T07

---

### P3-T04 — Implement menu bar extra with quick search popover

- **Description:**  
  Add macOS `MenuBarExtra` with compact quick search view, reusing `SearchViewModel` logic.
- **Acceptance criteria:**
  - [ ] Menu bar icon appears when app is running.
  - [ ] Clicking opens popover with search field and results list.
  - [ ] Actions in popover open selected files.
- **Effort:** L  
- **Dependencies:** P2-T02, P2-T04

---

### P3-T05 — Connect menu bar quick search to shared search engine

- **Description:**  
  Ensure main window and menu bar share the same `DatabaseManager` actor without concurrency issues.
- **Acceptance criteria:**
  - [ ] Both UI surfaces use the same `DatabaseManager`.
  - [ ] Simultaneous searches don't crash or misbehave.
- **Effort:** M  
- **Dependencies:** P3-T04, P1-T03

---

### P3-T06 — Implement global hotkey registration (⌥Space)

- **Description:**  
  Implement global keyboard shortcut using AppKit/Carbon to show/focus main window.
- **Acceptance criteria:**
  - [ ] ⌥Space opens or focuses main window when app is running.
  - [ ] Works even when app is in background.
  - [ ] Registration failure handled gracefully.
- **Effort:** L  
- **Dependencies:** P2-T01, GS-T03

---

### P3-T07 — Ensure window focus/activation from hotkey and menu bar

- **Description:**  
  Bring app to front and focus search field when triggered from hotkey or menu bar "Open Locate…".
- **Acceptance criteria:**
  - [ ] Hotkey and menu bar action reliably focus main window and search field.
- **Effort:** M  
- **Dependencies:** P3-T06, P3-T04

---

### P3-T08 — Power features regression tests

- **Description:**  
  Manual tests for regex, case sensitivity, menu bar, global hotkey from various states.
- **Acceptance criteria:**
  - [ ] Checklist document exists for these features.
  - [ ] All scenarios pass on at least one test machine.
- **Effort:** M  
- **Dependencies:** P3-T02, P3-T05, P3-T07

---

## Phase 4: Polish & Distribution (Week 4–5)

### P4-T01 — Implement Settings window shell

- **Description:**  
  Add Settings/Preferences window (⌘,) with tabs for: Indexed folders, Exclusion patterns, Indexing schedule.
- **Acceptance criteria:**
  - [ ] "Preferences…" menu item opens Settings window.
  - [ ] Window shows at least three placeholder sections.
- **Effort:** M  
- **Dependencies:** P2-T01

---

### P4-T02 — Implement indexed folders management in Settings

- **Description:**  
  UI to display, add (via `NSOpenPanel`), and remove indexed root folders. Persist list.
- **Acceptance criteria:**
  - [ ] User can add/remove folders in Settings.
  - [ ] Changes persisted across app relaunch.
  - [ ] Indexed roots used by indexing pipeline.
- **Effort:** L  
- **Dependencies:** P4-T01, P1-T05

---

### P4-T03 — Implement exclusion patterns configuration

- **Description:**  
  UI for managing exclusion patterns (globs). Integrate into `FileScanner`.
- **Acceptance criteria:**
  - [ ] User can add/remove exclusion patterns.
  - [ ] Exclusions saved and reloaded on restart.
  - [ ] New index respects exclusions.
- **Effort:** L  
- **Dependencies:** P4-T01, P1-T06

---

### P4-T04 — Wire Settings to "Rebuild Index" and show progress

- **Description:**  
  "Rebuild Index Now" button triggers indexing for all configured roots with visible progress.
- **Acceptance criteria:**
  - [ ] Button starts indexing based on current roots and exclusions.
  - [ ] Visible progress indicator while running.
  - [ ] Status bar updates on completion.
- **Effort:** M  
- **Dependencies:** P4-T02, P4-T03, P1-T07

---

### P4-T05 — Implement timed reindexing while app is running

- **Description:**  
  "Reindex every N hours" option with background scheduler.
- **Acceptance criteria:**
  - [ ] User can enable/disable and set interval.
  - [ ] Indexing triggered automatically at configured times.
- **Effort:** L  
- **Dependencies:** P4-T04, P1-T07

---

### P4-T06 — Implement first-launch onboarding flow

- **Description:**  
  Onboarding view on first run: explain app, select folders, "Build Index" button.
- **Acceptance criteria:**
  - [ ] Clean install launches into onboarding.
  - [ ] Selecting folders and clicking "Build Index" triggers indexing, then transitions to normal UI.
- **Effort:** L  
- **Dependencies:** P4-T02, P4-T04, P2-T11

---

### P4-T07 — Add "Full Disk Access" guidance and detection

- **Description:**  
  Help section with instructions for Full Disk Access. Detect permission issues and show hints.
- **Acceptance criteria:**
  - [ ] "Privacy & Permissions" info in Settings or Help menu.
  - [ ] Step-by-step instructions for Full Disk Access.
  - [ ] Permission failures show user-facing hint.
- **Effort:** M  
- **Dependencies:** P4-T06, P1-T06

---

### P4-T08 — Finalize app metadata, icon, and Info.plist

- **Description:**  
  Set final app name, version, copyright, bundle identifier, app icon.
- **Acceptance criteria:**
  - [ ] App shows final icon in Dock and Finder.
  - [ ] Bundle metadata correct when inspecting built app.
- **Effort:** S  
- **Dependencies:** GS-T03

---

### P4-T09 — Create DMG packaging process

- **Description:**  
  Script or documented process to archive, export, and package app into DMG.
- **Acceptance criteria:**
  - [ ] DMG file produced that contains app and opens on another Mac.
  - [ ] Process documented in `docs/release.md`.
- **Effort:** M  
- **Dependencies:** P4-T08, GS-T03

---

### P4-T10 — Configure notarization workflow

- **Description:**  
  Set up notarization using `notarytool`. Script to submit, poll, and staple.
- **Acceptance criteria:**
  - [ ] Successfully notarized build verified on clean macOS install.
  - [ ] Script or documented commands in repo.
- **Effort:** L  
- **Dependencies:** P4-T09

---

### P4-T11 — Manual QA pass and basic regression checklist

- **Description:**  
  Broad manual test on clean machine: onboarding, indexing, search, filters, regex, menu bar, hotkey, settings, DMG install.
- **Acceptance criteria:**
  - [ ] QA checklist document created (`docs/qa-checklist.md`).
  - [ ] All items executed and pass.
  - [ ] Critical bugs logged as issues.
- **Effort:** L  
- **Dependencies:** P4-T06, P3-T08, P4-T10

---

### P4-T12 — Performance and memory sanity check on larger dataset

- **Description:**  
  Test with large directory (hundreds of thousands of files). Observe CPU, memory, responsiveness.
- **Acceptance criteria:**
  - [ ] Document with measured index size and search latency.
  - [ ] App responsive, within targets (search <100ms, memory <50MB idle).
  - [ ] Issues requiring future work recorded.
- **Effort:** M  
- **Dependencies:** P1-T12, P4-T11

---

## Phase 5: Future (Post-v1)

### P5-T01 — FSEvents incremental updates
- Real-time file system monitoring for automatic index updates

### P5-T02 — Multiple database profiles
- Support multiple named databases for different use cases

### P5-T03 — App Store sandboxed version
- Limited "home folder only" mode for App Store distribution

### P5-T04 — Advanced query optimization
- Query caching, smarter FTS tokenization, sharded databases

---

## Task Summary

| Phase | Tasks | Est. Total Effort |
|-------|-------|-------------------|
| Getting Started | 5 | 5-6 hours |
| Phase 1: Core Engine | 12 | 20-25 hours |
| Phase 2: Basic UI | 11 | 18-22 hours |
| Phase 3: Power Features | 8 | 16-20 hours |
| Phase 4: Polish | 12 | 20-25 hours |
| **Total** | **48** | **~80-100 hours** |
