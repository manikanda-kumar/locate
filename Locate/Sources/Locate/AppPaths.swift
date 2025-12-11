import Foundation

enum AppPaths {
    static func defaultDatabaseURL() -> URL {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let databaseDirectory = homeDirectory.appending(path: ".locate", directoryHint: .isDirectory)
        return databaseDirectory.appending(path: "locate.sqlite")
    }
}
