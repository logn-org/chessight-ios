import Foundation

/// Real-time analysis engine.
///
/// Architecture:
/// - Phase 1 (background): Gather engine evals for ALL positions sequentially
/// - Phase 2 (after evals): Classify all moves in one batch
/// - UI is frozen with a progress overlay during both phases
/// - Already-cached results are shown instantly
@MainActor @Observable
final class AnalysisEngine {
    /// Use the shared singleton engine — never create/destroy per view
    var stockfish: StockfishActor? { EngineManager.shared.stockfish }
    var stockfishForExploration: StockfishActor? { EngineManager.shared.stockfish }

    private var backgroundTask: Task<Void, Never>?
    private var onDemandTask: Task<Void, Never>?

    // Cached results keyed by move index
    private(set) var cache: [Int: MoveAnalysis] = [:]
    // Cached position evals keyed by FEN (for reuse)
    private var evalCache: [String: PositionAnalysis] = [:]

    private(set) var progress = AnalysisProgress.idle
    var isInitialized: Bool { EngineManager.shared.isInitialized }
    private(set) var gameAnalysis: GameAnalysis?

    // Currently displayed live eval (updates in real-time)
    private(set) var liveEval: EngineEval = .initial

    private var currentGame: ParsedGame?
    private var targetDepth: Int = 18

    // MARK: - Lifecycle

    func initialize(config: EngineConfiguration) async throws {
        try await EngineManager.shared.ensureInitialized(config: config)
        targetDepth = config.depth
    }

    /// Just cancel tasks — never shutdown the engine (it's shared)
    func shutdown() async {
        cancelAll()
    }

    // MARK: - Start Analysis (called once when game loads)

    func startAnalysis(game: ParsedGame, depth: Int) {
        guard let stockfish = stockfish else { return }

        cancelAll()
        currentGame = game
        targetDepth = depth

        // Check session cache first — if this game was already analyzed, reuse it
        if let cached = EngineManager.shared.getCachedGameAnalysis(id: game.id) {
            cache = Dictionary(uniqueKeysWithValues: cached.moves.map { ($0.moveIndex, $0) })
            gameAnalysis = cached
            progress = AnalysisProgress(
                currentMove: game.moves.count,
                totalMoves: game.moves.count,
                isAnalyzing: false,
                currentDepth: cached.engineDepth
            )
            return // Already analyzed — no need to re-run engine
        }

        cache = [:]
        evalCache = [:]
        gameAnalysis = nil

        progress = AnalysisProgress(
            currentMove: 0,
            totalMoves: game.moves.count,
            isAnalyzing: true,
            currentDepth: depth
        )

        let bgMoveTime = Self.depthToMoveTime(depth)

        // Two-phase analysis:
        // Phase 1: Gather all engine evals (lightweight — no PieceAnalysis)
        // Phase 2: Classify all moves using cached evals (no engine calls)
        backgroundTask = Task { [weak self] in
            await stockfish.newGame()

            let startFEN = game.moves.first?.fenBefore
                ?? "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

            let startEval = await stockfish.analyzePositionTimed(fen: startFEN, moveTimeMs: bgMoveTime)
            self?.cacheEval(fen: startFEN, result: startEval)

            // Phase 1: Gather evals for every position
            for move in game.moves {
                guard !Task.isCancelled else { break }

                if self?.evalCache[move.fenBefore] == nil {
                    let beforeEval = await stockfish.analyzePositionTimed(fen: move.fenBefore, moveTimeMs: bgMoveTime)
                    self?.cacheEval(fen: move.fenBefore, result: beforeEval)
                }

                guard !Task.isCancelled else { break }

                if self?.evalCache[move.fen] == nil {
                    let afterEval = await stockfish.analyzePositionTimed(fen: move.fen, moveTimeMs: bgMoveTime)
                    self?.cacheEval(fen: move.fen, result: afterEval)
                }

                guard !Task.isCancelled else { break }

                self?.updateProgress(current: move.moveIndex + 1, total: game.moves.count)
            }

            guard !Task.isCancelled else { return }

            // Phase 2: Classify all moves using cached evals (no engine calls, pure computation)
            for move in game.moves {
                guard !Task.isCancelled else { break }

                guard let beforeEval = self?.evalCache[move.fenBefore],
                      let afterEval = self?.evalCache[move.fen] else { continue }

                let analysis = Self.buildMoveAnalysis(
                    move: move, beforeEval: beforeEval, afterEval: afterEval
                )

                self?.commitAnalysis(analysis, moveIndex: move.moveIndex, total: game.moves.count)
            }

            // Finalize
            if !Task.isCancelled {
                self?.finalizeGameAnalysis(game: game, depth: depth)
            }
        }
    }

