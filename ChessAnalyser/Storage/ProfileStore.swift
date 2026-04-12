import Foundation

@Observable
final class ProfileStore {
    private(set) var profiles: [ChessComProfile] = []
    private let storageKey = "saved_profiles"

    init() {
        load()
    }

    // MARK: - CRUD

    func addProfile(_ profile: ChessComProfile) {
        guard !profiles.contains(where: { $0.id == profile.id }) else { return }
        profiles.append(profile)
        save()
    }

    func removeProfile(_ profile: ChessComProfile) {
        profiles.removeAll { $0.id == profile.id }
        save()
    }

    func removeProfile(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        save()
    }

    func updateProfile(_ profile: ChessComProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            save()
        }
    }

    func hasProfile(_ username: String) -> Bool {
        profiles.contains { $0.username.lowercased() == username.lowercased() }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([ChessComProfile].self, from: data) else {
            return
        }
        profiles = stored
    }
}
