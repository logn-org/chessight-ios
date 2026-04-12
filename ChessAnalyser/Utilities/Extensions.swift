import SwiftUI

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        self
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    func elevatedCardStyle() -> some View {
        self
            .background(AppColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }
}

// MARK: - String Extensions

extension String {
    /// Convert UCI move notation (e.g., "e2e4") to a display-friendly format
    var uciFromSquare: String {
        guard count >= 4 else { return self }
        return String(prefix(2))
    }

    var uciToSquare: String {
        guard count >= 4 else { return self }
        return String(dropFirst(2).prefix(2))
    }
}

// MARK: - Date Extensions

extension Date {
    var timeAgoDisplay: String {
        let interval = -self.timeIntervalSinceNow
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 604800 { return "\(Int(interval / 86400))d ago" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Array Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
