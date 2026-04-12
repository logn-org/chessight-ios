import Foundation

struct MoveExplainer {

    /// One-line summary for the compact info bar
    static func explainShort(_ analysis: MoveAnalysis) -> String {
        let bestMove = analysis.bestMoveSAN
        let cpLoss = analysis.cpLoss

        switch analysis.classification {
        case .brilliant:
            return "A brilliant sacrifice — the engine's top choice"
        case .great:
            return "Near-perfect play"
        case .best:
            return "The engine's top recommendation"
        case .excellent:
            return "Very strong, only \(cpLossText(cpLoss)) from best"
        case .good:
            return "Solid move, \(cpLossText(cpLoss)) from best (\(bestMove))"
        case .ok:
            return "Playable but \(bestMove) was \(cpLossText(cpLoss)) better"
        case .book:
            if let name = OpeningBook.shared.openingName(for: analysis.fen) {
                return name
            }
            return "Opening theory"
        case .miss:
            if analysis.bestMoveEval.isMate {
                return "Missed checkmate! \(bestMove) wins"
            }
            return "Missed \(bestMove) which wins \(cpLossText(cpLoss))"
        case .inaccuracy:
            return "\(bestMove) was \(cpLossText(cpLoss)) better"
        case .mistake:
            return "Should have played \(bestMove) (\(cpLossText(cpLoss)) lost)"
        case .blunder:
            if cpLoss >= 500 {
                return "Loses \(materialLossDescription(cpLoss))! Best was \(bestMove)"
            }
            return "Serious error — \(bestMove) was \(cpLossText(cpLoss)) better"
        case .forced:
            return "Only legal move"
        case .none:
            return ""
        }
    }

    /// Generate a human-readable explanation for why a move was classified the way it was.
    static func explain(_ analysis: MoveAnalysis) -> String {
        let side = analysis.isWhite ? "White" : "Black"
        let san = analysis.san
        let cpLoss = analysis.cpLoss
        let evalBefore = analysis.evalBefore
        let evalAfter = analysis.evalAfter
        let bestMove = analysis.bestMoveSAN
        let isBestMove = "\(analysis.from)\(analysis.to)" == analysis.bestMove

        let isSacrifice = MoveClassifier.detectSacrifice(
            fenBefore: analysis.fenBefore,
            fenAfter: analysis.fen,
            isWhite: analysis.isWhite
        )

        switch analysis.classification {
        case .brilliant:
            return buildBrilliantExplanation(
                san: san, side: side, isSacrifice: isSacrifice,
                evalBefore: evalBefore, evalAfter: evalAfter
            )

        case .great:
            if isBestMove {
                return "\(san) is the top engine choice. A strong move that maintains \(side)'s advantage with no material or positional cost."
            }
            return "\(san) is nearly as good as the best move \(bestMove). \(side) loses only \(cpLossText(cpLoss)) — a negligible difference."

        case .best:
            return "\(san) is the engine's top recommendation. This is the strongest move in the position\(evalContext(evalAfter, side: side))."

        case .excellent:
            return "\(san) is a strong move, losing only \(cpLossText(cpLoss)) compared to the best move \(bestMove). \(evalShiftDescription(evalBefore, evalAfter, side: side))"

        case .good:
            return "\(san) is a solid move. The best move was \(bestMove)\(cpLoss > 0 ? ", which would have been \(cpLossText(cpLoss)) better" : ""). \(evalShiftDescription(evalBefore, evalAfter, side: side))"

        case .ok:
            return "\(san) is playable but not ideal. There was a better option — \(bestMove) was \(cpLossText(cpLoss)) stronger. The position is still manageable but \(side) missed a chance to play more precisely."

        case .book:
            if let name = OpeningBook.shared.openingName(for: analysis.fen) {
                return "\(san) is a book move from the \(name)."
            }
            return "\(san) is a well-known opening move from theory."

        case .miss:
            return buildMissExplanation(
                san: san, side: side, bestMove: bestMove,
                evalBefore: evalBefore, evalAfter: evalAfter,
                bestMoveEval: analysis.bestMoveEval
            )

        case .inaccuracy:
            return buildInaccuracyExplanation(
                san: san, side: side, bestMove: bestMove,
                cpLoss: cpLoss, evalBefore: evalBefore, evalAfter: evalAfter
            )

        case .mistake:
            return buildMistakeExplanation(
                san: san, side: side, bestMove: bestMove,
                cpLoss: cpLoss, evalBefore: evalBefore, evalAfter: evalAfter
            )

        case .blunder:
            return buildBlunderExplanation(
                san: san, side: side, bestMove: bestMove,
                cpLoss: cpLoss, evalBefore: evalBefore, evalAfter: evalAfter
            )

        case .forced:
            return "\(san) is the only legal move in this position."

        case .none:
            return ""
        }
    }

