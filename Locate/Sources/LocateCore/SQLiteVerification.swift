import SQLite3

public enum SQLiteVerification {
    public static func verify() -> (version: String, hasFTS5: Bool) {
        let version = String(cString: sqlite3_libversion())

        var db: OpaquePointer?
        defer { sqlite3_close(db) }

        guard sqlite3_open(":memory:", &db) == SQLITE_OK else {
            return (version, false)
        }

        var stmt: OpaquePointer?
        let sql = "SELECT 1 FROM (SELECT fts5())"
        let hasFTS5 = sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK ||
        sqlite3_prepare_v2(db, "CREATE VIRTUAL TABLE test USING fts5(content)", -1, &stmt, nil) == SQLITE_OK
        sqlite3_finalize(stmt)

        return (version, hasFTS5)
    }

    public static func runSelectOne() -> Bool {
        var db: OpaquePointer?
        defer { sqlite3_close(db) }

        guard sqlite3_open(":memory:", &db) == SQLITE_OK else { return false }

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, "SELECT 1", -1, &stmt, nil) == SQLITE_OK else { return false }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return false }

        return sqlite3_column_int(stmt, 0) == 1
    }
}