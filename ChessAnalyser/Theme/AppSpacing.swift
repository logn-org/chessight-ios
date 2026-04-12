import Foundation

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    static let cornerRadius: CGFloat = 8
    static let cornerRadiusLg: CGFloat = 12
    static let cornerRadiusSm: CGFloat = 4

    static let boardPadding: CGFloat = 2
    static let evalBarWidth: CGFloat = 28

    // MARK: - iPad Helpers

    static func isIPad(_ width: CGFloat) -> Bool { width > 700 }

    /// Board size that fits the available space.
    /// On iPad: uses most of the screen height, leaving room for nav bar and padding.
    /// On iPhone: fills the width minus padding.
    static func boardSize(for screenWidth: CGFloat, screenHeight: CGFloat, showEvalBar: Bool = false) -> CGFloat {
        if isIPad(screenWidth) {
            // Use 85% of height, capped to 65% of width (leave room for side panel)
            let heightBased = screenHeight - 100
            let widthBased = screenWidth * 0.6
            return max(1, min(heightBased, widthBased))
        }
        return max(1, showEvalBar
            ? screenWidth - evalBarWidth - sm * 2 - xs
            : screenWidth - sm * 2)
    }

    /// Max board size constant for iPad (used by AnalysisView which has its own calc)
    static let maxBoardSize: CGFloat = 800
}
