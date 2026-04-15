import Foundation
import FirebaseAnalytics

/// Centralized analytics tracking via Firebase Analytics.
/// No user identification — tracks only app usage patterns for improvement.
enum Analytics {

    // MARK: - Core Logging

    private static func log(_ event: String, params: [String: Any]? = nil) {
        FirebaseAnalytics.Analytics.logEvent(event, parameters: params)
    }

    // MARK: - Feature Usage

    static func gameAnalyzed(source: String, moveCount: Int, depthPreset: String) {
        log("game_analyzed", params: [
            "source": source,
            "move_count": moveCount,
            "depth_preset": depthPreset
        ])
    }

    static func gameLoadedFromProfile(timeClass: String) {
        log("game_loaded_from_profile", params: ["time_class": timeClass])
    }

    static func puzzleSolved(type: String, attempts: Int, usedHint: Bool, timeMs: Int) {
        log("puzzle_solved", params: [
            "puzzle_type": type,
            "attempts": attempts,
            "used_hint": usedHint,
            "time_to_solve_ms": timeMs
        ])
    }

    static func puzzleFailed(type: String, attempts: Int) {
        log("puzzle_failed", params: ["puzzle_type": type, "attempts": attempts])
    }

    static func botGameStarted(playerColor: String, botDepth: Int, fromEditor: Bool) {
        log("bot_game_started", params: [
            "player_color": playerColor,
            "bot_depth": botDepth,
            "from_editor": fromEditor
        ])
    }

    static func botGameEnded(result: String, moveCount: Int, durationMs: Int) {
        log("bot_game_ended", params: [
            "result": result,
            "move_count": moveCount,
            "duration_ms": durationMs
        ])
    }

    static func boardEditorUsed(action: String, loadedFEN: Bool) {
        log("board_editor_used", params: ["action": action, "loaded_fen": loadedFEN])
    }

    static func variationExplored(moveCount: Int, fromGame: Bool) {
        log("variation_explored", params: ["move_count": moveCount, "from_game": fromGame])
    }

    static func profileAdded() {
        log("profile_added")
    }

    static func profileGamesBrowsed(gamesViewedCount: Int) {
        log("profile_games_browsed", params: ["games_viewed_count": gamesViewedCount])
    }

    static func pgnImported(method: String, valid: Bool) {
        log("pgn_imported", params: ["method": method, "valid": valid])
    }

    static func shareExtensionUsed(contentType: String) {
        log("share_extension_used", params: ["content_type": contentType])
    }

    // MARK: - Engine Performance

    static func analysisCompleted(moveCount: Int, durationMs: Int, depthPreset: String) {
        let mps = durationMs > 0 ? Double(moveCount) / (Double(durationMs) / 1000.0) : 0
        log("analysis_completed", params: [
            "move_count": moveCount,
            "duration_ms": durationMs,
            "depth_preset": depthPreset,
            "moves_per_second": String(format: "%.2f", mps)
        ])
    }

    static func analysisAbandoned(movesCompleted: Int, totalMoves: Int, timeBeforeAbandonMs: Int) {
        log("analysis_abandoned", params: [
            "moves_completed": movesCompleted,
            "total_moves": totalMoves,
            "time_before_abandon_ms": timeBeforeAbandonMs
        ])
    }

    static func engineInitTime(durationMs: Int, threads: Int, hashMB: Int) {
        log("engine_init_time", params: [
            "duration_ms": durationMs,
            "threads": threads,
            "hash_mb": hashMB
        ])
    }

    static func tcnDecodeUsed(success: Bool, fallbackToArchive: Bool) {
        log("tcn_decode_used", params: [
            "success": success,
            "fallback_to_archive": fallbackToArchive
        ])
    }

    // MARK: - Classification Insights

    static func classificationDistribution(brilliant: Int, great: Int, best: Int, good: Int, ok: Int,
                                           inaccuracy: Int, mistake: Int, blunder: Int) {
        log("classification_distribution", params: [
            "brilliant": brilliant, "great": great, "best": best,
            "good": good, "ok": ok,
            "inaccuracy": inaccuracy, "mistake": mistake, "blunder": blunder
        ])
    }

    static func accuracyDistribution(whiteAccuracy: Double, blackAccuracy: Double) {
        log("accuracy_distribution", params: [
            "white_accuracy": Int(whiteAccuracy),
            "black_accuracy": Int(blackAccuracy)
        ])
    }

    static func gameResultVsAccuracy(result: String, winnerAccuracy: Double, loserAccuracy: Double) {
        log("game_result_vs_accuracy", params: [
            "result": result,
            "winner_accuracy": Int(winnerAccuracy),
            "loser_accuracy": Int(loserAccuracy)
        ])
    }

    // MARK: - Settings

