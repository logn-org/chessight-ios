import SwiftUI

@MainActor @Observable
final class AnalysisViewModel {
    let gameState = GameState()
    let analysisEngine = AnalysisEngine()
    private let api = ChessComAPI()

    var whiteUsername: String?
    var blackUsername: String?
    var whiteRating: Int?
    var blackRating: Int?

    var isLoading = false
    var error: String?
    var autoPlay = false
    var isFlipped = false
    private var autoPlayTask: Task<Void, Never>?

    // Sticky eval — never resets to 0
    private var lastKnownEval: EngineEval?

    // Interactive board
    var selectedSquare: Square?
    var legalMoveTargets: [Square] = []
    var showPromotionPicker = false
    var pendingPromotionFrom: Square?
    var pendingPromotionTo: Square?

    /// When true, engine analysis runs during exploration. When false, moves are made silently.
    var explorationAnalysisEnabled = true

    // Variation: exploration moves branching from the main game
    var isExploring = false
    var explorationBoard: ChessBoard?
    var explorationMoves: [GameMove] = []
    /// Index within explorationMoves we're currently viewing (for back/forward)
    var explorationViewIndex: Int = -1
    var explorationAfterResult: PositionAnalysis?
    var explorationBeforeResult: PositionAnalysis?
    var lastExplorationClassification: MoveClassification?
    private var savedMoveIndex: Int = -1
    private var explorationAnalysisTask: Task<Void, Never>?
    /// The last suggested best move UCI — used to detect if user played the suggested move
    private var lastSuggestedBestMove: String?

    // MARK: - Load

    func loadPGN(_ pgn: String) {
        do { try gameState.loadPGN(pgn); error = nil }
        catch { self.error = error.localizedDescription }
    }

    func loadFEN(_ fen: String) {
        gameState.loadFromFEN(fen)
        error = nil
    }

    /// Load a chess.com game. If `profileUsername` is provided, flip the board so that user is at the bottom.
    func loadChessComGame(_ game: ChessComGame, profileUsername: String? = nil) {
        whiteUsername = game.white.username
        blackUsername = game.black.username
        whiteRating = game.white.rating
        blackRating = game.black.rating
        loadPGN(game.pgn)

        // Flip board so the profile user is at the bottom.
        // Check both username fields (chess.com sometimes has case differences).
        if let profile = profileUsername?.lowercased() {
            let isBlack = game.black.username.lowercased() == profile
            let isWhite = game.white.username.lowercased() == profile
            if isBlack && !isWhite {
                isFlipped = true // Profile user played black → flip
            } else {
                isFlipped = false // Profile user played white (or not found) → normal
            }
        }
    }

    // MARK: - Analysis

    func startAnalysis(config: EngineConfiguration) async {
        CrashLogger.logEngine("Starting analysis (depth: \(config.depth))")
        do {
            if !analysisEngine.isInitialized {
                try await analysisEngine.initialize(config: config)
            }
            if let game = gameState.game {
                analysisEngine.startAnalysis(game: game, depth: config.depth)
                analysisEngine.analyzeCurrentMove(moveIndex: gameState.currentMoveIndex)
            }
        } catch { self.error = error.localizedDescription }
    }

    func stopAnalysis() { analysisEngine.cancelAll() }

    /// Force re-evaluate: clear ALL caches and re-run analysis from scratch
    func reEvaluate(config: EngineConfiguration) {
        guard let game = gameState.game else { return }
        // Exit variation if in one
        if isExploring { exitExploration() }
        // Clear ALL caches — session game cache, session eval cache, local caches
        EngineManager.shared.removeCachedGameAnalysis(id: game.id)
        EngineManager.shared.clearSessionEvalCache()
        analysisEngine.cancelAll()
        analysisEngine.clearCaches()
        // Re-run fresh analysis
        Task {
            try? await analysisEngine.initialize(config: config)
            analysisEngine.startAnalysis(game: game, depth: config.depth)
            analysisEngine.analyzeCurrentMove(moveIndex: gameState.currentMoveIndex)
        }
    }

