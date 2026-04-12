import Foundation

struct MoveClassifier {

    // MARK: - Expected Points (Win Probability)

    /// Convert a centipawn score (always from white's perspective) to white win probability.
    private static func winProbability(whiteCP: Int) -> Double {
        return 1.0 / (1.0 + exp(-0.00368208 * Double(whiteCP)))
    }

    /// Convert a Stockfish eval to white-perspective centipawns.
    ///
    /// IMPORTANT: Stockfish reports `score cp` from the side-to-move's perspective.
    /// - `evalBefore` a white move: white to move → score IS white's perspective
    /// - `evalAfter` a white move: black to move → score is BLACK's perspective → negate
    /// - `evalBefore` a black move: black to move → score is BLACK's perspective → negate
    /// - `evalAfter` a black move: white to move → score IS white's perspective
    ///
    /// `sideToMoveIsWhite`: true if white is the side to move in the position this eval describes.
    static func toWhiteCP(_ eval: EngineEval, sideToMoveIsWhite: Bool) -> Int {
        if let mate = eval.mate {
            // Mate is also from side-to-move perspective: positive = side to move mates
            let whiteMate = sideToMoveIsWhite ? mate : -mate
            return whiteMate > 0 ? (10000 - abs(whiteMate) * 10) : -(10000 - abs(whiteMate) * 10)
        }
        return sideToMoveIsWhite ? eval.score : -eval.score
    }

    /// Calculate expected points loss for a move.
    ///
    /// `before`: engine eval of position before the move (side to move = the player who moved)
    /// `after`: engine eval of position after the move (side to move = the opponent)
    /// `isWhite`: true if the moving player is white
    static func expectedPointsLoss(
        before: EngineEval,
        after: EngineEval,
        isWhite: Bool
    ) -> Double {
        // Convert both evals to white's perspective
        let whiteCPBefore = toWhiteCP(before, sideToMoveIsWhite: isWhite)
        let whiteCPAfter = toWhiteCP(after, sideToMoveIsWhite: !isWhite) // side flipped after move

        let wpBefore = winProbability(whiteCP: whiteCPBefore)
        let wpAfter = winProbability(whiteCP: whiteCPAfter)

        // Loss from the moving player's perspective (WintrChess formula)
        let rawLoss = (wpBefore - wpAfter) * (isWhite ? 1.0 : -1.0)
        return max(0, rawLoss)
    }

    /// Get expected points (win probability) for a player given an eval.
    /// `eval` is from side-to-move perspective, `sideToMoveIsWhite` tells us which side.
    static func expectedPoints(_ eval: EngineEval, sideToMoveIsWhite: Bool, forWhite: Bool) -> Double {
        let whiteCP = toWhiteCP(eval, sideToMoveIsWhite: sideToMoveIsWhite)
        let wp = winProbability(whiteCP: whiteCP)
        return forWhite ? wp : (1.0 - wp)
    }

    // MARK: - Main Classification

    /// Classify a move using expected points loss (WintrChess-inspired).
    static func classify(
        evalBefore: EngineEval,
        evalAfter: EngineEval,
        bestMoveEval: EngineEval,
        secondBestEval: EngineEval?,
        playedMoveUCI: String,
        bestMoveUCI: String,
        fenBefore: String,
        fenAfter: String,
        isWhite: Bool,
        legalMoveCount: Int
    ) -> MoveClassification {
        // Book move
        if OpeningBook.shared.isBookPosition(fenAfter) {
            return .book
        }

        // Forced move
        if legalMoveCount == 1 {
            return .forced
        }

        let isBestMove = normalizeUCI(playedMoveUCI) == normalizeUCI(bestMoveUCI)
        let color: PieceColor = isWhite ? .white : .black

        // If it's the best move, check for brilliant or great
        if isBestMove {
            let isPromotion = playedMoveUCI.count > 4

            if !isPromotion && considerBrilliant(
                playedMoveUCI: playedMoveUCI,
                fenBefore: fenBefore,
                fenAfter: fenAfter,
                color: color,
                bestMoveEval: bestMoveEval,
                secondBestEval: secondBestEval,
                isWhite: isWhite
            ) {
                return .brilliant
            }

            // Great = genuinely hard to find:
            if let secondEval = secondBestEval {
                let secondLoss = expectedPointsLoss(before: bestMoveEval, after: secondEval, isWhite: isWhite)
                let currentWinProb = expectedPoints(bestMoveEval, sideToMoveIsWhite: isWhite, forWhite: isWhite)
                if secondLoss >= 0.20 && currentWinProb > 0.20 && currentWinProb < 0.80 {
                    return .great
                }
            }

            return .best
        }

        // Non-best move: classify by point loss
        let baseClassification = pointLossClassify(
            evalBefore: evalBefore,
            evalAfter: evalAfter,
            isWhite: isWhite
        )

        // Check for "miss" — a mild move that overlooked a significantly better opportunity
        if shouldClassifyAsMiss(
            baseClassification: baseClassification,
            evalBefore: evalBefore,
            evalAfter: evalAfter,
            bestMoveEval: bestMoveEval,
            fenBefore: fenBefore,
            isWhite: isWhite
        ) {
            return .miss
        }

        return baseClassification
    }

