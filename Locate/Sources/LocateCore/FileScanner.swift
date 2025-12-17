import Foundation

public struct FileScanner: @unchecked Sendable {
    private enum ScanError: Error {
        case enumeratorUnavailable(String)
    }

    private let fileManager: FileManager
    private let exclusions: Set<String>

    public init(fileManager: FileManager = .default, exclusions: [String] = ["Library", ".git", "node_modules"]) {
        self.fileManager = fileManager
        self.exclusions = Set(exclusions)
    }

    public func scan(rootPath: String, rootID: Int64) async throws -> [DatabaseManager.IndexedEntry] {
        let stream = try streamEntries(rootPath: rootPath, rootID: rootID)
        var results: [DatabaseManager.IndexedEntry] = []
        results.reserveCapacity(1024)

        for try await entry in stream {
            results.append(entry)
        }

        return results
    }

    public func streamEntries(rootPath: String, rootID: Int64) throws -> AsyncThrowingStream<DatabaseManager.IndexedEntry, Error> {
        let rootURL = URL(fileURLWithPath: rootPath)
        let resourceKeys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .creationDateKey,
            .attributeModificationDateKey
        ]

        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsPackageDescendants, .skipsHiddenFiles]
        ) else {
            throw ScanError.enumeratorUnavailable(rootPath)
        }

        let rootComponents = rootURL.standardizedFileURL.pathComponents

        return AsyncThrowingStream { continuation in
            for case let item as URL in enumerator {
                let standardized = item.standardizedFileURL
                if shouldSkip(standardized, rootComponents: rootComponents) {
                    enumerator.skipDescendants()
                    continue
                }

                do {
                    let values = try standardized.resourceValues(forKeys: resourceKeys)
                    let isDirectory = values.isDirectory ?? false
                    let size = values.fileSize.map(Int64.init)
                    let modifiedAt = values.contentModificationDate.map { Int64($0.timeIntervalSince1970) }
                    let createdAt = values.creationDate.map { Int64($0.timeIntervalSince1970) }
                    let accessedAt = values.attributeModificationDate.map { Int64($0.timeIntervalSince1970) }

                    let name = standardized.lastPathComponent
                    let ext = standardized.pathExtension.isEmpty ? nil : standardized.pathExtension.lowercased()

                    let entry = DatabaseManager.IndexedEntry(
                        rootID: rootID,
                        parentID: nil,
                        name: name,
                        nameLower: name.lowercased(),
                        path: standardized.path,
                        isDirectory: isDirectory,
                        size: size,
                        fileExtension: ext,
                        modifiedAt: modifiedAt,
                        createdAt: createdAt,
                        accessedAt: accessedAt,
                        attributes: 0
                    )
                    continuation.yield(entry)
                } catch {
                    Log.error("FileScanner failed for \(standardized.path): \(error.localizedDescription)")
                    continuation.yield(with: .failure(error))
                    break
                }
            }
            continuation.finish()
        }
    }

    private func shouldSkip(_ url: URL, rootComponents: [String]) -> Bool {
        let name = url.lastPathComponent
        let isTopLevel = url.standardizedFileURL.pathComponents.dropFirst(rootComponents.count).first == name

        if name.hasPrefix(".") {
            return true
        }

        if exclusions.contains(name), isTopLevel {
            return true
        }

        return false
    }
}
