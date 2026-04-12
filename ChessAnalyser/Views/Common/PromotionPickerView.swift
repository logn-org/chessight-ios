import SwiftUI

/// Overlay picker for pawn promotion — shows Q/R/B/N choices.
struct PromotionPickerView: View {
    let color: PieceColor
    let onSelect: (PieceType) -> Void

    private let pieces: [PieceType] = [.queen, .rook, .bishop, .knight]

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: AppSpacing.md) {
                ForEach(pieces, id: \.rawValue) { pieceType in
                    Button {
                        onSelect(pieceType)
                    } label: {
                        Image(ChessPiece(type: pieceType, color: color).assetName)
                            .resizable()
                            .frame(width: 48, height: 48)
                            .padding(AppSpacing.sm)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusLg))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.4))
    }
}
