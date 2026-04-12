import Foundation

@Observable
final class GameListViewModel {
    private let api = ChessComAPI()

    var games: [ChessComGame] = []
    var isLoading = false
    var isLoadingMore = false
    var error: String?
    var hasMorePages = true

    /// All archive URLs (newest last), reversed for pagination (newest first)
    private var allArchives: [String] = []
    /// How many archives we've loaded so far
    private var archivesLoaded = 0

    /// Initial load — fetches archive list + first batch of games
    func loadGames(for username: String) async {
        isLoading = true
        error = nil
        games = []
        archivesLoaded = 0
        hasMorePages = true

        do {
            let archives = try await api.getGameArchives(username: username)
            // Reverse so newest months come first
            allArchives = archives.reversed()

            // Load first 2 months
            await loadNextBatch(for: username, count: 2)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// Load more games (older months) — triggered when scrolling to bottom
    func loadMore(for username: String) async {
        guard !isLoadingMore && hasMorePages else { return }
        isLoadingMore = true
        await loadNextBatch(for: username, count: 1)
        isLoadingMore = false
    }

    /// Pull-to-refresh — reloads from scratch (newest games)
    func refresh(for username: String) async {
        await loadGames(for: username)
    }

    private func loadNextBatch(for username: String, count: Int) async {
        var newGames: [ChessComGame] = []
        var loaded = 0

        while loaded < count && archivesLoaded < allArchives.count {
            let archiveURL = allArchives[archivesLoaded]
            archivesLoaded += 1
            loaded += 1

            do {
                let monthGames = try await api.getGamesFromArchive(archiveURL: archiveURL)
                newGames.append(contentsOf: monthGames)
            } catch {
                // Skip failed archives
                continue
            }
        }

        // Sort new games newest first and append
        let sorted = newGames.sorted { $0.endTime > $1.endTime }
        games.append(contentsOf: sorted)

        // No more pages if we've loaded all archives
        if archivesLoaded >= allArchives.count {
            hasMorePages = false
        }
    }
}