    func onMoveChanged() {
        if isExploring { return }
        deselect()
        // Play sound for the current move
        if let move = gameState.currentMove {
            SoundManager.shared.playForMove(
                isCapture: move.captured != nil,
                isCheck: move.isCheck,
                isCheckmate: move.isCheckmate,
                isCastling: move.isCastling
            )
        }
        analysisEngine.analyzeCurrentMove(moveIndex: gameState.currentMoveIndex)
    }

    // MARK: - Unified Navigation

    var canGoBack: Bool {
        if isExploring {
            return explorationViewIndex >= 0 || savedMoveIndex >= 0
        }
        return !gameState.isAtStart
    }

    var canGoForward: Bool {
        if isExploring {
            return explorationViewIndex < explorationMoves.count - 1
        }
        // If we have a parked variation and we're at the branch point, forward enters it
        if hasParkedVariation && gameState.currentMoveIndex == parkedSavedMoveIndex {
            return true
        }
        return !gameState.isAtEnd
    }

    /// True when we exited a variation by going back but the moves are still saved
    var hasParkedVariation: Bool {
        !isExploring && !parkedExplorationMoves.isEmpty
    }

    /// The parked variation moves (visible to UI)
    private(set) var parkedExplorationMoves: [GameMove] = []
    private var parkedSavedMoveIndex: Int = -1

    /// All variation moves for display (whether active or parked)
    var displayVariationMoves: [GameMove] {
        if isExploring { return explorationMoves }
        if hasParkedVariation { return parkedExplorationMoves }
        return []
    }

    func goBack() {
        if isExploring {
            if explorationViewIndex >= 0 {
                // Preserve current eval so bar doesn't reset during async analysis
                if let eval = explorationAfterResult?.eval, eval.depth > 0 {
                    lastKnownEval = eval
                }
                explorationViewIndex -= 1
                rebuildExplorationBoardToIndex()
                lastExplorationClassification = nil
                deselect()
                analyzeExplorationPosition()
            } else {
                // At branch point — park variation, go back in main game
                parkVariation()
                gameState.goBack()
                onMoveChanged()
            }
        } else {
            // Never clear parked variation on back — it persists until Resume/dismiss
            gameState.goBack()
            onMoveChanged()
        }
    }

    func goForward() {
        if isExploring {
            if explorationViewIndex < explorationMoves.count - 1 {
                if let eval = explorationAfterResult?.eval, eval.depth > 0 {
                    lastKnownEval = eval
                }
                explorationViewIndex += 1
                rebuildExplorationBoardToIndex()
                deselect()
                analyzeExplorationPosition()
            }
        } else if hasParkedVariation && gameState.currentMoveIndex == parkedSavedMoveIndex {
            unparkVariation()
        } else {
            gameState.goForward()
            onMoveChanged()
        }
    }

    func goToStart() {
        if isExploring {
            parkVariation()
        }
        // Keep parked variation — don't clear it
        gameState.goToStart()
        onMoveChanged()
    }

    /// Jump to a specific exploration move by index (tapping variation moves)
    func goToExplorationMove(_ index: Int) {
        if !isExploring && hasParkedVariation {
            // Re-enter parked variation at the specified index
            unparkVariation()
        }
        guard isExploring else { return }
        let clampedIndex = max(-1, min(index, explorationMoves.count - 1))
        saveCurrentEvalToSticky()
        explorationViewIndex = clampedIndex
        rebuildExplorationBoardToIndex()
        deselect()
        analyzeExplorationPosition()
    }

    func goToEnd() {
        if isExploring {
            if explorationMoves.count > 0 {
                explorationViewIndex = explorationMoves.count - 1
                rebuildExplorationBoardToIndex()
                deselect()
                analyzeExplorationPosition()
            }
        } else {
            // Keep parked variation — don't clear it
            gameState.goToEnd()
            onMoveChanged()
        }
    }

    /// Save variation moves and exit exploration (keeps moves for re-entry)
    private func parkVariation() {
        saveCurrentEvalToSticky()
        explorationAnalysisTask?.cancel()
        parkedExplorationMoves = explorationMoves
        parkedSavedMoveIndex = savedMoveIndex
        isExploring = false
        explorationBoard = nil
        explorationViewIndex = -1
        explorationBeforeResult = nil
        explorationAfterResult = nil
        lastExplorationClassification = nil
        lastSuggestedBestMove = nil
        deselect()
        gameState.goToMove(savedMoveIndex)
    }

