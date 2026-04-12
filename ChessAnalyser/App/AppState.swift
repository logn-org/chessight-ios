import SwiftUI

@Observable
final class AppState {
    var profileStore = ProfileStore()
    var engineConfig = EngineConfiguration()
    var analysisCache = AnalysisCache()

    // Navigation state
    var selectedTab: AppTab = .home

    // Shared content (from share sheet or URL)
    var sharedContent: String?
    var showSharedGame = false

    enum AppTab: Int, CaseIterable {
        case home = 0
        case profiles = 1
        case settings = 2

        var title: String {
            switch self {
            case .home: return "Home"
            case .profiles: return "Profiles"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .profiles: return "person.2.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
}
