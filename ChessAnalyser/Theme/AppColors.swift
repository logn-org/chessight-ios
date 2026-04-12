import SwiftUI

enum AppColors {
    // MARK: - Background
    static let background = Color(hex: 0x312E2B)
    static let surface = Color(hex: 0x272421)
    static let surfaceLight = Color(hex: 0x3C3936)
    static let surfaceElevated = Color(hex: 0x454240)

    // MARK: - Board
    static let boardLight = Color(hex: 0xEEEED2)
    static let boardDark = Color(hex: 0x769656)
    static let boardHighlightLight = Color(hex: 0xF6F669)
    static let boardHighlightDark = Color(hex: 0xBBCA2B)
    static let boardCheckRed = Color(hex: 0xFF0000).opacity(0.6)

    // MARK: - Text
    static let textPrimary = Color(hex: 0xFFFFFF)
    static let textSecondary = Color(hex: 0xA0A0A0)
    static let textMuted = Color(hex: 0x6B6B6B)

    // MARK: - Accent
    static let accent = Color(hex: 0x81B64C)
    static let accentDark = Color(hex: 0x629924)

    // MARK: - Move Classifications (chess.com colors)
    static let brilliant = Color(hex: 0x26C2A3)    // Teal/cyan
    static let great = Color(hex: 0x5C8BB0)         // Blue
    static let best = Color(hex: 0x96BC4B)           // Green
    static let excellent = Color(hex: 0x96BC4B)      // Green (same as best)
    static let good = Color(hex: 0x95AF8A)           // Muted green
    static let ok = Color(hex: 0xB0AA9E)             // Warm gray
    static let miss = Color(hex: 0xDB8C34)             // Amber/orange
    static let book = Color(hex: 0xA88764)           // Brown
    static let inaccuracy = Color(hex: 0xF7C631)     // Yellow
    static let mistake = Color(hex: 0xE58F2A)        // Orange
    static let blunder = Color(hex: 0xCA3431)         // Red
    static let forced = Color(hex: 0x808080)          // Gray

    // MARK: - Eval Bar
    static let evalWhite = Color(hex: 0xFFFFFF)
    static let evalBlack = Color(hex: 0x403D39)

    // MARK: - Board Arrows
    static let bestMoveArrow = Color(hex: 0x3B7DD8).opacity(0.75)    // Blue
    static let defenseArrow = Color(hex: 0x5D9948).opacity(0.65)     // Green
    static let attackArrow = Color(hex: 0xCA3431).opacity(0.65)      // Red

    // MARK: - Win/Loss/Draw
    static let win = Color(hex: 0x81B64C)
    static let loss = Color(hex: 0xCA3431)
    static let draw = Color(hex: 0xA0A0A0)
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
