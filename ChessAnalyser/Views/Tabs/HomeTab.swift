import SwiftUI

struct HomeTab: View {
    @Environment(AppState.self) private var appState
    @State private var showImportPGN = false
    @State private var recentAnalyses: [GameAnalysis] = []

    var body: some View {
        NavigationStack {
            ScrollView {
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

                    // Sample Games (for testing)
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Sample Games")
                            .font(AppFonts.subtitle)
                            .foregroundStyle(AppColors.textPrimary)
                            .padding(.horizontal, AppSpacing.md)

                        ForEach(SampleGames.all, id: \.name) { sample in
                            NavigationLink {
                                AnalysisView(pgn: sample.pgn)
                            } label: {
                                HStack {
                                    Image(systemName: "theatermasks.fill")
                                        .foregroundStyle(AppColors.accent)
                                    Text(sample.name)
                                        .font(AppFonts.body)
                                        .foregroundStyle(AppColors.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(AppFonts.caption)
                                        .foregroundStyle(AppColors.textMuted)
                                }
                                .padding(AppSpacing.md)
                                .background(AppColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                            }
                            .padding(.horizontal, AppSpacing.md)
                        }
                    }

                    // Recent Analyses
                    if !recentAnalyses.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Recent Analyses")
                                .font(AppFonts.subtitle)
                                .foregroundStyle(AppColors.textPrimary)
                                .padding(.horizontal, AppSpacing.md)

                            ForEach(recentAnalyses) { analysis in
                                NavigationLink {
                                    AnalysisView(pgn: analysis.pgn)
                                } label: {
                                    recentAnalysisRow(analysis)
                                }
                            }
                        }
                    }
                }
                .padding(.top, AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("Chessight")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showImportPGN) {
                ImportPGNView()
            }
            .onAppear {
                recentAnalyses = appState.analysisCache.recentAnalyses(limit: 10)
            }
        }
    }

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

            Image(systemName: "chevron.right")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textMuted)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        .padding(.horizontal, AppSpacing.md)
    }
}
