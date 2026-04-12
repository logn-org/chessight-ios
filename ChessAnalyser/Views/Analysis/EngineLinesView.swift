import SwiftUI

struct EngineLinesView: View {
    let lines: [EngineLine]
    /// True if white is the side to move in the position these lines describe.
    var sideToMoveIsWhite: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Engine Lines")
                .font(AppFonts.captionBold)
                .foregroundStyle(AppColors.textSecondary)

            ForEach(Array(lines.prefix(3).enumerated()), id: \.offset) { index, line in
                HStack(spacing: AppSpacing.sm) {
                    Text(line.eval.displayTextWhitePerspective(sideToMoveIsWhite: sideToMoveIsWhite))
                        .font(AppFonts.evalText)
                        .foregroundStyle(evalColor(line.eval))
                        .frame(width: 50, alignment: .trailing)

                    Text(line.moves.prefix(8).joined(separator: " "))
                        .font(AppFonts.moveText)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                }
                .padding(.vertical, AppSpacing.xs)

                if index < min(lines.count, 3) - 1 {
                    Divider().background(AppColors.surfaceLight)
                }
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    private func evalColor(_ eval: EngineEval) -> Color {
        let whiteCP = MoveClassifier.toWhiteCP(eval, sideToMoveIsWhite: sideToMoveIsWhite)
        if whiteCP > 50 { return AppColors.win }
        if whiteCP < -50 { return AppColors.loss }
        return AppColors.textSecondary
    }
}
