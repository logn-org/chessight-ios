import SwiftUI

enum AppFonts {
    static let title = Font.system(size: 20, weight: .bold, design: .default)
    static let subtitle = Font.system(size: 16, weight: .semibold, design: .default)
    static let body = Font.system(size: 14, weight: .regular, design: .default)
    static let bodyBold = Font.system(size: 14, weight: .semibold, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionBold = Font.system(size: 12, weight: .semibold, design: .default)
    static let small = Font.system(size: 10, weight: .regular, design: .default)

    // Move list and analysis
    static let moveText = Font.system(size: 14, weight: .medium, design: .monospaced)
    static let evalText = Font.system(size: 13, weight: .bold, design: .monospaced)
    static let evalBarText = Font.system(size: 10, weight: .bold, design: .monospaced)

    // Board coordinates
    static let coordinate = Font.system(size: 9, weight: .semibold, design: .default)
}
