import Foundation

// MARK: - UCI Output Types

enum UCIOutput: Equatable {
    case info(UCIInfoLine)
    case bestMove(move: String, ponder: String?)
    case readyOk
    case uciOk
    case unknown(String)
}

struct UCIInfoLine: Equatable {
    var depth: Int = 0
    var selDepth: Int = 0
    var score: Int = 0        // centipawns (white perspective)
    var mate: Int? = nil      // mate in N
    var multipv: Int = 1
    var pv: [String] = []     // principal variation (UCI notation)
    var nodes: Int? = nil
    var nps: Int? = nil
    var time: Int? = nil
}

// MARK: - UCI Command Building

enum UCICommand {
    static func uci() -> String { "uci" }
    static func isReady() -> String { "isready" }
    static func uciNewGame() -> String { "ucinewgame" }
    static func stop() -> String { "stop" }
    static func quit() -> String { "quit" }

    static func position(fen: String) -> String {
        "position fen \(fen)"
    }

    static func position(fen: String, moves: [String]) -> String {
        if moves.isEmpty {
            return "position fen \(fen)"
        }
        return "position fen \(fen) moves \(moves.joined(separator: " "))"
    }

    static func go(depth: Int) -> String {
        "go depth \(depth)"
    }

    static func go(moveTime: Int) -> String {
        "go movetime \(moveTime)"
    }

    static func setOption(name: String, value: String) -> String {
        "setoption name \(name) value \(value)"
    }

    static func setThreads(_ count: Int) -> String {
        setOption(name: "Threads", value: "\(count)")
    }

    static func setHash(_ mb: Int) -> String {
        setOption(name: "Hash", value: "\(mb)")
    }

    static func setMultiPV(_ count: Int) -> String {
        setOption(name: "MultiPV", value: "\(count)")
    }
}

// MARK: - UCI Response Parsing

enum UCIParser {

    static func parseLine(_ line: String) -> UCIOutput {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed == "readyok" { return .readyOk }
        if trimmed == "uciok" { return .uciOk }

        if trimmed.hasPrefix("bestmove") {
            return parseBestMove(trimmed)
        }

        if trimmed.hasPrefix("info") && trimmed.contains("depth") {
            if let info = parseInfoLine(trimmed) {
                return .info(info)
            }
        }

        return .unknown(trimmed)
    }

    static func parseBestMove(_ line: String) -> UCIOutput {
        let parts = line.split(separator: " ")
        var bestMove = ""
        var ponder: String? = nil

        for i in 0..<parts.count {
            if parts[i] == "bestmove" && i + 1 < parts.count {
                bestMove = String(parts[i + 1])
            }
            if parts[i] == "ponder" && i + 1 < parts.count {
                ponder = String(parts[i + 1])
            }
        }

        return .bestMove(move: bestMove, ponder: ponder)
    }

    static func parseInfoLine(_ line: String) -> UCIInfoLine? {
        let parts = line.split(separator: " ").map(String.init)
        var info = UCIInfoLine()
        var i = 0

        while i < parts.count {
            switch parts[i] {
            case "depth":
                i += 1
                if i < parts.count { info.depth = Int(parts[i]) ?? 0 }

            case "seldepth":
                i += 1
                if i < parts.count { info.selDepth = Int(parts[i]) ?? 0 }

            case "multipv":
                i += 1
                if i < parts.count { info.multipv = Int(parts[i]) ?? 1 }

            case "score":
                i += 1
                if i < parts.count {
                    if parts[i] == "cp" {
                        i += 1
                        if i < parts.count { info.score = Int(parts[i]) ?? 0 }
                    } else if parts[i] == "mate" {
                        i += 1
                        if i < parts.count { info.mate = Int(parts[i]) }
                    }
                }

            case "nodes":
                i += 1
                if i < parts.count { info.nodes = Int(parts[i]) }

            case "nps":
                i += 1
                if i < parts.count { info.nps = Int(parts[i]) }

            case "time":
                i += 1
                if i < parts.count { info.time = Int(parts[i]) }

            case "pv":
                // Everything after "pv" is the principal variation
                i += 1
                info.pv = Array(parts[i...])
                i = parts.count // Done

            default:
                break
            }
            i += 1
        }

        // Only return if we got meaningful data
        guard info.depth > 0 else { return nil }
        return info
    }

    // MARK: - UCI Move to Squares

    static func parseUCIMove(_ uci: String) -> (from: String, to: String, promotion: String?)? {
        guard uci.count >= 4 else { return nil }
        let from = String(uci.prefix(2))
        let to = String(uci.dropFirst(2).prefix(2))
        let promotion = uci.count > 4 ? String(uci.suffix(1)) : nil
        return (from, to, promotion)
    }
}