    // MARK: - On-Demand Analysis (called when user navigates to a move)

    func analyzeCurrentMove(moveIndex: Int) {
        guard let game = currentGame,
              let stockfish = stockfish,
              moveIndex >= 0,
              moveIndex < game.moves.count else {
            // Don't reset liveEval — keep the last known value
            return
        }

        // If already cached, show immediately
        if let cached = cache[moveIndex] {
            liveEval = cached.evalAfter
            return
        }

        let move = game.moves[moveIndex]

        // Cancel previous on-demand task
        onDemandTask?.cancel()

        // On-demand: use slightly shorter time for responsiveness
        let onDemandTime = max(150, Self.depthToMoveTime(targetDepth) / 2)
        onDemandTask = Task { [weak self] in
            let afterEval = await stockfish.analyzePositionTimed(fen: move.fen, moveTimeMs: onDemandTime)
            guard !Task.isCancelled else { return }

            self?.liveEval = afterEval.eval
            self?.cacheEval(fen: move.fen, result: afterEval)

            // Also get before-eval if needed
            let beforeEval: PositionAnalysis
            if let cached = self?.evalCache[move.fenBefore] {
                beforeEval = cached
            } else {
                beforeEval = await stockfish.analyzePositionTimed(fen: move.fenBefore, moveTimeMs: onDemandTime)
                guard !Task.isCancelled else { return }
                self?.cacheEval(fen: move.fenBefore, result: beforeEval)
            }

            let analysis = Self.buildMoveAnalysis(
                move: move, beforeEval: beforeEval, afterEval: afterEval
            )
            self?.cache[moveIndex] = analysis
        }
    }

    // MARK: - Query

    func getAnalysis(forMoveIndex index: Int) -> MoveAnalysis? {
        cache[index]
    }

    // MARK: - Control

    func cancelAll() {
        backgroundTask?.cancel()
        backgroundTask = nil
        onDemandTask?.cancel()
        onDemandTask = nil
        progress = AnalysisProgress(
            currentMove: progress.currentMove,
            totalMoves: progress.totalMoves,
            isAnalyzing: false,
            currentDepth: progress.currentDepth
        )
    }

    /// Map depth setting to movetime in milliseconds.
    static func depthToMoveTime(_ depth: Int) -> Int {
        switch depth {
        case ...10: return 100
        case 11...14: return 200    // Quick
        case 15...16: return 350
        case 17...18: return 500    // Standard
        case 19...20: return 1000
        case 21...22: return 2000   // Deep
        default: return 3000
        }
    }

    func clearCaches() {
        cache = [:]
        evalCache = [:]
        gameAnalysis = nil
        progress = .idle
    }

    func reset() {
        cancelAll()
        cache = [:]
        evalCache = [:]
        gameAnalysis = nil
        liveEval = .initial
        progress = .idle
    }

    // MARK: - Private helpers

    private func cacheEval(fen: String, result: PositionAnalysis) {
        evalCache[fen] = result
        EngineManager.shared.cacheEval(fen: fen, result: result) // Session cache
    }

    private func getCachedEval(fen: String) -> PositionAnalysis? {
        evalCache[fen] ?? EngineManager.shared.getCachedEval(fen: fen) // Check session cache too
    }

