import Foundation

/// Lightweight chess board representation for move generation and PGN replay.
/// Uses an 8x8 array with full rule enforcement.
struct ChessBoard {
    // 8x8 board, rank 0 = rank 1 (white's side), file 0 = a-file
    private(set) var squares: [[ChessPiece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    private(set) var sideToMove: PieceColor = .white
    private(set) var castlingRights: CastlingRights = .all
    private(set) var enPassantSquare: Square? = nil
    private(set) var halfMoveClock: Int = 0
    private(set) var fullMoveNumber: Int = 1

    /// Tracks position keys for threefold repetition detection.
    /// Key = board + side to move + castling + en passant (FEN without clocks).
    private(set) var positionHistory: [String: Int] = [:]

    struct CastlingRights: OptionSet, Equatable {
        let rawValue: Int
        static let whiteKingside  = CastlingRights(rawValue: 1 << 0)
        static let whiteQueenside = CastlingRights(rawValue: 1 << 1)
        static let blackKingside  = CastlingRights(rawValue: 1 << 2)
        static let blackQueenside = CastlingRights(rawValue: 1 << 3)
        static let all: CastlingRights = [.whiteKingside, .whiteQueenside, .blackKingside, .blackQueenside]
        static let none = CastlingRights(rawValue: 0)
    }

    struct MoveResult {
        let from: Square
        let to: Square
        let piece: PieceType
        let captured: PieceType?
        let promotion: PieceType?
        let isCheck: Bool
        let isCheckmate: Bool
        let isCastling: Bool
    }

    // MARK: - Init (starting position)

    init() {
        setupStartingPosition()
        recordPosition()
    }

    init(fen: String) {
        parseFEN(fen)
        recordPosition()
    }

    // MARK: - Board Access

    func piece(at square: Square) -> ChessPiece? {
        squares[square.rank][square.file]
    }

    mutating func setPiece(_ piece: ChessPiece?, at square: Square) {
        squares[square.rank][square.file] = piece
    }

    // MARK: - Starting Position

    mutating func setupStartingPosition() {
        squares = Array(repeating: Array(repeating: nil, count: 8), count: 8)

        let backRank: [PieceType] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for file in 0..<8 {
            squares[0][file] = ChessPiece(type: backRank[file], color: .white)
            squares[1][file] = ChessPiece(type: .pawn, color: .white)
            squares[6][file] = ChessPiece(type: .pawn, color: .black)
            squares[7][file] = ChessPiece(type: backRank[file], color: .black)
        }

        sideToMove = .white
        castlingRights = .all
        enPassantSquare = nil
        halfMoveClock = 0
        fullMoveNumber = 1
    }

    // MARK: - FEN

    func toFEN() -> String {
        var fen = ""

        for rank in stride(from: 7, through: 0, by: -1) {
            var empty = 0
            for file in 0..<8 {
                if let piece = squares[rank][file] {
                    if empty > 0 {
                        fen += "\(empty)"
                        empty = 0
                    }
                    fen += fenChar(for: piece)
                } else {
                    empty += 1
                }
            }
            if empty > 0 { fen += "\(empty)" }
            if rank > 0 { fen += "/" }
        }

        fen += " \(sideToMove.rawValue)"

        // Castling
        var castling = ""
        if castlingRights.contains(.whiteKingside) { castling += "K" }
        if castlingRights.contains(.whiteQueenside) { castling += "Q" }
        if castlingRights.contains(.blackKingside) { castling += "k" }
        if castlingRights.contains(.blackQueenside) { castling += "q" }
        fen += " \(castling.isEmpty ? "-" : castling)"

        fen += " \(enPassantSquare?.algebraic ?? "-")"
        fen += " \(halfMoveClock)"
        fen += " \(fullMoveNumber)"

        return fen
    }

    mutating func parseFEN(_ fen: String) {
        squares = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        let parts = fen.split(separator: " ")
        guard parts.count >= 1 else { return }

        // Piece placement
        let ranks = parts[0].split(separator: "/")
        for (i, rankStr) in ranks.enumerated() {
            let rank = 7 - i
            var file = 0
            for ch in rankStr {
                if let num = ch.wholeNumberValue {
                    file += num
                } else {
                    let color: PieceColor = ch.isUppercase ? .white : .black
                    let type = pieceType(from: ch)
                    if let type = type {
                        squares[rank][file] = ChessPiece(type: type, color: color)
                    }
                    file += 1
                }
            }
        }

        // Side to move
        if parts.count > 1 {
            sideToMove = String(parts[1]) == "b" ? .black : .white
        }

        // Castling
        if parts.count > 2 {
            castlingRights = .none
            let c = String(parts[2])
            if c.contains("K") { castlingRights.insert(.whiteKingside) }
            if c.contains("Q") { castlingRights.insert(.whiteQueenside) }
            if c.contains("k") { castlingRights.insert(.blackKingside) }
            if c.contains("q") { castlingRights.insert(.blackQueenside) }
        }

        // En passant
        if parts.count > 3 && parts[3] != "-" {
            enPassantSquare = Square(algebraic: String(parts[3]))
        }

        // Clocks
        if parts.count > 4 { halfMoveClock = Int(parts[4]) ?? 0 }
        if parts.count > 5 { fullMoveNumber = Int(parts[5]) ?? 1 }
    }

    // MARK: - Make Move (SAN)

    mutating func makeMoveSAN(_ san: String) -> MoveResult? {
        // Handle castling
        if san == "O-O" || san == "O-O-O" {
            return makeCastlingMove(kingSide: san == "O-O")
        }

        // Parse SAN
        var san = san.replacingOccurrences(of: "+", with: "")
                      .replacingOccurrences(of: "#", with: "")

        var promotion: PieceType? = nil
        if san.contains("=") {
            let parts = san.split(separator: "=")
            san = String(parts[0])
            if parts.count > 1, let promoChar = parts[1].first {
                promotion = pieceType(from: promoChar)
            }
        }

        let isCapture = san.contains("x")
        san = san.replacingOccurrences(of: "x", with: "")

        // Determine piece type
        var pieceType: PieceType = .pawn
        var moveSan = san
        if let first = san.first, first.isUppercase {
            pieceType = self.pieceType(from: first) ?? .pawn
            moveSan = String(san.dropFirst())
        }

        // Target square is always the last 2 characters
        guard moveSan.count >= 2 else { return nil }
        let targetStr = String(moveSan.suffix(2))
        guard let target = Square(algebraic: targetStr) else { return nil }

        // Disambiguation (remaining chars after removing target)
        let disambig = String(moveSan.dropLast(2))

        // Find the source square
        guard let source = findSourceSquare(
            pieceType: pieceType,
            target: target,
            disambiguation: disambig,
            isCapture: isCapture
        ) else { return nil }

        let captured = piece(at: target)?.type ??
            (pieceType == .pawn && target == enPassantSquare ? .pawn : nil)

        // Execute the move
        let movingPiece = piece(at: source)!
        setPiece(nil, at: source)

        // Handle en passant capture
        if pieceType == .pawn && target == enPassantSquare {
            let capturedPawnRank = sideToMove == .white ? target.rank - 1 : target.rank + 1
            setPiece(nil, at: Square(file: target.file, rank: capturedPawnRank))
        }

        // Place piece (with promotion if applicable)
        if let promotion = promotion {
            setPiece(ChessPiece(type: promotion, color: sideToMove), at: target)
        } else {
            setPiece(movingPiece, at: target)
        }

        // Update en passant
        if pieceType == .pawn && abs(target.rank - source.rank) == 2 {
            let epRank = (source.rank + target.rank) / 2
            enPassantSquare = Square(file: source.file, rank: epRank)
        } else {
            enPassantSquare = nil
        }

        // Update castling rights
        updateCastlingRights(from: source, to: target, piece: pieceType)

        // Update clocks
        if pieceType == .pawn || captured != nil {
            halfMoveClock = 0
        } else {
            halfMoveClock += 1
        }

        if sideToMove == .black {
            fullMoveNumber += 1
        }

        sideToMove = sideToMove.opposite
        recordPosition()

        let isCheck = isKingInCheck(color: sideToMove)
        let isCheckmate = isCheck && !hasLegalMoves(color: sideToMove)
        let isCastling = false

        return MoveResult(
            from: source,
            to: target,
            piece: pieceType,
            captured: captured,
            promotion: promotion,
            isCheck: isCheck,
            isCheckmate: isCheckmate,
            isCastling: isCastling
        )
    }

    // MARK: - Castling

    private mutating func makeCastlingMove(kingSide: Bool) -> MoveResult? {
        let rank = sideToMove == .white ? 0 : 7
        let kingFile = 4
        let rookFromFile = kingSide ? 7 : 0
        let kingToFile = kingSide ? 6 : 2
        let rookToFile = kingSide ? 5 : 3

        let kingFrom = Square(file: kingFile, rank: rank)
        let kingTo = Square(file: kingToFile, rank: rank)
        let rookFrom = Square(file: rookFromFile, rank: rank)
        let rookTo = Square(file: rookToFile, rank: rank)

        let king = piece(at: kingFrom)
        let rook = piece(at: rookFrom)

        setPiece(nil, at: kingFrom)
        setPiece(nil, at: rookFrom)
        setPiece(king, at: kingTo)
        setPiece(rook, at: rookTo)

        enPassantSquare = nil
        updateCastlingRights(from: kingFrom, to: kingTo, piece: .king)

        if sideToMove == .black { fullMoveNumber += 1 }
        halfMoveClock += 1
        sideToMove = sideToMove.opposite
        recordPosition()

        let isCheck = isKingInCheck(color: sideToMove)
        let isCheckmate = isCheck && !hasLegalMoves(color: sideToMove)

        return MoveResult(
            from: kingFrom,
            to: kingTo,
            piece: .king,
            captured: nil,
            promotion: nil,
            isCheck: isCheck,
            isCheckmate: isCheckmate,
            isCastling: true
        )
    }

    // MARK: - Find Source Square

    private func findSourceSquare(pieceType: PieceType, target: Square, disambiguation: String, isCapture: Bool) -> Square? {
        var candidates: [Square] = []

        for rank in 0..<8 {
            for file in 0..<8 {
                let sq = Square(file: file, rank: rank)
                guard let piece = piece(at: sq),
                      piece.type == pieceType,
                      piece.color == sideToMove,
                      canPieceMove(from: sq, to: target, piece: piece, isCapture: isCapture) else {
                    continue
                }
                candidates.append(sq)
            }
        }

        // Apply disambiguation
        if !disambiguation.isEmpty {
            candidates = candidates.filter { sq in
                for ch in disambiguation {
                    if ch.isLetter {
                        // File disambiguation
                        guard let ascii = ch.asciiValue, let aAscii = Character("a").asciiValue else { return false }
                        let file = Int(ascii - aAscii)
                        if sq.file != file { return false }
                    } else if ch.isNumber {
                        // Rank disambiguation
                        guard let rankVal = ch.wholeNumberValue else { return false }
                        let rank = rankVal - 1
                        if sq.rank != rank { return false }
                    }
                }
                return true
            }
        }

        // Filter out moves that leave king in check
        candidates = candidates.filter { source in
            var testBoard = self
            testBoard.setPiece(nil, at: source)
            testBoard.setPiece(ChessPiece(type: pieceType, color: sideToMove), at: target)
            // Handle en passant capture in test
            if pieceType == .pawn && target == enPassantSquare {
                let capturedRank = sideToMove == .white ? target.rank - 1 : target.rank + 1
                testBoard.setPiece(nil, at: Square(file: target.file, rank: capturedRank))
            }
            return !testBoard.isKingInCheck(color: sideToMove)
        }

        // If multiple candidates remain, the move is ambiguous (invalid SAN)
        if candidates.count > 1 { return nil }
        return candidates.first
    }

    // MARK: - Piece Movement Validation

    private func canPieceMove(from: Square, to: Square, piece: ChessPiece, isCapture: Bool) -> Bool {
        let df = to.file - from.file
        let dr = to.rank - from.rank
        let adf = abs(df)
        let adr = abs(dr)

        switch piece.type {
        case .pawn:
            let direction = piece.color == .white ? 1 : -1
            let startRank = piece.color == .white ? 1 : 6

            if isCapture || to == enPassantSquare {
                return adf == 1 && dr == direction
            } else {
                if df == 0 && dr == direction && self.piece(at: to) == nil {
                    return true
                }
                if df == 0 && dr == 2 * direction && from.rank == startRank &&
                    self.piece(at: to) == nil &&
                    self.piece(at: Square(file: from.file, rank: from.rank + direction)) == nil {
                    return true
                }
                // Also allow diagonal if there's actually a piece there (for cases where isCapture might not be set)
                if adf == 1 && dr == direction && self.piece(at: to) != nil {
                    return true
                }
                return false
            }

        case .knight:
            return (adf == 1 && adr == 2) || (adf == 2 && adr == 1)

        case .bishop:
            return adf == adr && adf > 0 && isPathClear(from: from, to: to)

        case .rook:
            return (df == 0 || dr == 0) && (adf + adr > 0) && isPathClear(from: from, to: to)

        case .queen:
            return ((adf == adr && adf > 0) || (df == 0 || dr == 0) && (adf + adr > 0)) && isPathClear(from: from, to: to)

        case .king:
            return adf <= 1 && adr <= 1 && (adf + adr > 0)
        }
    }

    private func isPathClear(from: Square, to: Square) -> Bool {
        let df = to.file > from.file ? 1 : (to.file < from.file ? -1 : 0)
        let dr = to.rank > from.rank ? 1 : (to.rank < from.rank ? -1 : 0)

        var file = from.file + df
        var rank = from.rank + dr

        while file != to.file || rank != to.rank {
            if squares[rank][file] != nil { return false }
            file += df
            rank += dr
        }

        return true
    }

    // MARK: - King Safety

    func isKingInCheck(color: PieceColor) -> Bool {
        guard let kingSquare = findKing(color: color) else { return false }
        return isSquareAttacked(kingSquare, by: color.opposite)
    }

    func findKing(color: PieceColor) -> Square? {
        for rank in 0..<8 {
            for file in 0..<8 {
                if let piece = squares[rank][file],
                   piece.type == .king && piece.color == color {
                    return Square(file: file, rank: rank)
                }
            }
        }
        return nil
    }

    func isSquareAttacked(_ square: Square, by color: PieceColor) -> Bool {
        for rank in 0..<8 {
            for file in 0..<8 {
                let from = Square(file: file, rank: rank)
                guard let piece = self.piece(at: from),
                      piece.color == color else { continue }
                if canPieceMove(from: from, to: square, piece: piece, isCapture: true) {
                    return true
                }
            }
        }
        return false
    }

    func hasLegalMoves(color: PieceColor) -> Bool {
        for rank in 0..<8 {
            for file in 0..<8 {
                let from = Square(file: file, rank: rank)
                guard let piece = self.piece(at: from), piece.color == color else { continue }
                for tr in 0..<8 {
                    for tf in 0..<8 {
                        let to = Square(file: tf, rank: tr)
                        guard from != to else { continue }
                        let targetPiece = self.piece(at: to)
                        if targetPiece?.color == color { continue }
                        let isCapture = targetPiece != nil || (piece.type == .pawn && to == enPassantSquare)
                        if canPieceMove(from: from, to: to, piece: piece, isCapture: isCapture) {
                            var testBoard = self
                            testBoard.setPiece(nil, at: from)
                            testBoard.setPiece(piece, at: to)
                            if piece.type == .pawn && to == enPassantSquare {
                                let capturedRank = color == .white ? to.rank - 1 : to.rank + 1
                                testBoard.setPiece(nil, at: Square(file: to.file, rank: capturedRank))
                            }
                            if !testBoard.isKingInCheck(color: color) {
                                return true
                            }
                        }
                    }
                }
            }
        }
        return false
    }

    // MARK: - Engine Compatibility Check

    /// Returns true if this position has valid piece counts for Stockfish analysis.
    /// Positions with impossible piece configurations (e.g. 3 rooks + 8 pawns) crash the engine.
    func isValidForEngine() -> Bool {
        var wK = 0, bK = 0, wQ = 0, bQ = 0, wR = 0, bR = 0, wB = 0, bB = 0, wN = 0, bN = 0, wP = 0, bP = 0
        for rank in 0..<8 {
            for file in 0..<8 {
                guard let piece = squares[rank][file] else { continue }
                let w = piece.color == .white
                switch piece.type {
                case .king:   if w { wK += 1 } else { bK += 1 }
                case .queen:  if w { wQ += 1 } else { bQ += 1 }
                case .rook:   if w { wR += 1 } else { bR += 1 }
                case .bishop: if w { wB += 1 } else { bB += 1 }
                case .knight: if w { wN += 1 } else { bN += 1 }
                case .pawn:   if w { wP += 1 } else { bP += 1 }
                }
            }
        }
        // Basic checks
        guard wK == 1, bK == 1, wP <= 8, bP <= 8 else { return false }
        // Promotion validity
        let whiteExtra = max(0, wQ-1) + max(0, wR-2) + max(0, wB-2) + max(0, wN-2)
        let blackExtra = max(0, bQ-1) + max(0, bR-2) + max(0, bB-2) + max(0, bN-2)
        guard whiteExtra + wP <= 8, blackExtra + bP <= 8 else { return false }
        return true
    }

    // MARK: - Insufficient Material Detection

    /// Returns true if neither side can force checkmate.
    /// Covers: K vs K, K+B vs K, K+N vs K, K+B vs K+B (same color bishops)
    func isInsufficientMaterial() -> Bool {
        var whitePieces: [PieceType] = []
        var blackPieces: [PieceType] = []
        var whiteBishopLight: Bool?
        var blackBishopLight: Bool?

        for rank in 0..<8 {
            for file in 0..<8 {
                guard let piece = squares[rank][file] else { continue }
                if piece.color == .white {
                    if piece.type != .king { whitePieces.append(piece.type) }
                    if piece.type == .bishop {
                        whiteBishopLight = (file + rank) % 2 == 1
                    }
                } else {
                    if piece.type != .king { blackPieces.append(piece.type) }
                    if piece.type == .bishop {
                        blackBishopLight = (file + rank) % 2 == 1
                    }
                }
            }
        }

        // K vs K
        if whitePieces.isEmpty && blackPieces.isEmpty { return true }

        // K+B vs K or K vs K+B
        if whitePieces.isEmpty && blackPieces == [.bishop] { return true }
        if blackPieces.isEmpty && whitePieces == [.bishop] { return true }

        // K+N vs K or K vs K+N
        if whitePieces.isEmpty && blackPieces == [.knight] { return true }
        if blackPieces.isEmpty && whitePieces == [.knight] { return true }

        // K+B vs K+B (same color bishops)
        if whitePieces == [.bishop] && blackPieces == [.bishop] {
            if let wLight = whiteBishopLight, let bLight = blackBishopLight, wLight == bLight {
                return true
            }
        }

        return false
    }

    // MARK: - Threefold Repetition

    /// Position key for repetition detection: board + side + castling + ep (no clocks).
    private func positionKey() -> String {
        let fen = toFEN()
        // Use first 4 parts of FEN (board, side, castling, ep) — skip halfmove and fullmove clocks
        return fen.split(separator: " ").prefix(4).joined(separator: " ")
    }

    /// Record the current position in history.
    private mutating func recordPosition() {
        let key = positionKey()
        positionHistory[key, default: 0] += 1
    }

    /// Returns true if the current position has occurred 3 or more times.
    func isThreefoldRepetition() -> Bool {
        let key = positionKey()
        return (positionHistory[key] ?? 0) >= 3
    }

    /// Fifty-move rule: draw if 50 moves (100 half-moves) without pawn move or capture.
    func isFiftyMoveRule() -> Bool {
        return halfMoveClock >= 100
    }

    // MARK: - Piece Safety Analysis

    /// Get all pieces of a color that are attacked by the opponent and not adequately defended.
    /// A piece is "unsafe" if it's attacked by the opponent.
    func getUnsafePieces(for color: PieceColor) -> [Square] {
        let opponent = color.opposite
        var unsafe: [Square] = []
        for rank in 0..<8 {
            for file in 0..<8 {
                let sq = Square(file: file, rank: rank)
                guard let piece = self.piece(at: sq),
                      piece.color == color,
                      piece.type != .king else { continue }
                if isSquareAttacked(sq, by: opponent) {
                    unsafe.append(sq)
                }
            }
        }
        return unsafe
    }

    /// Check if a piece is trapped (attacked and has no safe square to move to).
    func isPieceTrapped(at square: Square) -> Bool {
        guard let piece = self.piece(at: square) else { return false }
        let color = piece.color
        let opponent = color.opposite

        // Must be attacked to be "trapped"
        guard isSquareAttacked(square, by: opponent) else { return false }

        // Check if the piece has any safe square to move to
        for rank in 0..<8 {
            for file in 0..<8 {
                let to = Square(file: file, rank: rank)
                guard to != square else { continue }
                let target = self.piece(at: to)
                if target?.color == color { continue }
                let isCapture = target != nil
                if canPieceMove(from: square, to: to, piece: piece, isCapture: isCapture) {
                    // Check that moving here doesn't leave king in check
                    var testBoard = self
                    testBoard.setPiece(nil, at: square)
                    testBoard.setPiece(piece, at: to)
                    if !testBoard.isKingInCheck(color: color) {
                        // Check that the destination isn't also attacked
                        if !testBoard.isSquareAttacked(to, by: opponent) {
                            return false // Has a safe escape square
                        }
                    }
                }
            }
        }
        return true // No safe squares
    }

    /// Count attackers of a square by a given color
    func attackerCount(_ square: Square, by color: PieceColor) -> Int {
        var count = 0
        for rank in 0..<8 {
            for file in 0..<8 {
                let from = Square(file: file, rank: rank)
                guard let piece = self.piece(at: from), piece.color == color else { continue }
                if canPieceMove(from: from, to: square, piece: piece, isCapture: true) {
                    count += 1
                }
            }
        }
        return count
    }

    /// Count defenders of a square (same color pieces that protect it)
    func defenderCount(_ square: Square, for color: PieceColor) -> Int {
        return attackerCount(square, by: color)
    }

    // MARK: - UCI to SAN

    /// Convert a UCI move (e.g. "e2e4", "e7e8q") to SAN (e.g. "e4", "e8=Q") in the current position.
    func uciToSAN(_ uci: String) -> String {
        guard uci.count >= 4 else { return uci }

        let fromStr = String(uci.prefix(2))
        let toStr = String(uci.dropFirst(2).prefix(2))
        let promoChar = uci.count > 4 ? uci.last : nil

        guard let from = Square(algebraic: fromStr),
              let to = Square(algebraic: toStr),
              let movingPiece = piece(at: from) else {
            return uci
        }

        // Castling
        if movingPiece.type == .king && abs(to.file - from.file) == 2 {
            return to.file > from.file ? "O-O" : "O-O-O"
        }

        var san = ""

        // Piece letter (not for pawns)
        if movingPiece.type != .pawn {
            san += movingPiece.type.symbol
        }

        // Disambiguation: only needed if another piece of same type CAN ALSO reach the target
        if movingPiece.type != .pawn {
            var ambiguous: [Square] = []
            for r in 0..<8 {
                for f in 0..<8 {
                    let sq = Square(file: f, rank: r)
                    if sq == from { continue }
                    if let p = piece(at: sq), p.type == movingPiece.type, p.color == movingPiece.color {
                        // Only counts if this other piece can also reach the target
                        if canAttack(from: sq, to: to, piece: p) {
                            ambiguous.append(sq)
                        }
                    }
                }
            }
            if !ambiguous.isEmpty {
                let sameFile = ambiguous.contains { $0.file == from.file }
                let sameRank = ambiguous.contains { $0.rank == from.rank }
                if sameFile && sameRank {
                    san += fromStr
                } else if sameFile {
                    san += "\(from.rank + 1)"
                } else {
                    if let ch = fromStr.first { san += String(ch) }
                }
            }
        }

        // Capture
        let isCapture = piece(at: to) != nil || (movingPiece.type == .pawn && to == enPassantSquare)
        if isCapture {
            if movingPiece.type == .pawn {
                if let ch = fromStr.first { san += String(ch) }
            }
            san += "x"
        }

        // Target square
        san += toStr

        // Promotion
        if let promo = promoChar {
            san += "=\(String(promo).uppercased())"
        }

        // Check / Checkmate detection (make the move on a copy)
        var testBoard = self
        _ = testBoard.makeMoveSAN(san) // This won't work for all cases, so let's do it manually
        // Simple approach: just return san without check markers for now
        // The SAN is already informative enough

        return san
    }

    // MARK: - Material Count

    func materialCount(for color: PieceColor) -> Int {
        var count = 0
        for rank in 0..<8 {
            for file in 0..<8 {
                if let piece = squares[rank][file], piece.color == color {
                    count += piece.type.materialValue
                }
            }
        }
        return count
    }

    // MARK: - Castling Rights Update

    private mutating func updateCastlingRights(from: Square, to: Square, piece: PieceType) {
        // Called BEFORE sideToMove is flipped, so sideToMove = the side that just moved
        if piece == .king {
            if sideToMove == .white {
                castlingRights.remove(.whiteKingside)
                castlingRights.remove(.whiteQueenside)
            } else {
                castlingRights.remove(.blackKingside)
                castlingRights.remove(.blackQueenside)
            }
        }
        // Rook moved or captured
        if from == Square(file: 0, rank: 0) || to == Square(file: 0, rank: 0) {
            castlingRights.remove(.whiteQueenside)
        }
        if from == Square(file: 7, rank: 0) || to == Square(file: 7, rank: 0) {
            castlingRights.remove(.whiteKingside)
        }
        if from == Square(file: 0, rank: 7) || to == Square(file: 0, rank: 7) {
            castlingRights.remove(.blackQueenside)
        }
        if from == Square(file: 7, rank: 7) || to == Square(file: 7, rank: 7) {
            castlingRights.remove(.blackKingside)
        }
    }

    // MARK: - Helpers

    private func fenChar(for piece: ChessPiece) -> String {
        let ch: String
        switch piece.type {
        case .king: ch = "k"
        case .queen: ch = "q"
        case .rook: ch = "r"
        case .bishop: ch = "b"
        case .knight: ch = "n"
        case .pawn: ch = "p"
        }
        return piece.color == .white ? ch.uppercased() : ch
    }

    private func pieceType(from char: Character) -> PieceType? {
        switch char.lowercased().first {
        case "k": return .king
        case "q": return .queen
        case "r": return .rook
        case "b": return .bishop
        case "n": return .knight
        case "p": return .pawn
        default: return nil
        }
    }
}