    /// Re-enter a parked variation
    private func unparkVariation() {
        isExploring = true
        savedMoveIndex = parkedSavedMoveIndex
        explorationMoves = parkedExplorationMoves
        explorationViewIndex = 0  // Enter at the first variation move
        parkedExplorationMoves = []
        rebuildExplorationBoardToIndex()
        deselect()
        analyzeExplorationPosition()
    }

    // MARK: - Board Tap

    func tapSquare(_ square: Square) {
        guard !showPromotionPicker else { return }
        if isExploring {
            tapSquareInExploration(square)
        } else {
            tapSquareInGame(square)
        }
    }

    func completePromotion(piece: PieceType) {
        guard let from = pendingPromotionFrom, let to = pendingPromotionTo else { return }
        showPromotionPicker = false
        if !isExploring { enterExploration() }
        let uci = "\(from.algebraic)\(to.algebraic)\(piece.symbol.lowercased())"
        let board = explorationBoard ?? gameState.currentBoard
        let san = board.uciToSAN(uci)
        // Directly make the move with promotion
        guard var b = explorationBoard else { pendingPromotionFrom = nil; pendingPromotionTo = nil; return }
        let fenBefore = b.toFEN()
        let isWhite = b.sideToMove == .white
        guard let result = b.makeMoveSAN(san) else { pendingPromotionFrom = nil; pendingPromotionTo = nil; return }

        SoundManager.shared.playForMove(isCapture: result.captured != nil, isCheck: result.isCheck,
                                         isCheckmate: result.isCheckmate, isCastling: result.isCastling)
        let fenAfter = b.toFEN()
        if explorationViewIndex < explorationMoves.count - 1 {
            explorationMoves = Array(explorationMoves.prefix(explorationViewIndex + 1))
        }
        let move = GameMove(moveIndex: explorationMoves.count, san: san, from: from.algebraic, to: to.algebraic,
                            fen: fenAfter, fenBefore: fenBefore, isWhite: isWhite,
                            moveNumber: (explorationMoves.count / 2) + 1, piece: result.piece,
                            captured: result.captured, promotion: result.promotion,
                            isCheck: result.isCheck, isCheckmate: result.isCheckmate, isCastling: result.isCastling)
        explorationMoves.append(move)
        explorationViewIndex = explorationMoves.count - 1
        explorationBoard = b
        deselect()
        saveCurrentEvalToSticky()
        explorationAfterResult = nil
        lastSuggestedBestMove = nil
        analyzeExplorationPosition()
        pendingPromotionFrom = nil
        pendingPromotionTo = nil
    }

    func cancelPromotion() {
        showPromotionPicker = false
        pendingPromotionFrom = nil
        pendingPromotionTo = nil
    }

    private func isPawnPromotion(from: Square, to: Square, board: ChessBoard) -> Bool {
        guard let piece = board.piece(at: from), piece.type == .pawn else { return false }
        return to.rank == 7 || to.rank == 0
    }

    private func tapSquareInGame(_ square: Square) {
        let board = gameState.currentBoard

        if let selected = selectedSquare {
            if legalMoveTargets.contains(square) {
                if isPawnPromotion(from: selected, to: square, board: board) {
                    pendingPromotionFrom = selected
                    pendingPromotionTo = square
                    showPromotionPicker = true
                    deselect()
                    return
                }

                let moveUCI = "\(selected.algebraic)\(square.algebraic)"
                if let nextMove = nextGameMove,
                   "\(nextMove.from)\(nextMove.to)" == moveUCI {
                    deselect()
                    gameState.goForward()
                    onMoveChanged()
                } else {
                    enterExploration()
                    makeExplorationMove(from: selected, to: square)
                }
            } else if let piece = board.piece(at: square), piece.color == board.sideToMove {
                selectSquare(square, board: board)
            } else {
                deselect()
            }
        } else {
            if let piece = board.piece(at: square), piece.color == board.sideToMove {
                selectSquare(square, board: board)
            }
        }
    }

