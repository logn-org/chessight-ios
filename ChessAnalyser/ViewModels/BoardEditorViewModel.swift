import SwiftUI

enum EditorMode: String, CaseIterable {
    case place
    case move
    case erase
}

@MainActor @Observable
final class BoardEditorViewModel {
    var board = ChessBoard()
    var selectedPieceToPlace: ChessPiece?
    var sideToMove: PieceColor = .white
    var isFlipped = false
    var editorMode: EditorMode = .move

    var pickedUpSquare: Square?
    var pickedUpPiece: ChessPiece?
    var didLoadFEN = false

    // Undo history
    private var history: [ChessBoard] = []
    var canUndo: Bool { !history.isEmpty }

    var currentFEN: String {
        // Build FEN with the user-selected side to move
        var fen = board.toFEN()
        // Replace the side-to-move component
        var parts = fen.split(separator: " ").map(String.init)
        if parts.count >= 2 {
            parts[1] = sideToMove.rawValue
            fen = parts.joined(separator: " ")
        }
        return fen
    }

    let whitePieces: [ChessPiece] = [
        ChessPiece(type: .king, color: .white),
        ChessPiece(type: .queen, color: .white),
        ChessPiece(type: .rook, color: .white),
        ChessPiece(type: .bishop, color: .white),
        ChessPiece(type: .knight, color: .white),
        ChessPiece(type: .pawn, color: .white),
    ]

    let blackPieces: [ChessPiece] = [
        ChessPiece(type: .king, color: .black),
        ChessPiece(type: .queen, color: .black),
        ChessPiece(type: .rook, color: .black),
        ChessPiece(type: .bishop, color: .black),
        ChessPiece(type: .knight, color: .black),
        ChessPiece(type: .pawn, color: .black),
    ]

    // MARK: - Save state for undo

    private func saveState() {
        history.append(board)
        if history.count > 50 { history.removeFirst() }
    }

    func undo() {
        guard let previous = history.popLast() else { return }
        board = previous
        pickedUpSquare = nil
        pickedUpPiece = nil
    }

    // MARK: - Tap

    func tapSquare(_ square: Square) {
        switch editorMode {
        case .place:
            if let piece = selectedPieceToPlace {
                saveState()
                board.setPiece(piece, at: square)
            }
        case .erase:
            if board.piece(at: square) != nil {
                saveState()
                board.setPiece(nil, at: square)
            }
        case .move:
            if let pickedSq = pickedUpSquare, let piece = pickedUpPiece {
                saveState()
                board.setPiece(piece, at: square)
                if pickedSq != square {
                    board.setPiece(nil, at: pickedSq)
                }
                pickedUpSquare = nil
                pickedUpPiece = nil
            } else if let piece = board.piece(at: square) {
                pickedUpSquare = square
                pickedUpPiece = piece
            }
        }
    }

    func dragMove(from: Square, to: Square) {
        guard let piece = board.piece(at: from) else { return }
        saveState()
        board.setPiece(nil, at: from)
        board.setPiece(piece, at: to)
        pickedUpSquare = nil
        pickedUpPiece = nil
    }

    func selectPiece(_ piece: ChessPiece) {
        editorMode = .place
        if selectedPieceToPlace == piece {
            selectedPieceToPlace = nil
            editorMode = .move
        } else {
            selectedPieceToPlace = piece
        }
    }

    func setMode(_ mode: EditorMode) {
        editorMode = mode
        if mode != .place { selectedPieceToPlace = nil }
        pickedUpSquare = nil
        pickedUpPiece = nil
    }

    func clearBoard() {
        saveState()
        board = ChessBoard(fen: "8/8/8/8/8/8/8/8 w - - 0 1")
        pickedUpSquare = nil
        pickedUpPiece = nil
    }

    func resetToDefault() {
        saveState()
        board = ChessBoard()
        sideToMove = .white
        pickedUpSquare = nil
        pickedUpPiece = nil
    }

