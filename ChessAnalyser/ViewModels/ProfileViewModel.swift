import Foundation

@Observable
final class ProfileViewModel {
    private let api = ChessComAPI()

    var isLoading = false
    var error: String?
    var searchUsername = ""
    var validationResult: ValidationResult?

    enum ValidationResult {
        case valid(ChessComProfile)
        case invalid(String)
        case checking
    }

    // MARK: - Add Profile

    func addProfile(to store: ProfileStore) async {
        let username = searchUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else {
            error = "Please enter a username"
            return
        }

        guard !store.hasProfile(username) else {
            error = "Profile already saved"
            return
        }

        isLoading = true
        validationResult = .checking
        error = nil

        do {
            var profile = try await api.getPlayerProfile(username: username)
            let stats = try await api.getPlayerStats(username: username)
            profile.ratings = stats

            store.addProfile(profile)
            validationResult = .valid(profile)
            searchUsername = ""
            Analytics.profileAdded()
        } catch {
            validationResult = .invalid(error.localizedDescription)
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Refresh Profile

    func refreshProfile(_ profile: ChessComProfile, in store: ProfileStore) async {
        do {
            var updated = try await api.getPlayerProfile(username: profile.username)
            let stats = try await api.getPlayerStats(username: profile.username)
            updated.ratings = stats
            store.updateProfile(updated)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