    private func tapSquareInExploration(_ square: Square) {
        guard let board = explorationBoard else { return }

        if let selected = selectedSquare {
            if legalMoveTargets.contains(square) {
                if isPawnPromotion(from: selected, to: square, board: board) {
                    pendingPromotionFrom = selected
                    pendingPromotionTo = square
                    showPromotionPicker = true
                    deselect()
                    return
                }
                makeExplorationMove(from: selected, to: square)
            } else if let piece = board.piece(at: square), piece.color == board.sideToMove {
                selectSquare(square, board: board)
            } else {
                deselect()
            }
        } else {
            if let piece = board.piece(at: square), piece.color == board.sideToMove {
                selectSquare(square, board: board)
            }
        }
    }

    private func makeExplorationMove(from: Square, to: Square) {
        guard var board = explorationBoard else { return }
        let fenBefore = board.toFEN()
        let playedUCI = "\(from.algebraic)\(to.algebraic)"
        let san = board.uciToSAN(playedUCI)
        let isWhite = board.sideToMove == .white

        guard let result = board.makeMoveSAN(san) else { deselect(); return }

        // Play sound
        SoundManager.shared.playForMove(
            isCapture: result.captured != nil,
            isCheck: result.isCheck,
            isCheckmate: result.isCheckmate,
            isCastling: result.isCastling
        )

        // Check if user played the engine's suggested best move
        let playedSuggestedMove = playedUCI.lowercased() == (lastSuggestedBestMove ?? "").lowercased()

        let fenAfter = board.toFEN()

        // If we're not at the end of the variation, truncate future moves
        if explorationViewIndex < explorationMoves.count - 1 {
            explorationMoves = Array(explorationMoves.prefix(explorationViewIndex + 1))
        }

        let move = GameMove(
            moveIndex: explorationMoves.count,
            san: san,
            from: from.algebraic,
            to: to.algebraic,
            fen: fenAfter,
            fenBefore: fenBefore,
            isWhite: isWhite,
            moveNumber: (explorationMoves.count / 2) + 1,
            piece: result.piece,
            captured: result.captured,
            promotion: result.promotion,
            isCheck: result.isCheck,
            isCheckmate: result.isCheckmate,
            isCastling: result.isCastling
        )

        explorationMoves.append(move)
        explorationViewIndex = explorationMoves.count - 1
        explorationBoard = board
        deselect()

        if explorationAnalysisEnabled {
            saveCurrentEvalToSticky()
            // Clear all stale results so arrows/classification don't show old data
            explorationBeforeResult = explorationAfterResult // save for classification
            explorationAfterResult = nil
            lastSuggestedBestMove = nil
            lastExplorationClassification = nil

            // Always do full analysis to get proper classification
            analyzeExplorationPosition()
        } else {
            // No analysis — clear any stale results
            explorationAfterResult = nil
            lastSuggestedBestMove = nil
            lastExplorationClassification = nil
        }
    }

    // MARK: - Exploration

    func enterExploration() {
        guard !isExploring else { return }
        saveCurrentEvalToSticky()
        isExploring = true
        savedMoveIndex = gameState.currentMoveIndex
        explorationBoard = gameState.currentBoard
        explorationMoves = []
        explorationViewIndex = -1
        explorationBeforeResult = nil
        lastExplorationClassification = nil
        lastSuggestedBestMove = nil
        explorationAfterResult = nil
        deselect()

        // Run fresh analysis for the current position
        analyzeExplorationPosition()
    }

    func exitExploration() {
        saveCurrentEvalToSticky()
        explorationAnalysisTask?.cancel()
        isExploring = false
        explorationBoard = nil
        explorationMoves = []
        explorationViewIndex = -1
        explorationBeforeResult = nil
        explorationAfterResult = nil
        lastExplorationClassification = nil
        lastSuggestedBestMove = nil
        parkedExplorationMoves = []
        deselect()
        gameState.goToMove(savedMoveIndex)
    }

    func clearParkedVariation() {
        parkedExplorationMoves = []
    }

    private func rebuildExplorationBoardToIndex() {
        var board = gameState.boards[safe: savedMoveIndex + 1] ?? gameState.boards[0]
        if explorationViewIndex >= 0 {
            for i in 0...explorationViewIndex {
                if i < explorationMoves.count {
                    _ = board.makeMoveSAN(explorationMoves[i].san)
                }
            }
        }
        explorationBoard = board
    }

