import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.selectedTab) {
            HomeTab()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppState.AppTab.home)

            LearnTab()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .tag(AppState.AppTab.learn)

            ProfilesTab()
                .tabItem {
                    Label("Profiles", systemImage: "person.2.fill")
                }
                .tag(AppState.AppTab.profiles)

            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppState.AppTab.settings)
        }
        .onChange(of: appState.selectedTab) { oldTab, newTab in
            Analytics.tabSwitched(from: oldTab.title, to: newTab.title)
        }
        .tint(AppColors.accent)
        .fullScreenCover(isPresented: $appState.showSharedGame) {
            if let content = appState.sharedContent {
                NavigationStack {
                    SharedGameView(sharedText: content)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Close") {
                                    appState.showSharedGame = false
                                    appState.sharedContent = nil
                                }
                                .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                }
            }
        }
    }
}
