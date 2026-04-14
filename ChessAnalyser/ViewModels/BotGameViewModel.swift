import SwiftUI

/// ViewModel for playing against the Stockfish engine bot.
@MainActor @Observable
final class BotGameViewModel {
    var board = ChessBoard()
    var moveHistory: [GameMove] = []
    var selectedSquare: Square?
    var legalMoveTargets: [Square] = []
    var isFlipped = false
    var showPromotionPicker = false
    var pendingPromotionFrom: Square?
    var pendingPromotionTo: Square?

    // Game settings
    var playerColor: PieceColor = .white
    var botDepth: Int = 10
    var showHints = false
    var gameOver = false
    var gameResult: String?

    // Engine state
    private var gameStartTime = CFAbsoluteTimeGetCurrent()
    private var initialFEN: String?

    var isBotThinking = false
    var botBestMove: String?
    var botBestMoveUCI: String?
    var playerBestMoveUCI: String?
    var currentEval: EngineEval = .initial
    var lastMoveClassification: MoveClassification?
    private var evalBeforeLastMove: EngineEval?

    var sideToMove: PieceColor { board.sideToMove }
    var isPlayerTurn: Bool { sideToMove == playerColor }
    var moveCount: Int { moveHistory.count }

    // MARK: - Setup

    func startGame(asColor: PieceColor, fen: String? = nil, flipped: Bool? = nil) {
        initialFEN = fen
        if let fen = fen {
            board = ChessBoard(fen: fen)
        } else {
            board = ChessBoard()
        }
        moveHistory = []
        selectedSquare = nil
        legalMoveTargets = []
        playerColor = asColor
        // Always flip based on player color — if playing black, flip the board
        isFlipped = asColor == .black
        gameOver = false
        gameResult = nil
        isBotThinking = false
        botBestMove = nil
        botBestMoveUCI = nil
        playerBestMoveUCI = nil

        gameStartTime = CFAbsoluteTimeGetCurrent()
        Analytics.botGameStarted(playerColor: asColor.rawValue, botDepth: botDepth, fromEditor: fen != nil)

        if !isPlayerTurn {
            makeBotMove()
        }
    }

    func startRandomGame(fen: String? = nil, flipped: Bool? = nil) {
        startGame(asColor: Bool.random() ? .white : .black, fen: fen, flipped: flipped)
    }

    // MARK: - Player Move

    func tapSquare(_ square: Square) {
        guard isPlayerTurn && !gameOver && !isBotThinking && !showPromotionPicker else { return }

        if let selected = selectedSquare {
            if legalMoveTargets.contains(square) {
                // Check if this is a pawn promotion
                if let piece = board.piece(at: selected),
                   piece.type == .pawn,
                   (square.rank == 7 || square.rank == 0) {
                    // Show promotion picker
                    pendingPromotionFrom = selected
                    pendingPromotionTo = square
                    showPromotionPicker = true
                    deselect()
                } else {
                    makeMove(from: selected, to: square, promotion: nil)
                }
            } else if let piece = board.piece(at: square), piece.color == playerColor {
                selectSquare(square)
            } else {
                deselect()
            }
        } else {
            if let piece = board.piece(at: square), piece.color == playerColor {
                selectSquare(square)
            }
        }
    }

    func completePromotion(piece: PieceType) {
        guard let from = pendingPromotionFrom, let to = pendingPromotionTo else { return }
        showPromotionPicker = false
        makeMove(from: from, to: to, promotion: piece)
        pendingPromotionFrom = nil
        pendingPromotionTo = nil
    }

    func cancelPromotion() {
        showPromotionPicker = false
        pendingPromotionFrom = nil
        pendingPromotionTo = nil
    }

    private func selectSquare(_ square: Square) {
        selectedSquare = square
        legalMoveTargets = computeLegalMoves(from: square)
    }

    private func deselect() {
        selectedSquare = nil
        legalMoveTargets = []
    }

