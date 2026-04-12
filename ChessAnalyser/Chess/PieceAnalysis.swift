import Foundation

/// Port of WintrChess piece safety, trapped detection, attackers, defenders, and danger levels.

// MARK: - Attacking Moves

struct RawMove: Equatable {
    let piece: PieceType
    let color: PieceColor
    let from: Square
    let to: Square
}

struct PieceAnalysis {

    /// Get all moves that attack a given piece (direct attackers).
    static func getDirectAttackers(board: ChessBoard, target: Square, targetColor: PieceColor) -> [RawMove] {
        let attackerColor = targetColor.opposite
        var attackers: [RawMove] = []

        for rank in 0..<8 {
            for file in 0..<8 {
                let from = Square(file: file, rank: rank)
                guard let piece = board.piece(at: from),
                      piece.color == attackerColor,
                      from != target else { continue }

                // Check if this piece can capture the target
                if board.canAttack(from: from, to: target, piece: piece) {
                    attackers.append(RawMove(piece: piece.type, color: piece.color, from: from, to: target))
                }
            }
        }
        return attackers
    }

    /// Get attacking moves including transitive (battery/x-ray) attackers.
    static func getAttackingMoves(board: ChessBoard, target: Square, targetColor: PieceColor, transitive: Bool = true) -> [RawMove] {
        var attackers = getDirectAttackers(board: board, target: target, targetColor: targetColor)

        guard transitive else { return attackers }

        // Find battery attackers: remove front piece, check for new attackers
        // Cap iterations to prevent runaway computation in complex positions
        var frontier = attackers.map { $0.from }
        var visited = Set<String>()
        var iterations = 0
        let maxIterations = 8

        while !frontier.isEmpty && iterations < maxIterations {
            iterations += 1
            let blockerSquare = frontier.removeFirst()
            let key = blockerSquare.algebraic
            if visited.contains(key) { continue }
            visited.insert(key)

            guard let blocker = board.piece(at: blockerSquare),
                  blocker.type != .king else { continue } // King can't be front of battery

            // Remove blocker and check for revealed attackers
            var testBoard = board
            testBoard.setPiece(nil, at: blockerSquare)

            let revealedAttackers = getDirectAttackers(board: testBoard, target: target, targetColor: targetColor)
                .filter { revealed in
                    !attackers.contains(where: { $0.from == revealed.from }) && revealed.from != blockerSquare
                }

            attackers.append(contentsOf: revealedAttackers)
            frontier.append(contentsOf: revealedAttackers.map { $0.from })
        }

        return attackers
    }

    /// Get defenders of a piece (same-color pieces that could recapture if the piece is taken).
    static func getDefenders(board: ChessBoard, target: Square, targetColor: PieceColor) -> [RawMove] {
        // Defenders = pieces of the same color that attack the target square.
        // Simulated by: if opponent takes on target, who can recapture?
        let directAttackers = getDirectAttackers(board: board, target: target, targetColor: targetColor)

        if directAttackers.isEmpty {
            // No attackers — defenders are same-color pieces that "see" the square
            return getSameColorAttackers(board: board, target: target, color: targetColor)
        }

        // Find minimum recapture set: for each attacker capture, count recapturers
        var minRecapturers: [RawMove]?

        for attacker in directAttackers {
            var captureBoard = board
            guard let attackerPiece = captureBoard.piece(at: attacker.from) else { continue }
            captureBoard.setPiece(nil, at: attacker.from)
            captureBoard.setPiece(ChessPiece(type: attackerPiece.type, color: attackerPiece.color), at: target)

            let recapturers = getDirectAttackers(board: captureBoard, target: target, targetColor: attackerPiece.color)
            if minRecapturers == nil || recapturers.count < (minRecapturers?.count ?? Int.max) {
                minRecapturers = recapturers
            }
        }

        return minRecapturers ?? []
    }

    /// Get same-color pieces that can reach a square (for defender counting when no attackers)
    static func getSameColorAttackers(board: ChessBoard, target: Square, color: PieceColor) -> [RawMove] {
        var defenders: [RawMove] = []
        for rank in 0..<8 {
            for file in 0..<8 {
                let from = Square(file: file, rank: rank)
                guard let piece = board.piece(at: from),
                      piece.color == color,
                      from != target else { continue }
                if board.canAttack(from: from, to: target, piece: piece) {
                    defenders.append(RawMove(piece: piece.type, color: piece.color, from: from, to: target))
                }
            }
        }
        return defenders
    }

