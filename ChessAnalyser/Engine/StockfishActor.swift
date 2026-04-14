import Foundation

/// Thread-safe actor wrapping the Stockfish engine.
/// All engine communication is serialized through this actor.
actor StockfishActor {
    private let bridge = StockfishBridge()
    private var isReady = false

    // MARK: - Lifecycle

    func initialize(config: EngineConfiguration) async throws {
        try bridge.initialize()

        // Give the engine thread a moment to start its UCI loop
        try? await Task.sleep(for: .milliseconds(100))
        drainOutput()

        bridge.send(command: UCICommand.uci())
        try await waitForString("uciok", timeout: 10.0)

        bridge.send(command: UCICommand.setThreads(config.threads))
        bridge.send(command: UCICommand.setHash(config.hashMB))
        bridge.send(command: UCICommand.setMultiPV(config.multiPV))

        bridge.send(command: UCICommand.isReady())
        try await waitForString("readyok", timeout: 10.0)

        isReady = true
    }

    func shutdown() {
        bridge.send(command: UCICommand.quit())
        bridge.shutdown()
        isReady = false
    }

    // MARK: - Analysis

    /// Analyze a position with a time limit (ms). Fast for real-time use.
    func analyzePositionTimed(fen: String, moveTimeMs: Int) async -> PositionAnalysis {
        await syncEngine()
        bridge.send(command: UCICommand.position(fen: fen))
        bridge.send(command: UCICommand.go(moveTime: moveTimeMs))
        return await readUntilBestMove()
    }

    /// Analyze a position to a fixed depth. More accurate but slower.
    func analyzePositionDepth(fen: String, depth: Int) async -> PositionAnalysis {
        await syncEngine()
        bridge.send(command: UCICommand.position(fen: fen))
        bridge.send(command: UCICommand.go(depth: depth))
        return await readUntilBestMove()
    }

    /// Ensure the engine is in a clean state — stop any search, drain output, wait for ready.
    private func syncEngine() async {
        bridge.send(command: UCICommand.stop())
        // Drain any leftover output from previous search
        while bridge.readLine() != nil {}
        bridge.send(command: UCICommand.isReady())
        let deadline = Date().addingTimeInterval(3.0)
        while Date() < deadline {
            if let line = bridge.readLine(), line.contains("readyok") { break }
            try? await Task.sleep(for: .milliseconds(2))
        }
    }

    func stop() {
        bridge.send(command: UCICommand.stop())
    }

    func newGame() async {
        bridge.send(command: UCICommand.uciNewGame())
        bridge.send(command: UCICommand.isReady())
        let deadline = Date().addingTimeInterval(5.0)
        while Date() < deadline {
            if let line = bridge.readLine() {
                if line.contains("readyok") { break }
            }
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    // MARK: - Internal

    private func readUntilBestMove() async -> PositionAnalysis {
        var bestInfo: UCIInfoLine?
        var allInfos: [UCIInfoLine] = []

        let deadline = Date().addingTimeInterval(30.0)
        while Date() < deadline && !Task.isCancelled {
            if let line = bridge.readLine() {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { continue }

                let output = UCIParser.parseLine(trimmed)

                switch output {
                case .info(let info):
                    if info.multipv == 1 { bestInfo = info }
                    if let idx = allInfos.firstIndex(where: { $0.multipv == info.multipv }) {
                        allInfos[idx] = info
                    } else {
                        allInfos.append(info)
                    }

                case .bestMove(let move, _):
                    return buildResult(bestInfo: bestInfo, allInfos: allInfos, bestMove: move)

                default:
                    break
                }
            } else {
                try? await Task.sleep(for: .milliseconds(2))
            }
        }
        return buildResult(bestInfo: bestInfo, allInfos: allInfos, bestMove: "")
    }

    private func buildResult(bestInfo: UCIInfoLine?, allInfos: [UCIInfoLine], bestMove: String) -> PositionAnalysis {
        let eval: EngineEval
        if let info = bestInfo {
            eval = EngineEval(score: info.score, mate: info.mate, depth: info.depth, pv: info.pv, multipv: 1)
        } else {
            eval = .initial
        }

        let lines = allInfos.sorted { $0.multipv < $1.multipv }.map { info in
            EngineLine(
                eval: EngineEval(score: info.score, mate: info.mate, depth: info.depth, pv: info.pv, multipv: info.multipv),
                moves: info.pv,
                uciMoves: info.pv
            )
        }
        return PositionAnalysis(eval: eval, bestMove: bestMove, lines: lines)
    }

    private func waitForString(_ target: String, timeout: TimeInterval) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let line = bridge.readLine(), line.contains(target) { return }
            try? await Task.sleep(for: .milliseconds(10))
        }
        throw StockfishError.analysisTimeout
    }

    private func drainOutput() {
        while bridge.readLine() != nil {}
    }
}

struct PositionAnalysis: Equatable {
    let eval: EngineEval
    let bestMove: String
    let lines: [EngineLine]
}
