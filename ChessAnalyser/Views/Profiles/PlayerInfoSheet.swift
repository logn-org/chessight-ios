import SwiftUI

/// Sheet shown when tapping a player name in the analysis view.
struct PlayerInfoSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let username: String
    let rating: Int?

    @State private var profile: ChessComProfile?
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var isSaved = false

    private let api = ChessComAPI()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Avatar
                    Circle()
                        .fill(AppColors.surfaceLight)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(username.prefix(1)).uppercased())
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)
                        )

                    // Username
                    Text(username)
                        .font(.title2.bold())
                        .foregroundStyle(AppColors.textPrimary)

                    // Rating from game data (always available)
                    if let rating = rating {
                        Text("Rating: \(rating)")
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    // Loading state
                    if isLoading {
                        ProgressView("Loading profile...")
                            .tint(AppColors.accent)
                    }

                    // Profile info from API
                    if let profile = profile {
                        if let ratings = profile.ratings {
                            HStack(spacing: AppSpacing.xl) {
                                if let r = ratings.rapid { ratingBadge("Rapid", r.rating) }
                                if let b = ratings.blitz { ratingBadge("Blitz", b.rating) }
                                if let u = ratings.bullet { ratingBadge("Bullet", u.rating) }
                            }
                        }

                        if let name = profile.name, !name.isEmpty {
                            Text(name)
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        if let lastOnline = profile.lastOnline {
                            Text("Last online: \(lastOnline.timeAgoDisplay)")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }

                    // Failed to load — show reload button
                    if loadFailed && profile == nil {
                        VStack(spacing: AppSpacing.sm) {
                            Text("Could not load full profile from chess.com")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textMuted)
                                .multilineTextAlignment(.center)

                            Button {
                                Task { await loadProfile() }
                            } label: {
                                Label("Retry", systemImage: "arrow.clockwise")
                                    .font(AppFonts.captionBold)
                                    .foregroundStyle(AppColors.accent)
                            }
                        }
                    }

                    Spacer(minLength: AppSpacing.lg)

                    // Action buttons
                    VStack(spacing: AppSpacing.md) {
                        if isSaved {
                            NavigationLink {
                                ProfileDetailView(profile: profile ?? makeBasicProfile())
                            } label: {
                                Label("View Games", systemImage: "list.bullet")
                                    .font(AppFonts.bodyBold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.md)
                                    .background(AppColors.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                            }
                        } else {
                            Button { saveProfile() } label: {
                                Label("Save Profile", systemImage: "person.badge.plus")
                                    .font(AppFonts.bodyBold)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.md)
                                    .background(AppColors.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Player Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .presentationDetents([.medium])
        .task { await loadProfile() }
        .onAppear { isSaved = appState.profileStore.hasProfile(username) }
    }

    private func ratingBadge(_ title: String, _ rating: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(rating)")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(AppColors.textPrimary)
            Text(title)
                .font(AppFonts.small)
                .foregroundStyle(AppColors.textMuted)
        }
    }

    private func loadProfile() async {
        isLoading = true
        loadFailed = false
        do {
            var p = try await api.getPlayerProfile(username: username)
            let stats = try? await api.getPlayerStats(username: username)
            p.ratings = stats
            profile = p
        } catch {
            loadFailed = true
        }
        isLoading = false
    }

    private func saveProfile() {
        let p = profile ?? makeBasicProfile()
        appState.profileStore.addProfile(p)
        isSaved = true
    }

    private func makeBasicProfile() -> ChessComProfile {
        ChessComProfile(
            username: username,
            name: nil,
            avatar: nil,
            country: nil,
            joined: nil,
            lastOnline: nil,
            addedAt: Date(),
            ratings: nil
        )
    }
}