    // MARK: - Piece Safety

    /// Determine if a piece is safe on its current square.
    /// Optimized: only computes transitive attackers when direct attackers alone aren't conclusive.
    static func isPieceSafe(board: ChessBoard, square: Square, capturedPieceType: PieceType? = nil) -> Bool {
        guard let piece = board.piece(at: square) else { return true }

        let directAttackers = getDirectAttackers(board: board, target: square, targetColor: piece.color)

        // No attackers = safe (skip expensive defender/transitive computation)
        if directAttackers.isEmpty { return true }

        // A piece with a direct attacker of lower value isn't safe (skip expensive computation)
        let hasLowerValueAttacker = directAttackers.contains {
            $0.piece.materialValue < piece.type.materialValue
        }
        if hasLowerValueAttacker { return false }

        // Only compute defenders and transitive attackers when needed
        let defenders = getSameColorAttackers(board: board, target: square, color: piece.color)

        // Defended by a pawn = safe
        if defenders.contains(where: { $0.piece == .pawn }) { return true }

        // More defenders than direct attackers = likely safe (avoid transitive cost)
        if directAttackers.count <= defenders.count { return true }

        // Piece lower value than all direct attackers + has a low-value defender = safe
        if let lowestAttacker = directAttackers.min(by: { $0.piece.materialValue < $1.piece.materialValue }) {
            if piece.type.materialValue < lowestAttacker.piece.materialValue
                && defenders.contains(where: { $0.piece.materialValue < lowestAttacker.piece.materialValue }) {
                return true
            }
        }

        // Only now compute expensive transitive attackers for edge cases
        let allAttackers = getAttackingMoves(board: board, target: square, targetColor: piece.color, transitive: true)

        // Rook exchange (rook for 2 minor pieces) is safe
        if let captured = capturedPieceType,
           piece.type == .rook,
           captured.materialValue == PieceType.knight.materialValue,
           allAttackers.count == 1,
           !defenders.isEmpty,
           allAttackers[0].piece.materialValue == PieceType.knight.materialValue {
            return true
        }

        if allAttackers.count <= defenders.count { return true }

        return false
    }

    /// Get all unsafe pieces for a color (non-pawn, non-king pieces that are attacked and not adequately defended).
    static func getUnsafePieces(board: ChessBoard, color: PieceColor, capturedValue: Int = 0) -> [(square: Square, piece: ChessPiece)] {
        var unsafe: [(Square, ChessPiece)] = []

        for rank in 0..<8 {
            for file in 0..<8 {
                let sq = Square(file: file, rank: rank)
                guard let piece = board.piece(at: sq),
                      piece.color == color,
                      piece.type != .pawn,
                      piece.type != .king,
                      piece.type.materialValue > capturedValue else { continue }

                if !isPieceSafe(board: board, square: sq) {
                    unsafe.append((sq, piece))
                }
            }
        }
        return unsafe
    }

    // MARK: - Trapped Piece Detection

    /// A piece is trapped if it's unsafe AND every square it can move to is also unsafe.
    /// Optimized: only checks reachable squares using piece movement patterns, not all 64.
    static func isPieceTrapped(board: ChessBoard, square: Square) -> Bool {
        guard let piece = board.piece(at: square) else { return false }

        // Must be unsafe to be trapped
        if isPieceSafe(board: board, square: square) { return false }

        // Generate candidate squares based on piece type (much fewer than 64)
        let candidates = candidateMoveSquares(piece: piece, from: square, board: board)

        for to in candidates {
            let target = board.piece(at: to)
            if target?.color == piece.color { continue }

            if board.canAttack(from: square, to: to, piece: piece) {
                var testBoard = board
                testBoard.setPiece(nil, at: square)
                testBoard.setPiece(piece, at: to)

                if testBoard.isKingInCheck(color: piece.color) { continue }

                if isPieceSafe(board: testBoard, square: to, capturedPieceType: target?.type) {
                    return false
                }
            }
        }
        return true
    }