    private func selectSquare(_ square: Square, board: ChessBoard) {
        selectedSquare = square
        legalMoveTargets = computeLegalMoves(from: square, board: board)
    }

    private func deselect() {
        selectedSquare = nil
        legalMoveTargets = []
    }

    /// Save whatever eval is currently displayed to lastKnownEval so the bar never drops to 0
    private func saveCurrentEvalToSticky() {
        if let eval = explorationAfterResult?.eval, eval.depth > 0 {
            lastKnownEval = eval
        } else if let analysis = currentMoveAnalysis, analysis.evalAfter.depth > 0 {
            lastKnownEval = analysis.evalAfter
        } else if analysisEngine.liveEval.depth > 0 {
            lastKnownEval = analysisEngine.liveEval
        }
    }

    /// Full analysis: both before and after positions
    private func analyzeExplorationPosition() {
        guard let board = explorationBoard else { return }
        let afterFEN = board.toFEN()

        saveCurrentEvalToSticky()
        explorationAnalysisTask?.cancel()

        // Always clear — fresh analysis will replace
        explorationAfterResult = nil
        lastSuggestedBestMove = nil

        explorationAnalysisTask = Task {
            guard let stockfish = analysisEngine.stockfishForExploration else { return }

            let afterResult = await stockfish.analyzePositionTimed(fen: afterFEN, moveTimeMs: 400)
            guard !Task.isCancelled else { return }
            self.explorationAfterResult = afterResult
            self.lastSuggestedBestMove = afterResult.bestMove

            // Classify the last move if we have one
            guard !Task.isCancelled else { return }
            if let lastMove = currentExplorationMove {
                if let prevBefore = self.explorationBeforeResult, prevBefore.eval.depth > 0 {
                    self.classifyLastMove(beforeResult: prevBefore, afterResult: afterResult, move: lastMove)
                } else {
                    let beforeResult = await stockfish.analyzePositionTimed(fen: lastMove.fenBefore, moveTimeMs: 300)
                    guard !Task.isCancelled else { return }
                    self.classifyLastMove(beforeResult: beforeResult, afterResult: afterResult, move: lastMove)
                }
            }

            self.explorationBeforeResult = afterResult
        }
    }

    /// Quick analysis: only the after position (used when user played suggested move)
    private func analyzeExplorationPositionAfterOnly() {
        guard let board = explorationBoard else { return }
        let afterFEN = board.toFEN()

        saveCurrentEvalToSticky()
        explorationAnalysisTask?.cancel()
        explorationAfterResult = nil
        lastSuggestedBestMove = nil

        explorationAnalysisTask = Task {
            guard let stockfish = analysisEngine.stockfishForExploration else { return }
            let afterResult = await stockfish.analyzePositionTimed(fen: afterFEN, moveTimeMs: 400)
            guard !Task.isCancelled else { return }
            self.explorationAfterResult = afterResult
            self.lastSuggestedBestMove = afterResult.bestMove
            self.explorationBeforeResult = afterResult
        }
    }

    private func classifyLastMove(beforeResult: PositionAnalysis, afterResult: PositionAnalysis, move: GameMove) {
        let playedUCI = "\(move.from)\(move.to)"
        let classification = MoveClassifier.classify(
            evalBefore: beforeResult.eval,
            evalAfter: afterResult.eval,
            bestMoveEval: beforeResult.eval,
            playedMoveUCI: playedUCI,
            bestMoveUCI: beforeResult.bestMove,
            fenBefore: move.fenBefore,
            fenAfter: move.fen,
            isWhite: move.isWhite,
            legalMoveCount: 0
        )
        self.lastExplorationClassification = classification
    }

    func analyzeExplorationPositionPublic() { analyzeExplorationPosition() }

    func clearExplorationAnalysis() {
        explorationAnalysisTask?.cancel()
        explorationAfterResult = nil
        lastExplorationClassification = nil
        lastSuggestedBestMove = nil
    }

    /// The exploration move at the current view index
    private var currentExplorationMove: GameMove? {
        guard explorationViewIndex >= 0, explorationViewIndex < explorationMoves.count else { return nil }
        return explorationMoves[explorationViewIndex]
    }

    // MARK: - Display Properties

    var displayBoard: ChessBoard {
        explorationBoard ?? gameState.currentBoard
    }

