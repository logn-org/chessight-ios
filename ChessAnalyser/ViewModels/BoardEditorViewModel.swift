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

    func validatePosition() -> String? {
        var whiteKings = 0, blackKings = 0, totalPieces = 0
        for rank in 0..<8 {
            for file in 0..<8 {
                if let piece = board.piece(at: Square(file: file, rank: rank)) {
                    totalPieces += 1
                    if piece.type == .king {
                        if piece.color == .white { whiteKings += 1 }
                        else { blackKings += 1 }
                    }
                }
            }
        }
        if whiteKings != 1 { return "Position must have exactly one white king" }
        if blackKings != 1 { return "Position must have exactly one black king" }
        if totalPieces > 32 { return "Too many pieces on the board" }
        if totalPieces < 2 { return "Need at least two kings" }
        return nil
    }
}