    // MARK: - Brilliant

    private static func buildBrilliantExplanation(
        san: String, side: String, isSacrifice: Bool,
        evalBefore: EngineEval, evalAfter: EngineEval
    ) -> String {
        if isSacrifice {
            return "\(san) is a brilliant sacrifice! \(side) gives up material but gains a decisive advantage. The engine confirms this is the best move despite the material cost\(evalContext(evalAfter, side: side))."
        }
        return "\(san) is a brilliant move — the only way to maintain \(side)'s position. A difficult find that the engine rates as the top choice\(evalContext(evalAfter, side: side))."
    }

    // MARK: - Missed Win

    private static func buildMissExplanation(
        san: String, side: String, bestMove: String,
        evalBefore: EngineEval, evalAfter: EngineEval,
        bestMoveEval: EngineEval
    ) -> String {
        if bestMoveEval.isMate {
            let mate = bestMoveEval.mate ?? 0
            return "\(san) is not a bad move, but \(side) missed a forced checkmate! \(bestMove) leads to mate in \(abs(mate)). This was a critical moment where the game could have been decided."
        }

        let bestCP = abs(bestMoveEval.score)
        let advantage = Double(bestCP) / 100.0

        if advantage >= 5.0 {
            return "\(san) is a decent move, but \(side) missed a winning opportunity. \(bestMove) would have given a decisive advantage of +\(String(format: "%.1f", advantage)). The position was still playable after \(san), but the game-changing moment was overlooked."
        }

        if advantage >= 3.0 {
            return "\(san) is playable, but \(side) missed \(bestMove) which would have won significant material. The best move gives an advantage of +\(String(format: "%.1f", advantage)) — enough to convert the game."
        }

        return "\(san) is an okay move, but \(side) missed the stronger \(bestMove) which gives a clear advantage. The opportunity to seize control of the position was not taken."
    }

    // MARK: - Inaccuracy

    private static func buildInaccuracyExplanation(
        san: String, side: String, bestMove: String,
        cpLoss: Int, evalBefore: EngineEval, evalAfter: EngineEval
    ) -> String {
        var parts = ["\(san) is a slight inaccuracy."]

        if didLoseAdvantage(evalBefore, evalAfter, side: side) {
            parts.append("\(side) had an advantage but this move lets it slip.")
        }

        parts.append("The best move was \(bestMove), which was \(cpLossText(cpLoss)) better.")
        return parts.joined(separator: " ")
    }

    // MARK: - Mistake

    private static func buildMistakeExplanation(
        san: String, side: String, bestMove: String,
        cpLoss: Int, evalBefore: EngineEval, evalAfter: EngineEval
    ) -> String {
        var parts = ["\(san) is a mistake, losing \(cpLossText(cpLoss))."]

        if didSwingEval(evalBefore, evalAfter) {
            parts.append("This move shifts the evaluation significantly.")
        }
        if didLoseAdvantage(evalBefore, evalAfter, side: side) {
            parts.append("\(side) goes from a winning position to an equal or worse one.")
        }

        parts.append("The best move was \(bestMove)\(bestMoveEvalContext(evalBefore, side: side)).")
        return parts.joined(separator: " ")
    }

