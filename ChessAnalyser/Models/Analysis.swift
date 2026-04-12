import Foundation

struct EngineEval: Codable, Equatable {
    let score: Int          // centipawns from SIDE-TO-MOVE's perspective (Stockfish convention)
    let mate: Int?          // mate in N (positive = side-to-move mates, negative = opponent mates)
    let depth: Int
    let pv: [String]        // principal variation (UCI notation)
    let multipv: Int

    var isMate: Bool { mate != nil }

    /// Display text from side-to-move perspective (used raw)
    var displayText: String {
        if let mate = mate {
            return "M\(abs(mate))"
        }
        let value = Double(score) / 100.0
        if value > 0 {
            return "+\(String(format: "%.1f", value))"
        }
        return String(format: "%.1f", value)
    }

    /// Display text converted to white's perspective.
    /// `sideToMoveIsWhite`: true if the position this eval describes has white to move.
    func displayTextWhitePerspective(sideToMoveIsWhite: Bool) -> String {
        let whiteScore = sideToMoveIsWhite ? score : -score
        if let mate = mate {
            let whiteMate = sideToMoveIsWhite ? mate : -mate
            let prefix = whiteMate > 0 ? "+" : "-"
            return "\(prefix)M\(abs(whiteMate))"
        }
        let value = Double(whiteScore) / 100.0
        if value > 0 { return "+\(String(format: "%.1f", value))" }
        return String(format: "%.1f", value)
    }

    /// Eval bar percentage (0.0 = black winning, 1.0 = white winning).
    /// Must pass `sideToMoveIsWhite` since score is from side-to-move perspective.
    func barPercentage(sideToMoveIsWhite: Bool) -> Double {
        let whiteScore: Int
        if let mate = mate {
            let whiteMate = sideToMoveIsWhite ? mate : -mate
            return whiteMate > 0 ? 0.99 : 0.01
        } else {
            whiteScore = sideToMoveIsWhite ? score : -score
        }
        let clamped = max(-1000, min(1000, whiteScore))
        return 0.5 + (Double(clamped) / 2000.0)
    }

    /// Legacy bar percentage (assumes score is from white's perspective — only use for initial)
    var barPercentage: Double {
        barPercentage(sideToMoveIsWhite: true)
    }

    static let initial = EngineEval(score: 0, mate: nil, depth: 0, pv: [], multipv: 1)
}

struct EngineLine: Codable, Equatable {
    let eval: EngineEval
    let moves: [String]     // SAN notation for display
    let uciMoves: [String]  // UCI notation
}

struct MoveAnalysis: Codable, Identifiable, Equatable {
    var id: Int { moveIndex }
    let moveIndex: Int
    let san: String
    let from: String
    let to: String
    let fen: String
    let fenBefore: String
    let evalBefore: EngineEval
    let evalAfter: EngineEval
    let bestMove: String            // UCI notation
    let bestMoveSAN: String         // SAN notation
    let bestMoveEval: EngineEval
    let classification: MoveClassification
    let cpLoss: Int
    let engineLines: [EngineLine]
    let isWhite: Bool
    let moveNumber: Int
}

struct GameAnalysis: Codable, Identifiable {
    let id: String
    let pgn: String
    let moves: [MoveAnalysis]
    let white: String
    let black: String
    let whiteElo: String?
    let blackElo: String?
    let result: String
    let analyzedAt: Date
    let engineDepth: Int
    let whiteAccuracy: Double
    let blackAccuracy: Double

    var whiteMoveCount: [MoveClassification: Int] {
        var counts: [MoveClassification: Int] = [:]
        for move in moves where move.isWhite {
            counts[move.classification, default: 0] += 1
        }
        return counts
    }

    var blackMoveCount: [MoveClassification: Int] {
        var counts: [MoveClassification: Int] = [:]
        for move in moves where !move.isWhite {
            counts[move.classification, default: 0] += 1
        }
        return counts
    }
}

struct AnalysisProgress: Equatable {
    let currentMove: Int
    let totalMoves: Int
    let isAnalyzing: Bool
    let currentDepth: Int

    var percentage: Double {
        guard totalMoves > 0 else { return 0 }
        return Double(currentMove) / Double(totalMoves)
    }

    var displayText: String {
        "\(currentMove)/\(totalMoves) moves"
    }

    static let idle = AnalysisProgress(currentMove: 0, totalMoves: 0, isAnalyzing: false, currentDepth: 0)
}
