import Foundation
import Testing
@testable import LocateCore

struct TempDB {
    let url: URL

    init() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent("test.sqlite")
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }
}

@Test func migrationCreatesSchema() async throws {
    let temp = try TempDB()
    defer { temp.cleanup() }

    let manager = try DatabaseManager(path: temp.url.path)
    let stmt = try await manager.rawHandle().prepare("SELECT value FROM db_info WHERE key='version'")
    #expect(try stmt.step())
    #expect(stmt.columnText(0) == String(Migration.schemaVersion))
}

@Test func sqliteWrapperInsertAndSelect() throws {
    let temp = try TempDB()
    defer { temp.cleanup() }

    let db = try DatabaseHandle(path: temp.url.path)
    try Migration.migrateIfNeeded(using: db)
    try db.execute("CREATE TABLE sample (id INTEGER PRIMARY KEY, name TEXT)")
    let insert = try db.prepare("INSERT INTO sample(name) VALUES(?)")
    try insert.bindText("hello", at: 1)
    try insert.stepUntilDone()

    let query = try db.prepare("SELECT name FROM sample WHERE id = 1")
    #expect(try query.step())
    #expect(query.columnText(0) == "hello")
}

@Test func databaseManagerRootCRUD() async throws {
    let temp = try TempDB()
    defer { temp.cleanup() }

    let manager = try DatabaseManager(path: temp.url.path)
    let id = try await manager.addOrUpdateRoot(path: "/tmp/root1", volumeName: "Macintosh")
    try await manager.updateRootStats(id: id, fileCount: 10, dirCount: 5, lastIndexed: 123)
    let roots = try await manager.fetchRoots()
    #expect(roots.count == 1)
    #expect(roots[0].fileCount == 10)
    #expect(roots[0].dirCount == 5)
    #expect(roots[0].lastIndexed == 123)
}

@Test func fileScannerReturnsEntries() async throws {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let fileURL = tempDir.appendingPathComponent("sample.txt")
    try "hello".write(to: fileURL, atomically: true, encoding: .utf8)

    let scanner = FileScanner()
    let entries = try await scanner.scan(rootPath: tempDir.path, rootID: 1)
    #expect(entries.contains {
        URL(fileURLWithPath: $0.path).resolvingSymlinksInPath().path == fileURL.resolvingSymlinksInPath().path
    })
}

@Test func searchByNameReturnsMatches() async throws {
    let temp = try TempDB()
    defer { temp.cleanup() }

    let manager = try DatabaseManager(path: temp.url.path)
    let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)
    try await manager.insertFiles([
        .init(rootID: rootID, parentID: nil, name: "foo.txt", nameLower: "foo.txt", path: "/tmp/foo.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
        .init(rootID: rootID, parentID: nil, name: "bar.jpg", nameLower: "bar.jpg", path: "/tmp/bar.jpg", isDirectory: false, size: 20, fileExtension: "jpg", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
    ])

    let results = try await manager.searchByName("foo", limit: 10)
    #expect(results.count == 1)
    #expect(results[0].name == "foo.txt")
}

@Test func searchWithFilters() async throws {
    let temp = try TempDB()
    defer { temp.cleanup() }

    let manager = try DatabaseManager(path: temp.url.path)
    let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)
    try await manager.insertFiles([
        .init(rootID: rootID, parentID: nil, name: "alpha.txt", nameLower: "alpha.txt", path: "/tmp/alpha.txt", isDirectory: false, size: 100, fileExtension: "txt", modifiedAt: 1000, createdAt: nil, accessedAt: nil, attributes: 0),
        .init(rootID: rootID, parentID: nil, name: "beta.txt", nameLower: "beta.txt", path: "/tmp/beta.txt", isDirectory: false, size: 2000, fileExtension: "txt", modifiedAt: 2000, createdAt: nil, accessedAt: nil, attributes: 0),
        .init(rootID: rootID, parentID: nil, name: "gamma.jpg", nameLower: "gamma.jpg", path: "/tmp/gamma.jpg", isDirectory: false, size: 3000, fileExtension: "jpg", modifiedAt: 3000, createdAt: nil, accessedAt: nil, attributes: 0)
    ])

    let request = SearchRequest(query: "beta", extensions: ["txt"], minSize: 150, maxSize: 2500, modifiedAfter: 1500, modifiedBefore: 2500)
    let results = try await manager.search(request, limit: 10)
    #expect(results.count == 1)
    #expect(results[0].name == "beta.txt")
}

