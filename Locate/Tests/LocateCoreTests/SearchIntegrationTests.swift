import Foundation
import Testing
@testable import LocateCore

/// Integration tests for complete search scenarios
@Suite("Search Integration Tests")
struct SearchIntegrationTests {

    @Test("Complete regex search with all filters")
    func completeRegexSearchWithAllFilters() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        // Create a realistic file set
        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "Report_2024_Q1.pdf", nameLower: "report_2024_q1.pdf", path: "/tmp/Report_2024_Q1.pdf", isDirectory: false, size: 1_500_000, fileExtension: "pdf", modifiedAt: 1704067200, createdAt: nil, accessedAt: nil, attributes: 0), // Jan 1, 2024
            .init(rootID: rootID, parentID: nil, name: "Report_2024_Q2.pdf", nameLower: "report_2024_q2.pdf", path: "/tmp/Report_2024_Q2.pdf", isDirectory: false, size: 2_000_000, fileExtension: "pdf", modifiedAt: 1712016000, createdAt: nil, accessedAt: nil, attributes: 0), // Apr 2, 2024
            .init(rootID: rootID, parentID: nil, name: "summary_2023.pdf", nameLower: "summary_2023.pdf", path: "/tmp/summary_2023.pdf", isDirectory: false, size: 500_000, fileExtension: "pdf", modifiedAt: 1672531200, createdAt: nil, accessedAt: nil, attributes: 0), // Jan 1, 2023
            .init(rootID: rootID, parentID: nil, name: "Report_2024_Q3.txt", nameLower: "report_2024_q3.txt", path: "/tmp/Report_2024_Q3.txt", isDirectory: false, size: 100_000, fileExtension: "txt", modifiedAt: 1719792000, createdAt: nil, accessedAt: nil, attributes: 0), // Jul 1, 2024
            .init(rootID: rootID, parentID: nil, name: "data.pdf", nameLower: "data.pdf", path: "/tmp/data.pdf", isDirectory: false, size: 3_000_000, fileExtension: "pdf", modifiedAt: 1704067200, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Search for Reports from 2024, PDF only, size between 1MB-2.5MB, modified after Jan 1, 2024
        let request = SearchRequest(
            query: "^Report_2024_Q[1-2]",
            extensions: ["pdf"],
            minSize: 1_000_000,
            maxSize: 2_500_000,
            modifiedAfter: 1704067200, // Jan 1, 2024
            modifiedBefore: nil,
            useRegex: true,
            caseSensitive: true
        )

        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.name.hasPrefix("Report_2024_") })
        #expect(results.allSatisfy { $0.fileExtension == "pdf" })
        #expect(results.allSatisfy { $0.size ?? 0 >= 1_000_000 && $0.size ?? 0 <= 2_500_000 })
    }

    @Test("Case-sensitive regex with Unicode and filters")
    func caseSensitiveRegexWithUnicodeAndFilters() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "Résumé_Final.pdf", nameLower: "résumé_final.pdf", path: "/tmp/Résumé_Final.pdf", isDirectory: false, size: 1_000_000, fileExtension: "pdf", modifiedAt: 1704067200, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "résumé_draft.pdf", nameLower: "résumé_draft.pdf", path: "/tmp/résumé_draft.pdf", isDirectory: false, size: 500_000, fileExtension: "pdf", modifiedAt: 1704067200, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "RÉSUMÉ_OLD.pdf", nameLower: "résumé_old.pdf", path: "/tmp/RÉSUMÉ_OLD.pdf", isDirectory: false, size: 2_000_000, fileExtension: "pdf", modifiedAt: 1704067200, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Case-sensitive regex for "Résumé" with capital R and accent
        let request = SearchRequest(
            query: "^Résumé",
            extensions: ["pdf"],
            minSize: 800_000,
            useRegex: true,
            caseSensitive: true
        )

        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 1)
        #expect(results[0].name == "Résumé_Final.pdf")
    }

    @Test("Performance test: Large dataset regex search")
    func performanceLargeDatasetRegexSearch() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        // Insert 1000 files
        var entries: [DatabaseManager.IndexedEntry] = []
        for i in 0..<1000 {
            let name = "file_\(i)_data.txt"
            entries.append(
                .init(
                    rootID: rootID,
                    parentID: nil,
                    name: name,
                    nameLower: name.lowercased(),
                    path: "/tmp/\(name)",
                    isDirectory: false,
                    size: Int64(i * 1000),
                    fileExtension: "txt",
                    modifiedAt: Int64(1704067200 + i),
                    createdAt: nil,
                    accessedAt: nil,
                    attributes: 0
                )
            )
        }
        try await manager.insertFiles(entries)

        // Regex search for files in range 100-199
        let startTime = Date()
        let request = SearchRequest(
            query: "^file_1[0-9]{2}_",
            useRegex: true
        )
        let results = try await manager.search(request, limit: 200)
        let duration = Date().timeIntervalSince(startTime)

        #expect(results.count == 100)
        #expect(duration < 1.0, "Search should complete within 1 second")
    }

    @Test("Edge case: Empty database search")
    func emptyDatabaseSearch() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)

        let request = SearchRequest(query: "test", useRegex: true)
        let results = try await manager.search(request, limit: 10)

        #expect(results.isEmpty)
    }

    @Test("Edge case: Search with no matches")
    func searchWithNoMatches() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "apple.txt", nameLower: "apple.txt", path: "/tmp/apple.txt", isDirectory: false, size: 100, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "banana.txt", nameLower: "banana.txt", path: "/tmp/banana.txt", isDirectory: false, size: 200, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        let request = SearchRequest(query: "orange", useRegex: false)
        let results = try await manager.search(request, limit: 10)

        #expect(results.isEmpty)
    }

    @Test("Combined FTS and filters stress test")
    func combinedFTSAndFiltersStressTest() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        // Create files ensuring we have test PDFs in the right size range
        var entries: [DatabaseManager.IndexedEntry] = []

        // Add test PDFs specifically
        for i in 0..<50 {
            let name = "test_file_\(i).pdf"
            entries.append(
                .init(
                    rootID: rootID,
                    parentID: nil,
                    name: name,
                    nameLower: name.lowercased(),
                    path: "/tmp/\(name)",
                    isDirectory: false,
                    size: Int64(150_000 + (i * 10_000)), // 150KB to 640KB
                    fileExtension: "pdf",
                    modifiedAt: Int64(1704067200 + (i * 3600)),
                    createdAt: nil,
                    accessedAt: nil,
                    attributes: 0
                )
            )
        }

        // Add other files to make it realistic
        let extensions = ["txt", "jpg", "doc"]
        let prefixes = ["demo", "sample", "example"]
        for i in 0..<150 {
            let prefix = prefixes[i % prefixes.count]
            let ext = extensions[i % extensions.count]
            let name = "\(prefix)_\(i).\(ext)"
            entries.append(
                .init(
                    rootID: rootID,
                    parentID: nil,
                    name: name,
                    nameLower: name.lowercased(),
                    path: "/tmp/\(name)",
                    isDirectory: false,
                    size: Int64((i + 1) * 10_000),
                    fileExtension: ext,
                    modifiedAt: Int64(1704067200 + (i * 3600)),
                    createdAt: nil,
                    accessedAt: nil,
                    attributes: 0
                )
            )
        }

        try await manager.insertFiles(entries)

        // Search for "test" files, PDF only, size 100KB-2000KB
        let request = SearchRequest(
            query: "test",
            extensions: ["pdf"],
            minSize: 100_000,
            maxSize: 2_000_000,
            modifiedAfter: nil,
            modifiedBefore: nil,
            useRegex: false,
            caseSensitive: false
        )

        let results = try await manager.search(request, limit: 50)

        #expect(!results.isEmpty, "Should find matching test PDF files")
        #expect(results.allSatisfy { $0.name.contains("test") })
        #expect(results.allSatisfy { $0.fileExtension == "pdf" })
        #expect(results.allSatisfy {
            let size = $0.size ?? 0
            return size >= 100_000 && size <= 2_000_000
        })
    }

    @Test("Wildcard patterns with various file types")
    func wildcardPatternsWithVariousFileTypes() async throws {
        let temp = try TempDB()
        defer { temp.cleanup() }

        let manager = try DatabaseManager(path: temp.url.path)
        let rootID = try await manager.addOrUpdateRoot(path: temp.url.deletingLastPathComponent().path)

        try await manager.insertFiles([
            .init(rootID: rootID, parentID: nil, name: "img001.jpg", nameLower: "img001.jpg", path: "/tmp/img001.jpg", isDirectory: false, size: 100_000, fileExtension: "jpg", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "img002.png", nameLower: "img002.png", path: "/tmp/img002.png", isDirectory: false, size: 200_000, fileExtension: "png", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "img003.gif", nameLower: "img003.gif", path: "/tmp/img003.gif", isDirectory: false, size: 50_000, fileExtension: "gif", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0),
            .init(rootID: rootID, parentID: nil, name: "document.txt", nameLower: "document.txt", path: "/tmp/document.txt", isDirectory: false, size: 10_000, fileExtension: "txt", modifiedAt: nil, createdAt: nil, accessedAt: nil, attributes: 0)
        ])

        // Search for img files with any extension
        let request = SearchRequest(
            query: "^img\\d+\\.",
            useRegex: true
        )

        let results = try await manager.search(request, limit: 10)

        #expect(results.count == 3)
        #expect(results.allSatisfy { $0.name.hasPrefix("img") })
    }
}
