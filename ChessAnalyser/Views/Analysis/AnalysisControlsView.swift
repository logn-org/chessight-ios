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

    init(isFlipped: Bool, isAtStart: Bool, isAtEnd: Bool, autoPlay: Bool,
         isAnalyzing: Bool = false, showReEvaluate: Bool = true,
         onGoToStart: @escaping () -> Void, onGoBack: @escaping () -> Void,
         onGoForward: @escaping () -> Void, onGoToEnd: @escaping () -> Void,
         onToggleAutoPlay: @escaping () -> Void, onFlipBoard: @escaping () -> Void,
         onReEvaluate: @escaping () -> Void = {}) {
        self.isFlipped = isFlipped; self.isAtStart = isAtStart; self.isAtEnd = isAtEnd
        self.autoPlay = autoPlay; self.isAnalyzing = isAnalyzing; self.showReEvaluate = showReEvaluate
        self.onGoToStart = onGoToStart; self.onGoBack = onGoBack
        self.onGoForward = onGoForward; self.onGoToEnd = onGoToEnd
        self.onToggleAutoPlay = onToggleAutoPlay; self.onFlipBoard = onFlipBoard
        self.onReEvaluate = onReEvaluate
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left: flip
            Button(action: onFlipBoard) {
                Image(systemName: "arrow.up.arrow.down").font(.body)
            }
            .frame(maxWidth: .infinity)

            // Center: navigation
            HStack(spacing: AppSpacing.lg) {
                Button(action: onGoToStart) {
                    Image(systemName: "backward.end.fill").font(.title3)
                }.disabled(isAtStart)

                Button(action: onGoBack) {
                    Image(systemName: "chevron.left").font(.title2).fontWeight(.bold)
                }.disabled(isAtStart)

                Button(action: onToggleAutoPlay) {
                    Image(systemName: autoPlay ? "pause.fill" : "play.fill").font(.title2)
                }

                Button(action: onGoForward) {
                    Image(systemName: "chevron.right").font(.title2).fontWeight(.bold)
                }.disabled(isAtEnd)

                Button(action: onGoToEnd) {
                    Image(systemName: "forward.end.fill").font(.title3)
                }.disabled(isAtEnd)
            }
            .frame(maxWidth: .infinity)

            // Right: re-evaluate with engine
            if showReEvaluate {
                Button(action: onReEvaluate) {
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(AppColors.accent)
                    } else {
                        Image(systemName: "sparkle.magnifyingglass")
                            .font(.body)
                    }
                }
                .disabled(isAnalyzing)
                .frame(maxWidth: .infinity)
            } else {
                Spacer().frame(maxWidth: .infinity)
            }
        }
        .foregroundStyle(AppColors.textPrimary)
        .padding(.vertical, AppSpacing.sm)
    }
}
