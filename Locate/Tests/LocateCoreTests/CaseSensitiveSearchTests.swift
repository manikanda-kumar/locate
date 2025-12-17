import Foundation
import Testing
@testable import LocateCore

/// Test suite for case-sensitive search functionality
@Suite("Case Sensitive Search Tests")
struct CaseSensitiveSearchTests {

    @Test("Case-sensitive FTS search filters correctly")
    func caseSensitiveFTSSearch() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "README.txt", nameLower: "readme.txt", path: "/tmp/README.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "readme.txt", nameLower: "readme.txt", path: "/tmp/readme.txt", isDirectory: false, size: 20, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "ReadMe.txt", nameLower: "readme.txt", path: "/tmp/ReadMe.txt", isDirectory: false, size: 30, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Case-sensitive search for "README"
        let request = SearchRequest(query: "README", caseSensitive: true)
        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 1)
        #expect(results[0].name == "README.txt")
    }

    @Test("Case-insensitive search returns all matches")
    func caseInsensitiveSearch() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "Test.txt", nameLower: "test.txt", path: "/tmp/Test.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "TEST.txt", nameLower: "test.txt", path: "/tmp/TEST.txt", isDirectory: false, size: 20, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "test.txt", nameLower: "test.txt", path: "/tmp/test.txt", isDirectory: false, size: 30, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Case-insensitive search (default)
        let request = SearchRequest(query: "test", caseSensitive: false)
        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 3)
    }

    @Test("Case-sensitive regex search")
    func caseSensitiveRegexSearch() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "FileABC.txt", nameLower: "fileabc.txt", path: "/tmp/FileABC.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "fileabc.txt", nameLower: "fileabc.txt", path: "/tmp/fileabc.txt", isDirectory: false, size: 20, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "FILEABC.txt", nameLower: "fileabc.txt", path: "/tmp/FILEABC.txt", isDirectory: false, size: 30, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Case-sensitive regex search for uppercase pattern
        let request = SearchRequest(query: "File[A-Z]+", useRegex: true, caseSensitive: true)
        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 1)
        #expect(results[0].name == "FileABC.txt")
    }

    @Test("Case-insensitive regex search")
    func caseInsensitiveRegexSearch() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "Document.pdf", nameLower: "document.pdf", path: "/tmp/Document.pdf", isDirectory: false, size: 100, fileExtension: "pdf", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "DOCUMENT.pdf", nameLower: "document.pdf", path: "/tmp/DOCUMENT.pdf", isDirectory: false, size: 200, fileExtension: "pdf", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "document.pdf", nameLower: "document.pdf", path: "/tmp/document.pdf", isDirectory: false, size: 300, fileExtension: "pdf", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Case-insensitive regex search
        let request = SearchRequest(query: "DOCUMENT", useRegex: true, caseSensitive: false)
        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 3)
    }

    @Test("Case-sensitive search with exact word match")
    func caseSensitiveExactWordMatch() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "MyFile.txt", nameLower: "myfile.txt", path: "/tmp/MyFile.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "myfile.txt", nameLower: "myfile.txt", path: "/tmp/myfile.txt", isDirectory: false, size: 20, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "MYFILE.txt", nameLower: "myfile.txt", path: "/tmp/MYFILE.txt", isDirectory: false, size: 30, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Case-sensitive search for exact word "MyFile"
        let request = SearchRequest(query: "MyFile", caseSensitive: true)
        let results = try await manager.search(request, limit: 10)

        // FTS will find all matches, but case-sensitive filter keeps only exact match
        #expect(results.count == 1)
        #expect(results[0].name == "MyFile.txt")
    }

    @Test("Mixed case regex with anchors")
    func mixedCaseRegexWithAnchors() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "StartFile.txt", nameLower: "startfile.txt", path: "/tmp/StartFile.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "startfile.txt", nameLower: "startfile.txt", path: "/tmp/startfile.txt", isDirectory: false, size: 20, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "MyStartFile.txt", nameLower: "mystartfile.txt", path: "/tmp/MyStartFile.txt", isDirectory: false, size: 30, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Case-sensitive regex starting with "Start"
        let request = SearchRequest(query: "^Start", useRegex: true, caseSensitive: true)
        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 1)
        #expect(results[0].name == "StartFile.txt")
    }

    @Test("Unicode case sensitivity")
    func unicodeCaseSensitivity() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "Café.txt", nameLower: "café.txt", path: "/tmp/Café.txt", isDirectory: false, size: 10, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "café.txt", nameLower: "café.txt", path: "/tmp/café.txt", isDirectory: false, size: 20, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "CAFÉ.txt", nameLower: "café.txt", path: "/tmp/CAFÉ.txt", isDirectory: false, size: 30, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Case-sensitive search with Unicode
        let request = SearchRequest(query: "Café", caseSensitive: true)
        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 1)
        #expect(results[0].name == "Café.txt")
    }
}
