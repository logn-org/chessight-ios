import Foundation

/// Resolves chess.com game links to PGN by:
/// 1. Extracting game ID from URL
/// 2. Calling chess.com callback API to get game metadata + moveList
/// 3. Decoding TCN moveList to generate PGN locally (fast, 1 API call)
/// 4. Falls back to archive API if TCN decode fails
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
    static func extractGameId(from text: String) -> String? {
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
        let resolveTrace = PerformanceTracer.traceGameResolve()
        guard let callbackURL = URL(string: "https://www.chess.com/callback/live/game/\(gameId)") else {
            resolveTrace?.stop()
            throw GameResolveError.invalidData
        }
        let (data, response) = try await session.data(from: callbackURL)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GameResolveError.gameNotFound
        }

        let gameData = try JSONDecoder().decode(CallbackResponse.self, from: data)
        let headers = gameData.game.pgnHeaders

        // Primary: decode TCN moveList locally (fast, no second API call)
        if let moveList = gameData.game.moveList, !moveList.isEmpty {
            let startFEN = headers.SetUp == "1" ? headers.FEN : nil
            if let pgn = TCNDecoder.generatePGN(
                tcn: moveList,
                white: headers.White, black: headers.Black, date: headers.Date,
                result: headers.Result, whiteElo: headers.WhiteElo, blackElo: headers.BlackElo,
                timeControl: headers.TimeControl, eco: headers.ECO, startFEN: startFEN
            ) {
                // Validate the generated PGN
                if PGNParser.validate(pgn) == nil {
                    CrashLogger.logNetwork("TCN decode successful for game \(gameId)")
                    Analytics.tcnDecodeUsed(success: true, fallbackToArchive: false)
                    resolveTrace?.setValue(1, forMetric: "tcn_success")
                    resolveTrace?.stop()
                    return ResolvedGame(
                        pgn: pgn,
                        white: headers.White,
                        black: headers.Black,
                        whiteRating: headers.WhiteElo,
                        blackRating: headers.BlackElo
                    )
                }
                CrashLogger.logNetwork("TCN decode produced invalid PGN, falling back to archive")
            }
        }

        // Fallback: fetch PGN from player's game archive (slow, 2nd API call)
        CrashLogger.logNetwork("Falling back to archive API for game \(gameId)")
        Analytics.tcnDecodeUsed(success: false, fallbackToArchive: true)
        resolveTrace?.setValue(0, forMetric: "tcn_success")
        let result = try await resolveViaArchive(gameData: gameData, gameId: gameId)
        resolveTrace?.stop()
        return result
    }

    // MARK: - Archive Fallback

    private func resolveViaArchive(gameData: CallbackResponse, gameId: String) async throws -> ResolvedGame {
        let headers = gameData.game.pgnHeaders
        let white = headers.White
        let black = headers.Black
        let date = headers.Date
        let uuid = gameData.game.uuid

        let parts = date.split(separator: ".")
        guard parts.count >= 2 else { throw GameResolveError.invalidData }
        let year = String(parts[0])
        let month = String(parts[1])

        let archiveURL = "https://api.chess.com/pub/player/\(white.lowercased())/games/\(year)/\(month)"
        guard let url = URL(string: archiveURL) else { throw GameResolveError.invalidData }
        let (archiveData, archiveResponse) = try await session.data(from: url)

        guard let archiveHttp = archiveResponse as? HTTPURLResponse, archiveHttp.statusCode == 200 else {
            return try await resolveWithPlayer(black, year: year, month: month, uuid: uuid, gameData: gameData)
        }

        if let pgn = findPGNInArchive(data: archiveData, uuid: uuid, gameId: gameId) {
            return ResolvedGame(
                pgn: pgn,
                white: white,
                black: black,
                whiteRating: headers.WhiteElo,
                blackRating: headers.BlackElo
            )
        }

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

        if let game = archive.games.first(where: { $0.uuid == uuid }) {
            return game.pgn
        }
        if let game = archive.games.first(where: { $0.url.contains(gameId) }) {
            return game.pgn
        }
        return nil
    }
}

// MARK: - Models

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

// MARK: - Callback API Response

private struct CallbackResponse: Decodable {
    let game: GameInfo

    struct GameInfo: Decodable {
        let id: Int
        let uuid: String
        let moveList: String?
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
        let ECO: String?
        let SetUp: String?
        let FEN: String?
    }
}

