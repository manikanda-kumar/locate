import Foundation
import Testing
@testable import LocateCore

/// Test suite for regex search functionality
@Suite("Regex Search Tests")
struct RegexSearchTests {

    @Test("Regex search matches pattern correctly")
    func regexSearchMatchesPattern() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        // Insert test files with various names
        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "test123.txt", nameLower: "test123.txt", path: "/tmp/test123.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "test456.txt", nameLower: "test456.txt", path: "/tmp/test456.txt", isDirectory: false, size: 20, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "demo.txt", nameLower: "demo.txt", path: "/tmp/demo.txt", isDirectory: false, size: 30, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Search with regex pattern for "test" followed by digits
        let request = SearchRequest(query: "test\\d+", useRegex: true)
        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 2)
        #expect(results.contains { $0.name == "test123.txt" })
        #expect(results.contains { $0.name == "test456.txt" })
        #expect(!results.contains { $0.name == "demo.txt" })
    }

    @Test("Regex search with wildcard pattern")
    func regexSearchWithWildcard() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "report_2024.pdf", nameLower: "report_2024.pdf", path: "/tmp/report_2024.pdf", isDirectory: false, size: 100, fileExtension: "pdf", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "report_final.pdf", nameLower: "report_final.pdf", path: "/tmp/report_final.pdf", isDirectory: false, size: 200, fileExtension: "pdf", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "summary.pdf", nameLower: "summary.pdf", path: "/tmp/summary.pdf", isDirectory: false, size: 300, fileExtension: "pdf", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Match files starting with "report_"
        let request = SearchRequest(query: "^report_.*\\.pdf$", useRegex: true)
        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.name.hasPrefix("report_") })
    }

    @Test("Invalid regex pattern throws error")
    func invalidRegexPatternThrowsError() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "test.txt", nameLower: "test.txt", path: "/tmp/test.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Invalid regex pattern with unclosed bracket
        let request = SearchRequest(query: "[unclosed", useRegex: true)

        await #expect(throws: SQLiteError.self) {
            try await manager.search(request, limit: 10)
        }
    }

    @Test("Regex search with special characters")
    func regexSearchWithSpecialCharacters() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "file-1.txt", nameLower: "file-1.txt", path: "/tmp/file-1.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "file_2.txt", nameLower: "file_2.txt", path: "/tmp/file_2.txt", isDirectory: false, size: 20, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "file.txt", nameLower: "file.txt", path: "/tmp/file.txt", isDirectory: false, size: 30, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Match files with dash in name
        let request = SearchRequest(query: "file-\\d+", useRegex: true)
        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 1)
        #expect(results[0].name == "file-1.txt")
    }

    @Test("Regex search with extension filter")
    func regexSearchWithExtensionFilter() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "data123.txt", nameLower: "data123.txt", path: "/tmp/data123.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "data456.pdf", nameLower: "data456.pdf", path: "/tmp/data456.pdf", isDirectory: false, size: 20, fileExtension: "pdf", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "data789.txt", nameLower: "data789.txt", path: "/tmp/data789.txt", isDirectory: false, size: 30, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Regex pattern with extension filter
        let request = SearchRequest(query: "data\\d+", extensions: ["txt"], useRegex: true)
        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.fileExtension == "txt" })
        #expect(!results.contains { $0.name == "data456.pdf" })
    }

    @Test("Regex search respects size filters")
    func regexSearchRespectsSizeFilters() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "small1.txt", nameLower: "small1.txt", path: "/tmp/small1.txt", isDirectory: false, size: 50, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "large2.txt", nameLower: "large2.txt", path: "/tmp/large2.txt", isDirectory: false, size: 2000, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "medium3.txt", nameLower: "medium3.txt", path: "/tmp/medium3.txt", isDirectory: false, size: 500, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Regex with size filter
        let request = SearchRequest(query: ".*\\d+\\.txt", minSize: 100, maxSize: 1000, useRegex: true)
        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 1)
        #expect(results[0].name == "medium3.txt")
    }

    @Test("Empty regex pattern returns empty results")
    func emptyRegexPatternReturnsEmpty() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "test.txt", nameLower: "test.txt", path: "/tmp/test.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        let request = SearchRequest(query: "", useRegex: true)

        await #expect(throws: SQLiteError.self) {
            try await manager.search(request, limit: 10)
        }
    }
}
