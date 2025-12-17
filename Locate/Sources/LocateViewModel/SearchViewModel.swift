import Foundation
import AppKit
import LocateCore
import Observation

@MainActor
@Observable
public final class SearchViewModel {
    public enum FileTypeFilter: String, CaseIterable, Identifiable, Sendable {
        case all
        case documents
        case images
        case code

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .all: return "All"
            case .documents: return "Documents"
            case .images: return "Images"
            case .code: return "Code"
            }
        }

        public var extensions: [String]? {
            switch self {
            case .all:
                return nil
            case .documents:
                return ["pdf", "doc", "docx", "txt", "rtf", "pages"]
            case .images:
                return ["png", "jpg", "jpeg", "gif", "tiff", "heic", "webp"]
            case .code:
                return ["swift", "m", "mm", "h", "hpp", "cpp", "c", "rs", "py", "js", "ts", "tsx", "json", "yaml", "yml", "md"]
            }
        }
    }

    public enum SizePreset: String, CaseIterable, Identifiable, Sendable {
        case any
        case over1MB
        case over10MB
        case over100MB

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .any: return "Any Size"
            case .over1MB: return "> 1 MB"
            case .over10MB: return "> 10 MB"
            case .over100MB: return "> 100 MB"
            }
        }

        public var minimumBytes: Int64? {
            switch self {
            case .any: return nil
            case .over1MB: return 1_000_000
            case .over10MB: return 10_000_000
            case .over100MB: return 100_000_000
            }
        }
    }

    public enum DatePreset: String, CaseIterable, Identifiable, Sendable {
        case any
        case last24Hours
        case last7Days
        case last30Days

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .any: return "Any Date"
            case .last24Hours: return "Last 24h"
            case .last7Days: return "Last 7 days"
            case .last30Days: return "Last 30 days"
            }
        }

        public var modifiedAfter: Int64? {
            let now = Date()
            switch self {
            case .any:
                return nil
            case .last24Hours:
                return Int64(now.addingTimeInterval(-86_400).timeIntervalSince1970)
            case .last7Days:
                return Int64(now.addingTimeInterval(-604_800).timeIntervalSince1970)
            case .last30Days:
                return Int64(now.addingTimeInterval(-2_592_000).timeIntervalSince1970)
            }
        }
    }

    public enum IndexStatus: Equatable {
        case unknown
        case notIndexed
        case indexed(lastIndexed: Date?, fileCount: Int64, dirCount: Int64)
    }

    public struct SearchResult: Identifiable, Hashable {
        let record: FileRecord

        public var id: Int64 { record.id }
        public var url: URL { URL(filePath: record.path) }
        public var isDirectory: Bool { record.isDirectory }
        public var name: String { record.name }
        public var size: Int64? { record.size }

        public var modifiedDate: Date? {
            guard let modifiedAt = record.modifiedAt else { return nil }
            return Date(timeIntervalSince1970: TimeInterval(modifiedAt))
        }

        public var parentPath: String {
            url.deletingLastPathComponent().path(percentEncoded: false)
        }
    }

    public var query: String = ""
    public var fileType: FileTypeFilter = .all
    public var sizePreset: SizePreset = .any
    public var datePreset: DatePreset = .any
    public var useRegex = false
    public var caseSensitive = false
    public var results: [SearchResult] = []
    public var selection: Set<SearchResult.ID> = []
    public var isSearching = false
    public var isIndexing = false
    public var indexingProgress: String?
    public var lastError: String?
    public var regexValidationError: String?
    public private(set) var indexStatus: IndexStatus = .unknown

    private let databaseURL: URL
    private var databaseManager: DatabaseManager?
    private var hasLoaded = false
    private var searchTask: Task<Void, Never>?
    private var reindexTimer: Task<Void, Never>?

    public init(databaseURL: URL = AppPaths.defaultDatabaseURL()) {
        self.databaseURL = databaseURL
    }

    public func load() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refreshIndexStatus()
        startAutoReindexIfNeeded()
    }

    public func refreshIndexStatus() async {
        do {
            let manager = try ensureManager()
            let roots = try await manager.fetchRoots()
            guard !roots.isEmpty else {
                indexStatus = .notIndexed
                return
            }
            let totalFiles = roots.reduce(into: Int64(0)) { $0 += $1.fileCount }
            let totalDirs = roots.reduce(into: Int64(0)) { $0 += $1.dirCount }
            let latest = roots.compactMap(\.lastIndexed).max().map { Date(timeIntervalSince1970: TimeInterval($0)) }
            indexStatus = .indexed(lastIndexed: latest, fileCount: totalFiles, dirCount: totalDirs)
        } catch {
            indexStatus = .notIndexed
            lastError = error.localizedDescription
        }
    }

    public func clearQuery() {
        query = ""
        results = []
        lastError = nil
        selection.removeAll()
    }

    public func scheduleSearch(immediate: Bool = false) {
        searchTask?.cancel()
        let nextQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        searchTask = Task { [weak self] in
            guard let self else { return }
            if !immediate {
                try? await Task.sleep(for: .milliseconds(220))
            }
            guard !Task.isCancelled else { return }
            await self.runSearch(with: nextQuery)
        }
    }

    public var statusDescription: String {
        switch indexStatus {
        case .unknown:
            return "Loading index status…"
        case .notIndexed:
            return "No index yet. Build an index to start searching."
        case .indexed(let lastIndexed, let fileCount, let dirCount):
            var parts: [String] = []
            parts.append("\(fileCount) files")
            parts.append("\(dirCount) folders")
            if let lastIndexed {
                let relative = Formatting.relativeDateFormatter.localizedString(for: lastIndexed, relativeTo: Date())
                parts.append("updated \(relative)")
            }
            return parts.joined(separator: " · ")
        }
    }

    public var hasIndex: Bool {
        if case .indexed = indexStatus {
            return true
        }
        return false
    }

    public func openFile(_ result: SearchResult) {
        let url = result.url
        let opened = NSWorkspace.shared.open(url)
        if !opened {
            lastError = "Failed to open '\(result.name)'"
        }
    }

    public func revealInFinder(_ result: SearchResult) {
        NSWorkspace.shared.selectFile(result.url.path(percentEncoded: false), inFileViewerRootedAtPath: "")
    }

    public func copyPath(_ result: SearchResult) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(result.url.path(percentEncoded: false), forType: .string)
    }

    public func rebuildIndex(rootPath: String? = nil) async {
        let targetPath = rootPath ?? FileManager.default.homeDirectoryForCurrentUser.path(percentEncoded: false)
        isIndexing = true
        indexingProgress = "Starting indexing…"
        lastError = nil
        do {
            let manager = try ensureManager()
            let scanner = FileScanner(exclusions: AppSettings.shared.exclusionPatterns)
            try await manager.rebuildIndex(for: targetPath, scanner: scanner, batchSize: 500) { [weak self] progress in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    switch progress {
                    case .batchInserted(_, let files, let dirs):
                        self.indexingProgress = "Indexed \(files) files, \(dirs) folders…"
                    case .completed(let files, let dirs):
                        self.indexingProgress = "Completed: \(files) files, \(dirs) folders"
                    }
                }
            }
            await refreshIndexStatus()
            indexingProgress = nil
        } catch {
            lastError = "Indexing failed: \(error.localizedDescription)"
            indexingProgress = nil
        }
        isIndexing = false
    }

    public func rebuildIndexForAllFolders() async {
        let folders = AppSettings.shared.indexedFolders
        guard !folders.isEmpty else {
            lastError = "No folders configured. Add folders in Settings."
            return
        }

        isIndexing = true
        indexingProgress = "Starting indexing for \(folders.count) folder(s)…"
        lastError = nil

        var totalFiles: Int64 = 0
        var totalDirs: Int64 = 0

        do {
            let manager = try ensureManager()
            let scanner = FileScanner(exclusions: AppSettings.shared.exclusionPatterns)

            for (index, folder) in folders.enumerated() {
                indexingProgress = "Indexing folder \(index + 1)/\(folders.count): \(folder)"

                try await manager.rebuildIndex(for: folder, scanner: scanner, batchSize: 500) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        switch progress {
                        case .batchInserted(_, let files, let dirs):
                            self.indexingProgress = "Folder \(index + 1)/\(folders.count): \(files) files, \(dirs) folders…"
                        case .completed(let files, let dirs):
                            totalFiles += files
                            totalDirs += dirs
                        }
                    }
                }
            }

            await refreshIndexStatus()
            indexingProgress = "Completed: \(totalFiles) files, \(totalDirs) folders"

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                self.indexingProgress = nil
            }
        } catch {
            lastError = "Indexing failed: \(error.localizedDescription)"
            indexingProgress = nil
        }

        isIndexing = false
    }

    public func startAutoReindexIfNeeded() {
        reindexTimer?.cancel()

        guard AppSettings.shared.autoReindex else { return }

        let interval = AppSettings.shared.reindexIntervalHours * 3600
        reindexTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { break }
                guard let self, !self.isIndexing else { continue }
                await self.rebuildIndexForAllFolders()
            }
        }
    }

    public func stopAutoReindex() {
        reindexTimer?.cancel()
        reindexTimer = nil
    }

    private func ensureManager() throws -> DatabaseManager {
        if let databaseManager {
            return databaseManager
        }
        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let manager = try DatabaseManager(path: databaseURL.path)
        databaseManager = manager
        return manager
    }

    private func runSearch(with text: String) async {
        guard !text.isEmpty else {
            results = []
            lastError = nil
            selection.removeAll()
            return
        }
        isSearching = true
        do {
            let manager = try ensureManager()
            let request = buildRequest(for: text)
            let records = try await manager.search(request, limit: 200)
            results = records.map(SearchResult.init)
            lastError = nil
        } catch {
            results = []
            lastError = error.localizedDescription
        }
        isSearching = false
    }

    private func buildRequest(for text: String) -> SearchRequest {
        SearchRequest(
            query: text,
            extensions: fileType.extensions,
            minSize: sizePreset.minimumBytes,
            maxSize: nil,
            modifiedAfter: datePreset.modifiedAfter,
            modifiedBefore: nil,
            useRegex: useRegex,
            caseSensitive: caseSensitive
        )
    }

    public func validateRegex() {
        guard useRegex, !query.isEmpty else {
            regexValidationError = nil
            return
        }
        do {
            _ = try NSRegularExpression(pattern: query, options: [])
            regexValidationError = nil
        } catch {
            regexValidationError = "Invalid regex: \(error.localizedDescription)"
        }
    }
}
