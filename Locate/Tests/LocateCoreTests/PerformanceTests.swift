import Foundation
import Testing
@testable import LocateCore

@Test func coreEngineSmokePerformance() async throws {
    let tempRoot = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempRoot) }

    let fileManager = FileManager.default
    for dirIndex in 0..<10 {
        let dir = tempRoot.appendingPathComponent("dir-\(dirIndex)")
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        for fileIndex in 0..<1000 {
            let name = String(format: "file-%04d-%02d.txt", fileIndex, dirIndex)
            let url = dir.appendingPathComponent(name)
            fileManager.createFile(atPath: url.path, contents: Data("x".utf8))
        }
    }

    let dbURL = tempRoot.appendingPathComponent("smoke.sqlite")
    let manager = try DatabaseManager(path: dbURL.path)

    let clock = ContinuousClock()
    let indexStart = clock.now
    try await manager.rebuildIndex(for: tempRoot.path, batchSize: 1000)
    let indexDuration = indexStart.duration(to: clock.now)

    func measureSearch(_ query: String) async throws -> Duration {
        let start = clock.now
        _ = try await manager.searchByName(query, limit: 50)
        return start.duration(to: clock.now)
    }

    let searches = try await [
        measureSearch("file-0001"),
        measureSearch("file-0500"),
        measureSearch("dir-9")
    ]

    #expect(indexDuration < .seconds(8))
    #expect(searches.allSatisfy { $0 < .seconds(1) })
}
