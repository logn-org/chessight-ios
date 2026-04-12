import SwiftUI

/// Horizontal scrollable move list (chess.com style).
/// Shows moves in a single row: 1. e4 e5 2. Nf3 Nc6 ...
/// Auto-scrolls to the current move.
struct MoveListView: View {
    let moves: [GameMove]
    let analysisCache: [Int: MoveAnalysis]
    let currentMoveIndex: Int
    let onTapMove: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(moves) { move in
                        // Show move number before white's move
                        if move.isWhite {
                            Text("\(move.moveNumber).")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textMuted)
                                .padding(.leading, move.moveIndex == 0 ? 0 : 4)
                        }

                        moveChip(move)
                            .id(move.moveIndex)
                    }
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
            }
            .onChange(of: currentMoveIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
        .frame(height: 36)
        .background(AppColors.surface)
    }

    private func moveChip(_ move: GameMove) -> some View {
        let isSelected = move.moveIndex == currentMoveIndex
        let analysis = analysisCache[move.moveIndex]
        let classification = analysis?.classification

        return Button {
            onTapMove(move.moveIndex)
        } label: {
            HStack(spacing: 2) {
                // Classification dot for notable moves
                if let c = classification,
                   c != .none, c != .good, c != .book, c != .forced, c != .ok, c != .excellent {
                    Circle().fill(c.color).frame(width: 6, height: 6)
                }

                Text(move.san)
                    .font(AppFonts.moveText)
                    .foregroundStyle(isSelected ? AppColors.background : AppColors.textPrimary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? AppColors.accent : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
