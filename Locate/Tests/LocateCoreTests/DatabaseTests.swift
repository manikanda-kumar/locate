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

@Test func migrationCreatesSchema() throws {
    let temp = try TempDB()
    defer { temp.cleanup() }

    let manager = try DatabaseManager(path: temp.url.path)
    let stmt = try manager.rawHandle().prepare("SELECT value FROM db_info WHERE key='version'")
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

@Test func databaseManagerRootCRUD() throws {
    let temp = try TempDB()
    defer { temp.cleanup() }

    let manager = try DatabaseManager(path: temp.url.path)
    let id = try manager.addOrUpdateRoot(path: "/tmp/root1", volumeName: "Macintosh")
    try manager.updateRootStats(id: id, fileCount: 10, dirCount: 5, lastIndexed: 123)
    let roots = try manager.fetchRoots()
    #expect(roots.count == 1)
    #expect(roots[0].fileCount == 10)
    #expect(roots[0].dirCount == 5)
    #expect(roots[0].lastIndexed == 123)
}
