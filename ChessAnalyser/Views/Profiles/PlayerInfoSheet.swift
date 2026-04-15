import SwiftUI

struct PlayerInfoItem: Identifiable {
    let id = UUID()
    let username: String
    let rating: Int?
}

/// Sheet shown when tapping a player name in the analysis view.
struct PlayerInfoSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let username: String
    let rating: Int?

    @State private var profile: ChessComProfile?
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var errorMessage: String?
    @State private var isSaved = false

    private let api = ChessComAPI.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isLoading {
                    loadingContent
                } else if loadFailed && profile == nil {
                    errorContent
                } else {
                    profileContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

    // MARK: - Loading State

    private var loadingContent: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppColors.accent)
            Text("Loading profile...")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textMuted)
            Spacer()
        }
    }

    // MARK: - Error State

    private var errorContent: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "person.slash.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.textMuted)

            VStack(spacing: AppSpacing.sm) {
                Text("Profile not found")
                    .font(AppFonts.subtitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Could not load \"\(username)\" from chess.com")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await loadProfile() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            }

            Spacer()
        }
        .padding(.horizontal, AppSpacing.lg)
    }

    // MARK: - Profile Content

    private var profileContent: some View {
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
                    } else if profile != nil {
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
        errorMessage = nil
        Analytics.profileInfoViewed(username: username)
        do {
            var p = try await api.getPlayerProfile(username: username)
            let stats = try? await api.getPlayerStats(username: username)
            p.ratings = stats
            profile = p
        } catch {
            loadFailed = true
            errorMessage = error.localizedDescription
            Analytics.profileInfoFailed(username: username)
        }
        isLoading = false
    }

    private func saveProfile() {
        guard let p = profile else { return }
        appState.profileStore.addProfile(p)
        isSaved = true
        Analytics.profileInfoSaved(username: username)
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
