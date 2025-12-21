import Foundation
import os

public enum Log {
    // Use os.Logger where available, otherwise fall back to older logging.
    #if canImport(os)
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    private static let modernLogger = Logger(subsystem: "com.locate.core", category: "core")
    #endif

    public static func info(_ message: String) {
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            #if canImport(os)
            // Use string interpolation which works with os.Logger's OSLogMessage
            modernLogger.log(level: .info, "\(message, privacy: .private(mask: .hash))")
            #else
            NSLog("INFO: %@", message)
            #endif
        } else {
            // Fallback for older platforms
            NSLog("INFO: %@", message)
        }
    }

    public static func publicInfo(_ message: String) {
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            #if canImport(os)
            modernLogger.log(level: .info, "\(message, privacy: .public)")
            #else
            NSLog("INFO: %@", message)
            #endif
        } else {
            NSLog("INFO: %@", message)
        }
    }

    public static func error(_ message: String) {
        if #available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *) {
            #if canImport(os)
            modernLogger.log(level: .error, "\(message, privacy: .private(mask: .hash))")
            #else
            NSLog("ERROR: %@", message)
            #endif
        } else {
            NSLog("ERROR: %@", message)
        }
    }
}
