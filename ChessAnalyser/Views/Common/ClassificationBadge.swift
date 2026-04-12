import SwiftUI

struct ClassificationBadge: View {
    let classification: MoveClassification

    var body: some View {
        if classification != .none {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: classification.iconName)
                    .font(.system(size: 12))
                Text(classification.label)
                    .font(AppFonts.captionBold)
            }
            .foregroundStyle(classification.color)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(classification.color.opacity(0.15))
            .clipShape(Capsule())
        }
    }
}

struct ClassificationDot: View {
    let classification: MoveClassification

    var body: some View {
        if classification != .none {
            Image(systemName: classification.iconName)
                .font(.system(size: 14))
                .foregroundStyle(classification.color)
        }
    }
}