    /// Generate only the squares a piece could possibly reach, avoiding full 64-square scan.
    private static func candidateMoveSquares(piece: ChessPiece, from: Square, board: ChessBoard) -> [Square] {
        var squares: [Square] = []
        switch piece.type {
        case .knight:
            let offsets = [(-2,-1),(-2,1),(-1,-2),(-1,2),(1,-2),(1,2),(2,-1),(2,1)]
            for (df, dr) in offsets {
                let f = from.file + df, r = from.rank + dr
                if f >= 0 && f < 8 && r >= 0 && r < 8 { squares.append(Square(file: f, rank: r)) }
            }
        case .king:
            for df in -1...1 { for dr in -1...1 {
                if df == 0 && dr == 0 { continue }
                let f = from.file + df, r = from.rank + dr
                if f >= 0 && f < 8 && r >= 0 && r < 8 { squares.append(Square(file: f, rank: r)) }
            }}
        case .pawn:
            let dir = piece.color == .white ? 1 : -1
            for df in [-1, 0, 1] {
                let f = from.file + df, r = from.rank + dir
                if f >= 0 && f < 8 && r >= 0 && r < 8 { squares.append(Square(file: f, rank: r)) }
            }
        case .bishop, .rook, .queen:
            let directions: [(Int,Int)]
            switch piece.type {
            case .bishop: directions = [(-1,-1),(-1,1),(1,-1),(1,1)]
            case .rook: directions = [(-1,0),(1,0),(0,-1),(0,1)]
            default: directions = [(-1,-1),(-1,1),(1,-1),(1,1),(-1,0),(1,0),(0,-1),(0,1)]
            }
            for (df, dr) in directions {
                var f = from.file + df, r = from.rank + dr
                while f >= 0 && f < 8 && r >= 0 && r < 8 {
                    squares.append(Square(file: f, rank: r))
                    if board.piece(at: Square(file: f, rank: r)) != nil { break }
                    f += df; r += dr
                }
            }
        }
        return squares
    }

    // MARK: - Danger Levels

    /// Check if acting on a threat (moving/capturing) creates a greater counterthreat.
    static func moveCreatesGreaterThreat(
        board: ChessBoard,
        threatenedPiece: (square: Square, piece: ChessPiece),
        actingMove: RawMove
    ) -> Bool {
        let color = actingMove.color

        // Count unsafe pieces of higher/equal value before the move
        let previousUnsafe = getUnsafePieces(board: board, color: color)
            .filter { $0.piece.type.materialValue >= threatenedPiece.piece.type.materialValue && $0.square != threatenedPiece.square }

        // Make the move
        var afterBoard = board
        afterBoard.setPiece(nil, at: actingMove.from)
        let movingPiece = board.piece(at: actingMove.from) ?? ChessPiece(type: actingMove.piece, color: actingMove.color)
        afterBoard.setPiece(movingPiece, at: actingMove.to)

        // Count new unsafe pieces after
        let afterUnsafe = getUnsafePieces(board: afterBoard, color: color)
            .filter { $0.piece.type.materialValue >= threatenedPiece.piece.type.materialValue && $0.square != threatenedPiece.square }

        let newThreats = afterUnsafe.filter { after in
            !previousUnsafe.contains(where: { $0.square == after.square })
        }

        return !newThreats.isEmpty
    }

    // MARK: - Critical Move Candidate

    /// A move is a critical candidate if finding it was important to the game.
    static func isMoveCriticalCandidate(
        evalBefore: EngineEval,
        evalAfter: EngineEval,
        secondBestEval: EngineEval?,
        isWhite: Bool,
        isPromotion: Bool,
        isInCheck: Bool
    ) -> Bool {
        // Already completely winning even without finding this move
        if let secondEval = secondBestEval {
            let secondSubjective = isWhite ? secondEval.score : -secondEval.score
            if !secondEval.isMate && secondSubjective >= 700 { return false }
        } else {
            let subjective = isWhite ? evalAfter.score : -evalAfter.score
            if !evalAfter.isMate && subjective >= 700 { return false }
        }

        // Losing position can't be critical
        let subjectiveAfter = isWhite ? evalAfter.score : -evalAfter.score
        if !evalAfter.isMate && subjectiveAfter < 0 { return false }

        // Queen promotions aren't critical (obvious)
        if isPromotion { return false }

        // Escaping check isn't critical (forced response)
        if isInCheck { return false }

        return true
    }