    /// Detect checkmate, stalemate, or insufficient material on the current display board
    var boardGameEndStatus: GameEndStatus? {
        let board = displayBoard
        let color = board.sideToMove
        if !board.hasLegalMoves(color: color) {
            if board.isKingInCheck(color: color) {
                return .checkmate(winner: color.opposite)
            } else {
                return .stalemate
            }
        }
        if board.isInsufficientMaterial() {
            return .insufficientMaterial
        }
        if board.isThreefoldRepetition() {
            return .threefoldRepetition
        }
        if board.isFiftyMoveRule() {
            return .fiftyMoveRule
        }

        // At the last move of a loaded game — show the game result (resign, timeout, abandonment, etc.)
        if !isExploring,
           let game = gameState.game,
           gameState.isAtEnd,
           !game.moves.isEmpty {
            let result = game.result
            if result == "1-0" {
                // If it's not checkmate on the board, white won by resignation/timeout
                return .gameResult(result: result, winner: .white)
            } else if result == "0-1" {
                return .gameResult(result: result, winner: .black)
            } else if result == "1/2-1/2" {
                return .gameResult(result: result, winner: nil)
            }
        }

        return nil
    }

    enum GameEndStatus {
        case checkmate(winner: PieceColor)
        case stalemate
        case insufficientMaterial
        case threefoldRepetition
        case fiftyMoveRule
        case gameResult(result: String, winner: PieceColor?)

        var isCheckmate: Bool {
            if case .checkmate = self { return true }
            return false
        }

        var isWin: Bool {
            switch self {
            case .checkmate: return true
            case .gameResult(_, let winner): return winner != nil
            default: return false
            }
        }

        var displayText: String {
            switch self {
            case .checkmate(let winner):
                return "Checkmate\n\(winner == .white ? "White" : "Black") wins!"
            case .gameResult(let result, let winner):
                if let winner = winner {
                    return "\(result)\n\(winner == .white ? "White" : "Black") wins"
                }
                return "\(result)\nDraw"
            case .stalemate:
                return "Stalemate\nDraw"
            case .insufficientMaterial:
                return "Draw\nInsufficient material"
            case .threefoldRepetition:
                return "Draw\nThreefold repetition"
            case .fiftyMoveRule:
                return "Draw\nFifty-move rule"
            }
        }
    }

    var currentEval: EngineEval {
        let eval: EngineEval?
        if isExploring {
            eval = explorationAfterResult?.eval
        } else if let analysis = currentMoveAnalysis {
            eval = analysis.evalAfter
        } else if analysisEngine.liveEval.depth > 0 {
            eval = analysisEngine.liveEval
        } else {
            eval = nil
        }
        if let eval = eval, eval.depth > 0 { lastKnownEval = eval }
        return eval ?? lastKnownEval ?? .initial
    }

    var explorationBestMove: String? { explorationAfterResult?.bestMove }

    var explorationBestMoveSAN: String? {
        guard let bm = explorationBestMove, !bm.isEmpty else { return nil }
        return displayBoard.uciToSAN(bm)
    }

    var currentMoveAnalysis: MoveAnalysis? {
        guard !isExploring, gameState.currentMoveIndex >= 0 else { return nil }
        return analysisEngine.getAnalysis(forMoveIndex: gameState.currentMoveIndex)
    }

    var nextGameMove: GameMove? {
        guard let game = gameState.game else { return nil }
        let nextIndex = gameState.currentMoveIndex + 1
        guard nextIndex < game.moves.count else { return nil }
        return game.moves[nextIndex]
    }

    var displayWhiteName: String {
        if let u = whiteUsername { return whiteRating != nil ? "\(u) (\(whiteRating!))" : u }
        return gameState.whiteName
    }

    var displayBlackName: String {
        if let u = blackUsername { return blackRating != nil ? "\(u) (\(blackRating!))" : u }
        return gameState.blackName
    }

    // MARK: - Auto Play

    func toggleAutoPlay() {
        autoPlay.toggle()
        if autoPlay { startAutoPlay() } else { stopAutoPlay() }
    }

