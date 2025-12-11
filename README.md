# Locate

A macOS SwiftUI file search app with a SQLite/FTS5 core and a companion CLI for indexing and searching file metadata.

## Requirements
- macOS 12+
- Swift 6 toolchain

## Build & Test
- Build: `swift build`
- Tests: `swift test`

## CLI Usage (`LocateCLI`)
The CLI stores the database at `~/.locate/locate.sqlite` by default.

### Build or rebuild an index
```
swift run LocateCLI build-index /path/to/root [--db <dbPath>] [--batch <N>]
```
- Rebuilds the index for the root path.
- `--db` overrides the database location (example: `--db ~/.locate/locate-root.sqlite`).
- `--batch` controls insert batch size (default 500).

**Examples**
- Index current package sources: `swift run LocateCLI build-index .`
- Index repo root from package dir: `swift run LocateCLI build-index .. --db ~/.locate/locate-root.sqlite`

### Search
```
swift run LocateCLI search "query" [--db <dbPath>] [--ext csv,list] [--limit N] [--min-size N] [--max-size N] [--modified-after epoch] [--modified-before epoch]
```
- Prints matching file paths.
- `--ext` accepts a comma-separated list of extensions (case-insensitive).
- Size and modified-time filters accept integer values (bytes / seconds since epoch).
- `--limit` caps returned rows (default 50).

**Examples**
- Find Swift files: `swift run LocateCLI search Package --ext swift --limit 5`
- Find Markdown in root DB: `swift run LocateCLI search README --ext md --db ~/.locate/locate-root.sqlite --limit 5`
- Size-filtered search: `swift run LocateCLI search data --ext txt --min-size 1024 --max-size 1048576`

## App target
Run the SwiftUI app: `swift run Locate`

## Logging
Core components log indexing lifecycle and scanner failures via `os.Logger`.
