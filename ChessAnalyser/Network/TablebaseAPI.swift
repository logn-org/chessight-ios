import Foundation

/// Lichess Syzygy tablebase API for perfect endgame analysis.
/// Supports positions with up to 7 pieces.
/// Free, no auth required, rate-limited (be polite).
actor TablebaseAPI {
    private let baseURL = "https://tablebase.lichess.ovh/standard"
    private let session: URLSession
    private var cache: [String: TablebaseResult] = [:]

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        session = URLSession(configuration: config)
    }

    /// Query the tablebase for a position. Returns nil if not a tablebase position.
    func lookup(fen: String) async -> TablebaseResult? {
        // Only query positions with 7 or fewer pieces
        let pieceCount = countPieces(fen: fen)
        guard pieceCount <= 7 else { return nil }

        // Check cache
        let key = normalizeFEN(fen)
        if let cached = cache[key] { return cached }

        // Query API
        guard let encoded = fen.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?fen=\(encoded)") else {
            return nil
        }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }

            let apiResult = try JSONDecoder().decode(APITablebaseResult.self, from: data)
            let result = TablebaseResult(from: apiResult)
            cache[key] = result
            return result
        } catch {
            return nil
        }
    }

    /// Check if a position is a tablebase position (7 or fewer pieces)
    func isTablebasePosition(fen: String) -> Bool {
        countPieces(fen: fen) <= 7
    }

    private func countPieces(fen: String) -> Int {
        guard let board = fen.split(separator: " ").first else { return 99 }
        return board.filter { $0.isLetter }.count
    }

    private func normalizeFEN(_ fen: String) -> String {
        let parts = fen.split(separator: " ")
        guard parts.count >= 4 else { return fen }
        return "\(parts[0]) \(parts[1]) \(parts[2]) \(parts[3])"
    }
}

struct TablebaseResult: Equatable {
    let category: TablebaseCategory
    let bestMove: String?       // UCI notation
    let dtz: Int?               // Distance to zeroing (50-move rule)
    let dtm: Int?               // Distance to mate
    let moves: [TablebaseMove]

    init(from api: APITablebaseResult) {
        switch api.category {
        case "win": category = .win
        case "loss": category = .loss
        case "draw", "blessed-loss", "cursed-win": category = .draw
        default: category = .unknown
        }
        bestMove = api.moves.first?.uci
        dtz = api.dtz
        dtm = api.dtm
        moves = api.moves.map { TablebaseMove(uci: $0.uci, san: $0.san, category: $0.category) }
    }
}

struct TablebaseMove: Equatable {
    let uci: String
    let san: String?
    let category: String?
}

enum TablebaseCategory: String, Equatable {
    case win, loss, draw, unknown
}

// API response model
struct APITablebaseResult: Decodable {
    let category: String
    let dtz: Int?
    let dtm: Int?
    let moves: [APITablebaseMove]
}

struct APITablebaseMove: Decodable {
    let uci: String
    let san: String?
    let category: String?
}
