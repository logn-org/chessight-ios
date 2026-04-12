import Foundation

/// Resolves chess.com game links to PGN by:
/// 1. Extracting game ID from URL
/// 2. Calling chess.com callback API to get game metadata
/// 3. Fetching the PGN from the player's game archive
actor ChessComGameResolver {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpAdditionalHeaders = [
            "User-Agent": "Chessight-iOS/1.0",
            "Accept": "application/json"
        ]
        session = URLSession(configuration: config)
    }

    /// Extract game ID from a chess.com URL.
    /// Supports: https://www.chess.com/game/live/123456
    ///           https://www.chess.com/game/daily/123456
    ///           chess.com/game/live/123456
    static func extractGameId(from text: String) -> String? {
        // Match chess.com game URLs
        let patterns = [
            #"chess\.com/game/(?:live|daily)/(\d+)"#,
            #"chess\.com/analysis/game/(?:live|daily)/(\d+)"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }
        return nil
    }

    /// Resolve a chess.com game ID to a PGN string and metadata.
    func resolveGame(gameId: String) async throws -> ResolvedGame {
        CrashLogger.logNetwork("Resolving chess.com game: \(gameId)")
        guard let callbackURL = URL(string: "https://www.chess.com/callback/live/game/\(gameId)") else {
            throw GameResolveError.invalidData
        }
        let (data, response) = try await session.data(from: callbackURL)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GameResolveError.gameNotFound
        }

        let gameData = try JSONDecoder().decode(CallbackResponse.self, from: data)

        let white = gameData.game.pgnHeaders.White
        let black = gameData.game.pgnHeaders.Black
        let date = gameData.game.pgnHeaders.Date  // "2026.04.09"
        let uuid = gameData.game.uuid

        // Step 2: Parse date to get year/month for archive URL
        let parts = date.split(separator: ".")
        guard parts.count >= 2 else { throw GameResolveError.invalidData }
        let year = String(parts[0])
        let month = String(parts[1])

        // Step 3: Fetch game archive for one of the players
        let archiveURL = "https://api.chess.com/pub/player/\(white.lowercased())/games/\(year)/\(month)"
        guard let url = URL(string: archiveURL) else { throw GameResolveError.invalidData }
        let (archiveData, archiveResponse) = try await session.data(from: url)

        guard let archiveHttp = archiveResponse as? HTTPURLResponse, archiveHttp.statusCode == 200 else {
            // Try with black player if white fails
            return try await resolveWithPlayer(black, year: year, month: month, uuid: uuid, gameData: gameData)
        }

        if let pgn = findPGNInArchive(data: archiveData, uuid: uuid, gameId: gameId) {
            return ResolvedGame(
                pgn: pgn,
                white: white,
                black: black,
                whiteRating: gameData.game.pgnHeaders.WhiteElo,
                blackRating: gameData.game.pgnHeaders.BlackElo
            )
        }

        // Fallback: try other player
        return try await resolveWithPlayer(black, year: year, month: month, uuid: uuid, gameData: gameData)
    }

    private func resolveWithPlayer(_ username: String, year: String, month: String, uuid: String, gameData: CallbackResponse) async throws -> ResolvedGame {
        let archiveURL = "https://api.chess.com/pub/player/\(username.lowercased())/games/\(year)/\(month)"
        guard let archiveUrl = URL(string: archiveURL) else { throw GameResolveError.invalidData }
        let (data, response) = try await session.data(from: archiveUrl)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GameResolveError.archiveNotFound
        }

        guard let pgn = findPGNInArchive(data: data, uuid: uuid, gameId: String(gameData.game.id)) else {
            throw GameResolveError.gameNotFoundInArchive
        }

        return ResolvedGame(
            pgn: pgn,
            white: gameData.game.pgnHeaders.White,
            black: gameData.game.pgnHeaders.Black,
            whiteRating: gameData.game.pgnHeaders.WhiteElo,
            blackRating: gameData.game.pgnHeaders.BlackElo
        )
    }

    /// Search archive games for matching UUID or game ID
    private func findPGNInArchive(data: Data, uuid: String, gameId: String) -> String? {
        struct ArchiveResponse: Decodable {
            let games: [ArchiveGame]
        }
        struct ArchiveGame: Decodable {
            let url: String
            let pgn: String?
            let uuid: String?
        }

        guard let archive = try? JSONDecoder().decode(ArchiveResponse.self, from: data) else { return nil }

        // Match by UUID first
        if let game = archive.games.first(where: { $0.uuid == uuid }) {
            return game.pgn
        }

        // Match by game ID in URL
        if let game = archive.games.first(where: { $0.url.contains(gameId) }) {
            return game.pgn
        }

        return nil
    }
}

struct ResolvedGame {
    let pgn: String
    let white: String
    let black: String
    let whiteRating: Int?
    let blackRating: Int?
}

enum GameResolveError: Error, LocalizedError {
    case gameNotFound
    case invalidData
    case archiveNotFound
    case gameNotFoundInArchive

    var errorDescription: String? {
        switch self {
        case .gameNotFound: return "Game not found on chess.com"
        case .invalidData: return "Could not parse game data"
        case .archiveNotFound: return "Could not access player's game archive"
        case .gameNotFoundInArchive: return "Game not found in player's archive"
        }
    }
}

// MARK: - API Response Models

private struct CallbackResponse: Decodable {
    let game: GameInfo

    struct GameInfo: Decodable {
        let id: Int
        let uuid: String
        let pgnHeaders: PGNHeaders
    }

    struct PGNHeaders: Decodable {
        let White: String
        let Black: String
        let Date: String
        let Result: String?
        let WhiteElo: Int?
        let BlackElo: Int?
        let TimeControl: String?
    }
}
