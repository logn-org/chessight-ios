import SwiftUI

struct AnalysisControlsView: View {
    let isFlipped: Bool
    let isAtStart: Bool
    let isAtEnd: Bool
    let autoPlay: Bool
    let isAnalyzing: Bool
    let showReEvaluate: Bool
    let onGoToStart: () -> Void
    let onGoBack: () -> Void
    let onGoForward: () -> Void
    let onGoToEnd: () -> Void
    let onToggleAutoPlay: () -> Void
    let onFlipBoard: () -> Void
    let onReEvaluate: () -> Void
    let onShare: () -> Void

    init(isFlipped: Bool, isAtStart: Bool, isAtEnd: Bool, autoPlay: Bool,
         isAnalyzing: Bool = false, showReEvaluate: Bool = true,
         onGoToStart: @escaping () -> Void, onGoBack: @escaping () -> Void,
         onGoForward: @escaping () -> Void, onGoToEnd: @escaping () -> Void,
         onToggleAutoPlay: @escaping () -> Void, onFlipBoard: @escaping () -> Void,
         onReEvaluate: @escaping () -> Void = {}, onShare: @escaping () -> Void = {}) {
        self.isFlipped = isFlipped; self.isAtStart = isAtStart; self.isAtEnd = isAtEnd
        self.autoPlay = autoPlay; self.isAnalyzing = isAnalyzing; self.showReEvaluate = showReEvaluate
        self.onGoToStart = onGoToStart; self.onGoBack = onGoBack
        self.onGoForward = onGoForward; self.onGoToEnd = onGoToEnd
        self.onToggleAutoPlay = onToggleAutoPlay; self.onFlipBoard = onFlipBoard
        self.onReEvaluate = onReEvaluate; self.onShare = onShare
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            blockButton(icon: "arrow.up.arrow.down", label: "Flip", action: onFlipBoard)

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

            if showReEvaluate {
                blockButton(icon: "sparkle.magnifyingglass", label: "Eval", action: onReEvaluate, showSpinner: isAnalyzing)
                    .disabled(isAnalyzing)
            }

            blockButton(icon: "square.and.arrow.up", label: "Share", action: onShare)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
    }

    private func blockButton(icon: String, label: String, action: @escaping () -> Void, showSpinner: Bool = false) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if showSpinner {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(AppColors.accent)
                        .frame(height: 18)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                }
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
