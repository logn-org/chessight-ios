import Foundation

/// Singleton engine manager — one Stockfish instance for the entire app session.
/// Never destroyed while the app is running. Shared across all analysis views.
@MainActor
final class EngineManager {
    static let shared = EngineManager()

    private(set) var stockfish: StockfishActor?
    private(set) var isInitialized = false
    private var initTask: Task<Void, Error>?

    /// Session cache: game ID → completed GameAnalysis
    private(set) var sessionGameCache: [String: GameAnalysis] = [:]

    /// Session cache: FEN → PositionAnalysis (reused across games)
    private(set) var sessionEvalCache: [String: PositionAnalysis] = [:]

    private init() {}

    /// Initialize the engine (only once per session). Safe to call multiple times.
    func ensureInitialized(config: EngineConfiguration) async throws {
        if isInitialized { return }

        // If already initializing, wait for it
        if let task = initTask {
            try await task.value
            return
        }

        initTask = Task {
            CrashLogger.logEngine("Initializing Stockfish (threads: \(config.threads), hash: \(config.hashMB)MB)")
            let actor = StockfishActor()
            try await actor.initialize(config: config)
            self.stockfish = actor
            self.isInitialized = true
            CrashLogger.logEngine("Stockfish initialized successfully")
        }

        do {
            try await initTask!.value
        } catch {
            CrashLogger.log(error, context: "Stockfish initialization failed")
            throw error
        }
    }

    /// Cache a completed game analysis for the session
    func cacheGameAnalysis(_ analysis: GameAnalysis) {
        sessionGameCache[analysis.id] = analysis
    }

    /// Remove cached game analysis (for re-evaluation)
    func removeCachedGameAnalysis(id: String) {
        sessionGameCache.removeValue(forKey: id)
    }

    /// Get cached game analysis
    func getCachedGameAnalysis(id: String) -> GameAnalysis? {
        sessionGameCache[id]
    }

    /// Cache a position eval
    func cacheEval(fen: String, result: PositionAnalysis) {
        // Use board-only FEN as key (ignore clocks)
        let key = String(fen.split(separator: " ").prefix(4).joined(separator: " "))
        sessionEvalCache[key] = result
    }

    /// Get cached position eval
    func getCachedEval(fen: String) -> PositionAnalysis? {
        let key = String(fen.split(separator: " ").prefix(4).joined(separator: " "))
        return sessionEvalCache[key]
    }

    /// Clear session eval cache (for re-evaluation)
    func clearSessionEvalCache() {
        sessionEvalCache.removeAll()
    }

    /// Clear all session caches
    func clearSessionCache() {
        sessionGameCache.removeAll()
        sessionEvalCache.removeAll()
    }

}
