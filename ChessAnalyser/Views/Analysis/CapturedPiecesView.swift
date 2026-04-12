import SwiftUI

/// Shows captured pieces by comparing current board against the initial position.
/// Only shows pieces actually captured during play, not pieces missing from a custom FEN.
struct CapturedPiecesView: View {
    let board: ChessBoard
    let initialBoard: ChessBoard  // The starting position to compare against
    let capturedByWhite: Bool

    var body: some View {
        let captured = getCapturedPieces()
        let advantage = materialAdvantage()

        HStack(spacing: 0) {
            ForEach(Array(captured.enumerated()), id: \.offset) { _, pieceType in
                let piece = ChessPiece(type: pieceType, color: capturedByWhite ? .black : .white)
                Image(piece.assetName)
                    .resizable()
                    .frame(width: 14, height: 14)
                    .shadow(color: .white.opacity(piece.color == .black ? 0.5 : 0), radius: 1, x: 0, y: 0)
                    .padding(.trailing, -3)
            }

            if advantage > 0 {
                Text("+\(advantage)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.leading, captured.isEmpty ? 0 : 4)
            }

            Spacer()
        }
        .frame(height: 18)
    }

    private func getCapturedPieces() -> [PieceType] {
        let lostColor: PieceColor = capturedByWhite ? .black : .white

        // Count pieces in the INITIAL position (not standard setup)
        var initialCounts: [PieceType: Int] = [:]
        for rank in 0..<8 {
            for file in 0..<8 {
                if let piece = initialBoard.piece(at: Square(file: file, rank: rank)),
                   piece.color == lostColor, piece.type != .king {
                    initialCounts[piece.type, default: 0] += 1
                }
            }
        }

        // Count pieces on the CURRENT board
        var currentCounts: [PieceType: Int] = [:]
        for rank in 0..<8 {
            for file in 0..<8 {
                if let piece = board.piece(at: Square(file: file, rank: rank)),
                   piece.color == lostColor, piece.type != .king {
                    currentCounts[piece.type, default: 0] += 1
                }
            }
        }

        var captured: [PieceType] = []
        for type in [PieceType.queen, .rook, .bishop, .knight, .pawn] {
            let lost = max(0, (initialCounts[type] ?? 0) - (currentCounts[type] ?? 0))
            for _ in 0..<lost { captured.append(type) }
        }
        return captured
    }

    private func materialAdvantage() -> Int {
        let whiteMat = board.materialCount(for: .white)
        let blackMat = board.materialCount(for: .black)
        let diff = whiteMat - blackMat
        return capturedByWhite ? max(0, diff) : max(0, -diff)
    }
}
