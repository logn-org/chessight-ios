import SwiftUI

@MainActor @Observable
final class PuzzleViewModel {
    private let api = PuzzleAPI()

    var puzzle: DailyPuzzle?
    var isLoading = false
    var error: String?

    // Puzzle board state
    var board = ChessBoard()
    var selectedSquare: Square?
    var legalMoveTargets: [Square] = []
    var isFlipped = false

    // Puzzle solution tracking
    var solutionMoves: [String] = []  // UCI moves from PGN
    var currentSolutionIndex = 0       // Which solution move we're expecting next
    var puzzleCompleted = false
    var wrongMove = false
    var userMoves: [GameMove] = []
    var lastMoveFrom: String?
    var lastMoveTo: String?
    private var puzzleStartTime = CFAbsoluteTimeGetCurrent()
    private var puzzleAttempts = 0
    private var puzzleMode = "daily"

    // Promotion picker
    var showPromotionPicker = false
    var pendingPromotionFrom: Square?
    var pendingPromotionTo: Square?

    var sideToMove: PieceColor { board.sideToMove }
    var isUserTurn: Bool {
        // User plays every other move starting from the first solution move
        return currentSolutionIndex % 2 == 0 && !puzzleCompleted
    }

    // MARK: - Load

    func loadTodaysPuzzle() async {
        CrashLogger.log("Loading today's puzzle")
        isLoading = true
        error = nil
        puzzleMode = "daily"
        let trace = PerformanceTracer.tracePuzzleFetch()
        do {
            puzzle = try await api.getTodaysPuzzle()
            if let p = puzzle { setupPuzzle(p) }
        } catch {
            self.error = error.localizedDescription
        }
        trace?.stop()
        isLoading = false
    }

    /// Load a custom practice puzzle (no API call)
    func loadCustomPuzzle(title: String, fen: String, pgn: String) {
        puzzleMode = "practice"
        isLoading = false
        error = nil
        let p = DailyPuzzle(title: title, url: "", publishTime: Date(), fen: fen, pgn: pgn, image: nil)
        puzzle = p
        setupPuzzle(p)
    }