    // MARK: - Miss Detection

    /// A "miss" is when the played move is passable (ok/good/excellent) but a much better
    /// opportunity existed — like winning material, forcing mate, or gaining a decisive advantage.
    private static func shouldClassifyAsMiss(
        baseClassification: MoveClassification,
        evalBefore: EngineEval,
        evalAfter: EngineEval,
        bestMoveEval: EngineEval,
        fenBefore: String,
        isWhite: Bool
    ) -> Bool {
        // Only upgrade mild-to-moderate classifications to "miss"
        guard [.excellent, .good, .ok, .inaccuracy].contains(baseClassification) else { return false }

        // 1. Missed checkmate: best move leads to mate, played move doesn't
        if bestMoveEval.isMate && !evalAfter.isMate {
            // bestMoveEval.mate is from side-to-move perspective: positive = side to move mates
            if let mate = bestMoveEval.mate, mate > 0 {
                return true // Missed a winning mate
            }
        }

        // Convert to moving side's perspective for comparisons
        let bestWhiteCP = toWhiteCP(bestMoveEval, sideToMoveIsWhite: isWhite)
        let playedWhiteCP = toWhiteCP(evalAfter, sideToMoveIsWhite: !isWhite)

        // From the moving player's perspective
        let bestForMe = isWhite ? bestWhiteCP : -bestWhiteCP
        let playedForMe = isWhite ? playedWhiteCP : -playedWhiteCP

        // 2. Missed winning advantage: best move gives ≥150cp more than played
        let missedGain = bestForMe - playedForMe
        if missedGain >= 150 && bestForMe >= 100 {
            return true
        }

        // 3. Missed going from equal to winning
        let beforeWhiteCP = toWhiteCP(evalBefore, sideToMoveIsWhite: isWhite)
        let beforeForMe = isWhite ? beforeWhiteCP : -beforeWhiteCP
        if beforeForMe < 80 && bestForMe >= 200 && playedForMe < 100 {
            return true
        }

        return false
    }

    /// Backward-compatible overload (no secondBestEval)
    static func classify(
        evalBefore: EngineEval,
        evalAfter: EngineEval,
        bestMoveEval: EngineEval,
        playedMoveUCI: String,
        bestMoveUCI: String,
        fenBefore: String,
        fenAfter: String,
        isWhite: Bool,
        legalMoveCount: Int
    ) -> MoveClassification {
        return classify(
            evalBefore: evalBefore,
            evalAfter: evalAfter,
            bestMoveEval: bestMoveEval,
            secondBestEval: nil,
            playedMoveUCI: playedMoveUCI,
            bestMoveUCI: bestMoveUCI,
            fenBefore: fenBefore,
            fenAfter: fenAfter,
            isWhite: isWhite,
            legalMoveCount: legalMoveCount
        )
    }

    // MARK: - Point Loss Classification (WintrChess-inspired)

