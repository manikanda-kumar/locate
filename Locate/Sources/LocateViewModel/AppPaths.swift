import Foundation

public enum AppPaths {
    public static func defaultDatabaseURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let databaseDirectory = appSupport.appending(path: "Locate", directoryHint: .isDirectory)
        return databaseDirectory.appending(path: "locate.db")
    }
}
