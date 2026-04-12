import Foundation
import FirebaseCrashlytics

/// Centralized crash and error logging via Firebase Crashlytics.
enum CrashLogger {

    /// Log a non-fatal error
    static func log(_ error: Error, context: String? = nil) {
        if let context = context {
            Crashlytics.crashlytics().log("\(context): \(error.localizedDescription)")
        }
        Crashlytics.crashlytics().record(error: error)
    }

    /// Log a message (breadcrumb for crash reports)
    static func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    /// Set user identifier for crash reports
    static func setUser(_ userId: String) {
        Crashlytics.crashlytics().setUserID(userId)
    }

    /// Set custom key-value for crash reports
    static func setCustomValue(_ value: Any, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }

    /// Log app lifecycle events
    static func logAppEvent(_ event: String) {
        Crashlytics.crashlytics().log("App Event: \(event)")
    }

    /// Log engine-related events
    static func logEngine(_ message: String) {
        Crashlytics.crashlytics().log("Engine: \(message)")
    }

    /// Log network-related events
    static func logNetwork(_ message: String) {
        Crashlytics.crashlytics().log("Network: \(message)")
    }
}
