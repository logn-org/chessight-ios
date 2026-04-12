import SwiftUI

/// Two-row classification summary — one for white, one for black.
/// Tapping a chip cycles through that side's moves of that classification.
struct ClassificationSummaryView: View {
    let cache: [Int: MoveAnalysis]
    let currentMoveIndex: Int
    let onNavigateToMove: (Int) -> Void

    @State private var navIndex: [String: Int] = [:] // "w_blunder" → cycle index

    private let displayOrder: [MoveClassification] = [
        .brilliant, .great, .best, .excellent, .good, .ok,
        .book, .miss, .inaccuracy, .mistake, .blunder
    ]

    var body: some View {
        VStack(spacing: 2) {
            sideRow(isWhite: true)
            sideRow(isWhite: false)
        }
    }

    private func sideRow(isWhite: Bool) -> some View {
        let counts = classificationCounts(isWhite: isWhite)

        return HStack(spacing: 4) {
            // Side indicator
            Circle()
                .fill(isWhite ? Color.white : Color.black)
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(AppColors.surfaceLight, lineWidth: 0.5))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(displayOrder, id: \.self) { classification in
                        if let count = counts[classification], count > 0 {
                            chipButton(classification, count: count, isWhite: isWhite)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 2)
    }

    private func chipButton(_ classification: MoveClassification, count: Int, isWhite: Bool) -> some View {
        Button {
            navigateToNext(classification, isWhite: isWhite)
        } label: {
            HStack(spacing: 2) {
                Image(systemName: classification.iconName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(classification.color)

                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(classification.color.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func navigateToNext(_ classification: MoveClassification, isWhite: Bool) {
        let key = "\(isWhite ? "w" : "b")_\(classification.rawValue)"
        let moves = movesFor(classification, isWhite: isWhite)
        guard !moves.isEmpty else { return }

        let current = navIndex[key] ?? -1
        let next = current + 1
        let target: Int

        if next < moves.count {
            target = moves[next]
            navIndex[key] = next
        } else {
            target = moves[0]
            navIndex[key] = 0
        }

        onNavigateToMove(target)
    }

    private func movesFor(_ classification: MoveClassification, isWhite: Bool) -> [Int] {
        cache.values
            .filter { $0.classification == classification && $0.isWhite == isWhite }
            .sorted { $0.moveIndex < $1.moveIndex }
            .map { $0.moveIndex }
    }

    private func classificationCounts(isWhite: Bool) -> [MoveClassification: Int] {
        var counts: [MoveClassification: Int] = [:]
        for (_, analysis) in cache {
            guard analysis.isWhite == isWhite,
                  analysis.classification != .none,
                  analysis.classification != .forced else { continue }
            counts[analysis.classification, default: 0] += 1
        }
        return counts
    }
}