    private func updateProgress(current: Int, total: Int) {
        progress = AnalysisProgress(
            currentMove: current,
            totalMoves: total,
            isAnalyzing: true,
            currentDepth: targetDepth
        )
    }

    private func commitAnalysis(_ analysis: MoveAnalysis, moveIndex: Int, total: Int) {
        cache[moveIndex] = analysis
        progress = AnalysisProgress(
            currentMove: cache.count,
            totalMoves: total,
            isAnalyzing: true,
            currentDepth: targetDepth
        )
    }

    private func finalizeGameAnalysis(game: ParsedGame, depth: Int) {
        let moves = game.moves.indices.compactMap { cache[$0] }
        guard moves.count == game.moves.count else {
            progress = AnalysisProgress(
                currentMove: cache.count,
                totalMoves: game.moves.count,
                isAnalyzing: false,
                currentDepth: depth
            )
            return
        }

        let whiteAccuracy = MoveClassifier.calculateAccuracy(moves: moves, isWhite: true)
        let blackAccuracy = MoveClassifier.calculateAccuracy(moves: moves, isWhite: false)

        let analysis = GameAnalysis(
            id: game.id,
            pgn: game.pgn,
            moves: moves,
            white: game.white,
            black: game.black,
            whiteElo: game.whiteElo,
            blackElo: game.blackElo,
            result: game.result,
            analyzedAt: Date(),
            engineDepth: depth,
            whiteAccuracy: whiteAccuracy,
            blackAccuracy: blackAccuracy
        )
        gameAnalysis = analysis
        EngineManager.shared.cacheGameAnalysis(analysis) // Session cache

        progress = AnalysisProgress(
            currentMove: game.moves.count,
            totalMoves: game.moves.count,
            isAnalyzing: false,
            currentDepth: depth
        )
    }

    // MARK: - Move Analysis Builder

    static func buildMoveAnalysis(
        move: GameMove,
        beforeEval: PositionAnalysis,
        afterEval: PositionAnalysis
    ) -> MoveAnalysis {
        let bestMoveEval = beforeEval.eval
        let bestMoveUCI = beforeEval.bestMove
        let playedEval = afterEval.eval
        let playedMoveUCI = "\(move.from)\(move.to)"

        // Convert best move UCI to SAN for display
        let board = ChessBoard(fen: move.fenBefore)
        let bestMoveSAN = board.uciToSAN(bestMoveUCI)

        // Get second-best line eval (multiPV 2) if available
        let secondBestEval = beforeEval.lines.first(where: { $0.eval.multipv == 2 })?.eval

        // Expected points loss (more meaningful than raw centipawns)
        let epLoss = MoveClassifier.expectedPointsLoss(
            before: bestMoveEval,
            after: playedEval,
            isWhite: move.isWhite
        )
        // Convert to centipawn-equivalent for display/storage
        let cpLoss = Int(epLoss * 1000) // Store as millipawns of win probability

        let classification = MoveClassifier.classify(
            evalBefore: beforeEval.eval,
            evalAfter: playedEval,
            bestMoveEval: bestMoveEval,
            secondBestEval: secondBestEval,
            playedMoveUCI: playedMoveUCI,
            bestMoveUCI: bestMoveUCI,
            fenBefore: move.fenBefore,
            fenAfter: move.fen,
            isWhite: move.isWhite,
            legalMoveCount: 0
        )

        return MoveAnalysis(
            moveIndex: move.moveIndex,
            san: move.san,
            from: move.from,
            to: move.to,
            fen: move.fen,
            fenBefore: move.fenBefore,
            evalBefore: beforeEval.eval,
            evalAfter: playedEval,
            bestMove: bestMoveUCI,
            bestMoveSAN: bestMoveSAN,
            bestMoveEval: bestMoveEval,
            classification: classification,
            cpLoss: cpLoss,
            engineLines: afterEval.lines,
            isWhite: move.isWhite,
            moveNumber: move.moveNumber
        )
    }
}
