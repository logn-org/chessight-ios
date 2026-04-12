import Foundation

struct ChessComProfile: Codable, Identifiable, Equatable {
    var id: String { username.lowercased() }
    let username: String
    let name: String?
    let avatar: String?
    let country: String?
    let joined: Date?
    let lastOnline: Date?
    let addedAt: Date
    var ratings: ProfileRatings?

    static func == (lhs: ChessComProfile, rhs: ChessComProfile) -> Bool {
        lhs.username.lowercased() == rhs.username.lowercased()
    }
}

struct ProfileRatings: Codable, Equatable {
    let rapid: RatingInfo?
    let blitz: RatingInfo?
    let bullet: RatingInfo?

    var bestRating: (category: String, rating: Int)? {
        let options: [(String, RatingInfo?)] = [
            ("Rapid", rapid), ("Blitz", blitz), ("Bullet", bullet)
        ]
        return options
            .compactMap { name, info in info.map { (name, $0.rating) } }
            .max { $0.1 < $1.1 }
    }
}

struct RatingInfo: Codable, Equatable {
    let rating: Int
    let best: Int?
    let record: GameRecord?
}

struct GameRecord: Codable, Equatable {
    let win: Int
    let loss: Int
    let draw: Int

    var total: Int { win + loss + draw }
}

struct ChessComGame: Codable, Identifiable, Equatable {
    var id: String { url }
    let url: String
    let pgn: String
    let white: PlayerInfo
    let black: PlayerInfo
    let timeControl: String
    let timeClass: TimeClass
    let endTime: Date
    let rated: Bool

    var result: String {
        if white.result == "win" { return "1-0" }
        if black.result == "win" { return "0-1" }
        return "1/2-1/2"
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: endTime)
    }

    func opponent(for username: String) -> PlayerInfo {
        white.username.lowercased() == username.lowercased() ? black : white
    }

    func userSide(for username: String) -> PieceColor {
        white.username.lowercased() == username.lowercased() ? .white : .black
    }

    func userResult(for username: String) -> GameResult {
        let side = userSide(for: username)
        let info = side == .white ? white : black
        switch info.result {
        case "win": return .win
        case "checkmated", "timeout", "resigned", "abandoned": return .loss
        default: return .draw
        }
    }
}

struct PlayerInfo: Codable, Equatable {
    let username: String
    let rating: Int
    let result: String
}

enum TimeClass: String, Codable, Equatable {
    case rapid
    case blitz
    case bullet
    case daily

    var icon: String {
        switch self {
        case .rapid: return "timer"
        case .blitz: return "bolt.fill"
        case .bullet: return "circle.fill"
        case .daily: return "calendar"
        }
    }

    var label: String { rawValue.capitalized }
}

enum GameResult: String, Codable {
    case win
    case loss
    case draw

    var symbol: String {
        switch self {
        case .win: return "W"
        case .loss: return "L"
        case .draw: return "D"
        }
    }
}
