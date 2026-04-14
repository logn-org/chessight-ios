import SwiftUI

struct LearnTab: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Sample Games
                    learnSection(
                        title: "Famous Games",
                        subtitle: "Study legendary chess games move by move",
                        icon: "theatermasks.fill",
                        color: AppColors.accent
                    ) {
                        ForEach(SampleGames.all, id: \.name) { sample in
                            NavigationLink {
                                AnalysisView(pgn: sample.pgn)
                            } label: {
                                learnRow(title: sample.name, icon: "theatermasks.fill", color: AppColors.accent)
                            }
                        }
                    }

                    // Openings
                    learnSection(
                        title: "Openings",
                        subtitle: "Learn the most popular opening systems",
                        icon: "flag.fill",
                        color: AppColors.best
                    ) {
                        openingRow("Italian Game", moves: "1. e4 e5 2. Nf3 Nc6 3. Bc4")
                        openingRow("Sicilian Defense", moves: "1. e4 c5")
                        openingRow("French Defense", moves: "1. e4 e6 2. d4 d5")
                        openingRow("Ruy Lopez", moves: "1. e4 e5 2. Nf3 Nc6 3. Bb5")
                        openingRow("Queen's Gambit", moves: "1. d4 d5 2. c4")
                        openingRow("King's Indian Defense", moves: "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7")
                        openingRow("Caro-Kann Defense", moves: "1. e4 c6")
                        openingRow("English Opening", moves: "1. c4")
                        openingRow("Pirc Defense", moves: "1. e4 d6 2. d4 Nf6 3. Nc3 g6")
                        openingRow("Scandinavian Defense", moves: "1. e4 d5")
                    }

                    // Tactics
                    learnSection(
                        title: "Tactics",
                        subtitle: "Master essential tactical patterns",
                        icon: "bolt.fill",
                        color: AppColors.brilliant
                    ) {
                        tacticRow("Pin", fen: "r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4",
                                  description: "A piece is attacked and cannot move because it would expose a more valuable piece behind it")
                        tacticRow("Fork", fen: "r1bqkbnr/pppppppp/2n5/8/4N3/8/PPPPPPPP/R1BQKBNR w KQkq - 2 3",
                                  description: "One piece attacks two or more enemy pieces simultaneously")
                        tacticRow("Skewer", fen: "4k3/8/8/8/8/8/4R3/4K3 w - - 0 1",
                                  description: "A valuable piece is attacked and forced to move, exposing a piece behind it")
                        tacticRow("Discovered Attack", fen: "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4",
                                  description: "Moving one piece reveals an attack from another piece behind it")
                        tacticRow("Double Check", fen: "4k3/8/8/8/1B6/8/3N4/4K3 w - - 0 1",
                                  description: "Two pieces give check simultaneously — the king must move")
                    }

                    // Checkmate Patterns
                    learnSection(
                        title: "Checkmate Patterns",
                        subtitle: "Recognize common mating positions",
                        icon: "crown.fill",
                        color: AppColors.blunder
                    ) {
                        mateRow("Back Rank Mate", fen: "6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1",
                                description: "Rook or queen delivers checkmate on the back rank when pawns block the king's escape")
                        mateRow("Scholar's Mate", fen: "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5Q2/PPPP1PPP/RNB1K1NR w KQkq - 4 4",
                                description: "Qxf7# — earliest possible checkmate targeting f7")
                        mateRow("Smothered Mate", fen: "6rk/5Npp/8/8/8/8/8/4K3 w - - 0 1",
                                description: "A knight delivers checkmate while the king is trapped by its own pieces")
                        mateRow("Anastasia's Mate", fen: "5rk1/4Nppp/8/7R/8/8/8/4K3 w - - 0 1",
                                description: "Knight and rook combine to mate along the h-file with a pawn shield")
                        mateRow("Arabian Mate", fen: "7k/5N2/6R1/8/8/8/8/4K3 w - - 0 1",
                                description: "A knight and rook combine to deliver checkmate in the corner")
                    }

                    // Endgames
                    learnSection(
                        title: "Endgames",
                        subtitle: "Essential endgame positions and techniques",
                        icon: "flag.checkered",
                        color: AppColors.great
                    ) {
                        endgameRow("King + Queen vs King", fen: "4k3/8/8/8/8/8/8/4KQ2 w - - 0 1",
                                   description: "The most basic checkmate — force the king to the edge")
                        endgameRow("King + Rook vs King", fen: "4k3/8/8/8/8/8/8/4KR2 w - - 0 1",
                                   description: "Use the rook to cut off ranks and push the king to the edge")
                        endgameRow("King + Pawn vs King", fen: "4k3/8/8/8/4P3/8/8/4K3 w - - 0 1",
                                   description: "The key endgame — learn opposition and the square rule")
                        endgameRow("King + 2 Bishops vs King", fen: "4k3/8/8/8/8/8/8/2B1KB2 w - - 0 1",
                                   description: "Two bishops force the king into a corner for checkmate")
                        endgameRow("Lucena Position", fen: "3K4/3P1k2/8/8/8/8/1R6/8 w - - 0 1",
                                   description: "The most important rook endgame position — building the bridge")
                        endgameRow("Philidor Position", fen: "4k3/8/8/4P3/8/8/4r3/4K2R w - - 0 1",
                                   description: "Defensive technique in rook endgames — keep the rook on the third rank")
                    }
                }
                .padding(.top, AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("Learn")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                Analytics.screenViewed("learn")
            }
        }
    }

    // MARK: - Section Builder

    private func learnSection<Content: View>(
        title: String, subtitle: String, icon: String, color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFonts.subtitle)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .padding(.horizontal, AppSpacing.md)

            content()
        }
    }

    // MARK: - Row Types

    private func learnRow(title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
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
        .padding(.horizontal, AppSpacing.md)
    }

    private func openingRow(_ name: String, moves: String) -> some View {
        let pgn = "[Event \"Opening Study\"]\n[White \"White\"]\n[Black \"Black\"]\n[Result \"*\"]\n\n\(moves) *"
        return NavigationLink {
            AnalysisView(pgn: pgn)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(moves)
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.textMuted)
                        .lineLimit(1)
                }
                Spacer()
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

    private func tacticRow(_ name: String, fen: String, description: String) -> some View {
        NavigationLink {
            AnalysisView(fen: fen)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(description)
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.textMuted)
                        .lineLimit(2)
                }
                Spacer()
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

    private func mateRow(_ name: String, fen: String, description: String) -> some View {
        tacticRow(name, fen: fen, description: description)
    }

    private func endgameRow(_ name: String, fen: String, description: String) -> some View {
        tacticRow(name, fen: fen, description: description)
    }
}
