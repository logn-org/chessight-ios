import Foundation

actor ChessComAPI {
    static let shared = ChessComAPI()

    private let baseURL = "https://api.chess.com/pub"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.httpAdditionalHeaders = [
            "Accept": "application/json",
            "User-Agent": "Chessight-iOS/1.0"
        ]
        session = URLSession(configuration: config)
    }

    // MARK: - Player Profile

    func getPlayerProfile(username: String) async throws -> ChessComProfile {
        let url = try makeURL("\(baseURL)/player/\(username.lowercased())")
        let data = try await fetch(url)

        struct APIProfile: Decodable {
            let username: String
            let name: String?
            let avatar: String?
            let country: String?
            let joined: Int?
            let last_online: Int?
        }

        let apiProfile = try JSONDecoder().decode(APIProfile.self, from: data)

        return ChessComProfile(
            username: apiProfile.username,
            name: apiProfile.name,
            avatar: apiProfile.avatar,
            country: apiProfile.country,
            joined: apiProfile.joined.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            lastOnline: apiProfile.last_online.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            addedAt: Date(),
            ratings: nil
        )
    }

    // MARK: - Player Stats

    func getPlayerStats(username: String) async throws -> ProfileRatings {
        let url = try makeURL("\(baseURL)/player/\(username.lowercased())/stats")
        let data = try await fetch(url)

        struct APIStats: Decodable {
            let chess_rapid: APIRatingCategory?
            let chess_blitz: APIRatingCategory?
            let chess_bullet: APIRatingCategory?
        }

        struct APIRatingCategory: Decodable {
            let last: APIRatingLast?
            let best: APIRatingBest?
            let record: APIRecord?
        }

        struct APIRatingLast: Decodable {
            let rating: Int
        }

        struct APIRatingBest: Decodable {
            let rating: Int
        }

        struct APIRecord: Decodable {
            let win: Int
            let loss: Int
            let draw: Int
        }

        let stats = try JSONDecoder().decode(APIStats.self, from: data)

        func toRatingInfo(_ cat: APIRatingCategory?) -> RatingInfo? {
            guard let cat = cat, let last = cat.last else { return nil }
            return RatingInfo(
                rating: last.rating,
                best: cat.best?.rating,
                record: cat.record.map { GameRecord(win: $0.win, loss: $0.loss, draw: $0.draw) }
            )
        }

        return ProfileRatings(
            rapid: toRatingInfo(stats.chess_rapid),
            blitz: toRatingInfo(stats.chess_blitz),
            bullet: toRatingInfo(stats.chess_bullet)
        )
    }

    // MARK: - Game Archives

    func getGameArchives(username: String) async throws -> [String] {
        let url = try makeURL("\(baseURL)/player/\(username.lowercased())/games/archives")
        let data = try await fetch(url)

        struct APIArchives: Decodable {
            let archives: [String]
        }

        let archives = try JSONDecoder().decode(APIArchives.self, from: data)
        return archives.archives
    }

    // MARK: - Games from Archive

    func getGamesFromArchive(archiveURL: String) async throws -> [ChessComGame] {
        let url = try makeURL(archiveURL)
        let data = try await fetch(url)

        struct APIGames: Decodable {
            let games: [APIGame]
        }

        struct APIGame: Decodable {
            let url: String
            let pgn: String?
            let white: APIPlayer
            let black: APIPlayer
            let time_control: String?
            let time_class: String?
            let end_time: Int
            let rated: Bool?
        }

        struct APIPlayer: Decodable {
            let username: String
            let rating: Int
            let result: String
        }

        let apiGames = try JSONDecoder().decode(APIGames.self, from: data)

        return apiGames.games.compactMap { game in
            guard let pgn = game.pgn else { return nil }

            return ChessComGame(
                url: game.url,
                pgn: pgn,
                white: PlayerInfo(
                    username: game.white.username,
                    rating: game.white.rating,
                    result: game.white.result
                ),
                black: PlayerInfo(
                    username: game.black.username,
                    rating: game.black.rating,
                    result: game.black.result
                ),
                timeControl: game.time_control ?? "unknown",
                timeClass: TimeClass(rawValue: game.time_class ?? "rapid") ?? .rapid,
                endTime: Date(timeIntervalSince1970: TimeInterval(game.end_time)),
                rated: game.rated ?? true
            )
        }
    }

    // MARK: - Recent Games (convenience)

    func getRecentGames(username: String, limit: Int = 50) async throws -> [ChessComGame] {
        let archives = try await getGameArchives(username: username)

        // Get the last 2 months of archives
        let recentArchives = archives.suffix(2).reversed()

        var allGames: [ChessComGame] = []
        for archive in recentArchives {
            let games = try await getGamesFromArchive(archiveURL: archive)
            allGames.append(contentsOf: games)
            if allGames.count >= limit { break }
        }

        // Sort by date, newest first
        return allGames
            .sorted { $0.endTime > $1.endTime }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Validate Username

    func validateUsername(_ username: String) async -> Bool {
        do {
            _ = try await getPlayerProfile(username: username)
            return true
        } catch {
            return false
        }
    }

    private func makeURL(_ string: String) throws -> URL {
        guard let url = URL(string: string) else {
            throw ChessComError.invalidResponse
        }
        return url
    }

    // MARK: - Network

    private func fetch(_ url: URL, retries: Int = 3) async throws -> Data {
        var lastError: Error = ChessComError.invalidResponse
        CrashLogger.logNetwork("Fetching: \(url.absoluteString)")

        for attempt in 0..<retries {
            do {
                let (data, response) = try await session.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ChessComError.invalidResponse
                }

                switch httpResponse.statusCode {
                case 200:
                    return data
                case 404:
                    throw ChessComError.notFound // Don't retry 404s
                case 429:
                    // Rate limited — wait and retry
                    let delay = Double(attempt + 1) * 2.0
                    try? await Task.sleep(for: .seconds(delay))
                    lastError = ChessComError.rateLimited
                    continue
                case 301, 302, 307, 308:
                    // Follow redirect manually if needed
                    if let location = httpResponse.value(forHTTPHeaderField: "Location"),
                       let redirectURL = URL(string: location) {
                        return try await fetch(redirectURL, retries: retries - attempt)
                    }
                    throw ChessComError.httpError(httpResponse.statusCode)
                case 500...599:
                    // Server error — retry after delay
                    let delay = Double(attempt + 1) * 1.0
                    try? await Task.sleep(for: .seconds(delay))
                    lastError = ChessComError.httpError(httpResponse.statusCode)
                    continue
                default:
                    throw ChessComError.httpError(httpResponse.statusCode)
                }
            } catch let error as ChessComError {
                if case .notFound = error { throw error } // Don't retry 404
                lastError = error
                if attempt < retries - 1 {
                    try? await Task.sleep(for: .seconds(1.0))
                }
            } catch {
                lastError = error
                if attempt < retries - 1 {
                    try? await Task.sleep(for: .seconds(1.0))
                }
            }
        }

        throw lastError
    }
}

enum ChessComError: Error, LocalizedError {
    case invalidResponse
    case notFound
    case rateLimited
    case httpError(Int)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from chess.com"
        case .notFound: return "Player not found"
        case .rateLimited: return "Too many requests. Please wait a moment."
        case .httpError(let code): return "HTTP error: \(code)"
        case .decodingError(let msg): return "Failed to parse response: \(msg)"
        }
    }
}
