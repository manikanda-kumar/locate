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
        let stmt = try handle.prepare("DELETE FROM files WHERE root_id = ?")
        try stmt.bindInt64(rootID, at: 1)
        try stmt.stepUntilDone()
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
        if request.useRegex {
            return try await searchWithRegex(request, limit: limit)
        } else {
            return try await searchWithFTS(request, limit: limit)
        }
    }

    private func searchWithFTS(_ request: SearchRequest, limit: Int) async throws -> [FileRecord] {
        // Check if we have any terms to search (either optional terms or required terms)
        let hasSearchTerms = !request.optionalTerms.isEmpty || !request.requiredTerms.isEmpty
        let hasBooleanFilters = !request.requiredTerms.isEmpty || !request.excludedTerms.isEmpty

        // Build base query - use FTS if we have optional terms, otherwise scan with filters
        let base: String
        var clauses: [String] = []
        var params: [SQLParam] = []

        if !request.optionalTerms.isEmpty, let ftsQuery = makeFTSQuery(request.query) {
            base = """
            SELECT f.id, f.root_id, f.parent_id, f.name, f.name_lower, f.path, f.is_directory, f.size, f.extension, f.modified_at, f.created_at, f.accessed_at, f.attributes
            FROM files f
            JOIN files_fts ON f.id = files_fts.rowid
            """
            clauses.append("files_fts.name MATCH ?")
            params.append(.text(ftsQuery))
        } else if hasSearchTerms {
            // Only required/excluded terms - scan all files with LIKE for required terms
            base = """
            SELECT f.id, f.root_id, f.parent_id, f.name, f.name_lower, f.path, f.is_directory, f.size, f.extension, f.modified_at, f.created_at, f.accessed_at, f.attributes
            FROM files f
            """
            // Add LIKE clause for required terms to reduce scan
            for term in request.requiredTerms {
                let searchColumn = request.searchInPath ? "f.path" : "f.name_lower"
                clauses.append("\(searchColumn) LIKE ?")
                params.append(.text("%" + term.lowercased() + "%"))
            }
        } else {
            Log.error("Search query empty or invalid")
            return []
        }

        // File/Directory filter
        if request.searchFiles && !request.searchDirectories {
            clauses.append("f.is_directory = 0")
        } else if !request.searchFiles && request.searchDirectories {
            clauses.append("f.is_directory = 1")
        } else if !request.searchFiles && !request.searchDirectories {
            return [] // Nothing to search
        }

        // Extension inclusion filter
        if let exts = request.extensions?.map({ $0.lowercased() }), !exts.isEmpty {
            let placeholders = Array(repeating: "?", count: exts.count).joined(separator: ",")
            clauses.append("f.extension IN (\(placeholders))")
            params.append(contentsOf: exts.map { .text($0) })
        }

        // Extension exclusion filter
        if let excludedExts = request.excludedExtensions?.map({ $0.lowercased() }), !excludedExts.isEmpty {
            let placeholders = Array(repeating: "?", count: excludedExts.count).joined(separator: ",")
            clauses.append("(f.extension IS NULL OR f.extension NOT IN (\(placeholders)))")
            params.append(contentsOf: excludedExts.map { .text($0) })
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
        if let folderScope = request.folderScope {
            let escapedPath = folderScope
                .replacingOccurrences(of: "%", with: "\\%")
                .replacingOccurrences(of: "_", with: "\\_")
            clauses.append("f.path LIKE ? ESCAPE '\\'")
            params.append(.text(escapedPath + "%"))
        }

        var sql = base
        if !clauses.isEmpty {
            sql += " WHERE " + clauses.joined(separator: " AND ")
        }

        // Order by FTS rank if using FTS, otherwise by name
        if !request.optionalTerms.isEmpty {
            sql += " ORDER BY bm25(files_fts)"
        } else {
            sql += " ORDER BY f.name"
        }

        // Fetch more candidates when we need post-filtering
        let candidateLimit = hasBooleanFilters ? min(limit * 10, 10000) : limit
        sql += " LIMIT ?"
        params.append(.int64(Int64(candidateLimit)))

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
                // Apply boolean term filtering
                if hasBooleanFilters {
                    let textToMatch = request.searchInPath ? record.path : record.name
                    if !request.matchesBooleanTerms(textToMatch, caseSensitive: request.caseSensitive) {
                        continue
                    }
                }

                // Apply case sensitivity filter if needed (FTS is case-insensitive by default)
                if request.caseSensitive && !request.query.isEmpty {
                    let textToMatch = request.searchInPath ? record.path : record.name
                    if !textToMatch.contains(request.query) {
                        continue
                    }
                }

                results.append(record)
                if results.count >= limit {
                    break
                }
            }
        }

        return results
    }

    private func searchWithRegex(_ request: SearchRequest, limit: Int) async throws -> [FileRecord] {
        let hasBooleanFilters = !request.requiredTerms.isEmpty || !request.excludedTerms.isEmpty

        // Validate regex pattern (only if we have a query)
        var regex: NSRegularExpression? = nil
        if !request.query.isEmpty {
            let regexOptions: NSRegularExpression.Options = request.caseSensitive ? [] : [.caseInsensitive]
            do {
                regex = try NSRegularExpression(pattern: request.query, options: regexOptions)
            } catch {
                throw SQLiteError(message: "Invalid regex pattern: \(error.localizedDescription)", code: SQLITE_ERROR)
            }
        }

        // Build SQL query to fetch candidates with filters
        let base = """
        SELECT f.id, f.root_id, f.parent_id, f.name, f.name_lower, f.path, f.is_directory, f.size, f.extension, f.modified_at, f.created_at, f.accessed_at, f.attributes
        FROM files f
        """

        var clauses: [String] = []
        var params: [SQLParam] = []

        // File/Directory filter
        if request.searchFiles && !request.searchDirectories {
            clauses.append("f.is_directory = 0")
        } else if !request.searchFiles && request.searchDirectories {
            clauses.append("f.is_directory = 1")
        } else if !request.searchFiles && !request.searchDirectories {
            return [] // Nothing to search
        }

        // Extension inclusion filter
        if let exts = request.extensions?.map({ $0.lowercased() }), !exts.isEmpty {
            let placeholders = Array(repeating: "?", count: exts.count).joined(separator: ",")
            clauses.append("f.extension IN (\(placeholders))")
            params.append(contentsOf: exts.map { .text($0) })
        }

        // Extension exclusion filter
        if let excludedExts = request.excludedExtensions?.map({ $0.lowercased() }), !excludedExts.isEmpty {
            let placeholders = Array(repeating: "?", count: excludedExts.count).joined(separator: ",")
            clauses.append("(f.extension IS NULL OR f.extension NOT IN (\(placeholders)))")
            params.append(contentsOf: excludedExts.map { .text($0) })
        }

        // Add LIKE clause for required terms to reduce scan
        for term in request.requiredTerms {
            let searchColumn = request.searchInPath ? "f.path" : "f.name_lower"
            clauses.append("\(searchColumn) LIKE ?")
            params.append(.text("%" + term.lowercased() + "%"))
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
        if let folderScope = request.folderScope {
            let escapedPath = folderScope
                .replacingOccurrences(of: "%", with: "\\%")
                .replacingOccurrences(of: "_", with: "\\_")
            clauses.append("f.path LIKE ? ESCAPE '\\'")
            params.append(.text(escapedPath + "%"))
        }

        var sql = base
        if !clauses.isEmpty {
            sql += " WHERE " + clauses.joined(separator: " AND ")
        }
        sql += " LIMIT ?"
        let candidateLimit = min(limit * 10, 10000) // Fetch more candidates for regex filtering
        params.append(.int64(Int64(candidateLimit)))

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
                let textToMatch = request.searchInPath ? record.path : record.name

                // Apply regex filter (if we have a regex pattern)
                if let regex = regex {
                    let range = NSRange(location: 0, length: textToMatch.utf16.count)
                    if regex.firstMatch(in: textToMatch, range: range) == nil {
                        continue
                    }
                }

                // Apply boolean term filtering
                if hasBooleanFilters {
                    if !request.matchesBooleanTerms(textToMatch, caseSensitive: request.caseSensitive) {
                        continue
                    }
                }

                results.append(record)
                if results.count >= limit {
                    break
                }
            }
        }

        return results
    }

    internal func rawHandle() -> DatabaseHandle { handle }

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
    public var useRegex: Bool
    public var caseSensitive: Bool
    public var folderScope: String?

    // NEW: From Windows Locate review
    public var searchInPath: Bool
    public var searchFiles: Bool
    public var searchDirectories: Bool
    public var excludedExtensions: [String]?

    // Boolean operators parsed from query
    internal var requiredTerms: [String]
    internal var excludedTerms: [String]
    internal var optionalTerms: [String]

    public init(
        query: String,
        extensions: [String]? = nil,
        minSize: Int64? = nil,
        maxSize: Int64? = nil,
        modifiedAfter: Int64? = nil,
        modifiedBefore: Int64? = nil,
        useRegex: Bool = false,
        caseSensitive: Bool = false,
        folderScope: String? = nil,
        searchInPath: Bool = false,
        searchFiles: Bool = true,
        searchDirectories: Bool = true,
        excludedExtensions: [String]? = nil
    ) {
        self.extensions = extensions
        self.minSize = minSize
        self.maxSize = maxSize
        self.modifiedAfter = modifiedAfter
        self.modifiedBefore = modifiedBefore
        self.useRegex = useRegex
        self.caseSensitive = caseSensitive
        self.folderScope = folderScope
        self.searchInPath = searchInPath
        self.searchFiles = searchFiles
        self.searchDirectories = searchDirectories
        self.excludedExtensions = excludedExtensions

        // Parse boolean operators from query
        let parsed = Self.parseQuery(query)
        self.requiredTerms = parsed.required
        self.excludedTerms = parsed.excluded
        self.optionalTerms = parsed.optional

        // Build clean query from optional terms (for FTS/regex matching)
        self.query = parsed.optional.joined(separator: " ")
    }

    /// Parse query for boolean operators: +required -excluded optional
    private static func parseQuery(_ query: String) -> (required: [String], excluded: [String], optional: [String]) {
        var required: [String] = []
        var excluded: [String] = []
        var optional: [String] = []

        let tokens = query.split(whereSeparator: { $0.isWhitespace })
        for token in tokens {
            let term = String(token)
            if term.hasPrefix("+") && term.count > 1 {
                required.append(String(term.dropFirst()))
            } else if term.hasPrefix("-") && term.count > 1 {
                excluded.append(String(term.dropFirst()))
            } else {
                optional.append(term)
            }
        }

        return (required, excluded, optional)
    }

    /// Check if a filename/path matches the boolean operator requirements
    internal func matchesBooleanTerms(_ text: String, caseSensitive: Bool) -> Bool {
        let searchText = caseSensitive ? text : text.lowercased()

        // All required terms must be present
        for term in requiredTerms {
            let searchTerm = caseSensitive ? term : term.lowercased()
            if !searchText.contains(searchTerm) {
                return false
            }
        }

        // No excluded terms can be present
        for term in excludedTerms {
            let searchTerm = caseSensitive ? term : term.lowercased()
            if searchText.contains(searchTerm) {
                return false
            }
        }

        return true
    }

    /// Check if a file extension should be excluded
    internal func isExtensionExcluded(_ ext: String?) -> Bool {
        guard let excludedExts = excludedExtensions, !excludedExts.isEmpty else {
            return false
        }
        guard let ext = ext else { return false }
        let lowerExt = ext.lowercased()
        return excludedExts.contains { lowerExt == $0.lowercased() }
    }
}

private enum SQLParam {
    case text(String)
    case int64(Int64)
}
