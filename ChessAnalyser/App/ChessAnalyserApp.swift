import SwiftUI
import FirebaseCore
import FirebaseCrashlytics

@main
struct ChessightApp: App {
    @State private var appState = AppState()

    init() {
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        _ = SoundManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        if url.scheme == "chessight" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let content = components.queryItems?.first(where: { $0.name == "content" })?.value {
                appState.sharedContent = content
                appState.showSharedGame = true
                return
            }
            if let host = url.host {
                appState.sharedContent = host.removingPercentEncoding ?? host
                appState.showSharedGame = true
            }
        } else if url.host?.contains("chess.com") == true {
            appState.sharedContent = url.absoluteString
            appState.showSharedGame = true
        }
    }
}
