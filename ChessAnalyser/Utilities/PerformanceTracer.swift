import Foundation
import FirebasePerformance

/// Centralized performance tracing via Firebase Performance.
enum PerformanceTracer {

    // MARK: - Trace Helpers

    /// Start a named trace. Call `.stop()` on the returned trace when done.
    static func start(_ name: String) -> Trace? {
        let trace = Performance.startTrace(name: name)
        return trace
    }

    // MARK: - Engine Traces

    /// Trace Stockfish engine initialization.
    static func traceEngineInit() -> Trace? {
        return start("engine_init")
    }

    /// Trace full game analysis (all moves).
    static func traceGameAnalysis(moveCount: Int) -> Trace? {
        let trace = start("game_analysis")
        trace?.setValue(Int64(moveCount), forMetric: "move_count")
        return trace
    }

    /// Trace single position eval.
    static func tracePositionEval() -> Trace? {
        return start("position_eval")
    }

    // MARK: - Network Traces

    /// Trace chess.com game resolution.
    static func traceGameResolve() -> Trace? {
        return start("chesscom_game_resolve")
    }

    /// Trace chess.com profile fetch.
    static func traceProfileFetch() -> Trace? {
        return start("chesscom_profile_fetch")
    }

    /// Trace puzzle fetch.
    static func tracePuzzleFetch() -> Trace? {
        return start("puzzle_fetch")
    }

    // MARK: - UI Traces

    /// Trace PGN parsing and validation.
    static func tracePGNParse() -> Trace? {
        return start("pgn_parse")
    }

    /// Trace TCN decoding.
    static func traceTCNDecode() -> Trace? {
        return start("tcn_decode")
    }

    /// Trace move classification (all moves in a game).
    static func traceMoveClassification(moveCount: Int) -> Trace? {
        let trace = start("move_classification")
        trace?.setValue(Int64(moveCount), forMetric: "move_count")
        return trace
    }
}
