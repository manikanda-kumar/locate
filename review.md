# Locate for Mac - Architecture Review

*Oracle review conducted during planning phase. Use this document to track architectural decisions and feedback.*

---

## Initial Review Summary

### ✅ Architecture Validated

The proposed architecture is **solid and idiomatic for macOS**:
- SwiftUI + SQLite/FTS5 + Swift Concurrency stack is appropriate
- Manual indexing approach simplifies v1 significantly
- Actor-based DatabaseManager ensures thread safety

---

## Key Recommendations

### 1. Distribution Strategy

| Approach | Recommendation |
|----------|----------------|
| **v1** | Non-sandboxed DMG + notarization |
| **v2+** | Consider App Store with "home folder only" mode |

**Rationale:** App Sandbox cannot index full disk without user-granted Full Disk Access. Starting with DMG avoids fighting sandbox constraints.

---

### 2. Defer FSEvents to Phase 5

FSEvents is complex due to:
- Event coalescing
- Overflow handling  
- Symlink edge cases
- Volume mount/unmount

**v1 approach:** Manual "Rebuild Index" + optional timed re-index while app is open.

---

### 3. Phase 3 Scope Adjustment

| Keep for v1 | Defer to v2+ |
|-------------|--------------|
| Regex search mode | Multiple DB profiles |
| Menu bar popover | FSEvents monitoring |
| Global keyboard shortcut | |

---

### 4. Database Schema Improvements

Applied to plan.md:
- [x] Use `parent_id INTEGER` instead of `parent_path TEXT` for compactness
- [x] Add UPDATE/DELETE triggers for FTS sync
- [x] Add `name_lower` column for case-insensitive search
- [x] Add indexes on `extension`, `modified_at`, `parent_id`, `size`

---

### 5. Concurrency Best Practices

```swift
// Recommended pattern
actor DatabaseManager {
    private var db: OpaquePointer?
    
    func rebuildIndex(for root: String) async throws {
        // All DB operations happen within actor
        // Batch inserts in transactions (500-1000 per commit)
    }
    
    func search(_ request: SearchRequest) async throws -> [FileRecord] {
        // Safe concurrent access via actor isolation
    }
}
```

---

## Competitive Positioning

### Your Niche
Fast, deterministic **filename-first** search with:
- Regex/glob support
- Transparent index configuration
- Power-user query semantics

### vs Spotlight
- Spotlight: Content + metadata, opaque ranking, perceived latency
- **Locate**: Faster, more predictable for filename searches

### vs Alfred/Raycast
- Alfred: Workflow-focused, Spotlight-based file search
- **Locate**: More control over indexing, stronger filename/regex search

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Full Disk Access permission | Medium | Clear onboarding, graceful degradation, permission detection |
| Large index sizes | Low | Compress paths, default exclusions (Library, node_modules) |
| Index update performance | Low | Background threading, batched transactions |
| Spotlight competition | Low | Focus on speed, simplicity, power-user features |

---

## Performance Targets

| Metric | Target | Notes |
|--------|--------|-------|
| Search latency | <100ms | For 1M+ indexed files |
| Index size | <100MB | For typical Mac (~500K files) |
| Memory (idle) | <50MB | Resident memory when not actively searching |
| Indexing speed | >10K files/sec | With batched transactions |

---

## When to Revisit Architecture

Revisit and consider more advanced approaches if:

1. **Indexing time** becomes excessive for typical user datasets (>5 min for home folder)
2. **Search latency** frequently exceeds 200ms for simple queries
3. **Users request** real-time monitoring (FSEvents) as a high-priority feature
4. **App Store distribution** becomes a priority

At that point, consider:
- FSEvents-based incremental updates
- Sharded databases per volume
- XPC services for background indexing
- Query caching layer

---

## Review History

| Date | Reviewer | Focus | Outcome |
|------|----------|-------|---------|
| Initial | Oracle | Full architecture | Validated with adjustments |
| | | | |

*Add entries as the project evolves and re-reviews are conducted.*

---

## Open Questions

- [ ] Should we support multiple simultaneous databases in v1? (Currently: No, deferred)
- [ ] What's the right default exclusion list for macOS? (Proposed: Library, .git, node_modules, .Trash, .DS_Store)
- [ ] Should menu bar popover be the primary interface or secondary? (Currently: Secondary, main window is primary)

---

## References

- [locate32 Source](https://sourceforge.net/p/locate32/code/) - Windows implementation reference
- [SQLite FTS5](https://www.sqlite.org/fts5.html) - Full-text search documentation
- [Apple Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime) - Distribution requirements
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
