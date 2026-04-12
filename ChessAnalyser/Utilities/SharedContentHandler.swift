import Foundation

/// Parses shared content from the share sheet to determine what was shared.
enum SharedContent {
    case pgn(String)                    // Direct PGN text
    case chessComLink(gameId: String)   // Chess.com game link
    case unknown(String)                // Unrecognized text

    /// Parse incoming shared text to determine content type
    static func parse(_ text: String) -> SharedContent {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for chess.com game link
        if let gameId = ChessComGameResolver.extractGameId(from: trimmed) {
            return .chessComLink(gameId: gameId)
        }

        // Check if it looks like PGN (has move numbers or PGN headers)
        if trimmed.contains("[Event") || trimmed.contains("[White") ||
           trimmed.contains("1.") || trimmed.contains("1. ") {
            return .pgn(trimmed)
        }

        // Check for chess.com share text pattern: "Check out this game..."
        // Extract URL from the text
        if trimmed.lowercased().contains("chess") {
            // Try to find any URL in the text
            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector?.matches(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) ?? []
            for match in matches {
                if let range = Range(match.range, in: trimmed) {
                    let url = String(trimmed[range])
                    if let gameId = ChessComGameResolver.extractGameId(from: url) {
                        return .chessComLink(gameId: gameId)
                    }
                }
            }
        }

        return .unknown(trimmed)
    }
}
