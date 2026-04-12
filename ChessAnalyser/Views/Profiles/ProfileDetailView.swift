import SwiftUI

struct ProfileDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let profile: ChessComProfile
    @State private var viewModel = GameListViewModel()
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            profileHeader

            if viewModel.isLoading && viewModel.games.isEmpty {
                Spacer()
                ProgressView("Loading games...")
                    .tint(AppColors.accent)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
            } else if let error = viewModel.error, viewModel.games.isEmpty {
                Spacer()
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.mistake)

                    Text("Failed to load games")
                        .font(AppFonts.subtitle)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(error)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.xxl)

                    Button {
                        Task { await viewModel.loadGames(for: profile.username) }
                    } label: {
                        Label("Reload", systemImage: "arrow.clockwise")
                            .font(AppFonts.bodyBold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppSpacing.xl)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.accent)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
            } else {
                List {
                    ForEach(viewModel.games) { game in
                        NavigationLink {
                            AnalysisView(game: game, profileUsername: profile.username)
                        } label: {
                            GameListItemView(game: game, username: profile.username)
                        }
                        .listRowBackground(AppColors.surface)
                        .onAppear {
                            // Infinite scroll: load more when last item appears
                            if game.id == viewModel.games.last?.id {
                                Task { await viewModel.loadMore(for: profile.username) }
                            }
                        }
                    }

                    // Loading more indicator at the bottom
                    if viewModel.isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .tint(AppColors.accent)
                            Text("Loading older games...")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textMuted)
                            Spacer()
                        }
                        .listRowBackground(AppColors.background)
                        .padding(.vertical, AppSpacing.sm)
                    }

                    // No more games indicator
                    if !viewModel.hasMorePages && !viewModel.games.isEmpty {
                        HStack {
                            Spacer()
                            Text("No more games")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textMuted)
                            Spacer()
                        }
                        .listRowBackground(AppColors.background)
                        .padding(.vertical, AppSpacing.sm)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.refresh(for: profile.username)
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle(profile.username)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(AppColors.blunder)
                }
            }
        }
        .alert("Delete Profile", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                appState.profileStore.removeProfile(profile)
                dismiss()
            }
        } message: {
            Text("Remove \(profile.username) from saved profiles?")
        }
        .task {
            await viewModel.loadGames(for: profile.username)
        }
    }

    private var profileHeader: some View {
        HStack(spacing: AppSpacing.lg) {
            if let ratings = profile.ratings {
                if let rapid = ratings.rapid {
                    ratingColumn(title: "Rapid", rating: rapid.rating, icon: "timer")
                }
                if let blitz = ratings.blitz {
                    ratingColumn(title: "Blitz", rating: blitz.rating, icon: "bolt.fill")
                }
                if let bullet = ratings.bullet {
                    ratingColumn(title: "Bullet", rating: bullet.rating, icon: "circle.fill")
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(AppColors.surface)
    }

    private func ratingColumn(title: String, rating: Int, icon: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textMuted)
            Text("\(rating)")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(AppColors.textPrimary)
            Text(title)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
