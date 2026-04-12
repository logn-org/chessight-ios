import SwiftUI

struct MoveExplanationView: View {
    let analysis: MoveAnalysis

    var body: some View {
        let explanation = MoveExplainer.explain(analysis)
        if !explanation.isEmpty {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: analysis.classification.iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(analysis.classification.color)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(analysis.classification.label)
                            .font(AppFonts.captionBold)
                            .foregroundStyle(analysis.classification.color)

                        Text("(\(analysis.san))")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textMuted)
                    }

                    Text(explanation)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(analysis.classification.color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.easeInOut(duration: 0.2), value: analysis.moveIndex)
        }
    }
}