    /// Load a position from a FEN string. Returns an error message if invalid.
    func loadFEN(_ fen: String) -> String? {
        let trimmed = fen.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "FEN is empty" }

        let parts = trimmed.split(separator: " ")
        guard parts.count >= 1 else { return "Invalid FEN format" }

        // Basic validation: first part should have 8 ranks separated by /
        let ranks = parts[0].split(separator: "/")
        guard ranks.count == 8 else { return "FEN must have 8 ranks separated by /" }

        saveState()
        board = ChessBoard(fen: trimmed)

        // Set side to move from FEN
        if parts.count >= 2 {
            sideToMove = parts[1] == "b" ? .black : .white
        }

        pickedUpSquare = nil
        pickedUpPiece = nil
        didLoadFEN = true
        return nil
    }

    func toggleSideToMove() {
        sideToMove = sideToMove.opposite
        isFlipped = sideToMove == .black
    }

    /// Minimum check: both kings must exist for a playable game
    func validatePlayable() -> String? {
        var wK = 0, bK = 0
        for rank in 0..<8 {
            for file in 0..<8 {
                if let piece = board.piece(at: Square(file: file, rank: rank)), piece.type == .king {
                    if piece.color == .white { wK += 1 } else { bK += 1 }
                }
            }
        }
        if wK != 1 { return "Position must have exactly one white king" }
        if bK != 1 { return "Position must have exactly one black king" }
        return nil
    }

    /// Whether the current position is safe for Stockfish analysis
    var isEngineCompatible: Bool {
        let board = ChessBoard(fen: currentFEN)
        return board.isValidForEngine()
    }

    // MARK: - Chess960 Shuffle

    /// Set up a Chess960 (Fischer Random) starting position
    func shuffleChess960() {
        Analytics.chess960Generated()
        saveState()
        board = ChessBoard(fen: "8/8/8/8/8/8/8/8 w - - 0 1")

        // Generate random back rank following Chess960 rules:
        // 1. Bishops on opposite colors
        // 2. King between the two rooks
        var backRank: [PieceType] = Array(repeating: .pawn, count: 8) // placeholder

        // Place bishops on opposite colors
        let lightSquare = [0, 2, 4, 6].randomElement()!
        let darkSquare = [1, 3, 5, 7].randomElement()!
        backRank[lightSquare] = .bishop
        backRank[darkSquare] = .bishop

        // Place queen on random empty square
        var empty = (0..<8).filter { backRank[$0] == .pawn }
        let queenIdx = empty.randomElement()!
        backRank[queenIdx] = .queen
        empty = empty.filter { $0 != queenIdx }

        // Place knights on two random empty squares
        let knight1Idx = empty.randomElement()!
        empty = empty.filter { $0 != knight1Idx }
        let knight2Idx = empty.randomElement()!
        empty = empty.filter { $0 != knight2Idx }
        backRank[knight1Idx] = .knight
        backRank[knight2Idx] = .knight

        // Place rooks and king: king must be between the two rooks
        // 3 empty squares left — rook, king, rook (in file order)
        let sorted = empty.sorted()
        backRank[sorted[0]] = .rook
        backRank[sorted[1]] = .king
        backRank[sorted[2]] = .rook

        // Place pieces on the board
        for file in 0..<8 {
            // White back rank
            board.setPiece(ChessPiece(type: backRank[file], color: .white), at: Square(file: file, rank: 0))
            // White pawns
            board.setPiece(ChessPiece(type: .pawn, color: .white), at: Square(file: file, rank: 1))
            // Black pawns
            board.setPiece(ChessPiece(type: .pawn, color: .black), at: Square(file: file, rank: 6))
            // Black back rank (mirror)
            board.setPiece(ChessPiece(type: backRank[file], color: .black), at: Square(file: file, rank: 7))
        }

        sideToMove = .white
        pickedUpSquare = nil
        pickedUpPiece = nil
    }
}
