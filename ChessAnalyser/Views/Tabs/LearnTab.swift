import SwiftUI

struct LearnTab: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Study Cards (top)
                    studyCards

                    // Practice Section (bot modes)
                    practiceSection
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

    // MARK: - Study Cards

    private var studyCards: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                NavigationLink {
                    FamousGamesList()
                } label: {
                    studyCard(
                        title: "Famous Games",
                        subtitle: "Study legendary games",
                        icon: "theatermasks.fill",
                        color: AppColors.accent
                    )
                }

                NavigationLink {
                    OpeningsList()
                } label: {
                    studyCard(
                        title: "Openings",
                        subtitle: "Learn opening theory",
                        icon: "flag.fill",
                        color: AppColors.best
                    )
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private func studyCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
            Text(title)
                .font(AppFonts.subtitle)
                .foregroundStyle(AppColors.textPrimary)
            Text(subtitle)
                .font(AppFonts.small)
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Practice Section

    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Practice")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)

            Text("Play against Stockfish from specific positions")
                .font(AppFonts.small)
                .foregroundStyle(AppColors.textMuted)
                .padding(.horizontal, AppSpacing.md)

            // Tactics (white has the tactical advantage)
            practiceGroup(title: "Tactics", icon: "bolt.fill", color: AppColors.brilliant, items: [
                PracticeItem(name: "Pin", fens: [
                    "r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 0 1",
                    "r2qkbnr/ppp2ppp/2np4/4p1B1/4P1b1/5N2/PPPP1PPP/RN1QKB1R w KQkq - 0 1",
                    "rnbqk2r/pppp1ppp/4pn2/8/1bPP4/2N5/PP2PPPP/R1BQKBNR w KQkq - 0 1",
                ], userColor: .white),
                PracticeItem(name: "Fork", fens: [
                    "r1bqkbnr/pppppppp/2n5/8/4N3/8/PPPPPPPP/R1BQKBNR w KQkq - 0 1",
                    "r1bqkb1r/pppppppp/2n2n2/8/3NP3/8/PPPP1PPP/RNBQKB1R w KQkq - 0 1",
                    "r2qkbnr/ppp1pppp/2n5/3p4/3PP1b1/5N2/PPP2PPP/RNBQKB1R w KQkq - 0 1",
                ], userColor: .white),
                PracticeItem(name: "Skewer", fens: [
                    "4k3/8/8/8/8/4R3/8/4K3 w - - 0 1",
                    "6k1/8/8/8/8/8/B7/4K3 w - - 0 1",
                ], userColor: .white),
                PracticeItem(name: "Discovered Attack", fens: [
                    "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1",
                    "rnbqkb1r/ppp1pppp/5n2/3p4/3PP3/8/PPP2PPP/RNBQKBNR w KQkq - 0 1",
                ], userColor: .white),
            ])

            // Checkmate Patterns (white delivers the mate)
            practiceGroup(title: "Checkmate Patterns", icon: "crown.fill", color: AppColors.blunder, items: [
                PracticeItem(name: "Back Rank Mate", fens: [
                    "6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1",
                    "r5k1/5ppp/8/8/8/8/5PPP/4R1K1 w - - 0 1",
                    "5rk1/5ppp/8/8/8/8/8/3RK3 w - - 0 1",
                ], userColor: .white),
                PracticeItem(name: "Smothered Mate", fens: [
                    "6rk/5Npp/8/8/8/8/8/4K3 w - - 0 1",
                    "r4rk1/5Npp/8/8/8/8/6PP/6K1 w - - 0 1",
                ], userColor: .white),
                PracticeItem(name: "Arabian Mate", fens: [
                    "7k/5N2/6R1/8/8/8/8/4K3 w - - 0 1",
                    "k7/2N5/1R6/8/8/8/8/4K3 w - - 0 1",
                ], userColor: .white),
                PracticeItem(name: "Queen + Knight Mate", fens: [
                    "6k1/8/5N2/8/8/8/8/4K2Q w - - 0 1",
                    "7k/8/8/8/3N4/8/8/4K2Q w - - 0 1",
                ], userColor: .white),
            ])

            // Endgames (white has the winning material)
            practiceGroup(title: "Endgames", icon: "flag.checkered", color: AppColors.great, items: [
                PracticeItem(name: "King + Queen vs King", fens: [
                    "4k3/8/8/8/8/8/8/4KQ2 w - - 0 1",
                    "8/8/3k4/8/8/8/1Q6/4K3 w - - 0 1",
                    "k7/8/8/8/8/8/6Q1/4K3 w - - 0 1",
                    "7k/8/8/8/8/8/Q7/4K3 w - - 0 1",
                ], userColor: .white, goal: "Checkmate the lone king"),
                PracticeItem(name: "King + Rook vs King", fens: [
                    "4k3/8/8/8/8/8/8/R3K3 w - - 0 1",
                    "8/8/4k3/8/8/8/R7/4K3 w - - 0 1",
                    "k7/8/8/8/8/8/7R/4K3 w - - 0 1",
                    "3k4/8/8/8/8/8/R7/3K4 w - - 0 1",
                ], userColor: .white, goal: "Checkmate the lone king"),
                PracticeItem(name: "Defend: King vs King + Pawn", fens: [
                    "8/8/8/4k3/8/8/4P3/4K3 b - - 0 1",
                    "8/8/8/8/3k4/8/3P4/3K4 b - - 0 1",
                    "8/8/8/2k5/8/8/2P5/2K5 b - - 0 1",
                    "8/8/8/5k2/8/8/5P2/5K2 b - - 0 1",
                ], userColor: .black, goal: "Force a draw — block the pawn"),
                PracticeItem(name: "King + 2 Bishops vs King", fens: [
                    "4k3/8/8/8/8/8/8/2B1KB2 w - - 0 1",
                    "k7/8/8/8/8/8/8/2B1KB2 w - - 0 1",
                    "7k/8/8/8/8/8/8/2B1KB2 w - - 0 1",
                ], userColor: .white, goal: "Checkmate with two bishops"),
                PracticeItem(name: "Rook + Pawn Endgame", fens: [
                    "8/5k2/8/4P3/8/8/8/4K2R w - - 0 1",
                    "8/3k4/8/3P4/8/8/8/3K3R w - - 0 1",
                    "8/1k6/8/1P6/8/8/8/1K5R w - - 0 1",
                ], userColor: .white, goal: "Promote the pawn and checkmate"),
            ])
        }
    }

    // MARK: - Practice Group

    private func practiceGroup(title: String, icon: String, color: Color, items: [PracticeItem]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.horizontal, AppSpacing.md)

            ForEach(items, id: \.name) { item in
                NavigationLink {
                    BotGameView(
                        customFEN: item.fens.randomElement()!,
                        studyTitle: item.name,
                        autoStart: true,
                        practiceUserColor: item.userColor,
                        practiceFENs: item.fens
                    )
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textPrimary)
                            Text(item.goal)
                                .font(AppFonts.small)
                                .foregroundStyle(AppColors.textMuted)
                        }
                        Spacer()
                        Image(systemName: "play.circle.fill")
                            .foregroundStyle(color.opacity(0.7))
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
        }
    }
}