    /// Classify using expected points loss, with special mate transition handling.
    private static func pointLossClassify(
        evalBefore: EngineEval,
        evalAfter: EngineEval,
        isWhite: Bool
    ) -> MoveClassification {
        // Subjective values (from the moving side's perspective)
        let subjectiveBefore = subjectiveValue(evalBefore, isWhite: isWhite)
        let subjectiveAfter = subjectiveValue(evalAfter, isWhite: isWhite)

        // === Mate-to-Mate transitions ===
        if evalBefore.isMate && evalAfter.isMate {
            let mateBefore = subjectiveBefore
            let mateAfter = subjectiveAfter

            // Had winning mate, now losing mate → blunder or mistake
            if mateBefore > 0 && mateAfter < 0 {
                return mateAfter < -3 ? .mistake : .blunder
            }

            // For the losing side, keeping the same mate distance is best.
            // For the winning side, a loss of 1 is normal (opponent played a move).
            let mateLoss = mateAfter - mateBefore
            if mateLoss >= 0 || (mateLoss == 0 && mateAfter < 0) {
                return .best
            } else if abs(mateLoss) < 2 {
                return .excellent
            } else if abs(mateLoss) < 7 {
                return .ok
            } else {
                return .inaccuracy
            }
        }

        // === Mate-to-Centipawn transitions ===
        // Had a forced mate, now just a centipawn advantage — lost the mate
        if evalBefore.isMate && !evalAfter.isMate {
            let cpAfter = isWhite ? evalAfter.score : -evalAfter.score
            if cpAfter >= 800 { return .excellent }
            if cpAfter >= 400 { return .ok }
            if cpAfter >= 200 { return .inaccuracy }
            if cpAfter >= 0 { return .mistake }
            return .blunder
        }

        // === Centipawn-to-Mate transitions ===
        // Didn't have mate before, now there's a forced mate
        if !evalBefore.isMate && evalAfter.isMate {
            let mateAfter = subjectiveAfter
            if mateAfter > 0 {
                return .best // Found a mate — great!
            }
            // Allowed opponent to get a mate
            if mateAfter >= -2 { return .blunder }
            if mateAfter >= -5 { return .mistake }
            return .inaccuracy
        }

        // === Centipawn-to-Centipawn (normal case) ===
        let pointLoss = expectedPointsLoss(before: evalBefore, after: evalAfter, isWhite: isWhite)

        if pointLoss < 0.01 { return .best }
        if pointLoss < 0.03 { return .excellent }
        if pointLoss < 0.06 { return .good }
        if pointLoss < 0.09 { return .ok }
        if pointLoss < 0.13 { return .inaccuracy }
        if pointLoss < 0.22 { return .mistake }
        return .blunder
    }

    /// Get subjective mate value from the moving side's perspective.
    /// Positive = moving side has mate, negative = opponent has mate.
    private static func subjectiveValue(_ eval: EngineEval, isWhite: Bool) -> Int {
        if let mate = eval.mate {
            return isWhite ? mate : -mate
        }
        return isWhite ? eval.score : -eval.score
    }

    // MARK: - Brilliant Helpers

    /// Check if the played move is escaping a trapped piece (not brilliant)
    /// Chess.com-style brilliant detection (WintrChess algorithm).
    ///
    /// A move is brilliant when:
    /// 1. It's the engine's best move
    /// 2. NOT a promotion
    /// 3. After the move, the player has pieces under attack (en prise) that aren't adequately defended
    ///    OR the move is a direct material sacrifice (net material loss)
    /// 4. The move doesn't simply escape a trapped piece to safety
    /// 5. The unsafe pieces aren't ALL trapped (inevitable losses aren't brilliant)
    /// 6. It's not in a completely winning/losing position (the move matters)
    /// 7. The 2nd best move is noticeably worse (the find is non-trivial)
    private static func considerBrilliant(
        playedMoveUCI: String,
        fenBefore: String,
        fenAfter: String,
        color: PieceColor,
        bestMoveEval: EngineEval,
        secondBestEval: EngineEval?,
        isWhite: Bool
    ) -> Bool {
        // --- Cheap checks first (no board allocation) ---

        // Position matters (not already completely winning/losing)
        let winProb = expectedPoints(bestMoveEval, sideToMoveIsWhite: isWhite, forWhite: isWhite)
        if winProb > 0.92 || winProb < 0.08 { return false }

        // Not in a losing position / sacrifice must maintain advantage
        let subjectiveEval = isWhite ? toWhiteCP(bestMoveEval, sideToMoveIsWhite: isWhite) :
                                       -toWhiteCP(bestMoveEval, sideToMoveIsWhite: isWhite)
        if subjectiveEval < 0 { return false }

        // 2nd best is noticeably worse (the find is non-trivial)
        if let secondEval = secondBestEval {
            let secondLoss = expectedPointsLoss(before: bestMoveEval, after: secondEval, isWhite: isWhite)
            if secondLoss < 0.05 { return false }
        }

        guard let fromSq = Square(algebraic: String(playedMoveUCI.prefix(2))),
              let toSq = Square(algebraic: String(playedMoveUCI.dropFirst(2).prefix(2))) else { return false }

        // --- Now allocate boards (needed for remaining checks) ---
        let boardBefore = ChessBoard(fen: fenBefore)

        // Equal captures are NOT brilliant
        let capturedPiece = boardBefore.piece(at: toSq)
        let movingPiece = boardBefore.piece(at: fromSq)
        if let captured = capturedPiece, let moving = movingPiece {
            if captured.type.materialValue >= moving.type.materialValue {
                return false
            }
        }

        // Direct material sacrifice check
        let materialSacrifice = detectSacrifice(fenBefore: fenBefore, fenAfter: fenAfter, isWhite: isWhite)

        // If no 2nd best line and no sacrifice, bail early (before expensive PieceAnalysis)
        if secondBestEval == nil && !materialSacrifice { return false }

        let boardAfter = ChessBoard(fen: fenAfter)

        // Piece left en prise after the move
        let currentUnsafe = PieceAnalysis.getUnsafePieces(board: boardAfter, color: color)
        let hasEnPrisePieces = !currentUnsafe.isEmpty

        // Must have at least one form of risk
        guard materialSacrifice || hasEnPrisePieces else { return false }

        // Not just moving to safety
        if hasEnPrisePieces && !materialSacrifice && !boardAfter.isKingInCheck(color: color.opposite) {
            let previousUnsafe = PieceAnalysis.getUnsafePieces(board: boardBefore, color: color)
            if currentUnsafe.count < previousUnsafe.count {
                return false
            }
        }

        // Not escaping a trapped piece (only check if the moved piece was unsafe)
        if let _ = boardBefore.piece(at: fromSq) {
            if !PieceAnalysis.isPieceSafe(board: boardBefore, square: fromSq) {
                if PieceAnalysis.isPieceTrapped(board: boardBefore, square: fromSq) {
                    return false
                }
            }
        }

        // Not ALL unsafe pieces are trapped (inevitable losses)
        if hasEnPrisePieces && currentUnsafe.count <= 3 {
            let trappedCount = currentUnsafe.filter { PieceAnalysis.isPieceTrapped(board: boardAfter, square: $0.square) }.count
            if trappedCount == currentUnsafe.count { return false }
        }

        return true
    }

