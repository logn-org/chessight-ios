import SwiftUI

enum MoveClassification: String, Codable, CaseIterable, Equatable {
    case brilliant
    case great
    case best
    case excellent
    case good
    case ok
    case book
    case miss
    case inaccuracy
    case mistake
    case blunder
    case forced
    case none

    var label: String {
        switch self {
        case .brilliant: return "Brilliant"
        case .great: return "Great Move"
        case .best: return "Best Move"
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .ok: return "Ok"
        case .book: return "Book"
        case .miss: return "Missed Win"
        case .inaccuracy: return "Inaccuracy"
        case .mistake: return "Mistake"
        case .blunder: return "Blunder"
        case .forced: return "Forced"
        case .none: return ""
        }
    }

    var symbol: String {
        switch self {
        case .brilliant: return "!!"
        case .great: return "!"
        case .miss: return "?"
        case .inaccuracy: return "?!"
        case .mistake: return "?"
        case .blunder: return "??"
        default: return ""
        }
    }

    var color: Color {
        switch self {
        case .brilliant: return AppColors.brilliant
        case .great: return AppColors.great
        case .best: return AppColors.best
        case .excellent: return AppColors.excellent
        case .good: return AppColors.good
        case .ok: return AppColors.ok
        case .book: return AppColors.book
        case .miss: return AppColors.miss
        case .inaccuracy: return AppColors.inaccuracy
        case .mistake: return AppColors.mistake
        case .blunder: return AppColors.blunder
        case .forced: return AppColors.forced
        case .none: return .clear
        }
    }

    var iconName: String {
        switch self {
        case .brilliant: return "star.circle.fill"
        case .great: return "exclamationmark.circle.fill"
        case .best: return "checkmark.circle.fill"
        case .excellent: return "checkmark.seal.fill"
        case .good: return "hand.thumbsup.circle.fill"
        case .ok: return "minus.circle.fill"
        case .book: return "book.circle.fill"
        case .miss: return "eye.slash.circle.fill"
        case .inaccuracy: return "questionmark.circle.fill"
        case .mistake: return "xmark.circle.fill"
        case .blunder: return "exclamationmark.triangle.fill"
        case .forced: return "lock.circle.fill"
        case .none: return "circle"
        }
    }

    var isPositive: Bool {
        switch self {
        case .brilliant, .great, .best, .excellent, .good, .ok, .book, .forced:
            return true
        case .miss, .inaccuracy, .mistake, .blunder, .none:
            return false
        }
    }

    var priority: Int {
        switch self {
        case .brilliant: return 10
        case .blunder: return 9
        case .mistake: return 8
        case .miss: return 7
        case .great: return 7
        case .inaccuracy: return 6
        case .best: return 5
        case .excellent: return 4
        case .good: return 3
        case .ok: return 2
        case .book: return 2
        case .forced: return 1
        case .none: return 0
        }
    }
}

// MARK: - Classification Thresholds

enum ClassificationThreshold {
    static let best: Int = 10
    static let excellent: Int = 30
    static let good: Int = 50
    static let ok: Int = 80
    static let inaccuracy: Int = 150
    static let mistake: Int = 300
}
