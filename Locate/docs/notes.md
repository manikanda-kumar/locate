# SQLite Access Strategy

## Decision: Direct System SQLite via C APIs

For v1, we use macOS system SQLite directly via C APIs without third-party wrappers.

### Rationale

1. **No external dependencies** - System SQLite is always available on macOS
2. **FTS5 availability** - macOS 10.13+ includes SQLite with FTS5 enabled
3. **Full control** - Direct access to all SQLite features without wrapper limitations
4. **Performance** - No abstraction overhead

### Implementation Approach

- Import `SQLite3` module (available via Darwin)
- Create minimal Swift wrapper types in `LocateCore`:
  - `DatabaseHandle` - manages `sqlite3*` pointer lifecycle
  - `Statement` - wraps `sqlite3_stmt*` for prepared statements
- Use `@unchecked Sendable` where needed for C pointer types within actor isolation

### FTS5 Verification

FTS5 is enabled in system SQLite. Verified by:
```sql
SELECT sqlite_version();  -- Should be 3.x
PRAGMA compile_options;   -- Should include ENABLE_FTS5
```

### Module Import

```swift
import SQLite3  // System module, no bridging header needed
```

### Thread Safety

All database operations isolated within `actor DatabaseManager` to ensure thread safety.
SQLite opened in serialized mode as additional safety layer.