    private static func isEscapingTrappedPiece(
        playedMoveUCI: String,
        fenBefore: String,
        color: PieceColor
    ) -> Bool {
        guard let fromSq = Square(algebraic: String(playedMoveUCI.prefix(2))) else { return false }
        let board = ChessBoard(fen: fenBefore)
        return board.isPieceTrapped(at: fromSq)
    }

    // MARK: - Helpers

    private static func normalizeUCI(_ uci: String) -> String {
        uci.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Legacy material-based sacrifice detection (used by explainer)
    static func detectSacrifice(fenBefore: String, fenAfter: String, isWhite: Bool) -> Bool {
        let boardBefore = ChessBoard(fen: fenBefore)
        let boardAfter = ChessBoard(fen: fenAfter)
        let color: PieceColor = isWhite ? .white : .black
        let ourLoss = boardBefore.materialCount(for: color) - boardAfter.materialCount(for: color)
        let theirLoss = boardBefore.materialCount(for: color.opposite) - boardAfter.materialCount(for: color.opposite)
        return (ourLoss - theirLoss) >= 2
    }

    // MARK: - Accuracy (WintrChess formula)

    /// Per-move accuracy: 103.16 * exp(-4 * pointLoss) - 3.17
    /// Matches WintrChess/chess.com accuracy calculation.
    static func moveAccuracy(evalBefore: EngineEval, evalAfter: EngineEval, isWhite: Bool) -> Double {
        let pointLoss = expectedPointsLoss(before: evalBefore, after: evalAfter, isWhite: isWhite)
        let acc = 103.16 * exp(-4.0 * pointLoss) - 3.17
        return max(0, min(100, acc))
    }

    /// Game accuracy = mean of per-move accuracies for a side.
    static func calculateAccuracy(moves: [MoveAnalysis], isWhite: Bool) -> Double {
        let sideMoves = moves.filter { $0.isWhite == isWhite }
        guard !sideMoves.isEmpty else { return 100.0 }

        let totalAcc = sideMoves.reduce(0.0) { sum, move in
            sum + moveAccuracy(evalBefore: move.evalBefore, evalAfter: move.evalAfter, isWhite: isWhite)
        }
        return totalAcc / Double(sideMoves.count)
    }

    /// Backward-compatible cp-based accuracy
    static func calculateAccuracy(averageCPLoss: Double) -> Double {
        let accuracy = 103.1668 * exp(-0.04354 * averageCPLoss) - 3.1669
        return max(0, min(100, accuracy))
    }
}
