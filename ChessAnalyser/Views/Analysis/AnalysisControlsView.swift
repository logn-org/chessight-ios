import SwiftUI

struct AnalysisControlsView: View {
    let isAtStart: Bool
    let isAtEnd: Bool
    let autoPlay: Bool
    let onGoToStart: () -> Void
    let onGoBack: () -> Void
    let onGoForward: () -> Void
    let onGoToEnd: () -> Void
    let onToggleAutoPlay: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            blockButton(icon: "backward.end.fill", label: "Start", action: onGoToStart)
                .opacity(isAtStart ? 0.4 : 1)
                .disabled(isAtStart)

            blockButton(icon: "chevron.left", label: "Back", action: onGoBack)
                .opacity(isAtStart ? 0.4 : 1)
                .disabled(isAtStart)

            blockButton(
                icon: autoPlay ? "pause.fill" : "play.fill",
                label: autoPlay ? "Pause" : "Play",
                action: onToggleAutoPlay
            )

            blockButton(icon: "chevron.right", label: "Next", action: onGoForward)
                .opacity(isAtEnd ? 0.4 : 1)
                .disabled(isAtEnd)

            blockButton(icon: "forward.end.fill", label: "End", action: onGoToEnd)
                .opacity(isAtEnd ? 0.4 : 1)
                .disabled(isAtEnd)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
    }

    private func blockButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
    }
}
