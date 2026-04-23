import SwiftUI
import FirebaseCore
import FirebaseCrashlytics
import GoogleMobileAds
import AppTrackingTransparency

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
                .task {
                    await requestTrackingPermission()
                    MobileAds.shared.start(completionHandler: nil)
                    appState.ads.preload()
                    await appState.premium.start()
                }
                .onAppear {
                    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                    Analytics.appLaunched(isIPad: isIPad, appVersion: version)
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }

    private func requestTrackingPermission() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        // Small delay so the prompt doesn't compete with launch animations.
        try? await Task.sleep(nanoseconds: 500_000_000)
        _ = await ATTrackingManager.requestTrackingAuthorization()
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