    func loadRandomPuzzle() async {
        isLoading = true
        error = nil
        puzzleMode = "random"
        do {
            puzzle = try await api.getRandomPuzzle()
            if let p = puzzle { setupPuzzle(p) }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Setup

    private func setupPuzzle(_ puzzle: DailyPuzzle) {
        // Parse solution moves from PGN
        solutionMoves = parseSolutionMoves(pgn: puzzle.pgn)
        currentSolutionIndex = 0
        puzzleCompleted = false
        wrongMove = false
        showPromotionPicker = false
        pendingPromotionFrom = nil
        pendingPromotionTo = nil
        userMoves = []
        puzzleStartTime = CFAbsoluteTimeGetCurrent()
        puzzleAttempts = 0
        selectedSquare = nil
        legalMoveTargets = []

        // Set up the board from FEN
        board = ChessBoard(fen: puzzle.fen)

        // Flip board so the user's color is at the bottom
        // The first solution move is the user's first move
        // The side to move in the FEN is the user's color
        isFlipped = board.sideToMove == .black

        lastMoveFrom = nil
        lastMoveTo = nil

        // Play the initial opponent move (the move that sets up the puzzle)
        // Actually in chess.com puzzles, the FEN is the position AFTER a move,
        // and the first solution move is what the user should play.
        // No initial move needed — user goes first.
    }

    func resetPuzzle() {
        guard let p = puzzle else { return }
        setupPuzzle(p)
    }

    // MARK: - User Interaction

    func tapSquare(_ square: Square) {
        guard isUserTurn && !puzzleCompleted && !wrongMove && !showPromotionPicker else { return }

        if let selected = selectedSquare {
            if legalMoveTargets.contains(square) {
                tryUserMove(from: selected, to: square)
            } else if let piece = board.piece(at: square), piece.color == sideToMove {
                selectSquare(square)
            } else {
                deselect()
            }
        } else {
            if let piece = board.piece(at: square), piece.color == sideToMove {
                selectSquare(square)
            }
        }
    }

    private func selectSquare(_ square: Square) {
        selectedSquare = square
        legalMoveTargets = computeLegalMoves(from: square)
    }

    private func deselect() {
        selectedSquare = nil
        legalMoveTargets = []
    }

    // MARK: - Move Validation

    func completePromotion(piece: PieceType) {
        guard let from = pendingPromotionFrom, let to = pendingPromotionTo else { return }
        showPromotionPicker = false
        pendingPromotionFrom = nil
        pendingPromotionTo = nil

        let promoChar = piece.symbol.lowercased()
        let playedUCI = "\(from.algebraic)\(to.algebraic)\(promoChar)"

        guard currentSolutionIndex < solutionMoves.count else { deselect(); return }
        let expectedUCI = solutionMoves[currentSolutionIndex]

        if playedUCI.lowercased() == expectedUCI.lowercased() {
            Analytics.puzzlePromotionCorrect(piece: promoChar)
            executeMove(uci: playedUCI, isUser: true)
            currentSolutionIndex += 1
            deselect()

            if currentSolutionIndex >= solutionMoves.count {
                puzzleCompleted = true
                SoundManager.shared.playCheckmate()
                let timeMs = Int((CFAbsoluteTimeGetCurrent() - puzzleStartTime) * 1000)
                Analytics.puzzleSolved(type: puzzleMode, attempts: puzzleAttempts, usedHint: false, timeMs: timeMs)
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                playOpponentResponse()
            }
        } else {
            // Wrong promotion piece
            let expectedPromo = expectedUCI.count == 5 ? String(expectedUCI.last!) : "?"
            Analytics.puzzlePromotionWrong(expected: expectedPromo, chosen: promoChar)
            wrongMove = true
            puzzleAttempts += 1
            SoundManager.shared.playCheck()
            deselect()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                wrongMove = false
            }
        }
    }

    private func isPawnPromotion(from: Square, to: Square) -> Bool {
        guard let piece = board.piece(at: from), piece.type == .pawn else { return false }
        return to.rank == 7 || to.rank == 0
    }

    private func tryUserMove(from: Square, to: Square) {
        let playedUCI = "\(from.algebraic)\(to.algebraic)"

        // Check if this matches the expected solution move
        guard currentSolutionIndex < solutionMoves.count else { deselect(); return }
        let expectedUCI = solutionMoves[currentSolutionIndex]

        // If this is a promotion move, show the picker
        if isPawnPromotion(from: from, to: to) && expectedUCI.count == 5
            && expectedUCI.lowercased().hasPrefix(playedUCI.lowercased()) {
            pendingPromotionFrom = from
            pendingPromotionTo = to
            showPromotionPicker = true
            Analytics.puzzlePromotionShown()
            deselect()
            return
        }

        if playedUCI.lowercased() == expectedUCI.lowercased() {
            // Correct move!
            executeMove(uci: playedUCI, isUser: true)
            currentSolutionIndex += 1
            deselect()

            // Check if puzzle is complete
            if currentSolutionIndex >= solutionMoves.count {
                puzzleCompleted = true
                SoundManager.shared.playCheckmate() // Victory haptic
                let timeMs = Int((CFAbsoluteTimeGetCurrent() - puzzleStartTime) * 1000)
                Analytics.puzzleSolved(type: puzzleMode, attempts: puzzleAttempts, usedHint: false, timeMs: timeMs)
                return
            }

            // Play the opponent's response after a brief natural pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                playOpponentResponse()
            }
        } else {
            // Wrong move — show error and revert
            wrongMove = true
            puzzleAttempts += 1
            SoundManager.shared.playCheck() // Error haptic

            // Execute the wrong move briefly to show it
            let san = board.uciToSAN(playedUCI)
            _ = board.makeMoveSAN(san)
            lastMoveFrom = from.algebraic
            lastMoveTo = to.algebraic
            deselect()

            // Revert after showing the wrong move briefly
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                // Rebuild board to the correct state
                rebuildBoard()
                wrongMove = false
            }
        }
    }

    private func playOpponentResponse() {
        guard currentSolutionIndex < solutionMoves.count else { return }
        let uci = solutionMoves[currentSolutionIndex]
        executeMove(uci: uci, isUser: false)
        currentSolutionIndex += 1

        // Check if puzzle complete after opponent's move
        if currentSolutionIndex >= solutionMoves.count {
            puzzleCompleted = true
            SoundManager.shared.playCheckmate()
            let timeMs = Int((CFAbsoluteTimeGetCurrent() - puzzleStartTime) * 1000)
            Analytics.puzzleSolved(type: puzzleMode, attempts: puzzleAttempts, usedHint: false, timeMs: timeMs)
        }
    }

    private func executeMove(uci: String, isUser: Bool) {
        let fenBefore = board.toFEN()
        let san = board.uciToSAN(uci)
        let isWhite = board.sideToMove == .white
        let parsed = UCIParser.parseUCIMove(uci)

        guard let result = board.makeMoveSAN(san) else { return }

        SoundManager.shared.playForMove(
            isCapture: result.captured != nil,
            isCheck: result.isCheck,
            isCheckmate: result.isCheckmate,
            isCastling: result.isCastling
        )

        lastMoveFrom = parsed?.from
        lastMoveTo = parsed?.to

        let move = GameMove(
            moveIndex: userMoves.count,
            san: san,
            from: parsed?.from ?? "",
            to: parsed?.to ?? "",
            fen: board.toFEN(),
            fenBefore: fenBefore,
            isWhite: isWhite,
            moveNumber: (userMoves.count / 2) + 1,
            piece: result.piece,
            captured: result.captured,
            promotion: result.promotion,
            isCheck: result.isCheck,
            isCheckmate: result.isCheckmate,
            isCastling: result.isCastling
        )
        userMoves.append(move)
    }

    private func rebuildBoard() {
        guard let puzzle = puzzle else { return }
        board = ChessBoard(fen: puzzle.fen)
        userMoves = []
        lastMoveFrom = nil
        lastMoveTo = nil

        // Replay correct moves up to current index
        for i in 0..<currentSolutionIndex {
            let uci = solutionMoves[i]
            let san = board.uciToSAN(uci)
            let parsed = UCIParser.parseUCIMove(uci)
            _ = board.makeMoveSAN(san)
            lastMoveFrom = parsed?.from
            lastMoveTo = parsed?.to
        }
    }

    // MARK: - PGN Solution Parser

    private func parseSolutionMoves(pgn: String) -> [String] {
        // Chess.com puzzle PGN contains the solution line
        // Parse moves and convert to UCI
        var tempBoard = ChessBoard(fen: puzzle?.fen ?? "")
        let moveText = PGNParser.extractMoveText(pgn)
        let sanMoves = PGNParser.parseMoveText(moveText)

        var uciMoves: [String] = []
        for san in sanMoves {
            // Find the move on the board to get from/to squares
            let uci = sanToUCI(san: san, board: tempBoard)
            if let uci = uci {
                uciMoves.append(uci)
                _ = tempBoard.makeMoveSAN(san)
            }
        }
        return uciMoves
    }

    private func sanToUCI(san: String, board: ChessBoard) -> String? {
        // Try making the move on a copy to find from/to
        var testBoard = board
        guard let result = testBoard.makeMoveSAN(san) else { return nil }
        var uci = "\(result.from.algebraic)\(result.to.algebraic)"
        if let promo = result.promotion {
            uci += promo.symbol.lowercased()
        }
        return uci
    }

    // MARK: - Legal Moves

    private func computeLegalMoves(from: Square) -> [Square] {
        guard let piece = board.piece(at: from), piece.color == sideToMove else { return [] }
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
                } else { canMove = board.canAttack(from: from, to: to, piece: piece) }

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
}