    private func startAutoPlay() {
        autoPlayTask = Task {
            if isExploring {
                // Auto-play through variation moves
                while autoPlay && explorationViewIndex < explorationMoves.count - 1 {
                    try? await Task.sleep(for: .seconds(1.5))
                    guard autoPlay else { break }
                    goForward()
                }
            } else {
                // Auto-play through game moves (skip variation if parked)
                while autoPlay && !gameState.isAtEnd {
                    try? await Task.sleep(for: .seconds(1.5))
                    guard autoPlay else { break }
                    gameState.goForward()
                    onMoveChanged()
                }
            }
            autoPlay = false
        }
    }

    private func stopAutoPlay() { autoPlayTask?.cancel(); autoPlayTask = nil }

    // MARK: - Legal Moves

    func computeLegalMoves(from: Square, board: ChessBoard) -> [Square] {
        guard let piece = board.piece(at: from) else { return [] }
        var targets: [Square] = []

        for rank in 0..<8 {
            for file in 0..<8 {
                let to = Square(file: file, rank: rank)
                if to == from { continue }
                let target = board.piece(at: to)
                if target?.color == piece.color { continue }

                let isCapture = target != nil || (piece.type == .pawn && to == board.enPassantSquare)
                let canMove: Bool
                if piece.type == .pawn {
                    let dir = piece.color == .white ? 1 : -1
                    let startRank = piece.color == .white ? 1 : 6
                    if to.file == from.file && !isCapture {
                        // Forward moves (same file, no capture)
                        if to.rank - from.rank == dir && board.piece(at: to) == nil {
                            canMove = true
                        } else if from.rank == startRank && to.rank - from.rank == 2 * dir
                                    && board.piece(at: to) == nil
                                    && board.piece(at: Square(file: from.file, rank: from.rank + dir)) == nil {
                            canMove = true
                        } else { canMove = false }
                    } else if abs(to.file - from.file) == 1 && to.rank - from.rank == dir && isCapture {
                        // Diagonal captures only (must have enemy piece or en passant)
                        canMove = true
                    } else {
                        canMove = false
                    }
                } else {
                    canMove = board.canAttack(from: from, to: to, piece: piece)
                }

                if canMove {
                    var testBoard = board
                    testBoard.setPiece(nil, at: from)
                    testBoard.setPiece(piece, at: to)
                    if piece.type == .pawn && to == board.enPassantSquare {
                        let cr = piece.color == .white ? to.rank - 1 : to.rank + 1
                        testBoard.setPiece(nil, at: Square(file: to.file, rank: cr))
                    }
                    if !testBoard.isKingInCheck(color: piece.color) { targets.append(to) }
                }
            }
        }

        if piece.type == .king {
            let rank = piece.color == .white ? 0 : 7
            let opp = piece.color.opposite
            if from == Square(file: 4, rank: rank) {
                let ks: ChessBoard.CastlingRights = piece.color == .white ? .whiteKingside : .blackKingside
                let qs: ChessBoard.CastlingRights = piece.color == .white ? .whiteQueenside : .blackQueenside
                if board.castlingRights.contains(ks)
                    && board.piece(at: Square(file: 5, rank: rank)) == nil
                    && board.piece(at: Square(file: 6, rank: rank)) == nil
                    && !board.isSquareAttacked(Square(file: 4, rank: rank), by: opp)
                    && !board.isSquareAttacked(Square(file: 5, rank: rank), by: opp)
                    && !board.isSquareAttacked(Square(file: 6, rank: rank), by: opp) {
                    targets.append(Square(file: 6, rank: rank))
                }
                if board.castlingRights.contains(qs)
                    && board.piece(at: Square(file: 3, rank: rank)) == nil
                    && board.piece(at: Square(file: 2, rank: rank)) == nil
                    && board.piece(at: Square(file: 1, rank: rank)) == nil
                    && !board.isSquareAttacked(Square(file: 4, rank: rank), by: opp)
                    && !board.isSquareAttacked(Square(file: 3, rank: rank), by: opp)
                    && !board.isSquareAttacked(Square(file: 2, rank: rank), by: opp) {
                    targets.append(Square(file: 2, rank: rank))
                }
            }
        }
        return targets
    }

    func cleanup() {
        stopAutoPlay()
        analysisEngine.cancelAll()
        explorationAnalysisTask?.cancel()
    }
}