    // MARK: - Blunder

    private static func buildBlunderExplanation(
        san: String, side: String, bestMove: String,
        cpLoss: Int, evalBefore: EngineEval, evalAfter: EngineEval
    ) -> String {
        var parts: [String] = []

        if evalAfter.isMate {
            parts.append("\(san) is a blunder that allows checkmate.")
        } else if cpLoss >= 500 {
            parts.append("\(san) is a serious blunder, losing the equivalent of \(materialLossDescription(cpLoss)).")
        } else {
            parts.append("\(san) is a blunder, losing \(cpLossText(cpLoss)).")
        }

        if didSwingEval(evalBefore, evalAfter) {
            let opponent = side == "White" ? "Black" : "White"
            if wasWinning(evalBefore, side: side) && isLosing(evalAfter, side: side) {
                parts.append("\(side) went from a winning position to a losing one — \(opponent) now has a clear advantage.")
            } else if wasWinning(evalBefore, side: side) {
                parts.append("This throws away \(side)'s advantage.")
            }
        }

        parts.append("The best move was \(bestMove).")
        return parts.joined(separator: " ")
    }

    // MARK: - Helpers

    /// cpLoss is stored as millipawns of win probability (0-1000 = 0%-100%)
    private static func cpLossText(_ cpLoss: Int) -> String {
        let pct = Double(cpLoss) / 10.0 // Convert millipawns to percentage
        if pct < 1.0 {
            return String(format: "%.1f%%", pct)
        }
        return String(format: "%.0f%%", pct) + " win chance"
    }

    private static func materialLossDescription(_ cpLoss: Int) -> String {
        let pct = Double(cpLoss) / 10.0
        if pct >= 40 { return "the game" }
        if pct >= 25 { return "a decisive advantage" }
        if pct >= 15 { return "a significant advantage" }
        return String(format: "%.0f%% win chance", pct)
    }

    private static func evalContext(_ eval: EngineEval, side: String) -> String {
        if let mate = eval.mate {
            let mateSide = mate > 0 ? "White" : "Black"
            return ", with mate in \(abs(mate)) for \(mateSide)"
        }
        let pawns = Double(eval.score) / 100.0
        if abs(pawns) < 0.3 { return " in an equal position" }
        let advantage = pawns > 0 ? "White" : "Black"
        return String(format: " (%.1f advantage for %@)", abs(pawns), advantage)
    }

    private static func bestMoveEvalContext(_ evalBefore: EngineEval, side: String) -> String {
        if evalBefore.isMate { return "" }
        let pawns = Double(evalBefore.score) / 100.0
        if abs(pawns) < 0.3 { return ", keeping the position balanced" }
        let sideHasAdvantage = (side == "White" && pawns > 0) || (side == "Black" && pawns < 0)
        if sideHasAdvantage {
            return ", maintaining the advantage"
        }
        return ""
    }

    private static func evalShiftDescription(_ before: EngineEval, _ after: EngineEval, side: String) -> String {
        let shift = abs(after.score - before.score)
        if shift < 30 { return "The position remains roughly the same." }
        if shift < 80 { return "A small shift in evaluation." }
        return ""
    }

    private static func didLoseAdvantage(_ before: EngineEval, _ after: EngineEval, side: String) -> Bool {
        let beforeCP = side == "White" ? before.score : -before.score
        let afterCP = side == "White" ? after.score : -after.score
        return beforeCP > 50 && afterCP < 20
    }

    private static func didSwingEval(_ before: EngineEval, _ after: EngineEval) -> Bool {
        abs(after.score - before.score) > 150
    }

    private static func wasWinning(_ eval: EngineEval, side: String) -> Bool {
        let cp = side == "White" ? eval.score : -eval.score
        return cp > 100
    }

    private static func isLosing(_ eval: EngineEval, side: String) -> Bool {
        let cp = side == "White" ? eval.score : -eval.score
        return cp < -100
    }
}