    static func settingsChanged(setting: String, oldValue: String, newValue: String) {
        log("settings_changed", params: [
            "setting_name": setting,
            "old_value": oldValue,
            "new_value": newValue
        ])
    }

    static func depthPresetUsed(preset: String) {
        log("depth_preset_used", params: ["preset": preset])
    }

    // MARK: - Navigation & Engagement

    static func screenViewed(_ screenName: String) {
        log("screen_viewed", params: ["screen_name": screenName])
    }

    static func tabSwitched(from: String, to: String) {
        log("tab_switched", params: ["from_tab": from, "to_tab": to])
    }

    static func movesNavigated(count: Int, method: String) {
        log("moves_navigated", params: ["count": count, "method": method])
    }

    static func flipBoardUsed() {
        log("flip_board_used")
    }

    static func autoPlayUsed(durationMs: Int) {
        log("auto_play_used", params: ["duration_ms": durationMs])
    }

    // MARK: - Errors & Edge Cases

    static func pgnValidationFailed(error: String, source: String) {
        log("pgn_validation_failed", params: [
            "error_message": String(error.prefix(100)),
            "source": source
        ])
    }

    static func chessComAPIError(endpoint: String, httpCode: Int) {
        log("chess_com_api_error", params: ["endpoint": endpoint, "http_code": httpCode])
    }

    static func gameEndDetected(type: String) {
        log("game_end_detected", params: ["type": type])
    }

    // MARK: - Learn Tab

    static func learnCategoryOpened(category: String) {
        log("learn_category_opened", params: ["category": category])
    }

    static func guidedPuzzleStarted(name: String, category: String) {
        log("guided_puzzle_started", params: ["puzzle_name": name, "category": category])
    }

    static func guidedPuzzleSolved(name: String, category: String, usedHint: Bool, attempts: Int, timeMs: Int) {
        log("guided_puzzle_solved", params: [
            "puzzle_name": name,
            "category": category,
            "used_hint": usedHint,
            "attempts": attempts,
            "time_ms": timeMs
        ])
    }

    static func guidedPuzzleFailed(name: String, category: String, attempts: Int) {
        log("guided_puzzle_failed", params: ["puzzle_name": name, "category": category, "attempts": attempts])
    }

    static func guidedPuzzleHintUsed(name: String) {
        log("guided_puzzle_hint_used", params: ["puzzle_name": name])
    }

    static func guidedPuzzleTryAnother(name: String) {
        log("guided_puzzle_try_another", params: ["puzzle_name": name])
    }

    static func endgamePracticeStarted(name: String) {
        log("endgame_practice_started", params: ["pattern_name": name])
    }

    static func endgamePracticeCompleted(name: String, result: String, durationMs: Int) {
        log("endgame_practice_completed", params: [
            "pattern_name": name,
            "result": result,
            "duration_ms": durationMs
        ])
    }

    static func chess960Generated() {
        log("chess960_generated")
    }

    // MARK: - Share

    static func shareOpened(source: String) {
        log("share_opened", params: ["source": source])
    }

    static func shareCopied(contentType: String, source: String) {
        log("share_copied", params: ["content_type": contentType, "source": source])
    }

    // MARK: - Profile Info

    static func profileInfoViewed(username: String) {
        log("profile_info_viewed", params: ["username": username])
    }

    static func profileInfoSaved(username: String) {
        log("profile_info_saved", params: ["username": username])
    }

    static func profileInfoFailed(username: String) {
        log("profile_info_failed", params: ["username": username])
    }

    // MARK: - Puzzle Promotion

    static func puzzlePromotionShown() {
        log("puzzle_promotion_shown")
    }

    static func puzzlePromotionCorrect(piece: String) {
        log("puzzle_promotion_correct", params: ["piece": piece])
    }

    static func puzzlePromotionWrong(expected: String, chosen: String) {
        log("puzzle_promotion_wrong", params: ["expected": expected, "chosen": chosen])
    }

    // MARK: - Puzzle Navigation

    static func puzzleTryAnother() {
        log("puzzle_try_another")
    }

    static func puzzleHintUsed(type: String) {
        log("puzzle_hint_used", params: ["puzzle_type": type])
    }

    static func puzzleReset(type: String) {
        log("puzzle_reset", params: ["puzzle_type": type])
    }

    // MARK: - FEN Import

    static func fenImported(source: String, valid: Bool) {
        log("fen_imported", params: ["source": source, "valid": valid])
    }

    // MARK: - Device & Platform

    static func appLaunched(isIPad: Bool, appVersion: String) {
        log("app_launched", params: [
            "device_type": isIPad ? "tablet" : "phone",
            "app_version": appVersion
        ])
    }

    static func iPadLayoutUsed(screenName: String) {
        log("ipad_layout_used", params: ["screen_name": screenName])
    }
}
