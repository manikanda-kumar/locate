import Foundation
import LocateCore

@main
enum LocateCLI {
    static func main() async {
        do {
            try await run()
        } catch {
            fputs("Error: \(error)\n", stderr)
            Foundation.exit(EXIT_FAILURE)
        }
    }
}

private func run() async throws {
    var args = Array(CommandLine.arguments.dropFirst())
    guard let commandName = args.first else {
        printUsage()
        return
    }
    args.removeFirst()

    switch commandName {
    case "build-index":
        let options = try parseBuildIndexOptions(args)
        try await runBuildIndex(options: options)
    case "search":
        let options = try parseSearchOptions(args)
        try await runSearch(options: options)
    case "help", "-h", "--help":
        printUsage()
    default:
        fputs("Unknown command: \(commandName)\n", stderr)
        printUsage()
        Foundation.exit(EXIT_FAILURE)
    }
}

private func runBuildIndex(options: BuildIndexOptions) async throws {
    let manager = try DatabaseManager(path: options.databasePath)
    try await manager.rebuildIndex(for: options.rootPath, batchSize: options.batchSize) { event in
        switch event {
        case .batchInserted(let count, let files, let dirs):
            print("Inserted batch: count=\(count) files=\(files) dirs=\(dirs)")
        case .completed(let files, let dirs):
            print("Completed indexing: files=\(files) dirs=\(dirs)")
        }
    }
}

private func runSearch(options: SearchOptions) async throws {
    let manager = try DatabaseManager(path: options.databasePath)
    let request = SearchRequest(
        query: options.query,
        extensions: options.extensions,
        minSize: options.minSize,
        maxSize: options.maxSize,
        modifiedAfter: options.modifiedAfter,
        modifiedBefore: options.modifiedBefore
    )
    let results = try await manager.search(request, limit: options.limit)
    for record in results {
        print(record.path)
    }
}

private func parseBuildIndexOptions(_ args: [String]) throws -> BuildIndexOptions {
    var rootPath: String?
    var batchSize = 500
    var databasePath = defaultDatabasePath()
    var iterator = args.makeIterator()
    while let token = iterator.next() {
        switch token {
        case "--batch":
            guard let value = iterator.next(), let parsed = Int(value), parsed > 0 else {
                throw CLIError.invalidValue("--batch expects a positive integer")
            }
            batchSize = parsed
        case "--db":
            guard let value = iterator.next() else { throw CLIError.missingValue("--db") }
            databasePath = expandPath(value)
        default:
            if rootPath == nil {
                rootPath = expandPath(token)
            } else {
                throw CLIError.unexpectedArgument(token)
            }
        }
    }
    guard let rootPath else { throw CLIError.missingValue("rootPath") }
    try ensureParentDirectory(for: databasePath)
    return BuildIndexOptions(rootPath: rootPath, batchSize: batchSize, databasePath: databasePath)
}

private func parseSearchOptions(_ args: [String]) throws -> SearchOptions {
    var query: String?
    var extensions: [String]?
    var limit = 50
    var minSize: Int64?
    var maxSize: Int64?
    var modifiedAfter: Int64?
    var modifiedBefore: Int64?
    var databasePath = defaultDatabasePath()

    var iterator = args.makeIterator()
    while let token = iterator.next() {
        switch token {
        case "--ext":
            guard let value = iterator.next() else { throw CLIError.missingValue("--ext") }
            extensions = value.split(separator: ",").map { String($0).lowercased() }.filter { !$0.isEmpty }
        case "--limit":
            guard let value = iterator.next(), let parsed = Int(value), parsed > 0 else {
                throw CLIError.invalidValue("--limit expects a positive integer")
            }
            limit = parsed
        case "--min-size":
            minSize = try parseInt64(token: "--min-size", value: iterator.next())
        case "--max-size":
            maxSize = try parseInt64(token: "--max-size", value: iterator.next())
        case "--modified-after":
            modifiedAfter = try parseInt64(token: "--modified-after", value: iterator.next())
        case "--modified-before":
            modifiedBefore = try parseInt64(token: "--modified-before", value: iterator.next())
        case "--db":
            guard let value = iterator.next() else { throw CLIError.missingValue("--db") }
            databasePath = expandPath(value)
        default:
            if query == nil {
                query = token
            } else {
                throw CLIError.unexpectedArgument(token)
            }
        }
    }

    guard let query else { throw CLIError.missingValue("query") }
    try ensureParentDirectory(for: databasePath)
    return SearchOptions(
        query: query,
        extensions: extensions,
        limit: limit,
        minSize: minSize,
        maxSize: maxSize,
        modifiedAfter: modifiedAfter,
        modifiedBefore: modifiedBefore,
        databasePath: databasePath
    )
}

private func ensureParentDirectory(for path: String) throws {
    let url = URL(fileURLWithPath: path)
    let dir = url.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
}

private func parseInt64(token: String, value: String?) throws -> Int64 {
    guard let value, let parsed = Int64(value) else {
        throw CLIError.invalidValue("\(token) expects an integer value")
    }
    return parsed
}

private func expandPath(_ path: String) -> String {
    (path as NSString).expandingTildeInPath
}

private func defaultDatabasePath() -> String {
    let home = FileManager.default.homeDirectoryForCurrentUser
    return home.appendingPathComponent(".locate").appendingPathComponent("locate.sqlite").path
}

private func printUsage() {
    let usage = """
    LocateCLI
    Commands:
      build-index <rootPath> [--db <path>] [--batch <N>]
          Builds or rebuilds the index for the given root.

      search <query> [--db <path>] [--ext csv,list] [--limit N] [--min-size N] [--max-size N] [--modified-after epoch] [--modified-before epoch]
          Runs a search and prints matching file paths.
    """
    print(usage)
}

enum CLIError: Error, CustomStringConvertible {
    case missingValue(String)
    case invalidValue(String)
    case unexpectedArgument(String)

    var description: String {
        switch self {
        case .missingValue(let key): return "Missing value for \(key)"
        case .invalidValue(let message): return message
        case .unexpectedArgument(let arg): return "Unexpected argument: \(arg)"
        }
    }
}

struct BuildIndexOptions {
    let rootPath: String
    let batchSize: Int
    let databasePath: String
}

struct SearchOptions {
    let query: String
    let extensions: [String]?
    let limit: Int
    let minSize: Int64?
    let maxSize: Int64?
    let modifiedAfter: Int64?
    let modifiedBefore: Int64?
    let databasePath: String
}

