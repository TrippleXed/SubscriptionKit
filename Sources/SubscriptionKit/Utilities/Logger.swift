import Foundation
import os.log

/// Internal logger for SubscriptionKit
enum Logger {

    private static let subsystem = "com.subscriptionkit"
    private static let logger = os.Logger(subsystem: subsystem, category: "SubscriptionKit")

    /// Log level configuration
    public static var logLevel: LogLevel = .info

    /// Log levels
    public enum LogLevel: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        case none = 4

        public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard logLevel <= .debug else { return }
        let fileName = (file as NSString).lastPathComponent
        logger.debug("[\(fileName):\(line)] \(message)")
    }

    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard logLevel <= .info else { return }
        logger.info("\(message)")
    }

    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard logLevel <= .warning else { return }
        logger.warning("⚠️ \(message)")
    }

    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard logLevel <= .error else { return }
        let fileName = (file as NSString).lastPathComponent
        logger.error("❌ [\(fileName):\(line)] \(message)")
    }
}