    // MARK: - Board Arrows (attack/defense visualization)

    struct BoardArrow: Equatable {
        let from: Square
        let to: Square
        let type: ArrowType
    }

    enum ArrowType {
        case bestMove   // Blue
        case defense    // Green
        case attack     // Red
    }

    /// Generate arrows for the current position showing attacks and defenses.
    static func generateArrows(
        board: ChessBoard,
        analysis: MoveAnalysis?,
        showBestMove: Bool,
        showAttacks: Bool,
        showDefenses: Bool
    ) -> [BoardArrow] {
        var arrows: [BoardArrow] = []

        // Best move arrow (blue)
        if showBestMove, let analysis = analysis {
            if let parsed = UCIParser.parseUCIMove(analysis.bestMove),
               let from = Square(algebraic: parsed.from),
               let to = Square(algebraic: parsed.to) {
                arrows.append(BoardArrow(from: from, to: to, type: .bestMove))
            }
        }

        // Use the side to move from the board itself (works for every position)
        let sideToMove = board.sideToMove

        // Attack arrows (red) — show ALL pieces of side-to-move that are attacked by opponent
        if showAttacks {

            for rank in 0..<8 {
                for file in 0..<8 {
                    let sq = Square(file: file, rank: rank)
                    guard let piece = board.piece(at: sq),
                          piece.color == sideToMove,
                          piece.type != .king else { continue }

                    let attackers = getDirectAttackers(board: board, target: sq, targetColor: sideToMove)
                    if !attackers.isEmpty {
                        // Show the most valuable attacker (strongest threat)
                        if let topAttacker = attackers.min(by: { $0.piece.materialValue < $1.piece.materialValue }) {
                            arrows.append(BoardArrow(from: topAttacker.from, to: sq, type: .attack))
                        }
                    }
                }
            }
        }

        // Defense arrows (green) — show defenders of attacked pieces
        if showDefenses {

            for rank in 0..<8 {
                for file in 0..<8 {
                    let sq = Square(file: file, rank: rank)
                    guard let piece = board.piece(at: sq),
                          piece.color == sideToMove,
                          piece.type != .king else { continue }

                    // Only show defense for pieces that are actually attacked
                    let attackers = getDirectAttackers(board: board, target: sq, targetColor: sideToMove)
                    guard !attackers.isEmpty else { continue }

                    let defenders = getSameColorAttackers(board: board, target: sq, color: sideToMove)
                    if let topDefender = defenders.first {
                        arrows.append(BoardArrow(from: topDefender.from, to: sq, type: .defense))
                    }
                }
            }
        }

        return arrows
    }
}

// MARK: - ChessBoard Extension for canAttack

extension ChessBoard {
    /// Check if a piece at `from` can attack `to` (used for attack/defense analysis).
    /// Unlike canPieceMove, this doesn't need the isCapture flag — always checks attack patterns.
    func canAttack(from: Square, to: Square, piece: ChessPiece) -> Bool {
        let df = to.file - from.file
        let dr = to.rank - from.rank
        let adf = abs(df)
        let adr = abs(dr)

        switch piece.type {
        case .pawn:
            let direction = piece.color == .white ? 1 : -1
            return adf == 1 && dr == direction

        case .knight:
            return (adf == 1 && adr == 2) || (adf == 2 && adr == 1)

        case .bishop:
            return adf == adr && adf > 0 && isPathClearForAttack(from: from, to: to)

        case .rook:
            return (df == 0 || dr == 0) && (adf + adr > 0) && isPathClearForAttack(from: from, to: to)

        case .queen:
            return ((adf == adr && adf > 0) || ((df == 0 || dr == 0) && (adf + adr > 0))) && isPathClearForAttack(from: from, to: to)

        case .king:
            return adf <= 1 && adr <= 1 && (adf + adr > 0)
        }
    }

    private func isPathClearForAttack(from: Square, to: Square) -> Bool {
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
}