    private func makeMove(from: Square, to: Square, promotion: PieceType?) {
        let fenBefore = board.toFEN()
        var uci = "\(from.algebraic)\(to.algebraic)"
        if let promo = promotion {
            uci += promo.symbol.lowercased()
        }
        let san = board.uciToSAN(uci)
        let isWhite = board.sideToMove == .white

        // Save eval before for classification
        evalBeforeLastMove = currentEval

        guard let result = board.makeMoveSAN(san) else { deselect(); return }

        SoundManager.shared.playForMove(
            isCapture: result.captured != nil,
            isCheck: result.isCheck,
            isCheckmate: result.isCheckmate,
            isCastling: result.isCastling
        )

        let fenAfter = board.toFEN()
        appendMove(san: san, from: from, to: to, fen: fenAfter, fenBefore: fenBefore,
                   isWhite: isWhite, result: result)
        deselect()
        playerBestMoveUCI = nil
        lastMoveClassification = nil

        // Classify the player's move if hints enabled
        if showHints {
            classifyLastMove(playedUCI: uci, fenBefore: fenBefore, fenAfter: fenAfter, isWhite: isWhite)
        }

        if result.isCheckmate {
            gameOver = true
            gameResult = isWhite ? "White wins by checkmate!" : "Black wins by checkmate!"
            SoundManager.shared.playCheckmate()
            trackGameEnd()
            return
        }

        if !board.hasLegalMoves(color: board.sideToMove) {
            gameOver = true
            gameResult = "Draw by stalemate"
            trackGameEnd()
            return
        }

        if board.isInsufficientMaterial() {
            gameOver = true
            gameResult = "Draw — insufficient material"
            trackGameEnd()
            return
        }

        if board.isThreefoldRepetition() {
            gameOver = true
            gameResult = "Draw — threefold repetition"
            trackGameEnd()
            return
        }

        if board.isFiftyMoveRule() {
            gameOver = true
            gameResult = "Draw — fifty-move rule"
            trackGameEnd()
            return
        }

        // Bot's turn
        makeBotMove()
    }

    // MARK: - Bot Move

    private func makeBotMove() {
        guard !gameOver else { return }

        // Validate position before calling engine
        guard board.isValidForEngine() else {
            CrashLogger.logEngine("Bot move skipped — invalid position for engine")
            return
        }

        isBotThinking = true

        Task {
            try? await EngineManager.shared.ensureInitialized(
                config: EngineConfiguration()
            )
            guard let stockfish = EngineManager.shared.stockfish else {
                isBotThinking = false
                return
            }

            let fen = board.toFEN()
            // Use time-limited analysis — always responds within a bounded time
            // Higher depth = more time = stronger play, but never blocks forever
            let moveTimeMs = Self.botDepthToMoveTime(botDepth)
            let result = await stockfish.analyzePositionTimed(fen: fen, moveTimeMs: moveTimeMs)
            currentEval = result.eval

            guard !result.bestMove.isEmpty else {
                isBotThinking = false
                return
            }

            // Brief pause before bot moves — just enough to not feel instant
            try? await Task.sleep(for: .milliseconds(100))

            // Make the bot's move on the board
            let uci = result.bestMove
            let san = board.uciToSAN(uci)
            let isWhite = board.sideToMove == .white

            guard let moveResult = board.makeMoveSAN(san) else {
                isBotThinking = false
                return
            }

            SoundManager.shared.playForMove(
                isCapture: moveResult.captured != nil,
                isCheck: moveResult.isCheck,
                isCheckmate: moveResult.isCheckmate,
                isCastling: moveResult.isCastling
            )

            let fenAfter = board.toFEN()
            let parsed = UCIParser.parseUCIMove(uci)
            appendMove(
                san: san,
                from: Square(algebraic: parsed?.from ?? "") ?? Square(file: 0, rank: 0),
                to: Square(algebraic: parsed?.to ?? "") ?? Square(file: 0, rank: 0),
                fen: fenAfter,
                fenBefore: fen,
                isWhite: isWhite,
                result: moveResult
            )

            isBotThinking = false

            if moveResult.isCheckmate {
                gameOver = true
                gameResult = isWhite ? "White wins by checkmate!" : "Black wins by checkmate!"
                SoundManager.shared.playCheckmate()
                trackGameEnd()
                return
            }

            if !board.hasLegalMoves(color: board.sideToMove) {
                gameOver = true
                gameResult = "Draw by stalemate"
                trackGameEnd()
                return
            }

            if board.isInsufficientMaterial() {
                gameOver = true
                gameResult = "Draw — insufficient material"
                trackGameEnd()
                return
            }

            if board.isThreefoldRepetition() {
                gameOver = true
                gameResult = "Draw — threefold repetition"
                trackGameEnd()
                return
            }

            if board.isFiftyMoveRule() {
                gameOver = true
                gameResult = "Draw — fifty-move rule"
                trackGameEnd()
                return
            }

            // Get hint for player if enabled
            if showHints {
                await fetchPlayerHint()
            }
        }
    }

    // MARK: - Hints

    private func fetchPlayerHint() async {
        guard let stockfish = EngineManager.shared.stockfish else { return }
        let fen = board.toFEN()
        let result = await stockfish.analyzePositionTimed(fen: fen, moveTimeMs: 300)
        currentEval = result.eval
        if !result.bestMove.isEmpty {
            playerBestMoveUCI = result.bestMove
        }
    }

