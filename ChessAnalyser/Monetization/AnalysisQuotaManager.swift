import Foundation

/// Tracks the one free analysis per calendar day.
/// "Day" is defined by the user's current timezone (Calendar.current), resetting at local midnight.
@MainActor
@Observable
final class AnalysisQuotaManager {
    private let lastUsedKey = "analysis.quota.lastUsedDate"
    private let calendar = Calendar.current

    var lastUsedDate: Date?

    init() {
        let ts = UserDefaults.standard.double(forKey: lastUsedKey)
        lastUsedDate = ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }

    /// True if the user has NOT yet used their free daily analysis today (local timezone).
    var hasFreeToday: Bool {
        guard let lastUsedDate else { return true }
        return !calendar.isDateInToday(lastUsedDate)
    }

    /// Record that the free analysis was consumed now.
    func consumeFree() {
        let now = Date()
        lastUsedDate = now
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastUsedKey)
    }

    /// Time interval until the quota resets (local midnight tomorrow).
    var timeUntilReset: TimeInterval {
        guard let tomorrow = calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else {
            return 0
        }
        return tomorrow.timeIntervalSinceNow
    }

    /// Human-readable countdown, e.g. "Resets in 4h 32m".
    var resetCountdownText: String {
        let secs = Int(timeUntilReset)
        guard secs > 0 else { return "Resets soon" }
        let hours = secs / 3600
        let minutes = (secs % 3600) / 60
        if hours > 0 { return "Resets in \(hours)h \(minutes)m" }
        return "Resets in \(minutes)m"
    }

    #if DEBUG
    func resetForDebug() {
        lastUsedDate = nil
        UserDefaults.standard.removeObject(forKey: lastUsedKey)
    }
    #endif
}
