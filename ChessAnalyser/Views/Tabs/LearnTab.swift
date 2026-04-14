import SwiftUI

struct LearnTab: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Cards
                    studyCards
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
            // Row 1: Study
            HStack(spacing: AppSpacing.md) {
                NavigationLink {
                    FamousGamesList()
                } label: {
                    studyCard(title: "Famous Games", subtitle: "Study legendary games", icon: "theatermasks.fill", color: AppColors.accent)
                }

                NavigationLink {
                    OpeningsList()
                } label: {
                    studyCard(title: "Openings", subtitle: "Learn opening theory", icon: "flag.fill", color: AppColors.best)
                }
            }

            // Row 2: Practice
            HStack(spacing: AppSpacing.md) {
                NavigationLink {
                    PracticeCategoryList(title: "Tactics", items: tacticItems)
                } label: {
                    studyCard(title: "Tactics", subtitle: "Pins, forks, skewers", icon: "bolt.fill", color: AppColors.brilliant)
                }

                NavigationLink {
                    PracticeCategoryList(title: "Checkmates", items: checkmateItems)
                } label: {
                    studyCard(title: "Checkmates", subtitle: "Mating patterns", icon: "crown.fill", color: AppColors.blunder)
                }
            }

            // Row 3: Endgames
            HStack(spacing: AppSpacing.md) {
                NavigationLink {
                    PracticeCategoryList(title: "Endgames", items: endgameItems)
                } label: {
                    studyCard(title: "Endgames", subtitle: "Win & defend endgames", icon: "flag.checkered", color: AppColors.great)
                }

                // Placeholder for future content
                Color.clear.frame(maxWidth: .infinity, maxHeight: 120)
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

    // MARK: - Practice Data

    private var tacticItems: [PracticeItem] {[
        PracticeItem(name: "Pin", fens: PracticeFENs.pins, userColor: .white),
        PracticeItem(name: "Fork", fens: PracticeFENs.forks, userColor: .white),
        PracticeItem(name: "Skewer", fens: PracticeFENs.skewers, userColor: .white),
        PracticeItem(name: "Discovered Attack", fens: PracticeFENs.discoveredAttacks, userColor: .white),
        PracticeItem(name: "Double Check", fens: PracticeFENs.doubleChecks, userColor: .white),
    ]}

    private var checkmateItems: [PracticeItem] {[
        PracticeItem(name: "Back Rank Mate", fens: PracticeFENs.backRankMates, userColor: .white, goal: "Deliver back rank checkmate"),
        PracticeItem(name: "Smothered Mate", fens: PracticeFENs.smotheredMates, userColor: .white, goal: "Deliver smothered checkmate"),
        PracticeItem(name: "Arabian Mate", fens: PracticeFENs.arabianMates, userColor: .white, goal: "Checkmate with knight + rook"),
        PracticeItem(name: "Queen + Knight Mate", fens: PracticeFENs.queenKnightMates, userColor: .white, goal: "Checkmate with queen + knight"),
    ]}

    private var endgameItems: [PracticeItem] {[
        PracticeItem(name: "King + Queen vs King", fens: [
            "4k3/8/8/8/8/8/8/4KQ2 w - - 0 1", "8/8/3k4/8/8/8/1Q6/4K3 w - - 0 1",
            "k7/8/8/8/8/8/6Q1/4K3 w - - 0 1", "7k/8/8/8/8/8/Q7/4K3 w - - 0 1",
        ], userColor: .white, goal: "Checkmate the lone king"),
        PracticeItem(name: "King + Rook vs King", fens: [
            "4k3/8/8/8/8/8/8/R3K3 w - - 0 1", "8/8/4k3/8/8/8/R7/4K3 w - - 0 1",
            "k7/8/8/8/8/8/7R/4K3 w - - 0 1", "3k4/8/8/8/8/8/R7/3K4 w - - 0 1",
        ], userColor: .white, goal: "Checkmate the lone king"),
        PracticeItem(name: "Defend: King vs King + Pawn", fens: [
            "8/8/8/4k3/8/8/4P3/4K3 b - - 0 1", "8/8/8/8/3k4/8/3P4/3K4 b - - 0 1",
            "8/8/8/2k5/8/8/2P5/2K5 b - - 0 1", "8/8/8/5k2/8/8/5P2/5K2 b - - 0 1",
        ], userColor: .black, goal: "Force a draw — block the pawn"),
        PracticeItem(name: "King + 2 Bishops vs King", fens: [
            "4k3/8/8/8/8/8/8/2B1KB2 w - - 0 1", "k7/8/8/8/8/8/8/2B1KB2 w - - 0 1",
            "7k/8/8/8/8/8/8/2B1KB2 w - - 0 1",
        ], userColor: .white, goal: "Checkmate with two bishops"),
        PracticeItem(name: "Rook + Pawn Endgame", fens: [
            "8/5k2/8/4P3/8/8/8/4K2R w - - 0 1", "8/3k4/8/3P4/8/8/8/3K3R w - - 0 1",
            "8/1k6/8/1P6/8/8/8/1K5R w - - 0 1",
        ], userColor: .white, goal: "Promote the pawn and checkmate"),
    ]}
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

// MARK: - Practice Category List

struct PracticeCategoryList: View {
    let title: String
    let items: [PracticeItem]

    var body: some View {
        List {
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(AppFonts.bodyBold)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(item.goal)
                            .font(AppFonts.small)
                            .foregroundStyle(AppColors.textMuted)
                        Text("\(item.fens.count) positions")
                            .font(AppFonts.small)
                            .foregroundStyle(AppColors.accent)
                    }
                }
                .listRowBackground(AppColors.surface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle(title)
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
