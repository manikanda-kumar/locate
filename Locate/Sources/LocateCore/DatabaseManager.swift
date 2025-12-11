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
        try db.withTransaction {
            try createSchemaIfNeeded(db)
            try ensureVersion(db)
        }
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

    private static let insertFileSQL = """
    INSERT INTO files(
        id, root_id, parent_id, name, name_lower, path, is_directory, size, extension, modified_at, created_at, accessed_at, attributes
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """

    public struct IndexedEntry: Sendable {
        public let id: Int64?
        public let rootID: Int64
        public let parentID: Int64?
        public let name: String
        public let nameLower: String
        public let path: String
        public let isDirectory: Bool
        public let size: Int64?
        public let fileExtension: String?
        public let modifiedAt: Int64?
        public let createdAt: Int64?
        public let accessedAt: Int64?
        public let attributes: Int64

        public init(
            id: Int64? = nil,
            rootID: Int64,
            parentID: Int64?,
            name: String,
            nameLower: String,
            path: String,
            isDirectory: Bool,
            size: Int64?,
            fileExtension: String?,
            modifiedAt: Int64?,
            createdAt: Int64?,
            accessedAt: Int64?,
            attributes: Int64
        ) {
            self.id = id
            self.rootID = rootID
            self.parentID = parentID
            self.name = name
            self.nameLower = nameLower
            self.path = path
            self.isDirectory = isDirectory
            self.size = size
            self.fileExtension = fileExtension
            self.modifiedAt = modifiedAt
            self.createdAt = createdAt
            self.accessedAt = accessedAt
            self.attributes = attributes
        }
    }

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

    public func deleteFiles(forRoot rootID: Int64) throws {
        try handle.execute("DELETE FROM files WHERE root_id = \(rootID)")
    }

    public func insertFiles(_ entries: [IndexedEntry]) async throws {
        guard !entries.isEmpty else { return }
        try handle.withTransaction {
            let stmt = try handle.prepare(Self.insertFileSQL)
            for entry in entries {
                try stmt.reset()
                try stmt.bindOptionalInt64(entry.id, at: 1)
                try stmt.bindInt64(entry.rootID, at: 2)
                try stmt.bindOptionalInt64(entry.parentID, at: 3)
                try stmt.bindText(entry.name, at: 4)
                try stmt.bindText(entry.nameLower, at: 5)
                try stmt.bindText(entry.path, at: 6)
                try stmt.bindInt64(entry.isDirectory ? 1 : 0, at: 7)
                try stmt.bindOptionalInt64(entry.size, at: 8)
                try stmt.bindOptionalText(entry.fileExtension, at: 9)
                try stmt.bindOptionalInt64(entry.modifiedAt, at: 10)
                try stmt.bindOptionalInt64(entry.createdAt, at: 11)
                try stmt.bindOptionalInt64(entry.accessedAt, at: 12)
                try stmt.bindInt64(entry.attributes, at: 13)
                try stmt.stepUntilDone()
            }
        }
    }

    public func rebuildIndex(
        for rootPath: String,
        scanner: FileScanner = FileScanner(),
        batchSize: Int = 500,
        progress: (@Sendable (IndexProgress) -> Void)? = nil
    ) async throws {
        Log.info("Rebuilding index for \(rootPath) batchSize=\(batchSize)")
        let rootID = try addOrUpdateRoot(path: rootPath, volumeName: nil)
        let stream = try scanner.streamEntries(rootPath: rootPath, rootID: rootID)

        try deleteFiles(forRoot: rootID)

        var fileCount: Int64 = 0
        var dirCount: Int64 = 0
        var batch: [IndexedEntry] = []
        batch.reserveCapacity(batchSize)

        for try await entry in stream {
            if entry.isDirectory {
                dirCount += 1
            } else {
                fileCount += 1
            }
            batch.append(entry)
            if batch.count >= batchSize {
                try await insertFiles(batch)
                progress?(.batchInserted(count: batch.count, totalFiles: fileCount, totalDirs: dirCount))
                batch.removeAll(keepingCapacity: true)
            }
        }

        if !batch.isEmpty {
            try await insertFiles(batch)
            progress?(.batchInserted(count: batch.count, totalFiles: fileCount, totalDirs: dirCount))
            batch.removeAll(keepingCapacity: true)
        }

        let now = Int64(Date().timeIntervalSince1970)
        try updateRootStats(id: rootID, fileCount: fileCount, dirCount: dirCount, lastIndexed: now)
        progress?(.completed(fileCount: fileCount, dirCount: dirCount))
        Log.info("Index rebuilt for \(rootPath) files=\(fileCount) dirs=\(dirCount)")
    }

    public func searchByName(_ query: String, limit: Int = 50) async throws -> [FileRecord] {
        try await search(SearchRequest(query: query), limit: limit)
    }

    public func search(_ request: SearchRequest, limit: Int = 50) async throws -> [FileRecord] {
        let base = """
        SELECT f.id, f.root_id, f.parent_id, f.name, f.name_lower, f.path, f.is_directory, f.size, f.extension, f.modified_at, f.created_at, f.accessed_at, f.attributes
        FROM files f
        JOIN files_fts ON f.id = files_fts.rowid
        """

        guard let ftsQuery = makeFTSQuery(request.query) else {
            Log.error("Search query empty or invalid")
            return []
        }

        var clauses: [String] = ["files_fts.name MATCH ?"]
        var params: [SQLParam] = [.text(ftsQuery)]

        if let exts = request.extensions?.map({ $0.lowercased() }), !exts.isEmpty {
            let placeholders = Array(repeating: "?", count: exts.count).joined(separator: ",")
            clauses.append("f.extension IN (\(placeholders))")
            params.append(contentsOf: exts.map { .text($0) })
        }
        if let minSize = request.minSize {
            clauses.append("f.size >= ?")
            params.append(.int64(minSize))
        }
        if let maxSize = request.maxSize {
            clauses.append("f.size <= ?")
            params.append(.int64(maxSize))
        }
        if let modifiedAfter = request.modifiedAfter {
            clauses.append("f.modified_at >= ?")
            params.append(.int64(modifiedAfter))
        }
        if let modifiedBefore = request.modifiedBefore {
            clauses.append("f.modified_at <= ?")
            params.append(.int64(modifiedBefore))
        }

        var sql = base
        if !clauses.isEmpty {
            sql += " WHERE " + clauses.joined(separator: " AND ")
        }
        sql += " ORDER BY bm25(files_fts) LIMIT ?"
        params.append(.int64(Int64(limit)))

        let stmt = try handle.prepare(sql)
        for (idx, param) in params.enumerated() {
            let position = Int32(idx + 1)
            switch param {
            case .text(let text):
                try stmt.bindText(text, at: position)
            case .int64(let value):
                try stmt.bindInt64(value, at: position)
            }
        }

        var results: [FileRecord] = []
        while try stmt.step() {
            if let record = FileRecord(from: stmt) {
                results.append(record)
            }
        }
        return results
    }

    public func rawHandle() -> DatabaseHandle { handle }

    private func makeFTSQuery(_ text: String) -> String? {
        let tokens = text.split(whereSeparator: { $0.isWhitespace })
        guard !tokens.isEmpty else { return nil }

        let escaped = tokens.map { escapeFTSToken(String($0)) }
        return escaped.map { "\"\($0)\"*" }.joined(separator: " ")
    }

    private func escapeFTSToken(_ token: String) -> String {
        token
            .replacingOccurrences(of: "\"", with: "\"\"")
            .replacingOccurrences(of: "'", with: "''")
            .replacingOccurrences(of: "*", with: "")
    }
}

public enum IndexProgress: Equatable, Sendable {
    case batchInserted(count: Int, totalFiles: Int64, totalDirs: Int64)
    case completed(fileCount: Int64, dirCount: Int64)
}

public struct SearchRequest: Sendable {
    public var query: String
    public var extensions: [String]?
    public var minSize: Int64?
    public var maxSize: Int64?
    public var modifiedAfter: Int64?
    public var modifiedBefore: Int64?

    public init(query: String, extensions: [String]? = nil, minSize: Int64? = nil, maxSize: Int64? = nil, modifiedAfter: Int64? = nil, modifiedBefore: Int64? = nil) {
        self.query = query
        self.extensions = extensions
        self.minSize = minSize
        self.maxSize = maxSize
        self.modifiedAfter = modifiedAfter
        self.modifiedBefore = modifiedBefore
    }
}

private enum SQLParam {
    case text(String)
    case int64(Int64)
}
