import SwiftUI

struct HomeTab: View {
    @Environment(AppState.self) private var appState
    @State private var showImportPGN = false
    @State private var recentAnalyses: [GameAnalysis] = []

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isIPad = AppSpacing.isIPad(geometry.size.width)

                ScrollView {
                    if isIPad {
                        iPadHome
                    } else {
                        iPhoneHome
                    }
                }
                .background(AppColors.background)
            }
            .navigationTitle("Hey, Strategist")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showImportPGN) {
                ImportPGNView()
            }
            .onAppear {
                Analytics.screenViewed("home")
                recentAnalyses = appState.analysisCache.recentAnalyses(limit: 1)
            }
        }
    }

    // MARK: - iPad Layout

    private var iPadHome: some View {
        VStack(spacing: AppSpacing.xl) {
            // Hero: Daily Puzzle (full width)
            NavigationLink {
                PuzzleView()
            } label: {
                HStack(spacing: AppSpacing.lg) {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AppColors.inaccuracy)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Puzzle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                        Text("Chess.com puzzle of the day")
                            .font(.system(size: 15))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(AppColors.textMuted)
                }
                .padding(AppSpacing.xl)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            // Quick Actions — 2x3 grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppSpacing.md),
                GridItem(.flexible(), spacing: AppSpacing.md),
                GridItem(.flexible(), spacing: AppSpacing.md),
            ], spacing: AppSpacing.md) {
                NavigationLink {
                    BotGameView()
                } label: {
                    iPadActionCard(icon: "cpu", title: "Play vs Bot", color: AppColors.accent)
                }

                NavigationLink {
                    PlayView()
                } label: {
                    iPadActionCard(icon: "play.circle.fill", title: "Free Play", color: AppColors.great)
                }

                NavigationLink {
                    BoardEditorView()
                } label: {
                    iPadActionCard(icon: "square.grid.3x3.fill", title: "Board Editor", color: AppColors.brilliant)
                }

                Button { showImportPGN = true } label: {
                    iPadActionCard(icon: "doc.text.fill", title: "Import Game", color: AppColors.textSecondary)
                }

                Button { appState.selectedTab = .profiles } label: {
                    iPadActionCard(icon: "person.circle.fill", title: "Chess.com", color: AppColors.textSecondary)
                }
            }

            // Recent Analysis (just the most recent; full list under "Show more")
            if !recentAnalyses.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("Recent Analysis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        showMoreLink
                    }

                    ForEach(recentAnalyses) { analysis in
                        NavigationLink {
                            AnalysisView(pgn: analysis.pgn)
                        } label: {
                            recentAnalysisRow(analysis)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.top, AppSpacing.lg)
    }

    private func iPadActionCard(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - iPhone Layout

    private var iPhoneHome: some View {
        VStack(spacing: AppSpacing.lg) {
            // Daily Puzzle
            NavigationLink {
                PuzzleView()
            } label: {
                HStack {
                    Image(systemName: "puzzlepiece.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.inaccuracy)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Puzzle")
                            .font(AppFonts.subtitle)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("Chess.com puzzle of the day")
                            .font(AppFonts.small)
                            .foregroundStyle(AppColors.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppColors.textMuted)
                }
                .padding(AppSpacing.lg)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            }
            .padding(.horizontal, AppSpacing.md)

            // Quick Actions
            VStack(spacing: AppSpacing.md) {
                NavigationLink {
                    BotGameView()
                } label: {
                    homeActionRow(icon: "cpu", title: "Play vs Bot", color: AppColors.accent)
                }

                NavigationLink {
                    PlayView()
                } label: {
                    homeActionRow(icon: "play.circle.fill", title: "Free Play", color: AppColors.great)
                }

                NavigationLink {
                    BoardEditorView()
                } label: {
                    homeActionRow(icon: "square.grid.3x3.fill", title: "Board Editor", color: AppColors.brilliant)
                }

                Button { showImportPGN = true } label: {
                    homeActionRow(icon: "doc.text.fill", title: "Import Game", color: AppColors.textPrimary)
                }

                Button {
                    appState.selectedTab = .profiles
                } label: {
                    homeActionRow(icon: "person.circle.fill", title: "Chess.com Games", color: AppColors.textPrimary)
                }
            }
            .padding(.horizontal, AppSpacing.md)

            // Recent Analysis (just the most recent; full list under "Show more")
            if !recentAnalyses.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack {
                        Text("Recent Analysis")
                            .font(AppFonts.subtitle)
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        showMoreLink
                    }
                    .padding(.horizontal, AppSpacing.md)

                    ForEach(recentAnalyses) { analysis in
                        NavigationLink {
                            AnalysisView(pgn: analysis.pgn)
                        } label: {
                            recentAnalysisRow(analysis)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
        }
        .padding(.top, AppSpacing.md)
    }

    @ViewBuilder
    private var showMoreLink: some View {
        if appState.analysisCache.cachedGameIds.count > 1 {
            NavigationLink {
                AllRecentAnalysesView()
            } label: {
                HStack(spacing: 4) {
                    Text("Show all (\(appState.analysisCache.cachedGameIds.count))")
                        .font(AppFonts.captionBold)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(AppColors.accent)
            }
        }
    }

    // MARK: - Shared Components

    private func homeActionRow(icon: String, title: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(AppFonts.subtitle)
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    private func recentAnalysisRow(_ analysis: GameAnalysis) -> some View {
        RecentAnalysisRow(analysis: analysis)
    }
}

// MARK: - Shared row

struct RecentAnalysisRow: View {
    let analysis: GameAnalysis
    /// Set to false when the row is embedded in a List (SwiftUI adds its own disclosure chevron).
    var showChevron: Bool = true

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("\(analysis.white) vs \(analysis.black)")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.sm) {
                    Text(analysis.result)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    Text(analysis.analyzedAt.timeAgoDisplay)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text(String(format: "%.0f%%", analysis.whiteAccuracy))
                    .font(AppFonts.captionBold)
                    .foregroundStyle(AppColors.textPrimary)

                Text(String(format: "%.0f%%", analysis.blackAccuracy))
                    .font(AppFonts.captionBold)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }
}

// MARK: - All Recent Analyses

struct AllRecentAnalysesView: View {
    @Environment(AppState.self) private var appState
    @State private var analyses: [GameAnalysis] = []
    @State private var showClearAllAlert = false

    var body: some View {
        Group {
            if analyses.isEmpty {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundStyle(AppColors.textMuted)
                    Text("No analyses yet")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(analyses) { analysis in
                        NavigationLink {
                            AnalysisView(pgn: analysis.pgn)
                        } label: {
                            RecentAnalysisRow(analysis: analysis, showChevron: false)
                        }
                        .listRowBackground(AppColors.background)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: AppSpacing.md, bottom: 4, trailing: AppSpacing.md))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(analysis)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppColors.background)
        .navigationTitle("Recent Analyses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if !analyses.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showClearAllAlert = true } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(AppColors.blunder)
                    }
                }
            }
        }
        .alert("Clear all analyses?", isPresented: $showClearAllAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear All", role: .destructive) {
                appState.analysisCache.clearAll()
                analyses = []
            }
        } message: {
            Text("This removes all \(analyses.count) cached analyses. Opening a game again will consume your free daily quota or require premium / a rewarded ad.")
        }
        .onAppear {
            analyses = appState.analysisCache.recentAnalyses(limit: AnalysisCache.maxCachedGames)
            Analytics.screenViewed("recent_analyses")
        }
    }

    private func delete(_ analysis: GameAnalysis) {
        appState.analysisCache.delete(id: analysis.id)
        analyses.removeAll { $0.id == analysis.id }
    }
}
