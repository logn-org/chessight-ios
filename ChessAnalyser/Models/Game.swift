import Foundation

struct GameMove: Codable, Identifiable, Equatable {
    var id: Int { moveIndex }
    let moveIndex: Int
    let san: String
    let from: String
    let to: String
    let fen: String
    let fenBefore: String
    let isWhite: Bool
    let moveNumber: Int
    let piece: PieceType
    let captured: PieceType?
    let promotion: PieceType?
    let isCheck: Bool
    let isCheckmate: Bool
    let isCastling: Bool
}

struct ParsedGame: Codable, Identifiable, Equatable {
    let id: String
    let headers: [String: String]
    let moves: [GameMove]
    let pgn: String

    var white: String { headers["White"] ?? "White" }
    var black: String { headers["Black"] ?? "Black" }
    var whiteElo: String? { headers["WhiteElo"] }
    var blackElo: String? { headers["BlackElo"] }
    var result: String { headers["Result"] ?? "*" }
    var date: String? { headers["Date"] }
    var event: String? { headers["Event"] }
    var timeControl: String? { headers["TimeControl"] }
    var opening: String? { headers["ECO"] ?? headers["Opening"] }
}

enum PieceType: String, Codable, Equatable {
    case king = "k"
    case queen = "q"
    case rook = "r"
    case bishop = "b"
    case knight = "n"
    case pawn = "p"

    var materialValue: Int {
        switch self {
        case .king: return 0
        case .queen: return 9
        case .rook: return 5
        case .bishop: return 3
        case .knight: return 3
        case .pawn: return 1
        }
    }

    var symbol: String {
        switch self {
        case .king: return "K"
        case .queen: return "Q"
        case .rook: return "R"
        case .bishop: return "B"
        case .knight: return "N"
        case .pawn: return ""
        }
    }
}

enum PieceColor: String, Codable, Equatable {
    case white = "w"
    case black = "b"

    var opposite: PieceColor {
        self == .white ? .black : .white
    }
}

struct ChessPiece: Codable, Equatable {
    let type: PieceType
    let color: PieceColor

    var assetName: String {
        let colorPrefix = color == .white ? "w" : "b"
        return "\(colorPrefix)\(type.symbol.isEmpty ? "P" : type.symbol)"
    }
}

struct Square: Hashable, Codable, Equatable {
    let file: Int // 0-7 (a-h)
    let rank: Int // 0-7 (1-8)

    var algebraic: String {
        let fileChar = Character(UnicodeScalar(97 + file)!)
        return "\(fileChar)\(rank + 1)"
    }

    init(file: Int, rank: Int) {
        self.file = file
        self.rank = rank
    }

    init?(algebraic: String) {
        guard algebraic.count == 2,
              let fileChar = algebraic.first,
              let rankChar = algebraic.last,
              let file = fileChar.asciiValue.map({ Int($0) - 97 }),
              let rank = rankChar.wholeNumberValue.map({ $0 - 1 }),
              (0...7).contains(file),
              (0...7).contains(rank) else {
            return nil
        }
        self.file = file
        self.rank = rank
    }

    var isLight: Bool {
        (file + rank) % 2 != 0
    }
}
