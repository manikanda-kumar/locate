import Foundation
import SQLite3

public enum Migration {
    public static let schemaVersion = 1
    private static let schemaSQL: [String] = [
        "CREATE TABLE IF NOT EXISTS db_info (key TEXT PRIMARY KEY, value TEXT)",
        "CREATE TABLE IF NOT EXISTS roots (id INTEGER PRIMARY KEY, path TEXT NOT NULL UNIQUE, volume_name TEXT, file_count INTEGER DEFAULT 0, dir_count INTEGER DEFAULT 0, last_indexed INTEGER)",
        "CREATE TABLE IF NOT EXISTS files (id INTEGER PRIMARY KEY, root_id INTEGER NOT NULL REFERENCES roots(id), parent_id INTEGER REFERENCES files(id), name TEXT NOT NULL, name_lower TEXT NOT NULL, path TEXT NOT NULL, is_directory INTEGER NOT NULL DEFAULT 0, size INTEGER, extension TEXT, modified_at INTEGER, created_at INTEGER, accessed_at INTEGER, attributes INTEGER DEFAULT 0)",
        "CREATE INDEX IF NOT EXISTS idx_files_parent ON files(parent_id)",
        "CREATE INDEX IF NOT EXISTS idx_files_root ON files(root_id)",
        "CREATE INDEX IF NOT EXISTS idx_files_extension ON files(extension)",
        "CREATE INDEX IF NOT EXISTS idx_files_modified ON files(modified_at)",
        "CREATE INDEX IF NOT EXISTS idx_files_size ON files(size)",
        "CREATE INDEX IF NOT EXISTS idx_files_name_lower ON files(name_lower)",
        "CREATE VIRTUAL TABLE IF NOT EXISTS files_fts USING fts5(name, content='files', content_rowid='id', tokenize='unicode61')",
        "CREATE TRIGGER IF NOT EXISTS files_ai AFTER INSERT ON files BEGIN INSERT INTO files_fts(rowid, name) VALUES (new.id, new.name); END;",
        "CREATE TRIGGER IF NOT EXISTS files_ad AFTER DELETE ON files BEGIN DELETE FROM files_fts WHERE rowid = old.id; END;",
        "CREATE TRIGGER IF NOT EXISTS files_au AFTER UPDATE OF name ON files BEGIN UPDATE files_fts SET name = new.name WHERE rowid = old.id; END;"
    ]

    public static func migrateIfNeeded(using db: DatabaseHandle) throws {
        try db.execute("BEGIN IMMEDIATE TRANSACTION")
        defer { try? db.execute("COMMIT") }

        try createSchemaIfNeeded(db)
        try ensureVersion(db)
    }

    private static func createSchemaIfNeeded(_ db: DatabaseHandle) throws {
        for sql in schemaSQL {
            try db.execute(sql)
        }
    }

    private static func ensureVersion(_ db: DatabaseHandle) throws {
        let stmt = try db.prepare("SELECT value FROM db_info WHERE key = 'version'")
        if try stmt.step(), let versionString = stmt.columnText(0), Int(versionString) == schemaVersion {
            return
        }
        let upsert = try db.prepare("INSERT INTO db_info(key, value) VALUES('version', ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value")
        try upsert.bindText(String(schemaVersion), at: 1)
        try upsert.stepUntilDone()
    }
}

public actor DatabaseManager {
    private let handle: DatabaseHandle

    public init(path: String) throws {
        self.handle = try DatabaseHandle(path: path)
        try Migration.migrateIfNeeded(using: handle)
    }

    public func addOrUpdateRoot(path: String, volumeName: String? = nil) throws -> Int64 {
        let sql = "INSERT INTO roots(path, volume_name) VALUES(?, ?) ON CONFLICT(path) DO UPDATE SET volume_name=excluded.volume_name RETURNING id"
        let stmt = try handle.prepare(sql)
        try stmt.bindText(path, at: 1)
        try stmt.bindOptionalText(volumeName, at: 2)
        guard try stmt.step() else { throw SQLiteError(message: "Failed to insert root", code: SQLITE_ERROR) }
        return stmt.columnInt64(0)
    }

    public func fetchRoots() throws -> [Root] {
        let stmt = try handle.prepare("SELECT id, path, volume_name, file_count, dir_count, last_indexed FROM roots ORDER BY path")
        var roots: [Root] = []
        while try stmt.step() {
            if let root = Root(from: stmt) {
                roots.append(root)
            }
        }
        return roots
    }

    public func updateRootStats(id: Int64, fileCount: Int64, dirCount: Int64, lastIndexed: Int64) throws {
        let stmt = try handle.prepare("UPDATE roots SET file_count = ?, dir_count = ?, last_indexed = ? WHERE id = ?")
        try stmt.bindInt64(fileCount, at: 1)
        try stmt.bindInt64(dirCount, at: 2)
        try stmt.bindInt64(lastIndexed, at: 3)
        try stmt.bindInt64(id, at: 4)
        try stmt.stepUntilDone()
    }

    public func rawHandle() -> DatabaseHandle { handle }
}
