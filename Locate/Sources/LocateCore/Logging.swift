import Foundation
import os

public enum Log {
    private static let logger = Logger(subsystem: "com.locate.core", category: "core")

    public static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    public static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
