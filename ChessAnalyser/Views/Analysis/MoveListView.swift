import SwiftUI

/// Horizontal scrollable move list (chess.com style).
/// Shows moves in a single row: 1. e4 e5 2. Nf3 Nc6 ...
/// Auto-scrolls to the current move.
struct MoveListView: View {
    let moves: [GameMove]
    let analysisCache: [Int: MoveAnalysis]
    let currentMoveIndex: Int
    let onTapMove: (Int) -> Void
    var vertical: Bool = false

    var body: some View {
        if vertical {
            verticalMoveList
        } else {
            horizontalMoveList
        }
    }

    // MARK: - Horizontal (iPhone / compact)

    private var horizontalMoveList: some View {
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

    // MARK: - Vertical (iPad side panel)

    private var verticalMoveList: some View {
        ScrollViewReader { proxy in
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 0),
                GridItem(.flexible(), spacing: 0),
                GridItem(.flexible(), spacing: 0),
            ], spacing: 4) {
                ForEach(movePairs, id: \.number) { pair in
                    // Move number
                    Text("\(pair.number).")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 2)

                    // White move
                    if let white = pair.white {
                        moveChip(white)
                            .id(white.moveIndex)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Color.clear.frame(height: 1)
                    }

                    // Black move
                    if let black = pair.black {
                        moveChip(black)
                            .id(black.moveIndex)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Color.clear.frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xs)
            .onChange(of: currentMoveIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }

    // MARK: - Move Pairs for vertical layout

    private struct MovePair {
        let number: Int
        let white: GameMove?
        let black: GameMove?
    }

    private var movePairs: [MovePair] {
        var pairs: [MovePair] = []
        var i = 0
        while i < moves.count {
            let white = moves[i].isWhite ? moves[i] : nil
            let black: GameMove?
            if white != nil && i + 1 < moves.count && !moves[i + 1].isWhite {
                black = moves[i + 1]
                i += 2
            } else if white == nil {
                // Black move without white (shouldn't happen but handle gracefully)
                pairs.append(MovePair(number: moves[i].moveNumber, white: nil, black: moves[i]))
                i += 1
                continue
            } else {
                black = nil
                i += 1
            }
            pairs.append(MovePair(number: white?.moveNumber ?? (black?.moveNumber ?? 1), white: white, black: black))
        }
        return pairs
    }

    // MARK: - Move Chip

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
