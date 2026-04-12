import Foundation

actor PuzzleAPI {
    private let session: URLSession
    private var todayCache: DailyPuzzle?

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.httpAdditionalHeaders = ["User-Agent": "Chessight-iOS/1.0"]
        session = URLSession(configuration: config)
    }

    /// Fetch today's puzzle (cached)
    func getTodaysPuzzle() async throws -> DailyPuzzle {
        if let cached = todayCache { return cached }
        guard let url = URL(string: "https://api.chess.com/pub/puzzle") else { throw PuzzleError.invalidResponse }
        let puzzle = try await fetchPuzzle(url: url)
        todayCache = puzzle
        return puzzle
    }

    /// Fetch a random puzzle (never cached)
    func getRandomPuzzle() async throws -> DailyPuzzle {
        guard let url = URL(string: "https://api.chess.com/pub/puzzle/random") else { throw PuzzleError.invalidResponse }
        return try await fetchPuzzle(url: url)
    }

    private func fetchPuzzle(url: URL) async throws -> DailyPuzzle {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            if (response as? HTTPURLResponse)?.statusCode == 404 { throw PuzzleError.noPuzzleForDate }
            throw PuzzleError.invalidResponse
        }
        let apiPuzzle = try JSONDecoder().decode(APIPuzzle.self, from: data)
        return DailyPuzzle(
            title: apiPuzzle.title,
            url: apiPuzzle.url,
            publishTime: Date(timeIntervalSince1970: TimeInterval(apiPuzzle.publish_time)),
            fen: apiPuzzle.fen,
            pgn: apiPuzzle.pgn,
            image: apiPuzzle.image
        )
    }
}

struct DailyPuzzle: Equatable {
    let title: String
    let url: String
    let publishTime: Date
    let fen: String
    let pgn: String
    let image: String?
}

private struct APIPuzzle: Decodable {
    let title: String
    let url: String
    let publish_time: Int
    let fen: String
    let pgn: String
    let image: String?
}

enum PuzzleError: Error, LocalizedError {
    case invalidResponse
    case noPuzzleForDate
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response"
        case .noPuzzleForDate: return "No puzzle available"
        case .httpError(let code): return "HTTP error: \(code)"
        }
    }
}
