import SwiftUI

struct AccuracyView: View {
    let whiteAccuracy: Double
    let blackAccuracy: Double
    let whiteName: String
    let blackName: String
    let whiteCounts: [MoveClassification: Int]
    let blackCounts: [MoveClassification: Int]

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Game Accuracy")
                .font(AppFonts.subtitle)
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: AppSpacing.xl) {
                accuracyColumn(
                    name: whiteName,
                    accuracy: whiteAccuracy,
                    isWhite: true,
                    counts: whiteCounts
                )

                Divider()
                    .background(AppColors.surfaceLight)
                    .frame(height: 200)

                accuracyColumn(
                    name: blackName,
                    accuracy: blackAccuracy,
                    isWhite: false,
                    counts: blackCounts
                )
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    private func accuracyColumn(name: String, accuracy: Double, isWhite: Bool, counts: [MoveClassification: Int]) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(isWhite ? Color.white : Color.black)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(AppColors.surfaceLight, lineWidth: 1))

            Text(name)
                .font(AppFonts.bodyBold)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            Text(String(format: "%.1f%%", accuracy))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(accuracyColor(accuracy))

            // Move classification breakdown
            VStack(alignment: .leading, spacing: 2) {
                let orderedClassifications: [MoveClassification] = [
                    .brilliant, .great, .best, .excellent, .good, .ok, .book,
                    .miss, .inaccuracy, .mistake, .blunder
                ]

                ForEach(orderedClassifications, id: \.self) { classification in
                    if let count = counts[classification], count > 0 {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: classification.iconName)
                                .font(.system(size: 10))
                                .foregroundStyle(classification.color)
                                .frame(width: 14)

                            Text(classification.label)
                                .font(AppFonts.small)
                                .foregroundStyle(AppColors.textSecondary)

                            Spacer()

                            Text("\(count)")
                                .font(AppFonts.captionBold)
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                }
            }
            .frame(maxWidth: 140)
        }
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 90 { return AppColors.best }
        if accuracy >= 70 { return AppColors.good }
        if accuracy >= 50 { return AppColors.inaccuracy }
        return AppColors.mistake
    }
}
