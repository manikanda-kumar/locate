import Foundation
import AppKit

public struct PermissionsHelper {
    public static func hasFullDiskAccess() -> Bool {
        // Test by trying to read a protected directory
        let testPaths = [
            NSHomeDirectory() + "/Library/Safari/History.db",
            NSHomeDirectory() + "/Library/Mail",
            "/Library/Application Support/com.apple.TCC/TCC.db"
        ]

        for path in testPaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.isReadableFile(atPath: url.path) {
                return true
            }
        }

        return false
    }

    public static func openSystemPreferences() {
        // Open System Settings > Privacy & Security > Full Disk Access
        if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
        } else {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
        }
    }

    public static func canAccessPath(_ path: String) -> Bool {
        let fm = FileManager.default
        return fm.isReadableFile(atPath: path)
    }
}
