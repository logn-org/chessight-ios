import Foundation
import FirebaseCrashlytics
import os

/// Centralized logging. Emits to:
///   1. os.Logger (visible in Console.app in real time — filter by subsystem
///      `com.logncomplexity.chessight` while TestFlight-testing on a device)
///   2. Firebase Crashlytics (breadcrumbs attached to any subsequent crash)
enum CrashLogger {

    private static let generalLogger     = Logger(subsystem: "com.logncomplexity.chessight", category: "general")
    private static let engineLogger      = Logger(subsystem: "com.logncomplexity.chessight", category: "engine")
    private static let networkLogger     = Logger(subsystem: "com.logncomplexity.chessight", category: "network")
    private static let monetizationLog   = Logger(subsystem: "com.logncomplexity.chessight", category: "monetization")
    private static let adsLog            = Logger(subsystem: "com.logncomplexity.chessight", category: "ads")

    /// Log a non-fatal error
    static func log(_ error: Error, context: String? = nil) {
        let msg = context.map { "\($0): \(error.localizedDescription)" } ?? error.localizedDescription
        generalLogger.error("\(msg, privacy: .public)")
        if let context = context {
            Crashlytics.crashlytics().log("\(context): \(error.localizedDescription)")
        }
        Crashlytics.crashlytics().record(error: error)
    }

    /// Log a message (breadcrumb for crash reports)
    static func log(_ message: String) {
        generalLogger.info("\(message, privacy: .public)")
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
        generalLogger.info("App Event: \(event, privacy: .public)")
        Crashlytics.crashlytics().log("App Event: \(event)")
    }

    /// Log engine-related events
    static func logEngine(_ message: String) {
        engineLogger.info("\(message, privacy: .public)")
        Crashlytics.crashlytics().log("Engine: \(message)")
    }

    /// Log network-related events
    static func logNetwork(_ message: String) {
        networkLogger.info("\(message, privacy: .public)")
        Crashlytics.crashlytics().log("Network: \(message)")
    }

    /// Log StoreKit / premium / paywall events
    static func logMonetization(_ message: String) {
        monetizationLog.info("\(message, privacy: .public)")
        Crashlytics.crashlytics().log("Monetization: \(message)")
    }

    static func logMonetizationError(_ error: Error, context: String? = nil) {
        let msg = context.map { "\($0): \(error.localizedDescription)" } ?? error.localizedDescription
        monetizationLog.error("\(msg, privacy: .public)")
        if let context = context {
            Crashlytics.crashlytics().log("Monetization: \(context): \(error.localizedDescription)")
        }
        Crashlytics.crashlytics().record(error: error)
    }

    /// Log AdMob / rewarded ad events
    static func logAds(_ message: String) {
        adsLog.info("\(message, privacy: .public)")
        Crashlytics.crashlytics().log("Ads: \(message)")
    }

    static func logAdsError(_ error: Error, context: String? = nil) {
        let msg = context.map { "\($0): \(error.localizedDescription)" } ?? error.localizedDescription
        adsLog.error("\(msg, privacy: .public)")
        if let context = context {
            Crashlytics.crashlytics().log("Ads: \(context): \(error.localizedDescription)")
        }
        Crashlytics.crashlytics().record(error: error)
    }
}