// MARK: - TCN Decoder

/// Decodes chess.com's TCN (Ternary Chess Notation) move encoding.
/// Port of the chess-tcn npm library used by chess.com.
enum TCNDecoder {
    private static let tcnChars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?{~}(^)[_]@#$,./&-*++=")
    private static let pieceChars = Array("qnrbkp")
    private static let fileChars = Array("abcdefgh")

    struct DecodedMove {
        let from: String?  // nil for drop moves (crazyhouse)
        let to: String
        let promotion: Character?
    }

    /// Decode a TCN string into an array of UCI-style moves.
    static func decode(_ tcn: String) -> [DecodedMove] {
        let chars = Array(tcn)
        var moves: [DecodedMove] = []

        var i = 0
        while i + 1 < chars.count {
            guard let fromIdx = tcnChars.firstIndex(of: chars[i]),
                  let toIdx = tcnChars.firstIndex(of: chars[i + 1]) else {
                i += 2
                continue
            }

            var promotion: Character? = nil
            var actualToIdx = toIdx

            // Promotion: toIdx > 63 encodes piece type and direction
            if toIdx > 63 {
                let promoIdx = (toIdx - 64) / 3
                if promoIdx < pieceChars.count {
                    promotion = pieceChars[promoIdx]
                }
                actualToIdx = fromIdx + (fromIdx < 16 ? -8 : 8) + ((toIdx - 1) % 3) - 1
            }

            let from: String?
            if fromIdx > 75 {
                // Drop move (crazyhouse) — skip, not supported
                from = nil
            } else {
                let fromFile = fileChars[fromIdx % 8]
                let fromRank = fromIdx / 8 + 1
                from = "\(fromFile)\(fromRank)"
            }

            let toFile = fileChars[actualToIdx % 8]
            let toRank = actualToIdx / 8 + 1
            let to = "\(toFile)\(toRank)"

            moves.append(DecodedMove(from: from, to: to, promotion: promotion))
            i += 2
        }

        return moves
    }

    /// Generate a PGN string from TCN-encoded moves and header values.
    static func generatePGN(
        tcn: String,
        white: String, black: String, date: String,
        result: String?, whiteElo: Int?, blackElo: Int?,
        timeControl: String?, eco: String?, startFEN: String? = nil
    ) -> String? {
        let moves = decode(tcn)
        guard !moves.isEmpty else { return nil }

        var board = startFEN != nil ? ChessBoard(fen: startFEN!) : ChessBoard()
        var sanMoves: [String] = []

        for move in moves {
            guard let from = move.from else { continue } // Skip drop moves

            var uci = "\(from)\(move.to)"
            if let promo = move.promotion {
                uci += String(promo)
            }

            let san = board.uciToSAN(uci)
            guard board.makeMoveSAN(san) != nil else {
                // Invalid move — stop here, return what we have
                break
            }
            sanMoves.append(san)
        }

        guard !sanMoves.isEmpty else { return nil }

        // Build PGN string
        var pgn = ""
        pgn += "[Event \"Live Chess\"]\n"
        pgn += "[Site \"Chess.com\"]\n"
        pgn += "[Date \"\(date)\"]\n"
        pgn += "[White \"\(white)\"]\n"
        pgn += "[Black \"\(black)\"]\n"
        pgn += "[Result \"\(result ?? "*")\"]\n"
        if let elo = whiteElo { pgn += "[WhiteElo \"\(elo)\"]\n" }
        if let elo = blackElo { pgn += "[BlackElo \"\(elo)\"]\n" }
        if let tc = timeControl { pgn += "[TimeControl \"\(tc)\"]\n" }
        if let e = eco { pgn += "[ECO \"\(e)\"]\n" }
        if let fen = startFEN {
            pgn += "[SetUp \"1\"]\n"
            pgn += "[FEN \"\(fen)\"]\n"
        }
        pgn += "\n"

        // Format moves: 1. e4 e5 2. Nf3 Nc6 ...
        for (i, san) in sanMoves.enumerated() {
            if i % 2 == 0 {
                pgn += "\(i / 2 + 1). "
            }
            pgn += san
            if i < sanMoves.count - 1 {
                pgn += " "
            }
        }
        pgn += " \(result ?? "*")"

        return pgn
    }
}