    func toggleHints() {
        showHints.toggle()
        if showHints && isPlayerTurn && !gameOver {
            Task { await fetchPlayerHint() }
        } else {
            playerBestMoveUCI = nil
        }
    }

    // MARK: - Undo

    func undoLastTwoMoves() {
        // Undo bot move + player move
        guard moveHistory.count >= 2 else { return }
        moveHistory.removeLast(2)
        rebuildBoard()
        deselect()
        playerBestMoveUCI = nil
        gameOver = false
        gameResult = nil

        if showHints {
            Task { await fetchPlayerHint() }
        }
    }

    func resign() {
        gameOver = true
        gameResult = playerColor == .white ? "Black wins — White resigned" : "White wins — Black resigned"
        trackGameEnd()
    }

    private func trackGameEnd() {
        let durationMs = Int((CFAbsoluteTimeGetCurrent() - gameStartTime) * 1000)
        Analytics.botGameEnded(result: gameResult ?? "", moveCount: moveHistory.count, durationMs: durationMs)
    }

    // MARK: - Helpers

    private func appendMove(san: String, from: Square, to: Square, fen: String, fenBefore: String,
                            isWhite: Bool, result: ChessBoard.MoveResult) {
        let move = GameMove(
            moveIndex: moveHistory.count,
            san: san,
            from: from.algebraic,
            to: to.algebraic,
            fen: fen,
            fenBefore: fenBefore,
            isWhite: isWhite,
            moveNumber: (moveHistory.count / 2) + 1,
            piece: result.piece,
            captured: result.captured,
            promotion: result.promotion,
            isCheck: result.isCheck,
            isCheckmate: result.isCheckmate,
            isCastling: result.isCastling
        )
        moveHistory.append(move)
    }

    private func rebuildBoard() {
        board = initialFEN != nil ? ChessBoard(fen: initialFEN!) : ChessBoard()
        for move in moveHistory {
            _ = board.makeMoveSAN(move.san)
        }
    }

    /// Map bot depth (1-20) to response time in ms.
    /// Ensures the bot always responds within a reasonable time.
    /// Higher depth = more thinking time = stronger play.
    static func botDepthToMoveTime(_ depth: Int) -> Int {
        switch depth {
        case 1:     return 50      // ~depth 4-6, instant
        case 2:     return 80
        case 3:     return 100     // ~depth 6-8
        case 4:     return 150
        case 5:     return 200     // ~depth 8-10, beginner
        case 6:     return 250
        case 7:     return 300
        case 8:     return 400     // ~depth 10-12
        case 9:     return 500
        case 10:    return 600     // ~depth 12-14, intermediate
        case 11:    return 700
        case 12:    return 800
        case 13:    return 1000    // ~depth 14-16
        case 14:    return 1200
        case 15:    return 1500    // ~depth 16-18, strong
        case 16:    return 1800
        case 17:    return 2000
        case 18:    return 2500    // ~depth 18-20, expert
        case 19:    return 2800
        case 20:    return 3000    // ~depth 20+, maximum
        default:    return 600
        }
    }

    private func classifyLastMove(playedUCI: String, fenBefore: String, fenAfter: String, isWhite: Bool) {
        Task {
            guard let stockfish = EngineManager.shared.stockfish else { return }
            // Get eval of the position after the move
            let afterResult = await stockfish.analyzePositionTimed(fen: fenAfter, moveTimeMs: 200)
            currentEval = afterResult.eval

            guard let beforeEval = evalBeforeLastMove, beforeEval.depth > 0 else {
                lastMoveClassification = nil
                return
            }

            let classification = MoveClassifier.classify(
                evalBefore: beforeEval,
                evalAfter: afterResult.eval,
                bestMoveEval: beforeEval,
                playedMoveUCI: playedUCI,
                bestMoveUCI: playerBestMoveUCI ?? "",
                fenBefore: fenBefore,
                fenAfter: fenAfter,
                isWhite: isWhite,
                legalMoveCount: 0
            )
            lastMoveClassification = classification
        }
    }

    private func computeLegalMoves(from: Square) -> [Square] {
        guard let piece = board.piece(at: from), piece.color == playerColor else { return [] }
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
                        if to.rank - from.rank == dir && board.piece(at: to) == nil { canMove = true }
                        else if from.rank == startRank && to.rank - from.rank == 2 * dir
                                    && board.piece(at: to) == nil
                                    && board.piece(at: Square(file: from.file, rank: from.rank + dir)) == nil { canMove = true }
                        else { canMove = false }
                    } else if abs(to.file - from.file) == 1 && to.rank - from.rank == dir && isCapture {
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

        // Castling
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
}
