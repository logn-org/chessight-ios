import SwiftUI

struct EvalBarView: View {
    let eval: EngineEval
    var sideToMoveIsWhite: Bool = true
    var isVertical: Bool = true
    /// When true, the bar dims and hides its label — the displayed value is stale
    /// while a fresh engine analysis is running.
    var isPending: Bool = false

    /// Sticky display values — only updated with real engine data
    @State private var whiteRatio: Double = 0.5
    @State private var evalLabel: String = ""
    @State private var hasReceivedData = false

    var body: some View {
        GeometryReader { geometry in
            let size = isVertical ? geometry.size.height : geometry.size.width

            ZStack(alignment: isVertical ? .bottom : .leading) {
                Rectangle().fill(AppColors.evalBlack)

                Rectangle()
                    .fill(AppColors.evalWhite)
                    .frame(
                        width: isVertical ? nil : size * whiteRatio,
                        height: isVertical ? size * whiteRatio : nil
                    )
                    .animation(hasReceivedData ? .easeInOut(duration: 0.35) : nil, value: whiteRatio)

                if !isPending {
                    VStack {
                        if whiteRatio < 0.5 {
                            Text(evalLabel)
                                .font(AppFonts.evalBarText)
                                .foregroundStyle(AppColors.evalWhite)
                                .lineLimit(1).minimumScaleFactor(0.6)
                                .padding(.horizontal, 2).padding(.top, 2)
                            Spacer()
                        } else {
                            Spacer()
                            Text(evalLabel)
                                .font(AppFonts.evalBarText)
                                .foregroundStyle(AppColors.evalBlack)
                                .lineLimit(1).minimumScaleFactor(0.6)
                                .padding(.horizontal, 2).padding(.bottom, 2)
                        }
                    }
                }
            }
        }
        .frame(width: isVertical ? AppSpacing.evalBarWidth : nil,
               height: isVertical ? nil : AppSpacing.evalBarWidth)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
        .opacity(isPending ? 0.35 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPending)
        .onChange(of: eval) { _, _ in updateIfValid() }
        .onChange(of: sideToMoveIsWhite) { _, _ in updateIfValid() }
        .onAppear { updateIfValid() }
    }

    private func updateIfValid() {
        guard eval.depth > 0 else { return }

        // Convert to white's perspective ONCE
        let whiteCP = MoveClassifier.toWhiteCP(eval, sideToMoveIsWhite: sideToMoveIsWhite)

        // Bar ratio: 0.0 = black winning, 1.0 = white winning
        if let mate = eval.mate {
            let whiteMate = sideToMoveIsWhite ? mate : -mate
            whiteRatio = whiteMate > 0 ? 0.99 : 0.01
        } else {
            let clamped = max(-1000, min(1000, whiteCP))
            whiteRatio = 0.5 + (Double(clamped) / 2000.0)
        }

        // Label: always show from white's perspective
        if let mate = eval.mate {
            let whiteMate = sideToMoveIsWhite ? mate : -mate
            let prefix = whiteMate > 0 ? "+" : "-"
            evalLabel = "\(prefix)M\(abs(whiteMate))"
        } else {
            let value = Double(whiteCP) / 100.0
            evalLabel = value >= 0
                ? "+\(String(format: "%.1f", value))"
                : String(format: "%.1f", value)
        }

        if !hasReceivedData {
            hasReceivedData = true
        }
    }
}
