import Foundation
import Testing
@testable import LocateViewModel

/// Test suite for SearchViewModel functionality
@Suite("SearchViewModel Tests")
@MainActor
struct SearchViewModelTests {

    @Test("Regex validation succeeds for valid pattern")
    func regexValidationSucceedsForValidPattern() async throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".db")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let model = SearchViewModel(databaseURL: tempURL)
        model.useRegex = true
        model.query = "test\\d+"

        model.validateRegex()

        #expect(model.regexValidationError == nil)
    }

    @Test("Regex validation fails for invalid pattern")
    func regexValidationFailsForInvalidPattern() async throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".db")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let model = SearchViewModel(databaseURL: tempURL)
        model.useRegex = true
        model.query = "[unclosed"

        model.validateRegex()

        #expect(model.regexValidationError != nil)
        #expect(model.regexValidationError?.contains("Invalid regex") == true)
    }

    @Test("Regex validation clears error when regex mode is disabled")
    func regexValidationClearsErrorWhenDisabled() async throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".db")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let model = SearchViewModel(databaseURL: tempURL)
        model.useRegex = true
        model.query = "[invalid"

        model.validateRegex()
        #expect(model.regexValidationError != nil)

        model.useRegex = false
        model.validateRegex()

        #expect(model.regexValidationError == nil)
    }

    @Test("Regex validation clears error for empty query")
    func regexValidationClearsErrorForEmptyQuery() async throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".db")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let model = SearchViewModel(databaseURL: tempURL)
        model.useRegex = true
        model.query = "[invalid"

        model.validateRegex()
        #expect(model.regexValidationError != nil)

        model.query = ""
        model.validateRegex()

        #expect(model.regexValidationError == nil)
    }

    @Test("Regex validation handles complex patterns")
    func regexValidationHandlesComplexPatterns() async throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".db")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let model = SearchViewModel(databaseURL: tempURL)
        model.useRegex = true

        // Test various valid complex patterns
        let validPatterns = [
            "^[A-Z][a-z]+$",
            "\\d{2,4}",
            "(?:foo|bar)",
            "[A-Za-z0-9_.-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}",
            "^(?=.*[a-z])(?=.*[A-Z]).+$"
        ]

        for pattern in validPatterns {
            model.query = pattern
            model.validateRegex()
            #expect(model.regexValidationError == nil, "Pattern should be valid: \(pattern)")
        }
    }

    @Test("Regex validation detects various invalid patterns")
    func regexValidationDetectsInvalidPatterns() async throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".db")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let model = SearchViewModel(databaseURL: tempURL)
        model.useRegex = true

        // Test various invalid patterns
        let invalidPatterns = [
            "[unclosed",
            "(?:unclosed",
            "**",
            "(?P<invalid>",
            "\\k<notexist>"
        ]

        for pattern in invalidPatterns {
            model.query = pattern
            model.validateRegex()
            #expect(model.regexValidationError != nil, "Pattern should be invalid: \(pattern)")
        }
    }

    @Test("FileType filter extensions are correct")
    func fileTypeFilterExtensions() {
        #expect(SearchViewModel.FileTypeFilter.all.extensions == nil)
        #expect(SearchViewModel.FileTypeFilter.documents.extensions?.contains("pdf") == true)
        #expect(SearchViewModel.FileTypeFilter.images.extensions?.contains("png") == true)
        #expect(SearchViewModel.FileTypeFilter.code.extensions?.contains("swift") == true)
    }

    @Test("Size preset values are correct")
    func sizePresetValues() {
        #expect(SearchViewModel.SizePreset.any.minimumBytes == nil)
        #expect(SearchViewModel.SizePreset.over1MB.minimumBytes == 1_000_000)
        #expect(SearchViewModel.SizePreset.over10MB.minimumBytes == 10_000_000)
        #expect(SearchViewModel.SizePreset.over100MB.minimumBytes == 100_000_000)
    }

    @Test("Date preset calculates correct timestamps")
    func datePresetTimestamps() {
        let now = Date()
        let twentyFourHoursAgo = now.addingTimeInterval(-86_400)
        let sevenDaysAgo = now.addingTimeInterval(-604_800)
        let thirtyDaysAgo = now.addingTimeInterval(-2_592_000)

        #expect(SearchViewModel.DatePreset.any.modifiedAfter == nil)

        if let last24 = SearchViewModel.DatePreset.last24Hours.modifiedAfter {
            let difference = abs(Double(last24) - twentyFourHoursAgo.timeIntervalSince1970)
            #expect(difference < 2, "Last 24 hours should be within 2 seconds of expected")
        } else {
            Issue.record("Last 24 hours preset should return a timestamp")
        }

        if let last7 = SearchViewModel.DatePreset.last7Days.modifiedAfter {
            let difference = abs(Double(last7) - sevenDaysAgo.timeIntervalSince1970)
            #expect(difference < 2, "Last 7 days should be within 2 seconds of expected")
        } else {
            Issue.record("Last 7 days preset should return a timestamp")
        }

        if let last30 = SearchViewModel.DatePreset.last30Days.modifiedAfter {
            let difference = abs(Double(last30) - thirtyDaysAgo.timeIntervalSince1970)
            #expect(difference < 2, "Last 30 days should be within 2 seconds of expected")
        } else {
            Issue.record("Last 30 days preset should return a timestamp")
        }
    }

    @Test("Clear query resets all relevant state")
    func clearQueryResetsState() async throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".db")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let model = SearchViewModel(databaseURL: tempURL)
        model.query = "test"
        model.lastError = "Some error"
        model.selection.insert(123)

        model.clearQuery()

        #expect(model.query.isEmpty)
        #expect(model.results.isEmpty)
        #expect(model.lastError == nil)
        #expect(model.selection.isEmpty)
    }

    @Test("Index status computed correctly for no index")
    func indexStatusNoIndex() async throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".db")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let model = SearchViewModel(databaseURL: tempURL)
        await model.load()

        #expect(model.hasIndex == false)
        #expect(model.statusDescription.contains("No index"))
    }
}