@Test func searchByNameReturnsEmptyForBlankQuery() async throws {
    let temp = try TempDB()
    defer { temp.cleanup() }

    let manager = try DatabaseManager(path: temp.url.path)
    let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)
    try await manager.insertFiles([
        .init(rootID: rootID, parentID: nil, name: "note.txt", nameLower: "note.txt", path: "/tmp/note.txt", isDirectory: false, size: 1, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
    ])

    let results = try await manager.searchByName("   ", limit: 10)
    #expect(results.isEmpty)
}

@Test func searchByNameEscapesQuotes() async throws {
    let temp = try TempDB()
    defer { temp.cleanup() }

    let manager = try DatabaseManager(path: temp.url.path)
    let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)
    let quirkyName = #"report"draft.txt"#
    try await manager.insertFiles([
        .init(rootID: rootID, parentID: nil, name: quirkyName, nameLower: quirkyName.lowercased(), path: "/tmp/\(quirkyName)", isDirectory: false, size: 5, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
    ])

    let results = try await manager.searchByName(#"report"draft"#, limit: 10)
    #expect(results.count == 1)
    #expect(results[0].name == quirkyName)
}

@Test func fileScannerSkipsTopLevelExclusions() async throws {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let gitDir = tempDir.appendingPathComponent(".git")
    try FileManager.default.createDirectory(at: gitDir, withIntermediateDirectories: true)
    try "ignore".write(to: gitDir.appendingPathComponent("ignored.txt"), atomically: true, encoding: .utf8)

    let libraryDir = tempDir.appendingPathComponent("Library")
    try FileManager.default.createDirectory(at: libraryDir, withIntermediateDirectories: true)
    try "skip".write(to: libraryDir.appendingPathComponent("skip.txt"), atomically: true, encoding: .utf8)

    let visibleFile = tempDir.appendingPathComponent("visible.txt")
    try "keep".write(to: visibleFile, atomically: true, encoding: .utf8)

    let scanner = FileScanner()
    let entries = try await scanner.scan(rootPath: tempDir.path, rootID: 99)
    let names = Set(entries.map(\.name))

    #expect(!names.contains("Library"))
    #expect(!entries.contains { $0.path.contains("skip.txt") })
    #expect(!names.contains(".git"))
    #expect(names.contains("visible.txt"))
}

@Test func rebuildIndexStreamsAndUpdatesCounts() async throws {
    let tempDB = try TempDB()
    defer { tempDB.cleanup() }

    let rootURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: rootURL) }

    let fileA = rootURL.appendingPathComponent("a.txt")
    try "a".write(to: fileA, atomically: true, encoding: .utf8)

    let folder = rootURL.appendingPathComponent("Folder")
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    let fileB = folder.appendingPathComponent("b.txt")
    try "b".write(to: fileB, atomically: true, encoding: .utf8)

    final class ProgressCollector: @unchecked Sendable {
        private let lock = NSLock()
        private var events: [IndexProgress] = []

        func append(_ event: IndexProgress) {
            lock.lock()
            events.append(event)
            lock.unlock()
        }

        var snapshot: [IndexProgress] {
            lock.lock()
            defer { lock.unlock() }
            return events
        }
    }

    let manager = try DatabaseManager(path: tempDB.url.path)
    let progressCollector = ProgressCollector()
    try await manager.rebuildIndex(for: rootURL.path, batchSize: 1) { event in
        progressCollector.append(event)
    }

    let roots = try await manager.fetchRoots()
    #expect(roots.count == 1)
    let root = roots[0]
    #expect(root.fileCount == 2)
    #expect(root.dirCount == 1)

    let stmt = try await manager.rawHandle().prepare("SELECT COUNT(*) FROM files WHERE root_id = \(root.id)")
    #expect(try stmt.step())
    #expect(stmt.columnInt64(0) == 3)

    #expect(progressCollector.snapshot.contains { event in
        if case .completed(let fileCount, let dirCount) = event {
            return fileCount == 2 && dirCount == 1
        }
        return false
    })
}
