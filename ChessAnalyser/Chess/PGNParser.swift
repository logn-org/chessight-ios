import Foundation

enum PGNParserError: Error, LocalizedError {
    case invalidPGN(String)
    case invalidMove(String)
    case emptyPGN

    var errorDescription: String? {
        switch self {
        case .invalidPGN(let detail): return "Invalid PGN: \(detail)"
        case .invalidMove(let move): return "Invalid move: \(move)"
        case .emptyPGN: return "PGN is empty"
        }
    }
}

struct PGNParser {

    // MARK: - Parse Single PGN

    static func parse(_ pgn: String) throws -> ParsedGame {
        let trimmed = pgn.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PGNParserError.emptyPGN }

        let headers = parseHeaders(trimmed)
        let moveText = extractMoveText(trimmed)
        let sanMoves = parseMoveText(moveText)

        let moves = replayMoves(sanMoves, startingFEN: headers["FEN"])

        let id = generateGameId(headers: headers, pgn: trimmed)

        return ParsedGame(
            id: id,
            headers: headers,
            moves: moves,
            pgn: trimmed
        )
    }

    // MARK: - Parse Multiple Games

    static func parseMultiple(_ text: String) throws -> [ParsedGame] {
        let games = splitPGNGames(text)
        return try games.map { try parse($0) }
    }

    // MARK: - Header Parsing

    static func parseHeaders(_ pgn: String) -> [String: String] {
        var headers: [String: String] = [:]
        let headerPattern = /\[(\w+)\s+"([^"]*)"\]/
        for match in pgn.matches(of: headerPattern) {
            headers[String(match.1)] = String(match.2)
        }
        return headers
    }

    // MARK: - Move Text Extraction

    static func extractMoveText(_ pgn: String) -> String {
        // Remove headers
        var text = pgn
        let headerPattern = /\[[^\]]*\]\s*/
        text = text.replacing(headerPattern, with: "")

        // Remove comments
        let commentPattern = /\{[^}]*\}/
        text = text.replacing(commentPattern, with: "")

        // Remove variations (recursive parentheses)
        var result = text
        var changed = true
        while changed {
            let before = result
            let variationPattern = /\([^()]*\)/
            result = result.replacing(variationPattern, with: "")
            changed = result != before
        }

        // Remove NAGs ($1, $2, etc.)
        let nagPattern = /\$\d+/
        result = result.replacing(nagPattern, with: "")

        // Remove result
        let resultPattern = /\s*(1-0|0-1|1\/2-1\/2|\*)\s*$/
        result = result.replacing(resultPattern, with: "")

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Move Text Parsing

    static func parseMoveText(_ moveText: String) -> [String] {
        let cleaned = moveText
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")

        // Split on whitespace
        let tokens = cleaned.split(separator: " ").map(String.init)

        var moves: [String] = []
        for token in tokens {
            let trimmed = token.trimmingCharacters(in: .whitespaces)
            // Skip move numbers (1. or 1...)
            if trimmed.contains(".") {
                // Could be "1.e4" — extract move after dots
                if let lastDot = trimmed.lastIndex(of: ".") {
                    let afterDot = String(trimmed[trimmed.index(after: lastDot)...])
                    if !afterDot.isEmpty && isValidSAN(afterDot) {
                        moves.append(afterDot)
                    }
                }
                continue
            }
            if isValidSAN(trimmed) {
                moves.append(trimmed)
            }
        }

        return moves
    }

    // MARK: - Validate SAN

    static func isValidSAN(_ san: String) -> Bool {
        guard !san.isEmpty else { return false }
        // Basic SAN pattern: piece letter + squares + check/mate symbols
        let pattern = /^[KQRBNP]?[a-h]?[1-8]?x?[a-h][1-8](=[QRBN])?[+#]?$/
        if san.matches(of: pattern).isEmpty == false { return true }
        // Castling
        if san == "O-O" || san == "O-O-O" { return true }
        return false
    }

    // MARK: - PGN Validation

    /// Validate a PGN by replaying all moves on a board.
    /// Returns nil if valid, or an error description if invalid.
    static func validate(_ pgn: String) -> String? {
        let trimmed = pgn.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "PGN is empty" }

        let headers = parseHeaders(trimmed)
        let moveText = extractMoveText(trimmed)
        let sanMoves = parseMoveText(moveText)

        guard !sanMoves.isEmpty else { return "No moves found in PGN" }

        var board: ChessBoard
        if let fen = headers["FEN"], !fen.isEmpty {
            board = ChessBoard(fen: fen)
        } else {
            board = ChessBoard()
        }
        let startsAsBlack = board.sideToMove == .black
        for (index, san) in sanMoves.enumerated() {
            let isWhite = startsAsBlack ? (index % 2 != 0) : (index % 2 == 0)
            let moveNumber = startsAsBlack ? ((index + 1) / 2) + 1 : (index / 2) + 1
            let side = isWhite ? "White" : "Black"
            guard board.makeMoveSAN(san) != nil else {
                return "Invalid move at \(moveNumber). \(side): \(san) — position: \(board.toFEN())"
            }
        }
        return nil
    }

    // MARK: - Replay Moves to Generate Full Game Data

    static func replayMoves(_ sanMoves: [String], startingFEN: String? = nil) -> [GameMove] {
        var board: ChessBoard
        if let fen = startingFEN, !fen.isEmpty {
            board = ChessBoard(fen: fen)
        } else {
            board = ChessBoard()
        }
        let startsAsBlack = board.sideToMove == .black
        var moves: [GameMove] = []

        for (index, san) in sanMoves.enumerated() {
            let fenBefore = board.toFEN()
            let isWhite = startsAsBlack ? (index % 2 != 0) : (index % 2 == 0)
            let moveNumber = startsAsBlack ? ((index + 1) / 2) + 1 : (index / 2) + 1

            guard let moveResult = board.makeMoveSAN(san) else {
                CrashLogger.logEngine("PGN validation: invalid move '\(san)' at move \(moveNumber) (\(isWhite ? "White" : "Black")), skipping remaining moves")
                break
            }

            let fenAfter = board.toFEN()

            let gameMove = GameMove(
                moveIndex: index,
                san: san,
                from: moveResult.from.algebraic,
                to: moveResult.to.algebraic,
                fen: fenAfter,
                fenBefore: fenBefore,
                isWhite: isWhite,
                moveNumber: moveNumber,
                piece: moveResult.piece,
                captured: moveResult.captured,
                promotion: moveResult.promotion,
                isCheck: moveResult.isCheck,
                isCheckmate: moveResult.isCheckmate,
                isCastling: moveResult.isCastling
            )

            moves.append(gameMove)
        }

        return moves
    }

    // MARK: - Split Multiple Games

    static func splitPGNGames(_ text: String) -> [String] {
        var games: [String] = []
        var current = ""
        var inHeaders = false

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[") && !inHeaders && !current.isEmpty {
                // Start of a new game
                let game = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !game.isEmpty {
                    games.append(game)
                }
                current = ""
                inHeaders = true
            }

            if trimmed.hasPrefix("[") {
                inHeaders = true
            } else if !trimmed.isEmpty {
                inHeaders = false
            }

            current += line + "\n"
        }

        let last = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !last.isEmpty {
            games.append(last)
        }

        return games
    }

    // MARK: - ID Generation

    private static func generateGameId(headers: [String: String], pgn: String) -> String {
        // Use Site URL if available (chess.com game URL)
        if let site = headers["Site"], site.contains("chess.com") {
            return site
        }
        // Otherwise hash the PGN
        var hasher = Hasher()
        hasher.combine(pgn)
        return "game_\(abs(hasher.finalize()))"
    }
}
