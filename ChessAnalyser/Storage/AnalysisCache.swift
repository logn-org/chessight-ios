import Foundation
import CryptoKit

@Observable
final class AnalysisCache {
    /// Maximum number of games to keep on disk. Oldest analysis is evicted
    /// when a new one is saved past this cap. Change here to adjust.
    static let maxCachedGames: Int = 100

    /// Shared singleton so engine, view model, and views all see the same cache.
    static let shared = AnalysisCache()

    /// UserDefaults key for the set of game IDs that have been "paid for" (quota/ad)
    /// but whose analysis hasn't fully completed. Pending games are free to re-analyze
    /// so a user who navigates away mid-analysis doesn't lose their effort.
    private static let pendingKey = "analysis.cache.pending"

    private let cacheDirectory: URL
    private(set) var cachedGameIds: Set<String> = []
    private(set) var pendingGameIds: Set<String> = []

    init() {
        // Application Support: preserved when the user offloads the app,
        // removed when the app is fully uninstalled. Not exposed to the
        // Files app like Documents would be.
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        cacheDirectory = support.appendingPathComponent("analysis_cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Don't back this up to iCloud — it's a local speedup cache.
        var dir = cacheDirectory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)

        migrateLegacyIds()
        loadIndex()
        pendingGameIds = Set(UserDefaults.standard.stringArray(forKey: Self.pendingKey) ?? [])
    }

    // MARK: - Save / Load

    func save(_ analysis: GameAnalysis) {
        let fileName = sanitizeFilename(analysis.id)
        let url = cacheDirectory.appendingPathComponent("\(fileName).json")
        guard let data = try? JSONEncoder().encode(analysis) else { return }
        try? data.write(to: url)
        cachedGameIds.insert(analysis.id)
        clearPending(analysis.id) // analysis is now fully cached; no longer "pending"
        enforceCapacity()
    }

    func load(id: String) -> GameAnalysis? {
        let fileName = sanitizeFilename(id)
        let url = cacheDirectory.appendingPathComponent("\(fileName).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(GameAnalysis.self, from: data)
    }

    func isCached(_ id: String) -> Bool {
        cachedGameIds.contains(id)
    }

    func recentAnalyses(limit: Int = 20) -> [GameAnalysis] {
        var analyses: [GameAnalysis] = []
        let files = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []

        let sorted = files
            .filter { $0.pathExtension == "json" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return date1 > date2
            }
            .prefix(limit)

        for url in sorted {
            if let data = try? Data(contentsOf: url),
               let analysis = try? JSONDecoder().decode(GameAnalysis.self, from: data) {
                analyses.append(analysis)
            }
        }

        return analyses
    }

    func delete(id: String) {
        let fileName = sanitizeFilename(id)
        let url = cacheDirectory.appendingPathComponent("\(fileName).json")
        try? FileManager.default.removeItem(at: url)
        cachedGameIds.remove(id)
        clearPending(id)
    }

    func clearAll() {
        let files = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        for url in files where url.pathExtension == "json" {
            try? FileManager.default.removeItem(at: url)
        }
        cachedGameIds.removeAll()
        pendingGameIds.removeAll()
        persistPending()
    }

    // MARK: - Pending (paid but not yet completed)

    /// A game the user has "paid for" (via quota or rewarded ad) whose analysis
    /// hasn't completed yet. Re-opening a pending game runs analysis for free.
    func isPending(_ id: String) -> Bool { pendingGameIds.contains(id) }

    func markPending(_ id: String) {
        guard !pendingGameIds.contains(id) else { return }
        pendingGameIds.insert(id)
        persistPending()
    }

    func clearPending(_ id: String) {
        guard pendingGameIds.remove(id) != nil else { return }
        persistPending()
    }

    private func persistPending() {
        UserDefaults.standard.set(Array(pendingGameIds), forKey: Self.pendingKey)
    }

    // MARK: - Helpers

    private func loadIndex() {
        let files = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        cachedGameIds = Set(files.filter { $0.pathExtension == "json" }.map {
            $0.deletingPathExtension().lastPathComponent
        })
    }

    /// Enforce the cache cap by removing the oldest files (by modification date)
    /// until we're within the limit. Called after each save.
    private func enforceCapacity() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        )) ?? []

        let jsonFiles = files.filter { $0.pathExtension == "json" }
        guard jsonFiles.count > Self.maxCachedGames else { return }

        let oldestFirst = jsonFiles.sorted { a, b in
            let dateA = (try? a.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            let dateB = (try? b.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            return dateA < dateB
        }

        let evictionCount = jsonFiles.count - Self.maxCachedGames
        for url in oldestFirst.prefix(evictionCount) {
            try? FileManager.default.removeItem(at: url)
            cachedGameIds.remove(url.deletingPathExtension().lastPathComponent)
        }
    }

    /// One-time migration from the pre-SHA256 unstable Hasher IDs.
    /// Old filenames look like "game_<all-digits>"; new ones are "game_<16-hex-chars>".
    /// For each legacy file we recompute the SHA256-based ID from the stored PGN
    /// and rewrite the file under the new name so future lookups hit.
    private func migrateLegacyIds() {
        let flagKey = "analysis.cache.legacyCleanup.v1"
        guard !UserDefaults.standard.bool(forKey: flagKey) else { return }
        let files = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        for url in files where url.pathExtension == "json" {
            let name = url.deletingPathExtension().lastPathComponent
            guard name.hasPrefix("game_") else { continue }
            let suffix = String(name.dropFirst(5))
            // SHA256-derived IDs contain hex letters (a–f); legacy Hasher IDs are digits only.
            guard suffix.allSatisfy({ $0.isNumber }) else { continue }

            guard let data = try? Data(contentsOf: url),
                  var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let pgn = json["pgn"] as? String else {
                try? FileManager.default.removeItem(at: url)
                continue
            }

            let digest = SHA256.hash(data: Data(pgn.utf8))
            let hex = digest.compactMap { String(format: "%02x", $0) }.joined()
            let newId = "game_\(hex.prefix(16))"
            json["id"] = newId

            if let newData = try? JSONSerialization.data(withJSONObject: json) {
                let newURL = cacheDirectory.appendingPathComponent("\(sanitizeFilename(newId)).json")
                try? newData.write(to: newURL)
            }
            try? FileManager.default.removeItem(at: url)
        }
        UserDefaults.standard.set(true, forKey: flagKey)
    }

    private func sanitizeFilename(_ id: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return id.unicodeScalars.map { allowed.contains($0) ? String($0) : "_" }.joined()
    }
}