// MARK: - Data

struct PracticeItem {
    let name: String
    let fens: [String]
    /// The color the user plays
    let userColor: PieceColor
    /// Goal description shown in the UI
    let goal: String

    init(name: String, fens: [String], userColor: PieceColor, goal: String = "Find the winning move") {
        self.name = name; self.fens = fens; self.userColor = userColor; self.goal = goal
    }
}

// MARK: - Famous Games List

struct FamousGamesList: View {
    var body: some View {
        List {
            ForEach(SampleGames.all, id: \.name) { sample in
                NavigationLink {
                    AnalysisView(pgn: sample.pgn)
                } label: {
                    HStack {
                        Image(systemName: "theatermasks.fill")
                            .foregroundStyle(AppColors.accent)
                            .frame(width: 24)
                        Text(sample.name)
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                .listRowBackground(AppColors.surface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle("Famous Games")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Openings List

struct OpeningsList: View {
    private let openings: [(name: String, moves: String)] = [
        ("Italian Game", "1. e4 e5 2. Nf3 Nc6 3. Bc4"),
        ("Sicilian Defense", "1. e4 c5"),
        ("French Defense", "1. e4 e6 2. d4 d5"),
        ("Ruy Lopez", "1. e4 e5 2. Nf3 Nc6 3. Bb5"),
        ("Queen's Gambit", "1. d4 d5 2. c4"),
        ("King's Indian Defense", "1. d4 Nf6 2. c4 g6 3. Nc3 Bg7"),
        ("Caro-Kann Defense", "1. e4 c6"),
        ("English Opening", "1. c4"),
        ("Pirc Defense", "1. e4 d6 2. d4 Nf6 3. Nc3 g6"),
        ("Scandinavian Defense", "1. e4 d5"),
    ]

    var body: some View {
        List {
            ForEach(openings, id: \.name) { opening in
                let pgn = "[Event \"\(opening.name)\"]\n[White \"White\"]\n[Black \"Black\"]\n[Result \"*\"]\n\n\(opening.moves) *"
                NavigationLink {
                    AnalysisView(pgn: pgn, studyMode: true, studyTitle: opening.name)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(opening.name)
                            .font(AppFonts.body)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(opening.moves)
                            .font(AppFonts.small)
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
                .listRowBackground(AppColors.surface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle("Openings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
