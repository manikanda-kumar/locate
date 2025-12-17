# Oracle Review — Architecture & Improvement Areas

This document captures architecture-level improvement areas discovered during a repo review, plus recommended next steps.

## Production Release Notes

> **Important:** Document these points in release notes and on the project website before public release.

### Security & Distribution Posture

- **Unsandboxed App:** Locate runs without macOS App Sandbox (`com.apple.security.app-sandbox = false`). This is intentional for a `locate`-style tool but means:
  - The app is **not Mac App Store eligible** in this form
  - Direct download distribution only (DMG, notarized)
  - Any local process running as the same user can read the index database

- **Full Disk Access:** For complete filesystem indexing, users should grant Full Disk Access in System Settings → Privacy & Security. Without it, some protected directories will be skipped.

- **Index Storage:** The search index is stored unencrypted at `~/.locate/locate.sqlite`. It contains file paths and names (not file contents). The directory is created with `0700` permissions (user-only access).

### Applied Hardening (v1.0)

The following security and reliability improvements were applied:

1. **FileScanner resilience** — Skips unreadable files instead of aborting the entire index operation
2. **SQL injection prevention** — All SQL queries use parameterized statements
3. **Directory permissions** — `~/.locate` created with restrictive `0700` permissions
4. **Concurrent indexing guard** — Auto-reindex skips if manual indexing is already in progress
5. **API encapsulation** — Internal database handle no longer exposed publicly

## High-Impact Fixes (Correctness & Consistency)

### Align platform targets and documentation
- `Locate/Package.swift` targets macOS 15 (`.macOS(.v15)`), while docs and `Locate/Info.plist` state macOS 12.
- Pick a single minimum target and align: `Locate/Package.swift`, `Locate/Info.plist`, `README.md`, and `docs/README.md`.

### Fix database location mismatch
- Docs claim: `~/Library/Application Support/Locate/locate.db` (`docs/README.md`).
- Code uses: `~/.locate/locate.sqlite` (`Locate/Sources/LocateViewModel/AppPaths.swift`, `Locate/Sources/LocateCLI/main.swift`).
- Recommendation: default the app to Application Support (and keep CLI configurable via `--db`), then update docs accordingly.

### Fix NULL-vs-0 decoding for SQLite columns
- `FileRecord` decoding treats integer `0` as `nil` for size and timestamps (`Locate/Sources/LocateCore/Models.swift`).
- This breaks real cases (e.g., empty files have size `0`, not “unknown”).
- Recommendation: use `sqlite3_column_type(... ) == SQLITE_NULL` checks (or add `Statement.columnOptionalInt64(_:)`) and decode based on NULL, not “== 0”.

## Indexing & Data Lifecycle

### Purge data when indexed folders are removed
- Removing a folder from Settings appears to only change `UserDefaults`; the DB still retains `roots/files` for removed paths.
- Recommendation: add a “reconcile index” step that deletes roots no longer in `AppSettings.indexedFolders` (and cascades file rows).

### Make indexing resilient to partial failures
- `FileScanner.streamEntries` currently fails the entire stream on the first unreadable file.
- Recommendation: log-and-skip per-entry errors (with counters and a final summary), so indexing succeeds even with intermittent permission or I/O failures.

### Hidden-files behavior should be explicit
- `FileScanner` uses `.skipsHiddenFiles` and also skips `name.hasPrefix(".")`.
- Recommendation: centralize this behind a single setting (planned in `docs/ux-improvements.md` Phase 5C) and avoid double-filtering.

## Search UX & Performance

### Wire “search as you type” to match product claims
- Main window triggers searching primarily on submit/button, not on each query edit (`Locate/Sources/Locate/SearchView.swift`).
- Menu bar view similarly only searches on submit (`Locate/Sources/Locate/MenuBarSearchView.swift`).
- Recommendation: use `onChange(of:) { _, _ in ... }` (2-parameter or 0-parameter variant) for query and filter changes and debounce in `SearchViewModel`.

### Keep search responsive during indexing
- A single `DatabaseManager` actor likely serializes long indexing transactions with searches.
- Recommendation: consider separate read/write connections (WAL) or a dedicated read actor/connection for queries while indexing runs.

## Concurrency, Safety, and API Hygiene

### Remove force unwraps and redundant branches in permissions helper
- `PermissionsHelper.openSystemPreferences()` force-unwraps a URL and has identical macOS branches.
- Recommendation: safely construct the URL and fail gracefully with user-visible messaging/logging.

### Normalize string APIs and SwiftUI guidance
- Replace `replacingOccurrences(of:with:)` with `replacing(_:with:)` where applicable (e.g., path display in Settings/Onboarding).
- `SettingsView` uses `.tabItem { ... }`; repo guidelines request the modern `Tab` API—recommend migrating for consistency.

## Docs & Process

### Close the loop on “power features” regression testing
- `tasks.md` flags `P3-T08` as not completed, but the checklist exists in `docs/power-features-tests.md`.
- Recommendation: run the checklist on at least one machine and record results (date/macOS version) at the bottom of `docs/power-features-tests.md`.

### Add CI (optional but high leverage)
- No `.github/workflows` present.
- Recommendation: add a basic workflow that runs formatting (if configured) and unit tests on macOS.

