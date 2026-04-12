import SwiftUI

struct PuzzleView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = PuzzleViewModel()
    @State private var mode: PuzzleMode = .today
    @State private var hasLoadedOnce = false
    @State private var showHint = false
    @State private var hintMoveUCI: String?

    enum PuzzleMode { case today, random }

    var body: some View {
        ZStack {
            if !hasLoadedOnce && viewModel.isLoading {
                // First load — show centered loading
                initialLoadingView
            } else if let error = viewModel.error, !hasLoadedOnce {
                errorView(error)
            } else {
                // Puzzle content (stays visible during subsequent loads)
                if viewModel.puzzle != nil {
                    puzzleContent
                }

                // Overlay spinner for subsequent loads
                if viewModel.isLoading && hasLoadedOnce {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    VStack(spacing: AppSpacing.md) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        Text("Loading puzzle...")
                            .font(AppFonts.bodyBold)
                            .foregroundStyle(.white)
                    }
                    .padding(AppSpacing.xl)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusLg))
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle(mode == .today ? "Daily Puzzle" : "Puzzle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { mode = .today; loadPuzzle() } label: {
                        Label("Today's Puzzle", systemImage: "calendar")
                    }
                    Button { mode = .random; loadPuzzle() } label: {
                        Label("Random Puzzle", systemImage: "shuffle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
        .task { loadPuzzle() }
        .onChange(of: viewModel.currentSolutionIndex) { _, _ in
            // Reset hint after each move
            showHint = false
            hintMoveUCI = nil
        }
    }

    // MARK: - Initial Loading

    private var initialLoadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "puzzlepiece.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.inaccuracy)
                .symbolEffect(.pulse)

            Text("Loading puzzle...")
                .font(AppFonts.subtitle)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "puzzlepiece")
                .font(.system(size: 40)).foregroundStyle(AppColors.mistake)
            Text(error).font(AppFonts.body).foregroundStyle(AppColors.textSecondary)
            Button {
                loadPuzzle()
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.accent)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Puzzle Content

    private var puzzleContent: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let boardSize = screenWidth - AppSpacing.sm * 2

            VStack(spacing: 0) {
                // Title
                if let puzzle = viewModel.puzzle {
                    Text(puzzle.title)
                        .font(AppFonts.subtitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.md)
                        .frame(height: 28)
                }

                // Status bar
                statusBar

                // Board
                InteractiveBoardView(
                    board: viewModel.board,
                    selectedSquare: viewModel.selectedSquare,
                    legalMoveTargets: viewModel.legalMoveTargets,
                    lastMove: lastMove,
                    arrows: hintArrows,
                    showCoordinates: appState.engineConfig.showBoardCoordinates,
                    flipped: viewModel.isFlipped,
                    onTapSquare: { viewModel.tapSquare($0) }
                )
                .frame(width: boardSize, height: boardSize)
                .padding(.horizontal, AppSpacing.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm)
                        .stroke(viewModel.wrongMove ? AppColors.blunder : Color.clear, lineWidth: 3)
                        .padding(.horizontal, AppSpacing.sm)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.wrongMove)
                )

                // Move history
                if !viewModel.userMoves.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
                            ForEach(viewModel.userMoves) { move in
                                if move.isWhite {
                                    Text("\(move.moveNumber).")
                                        .font(AppFonts.caption)
                                        .foregroundStyle(AppColors.textMuted)
                                }
                                Text(move.san)
                                    .font(AppFonts.moveText)
                                    .foregroundStyle(AppColors.textPrimary)
                                    .padding(.horizontal, 3)
                            }
                        }
                        .padding(.horizontal, AppSpacing.sm)
                    }
                    .frame(height: 30)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.top, AppSpacing.xs)
                }

                // Controls
                HStack(spacing: AppSpacing.lg) {
                    Button { viewModel.isFlipped.toggle() } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }

                    Button { viewModel.resetPuzzle(); showHint = false; hintMoveUCI = nil } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }

                    // Hint / show engine move
                    Button { toggleHint() } label: {
                        Image(systemName: showHint ? "lightbulb.fill" : "lightbulb")
                            .foregroundStyle(showHint ? AppColors.accent : AppColors.textPrimary)
                    }

                    Button {
                        mode = .random
                        showHint = false
                        hintMoveUCI = nil
                        loadPuzzle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "shuffle")
                            Text("Next")
                                .font(AppFonts.captionBold)
                        }
                        .foregroundStyle(AppColors.accent)
                    }
                }
                .font(.title3)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.vertical, AppSpacing.sm)

                // Chess.com credit
                if let puzzle = viewModel.puzzle {
                    Link(destination: URL(string: puzzle.url) ?? URL(string: "https://chess.com")  ?? URL(fileURLWithPath: "/")) {
                        HStack(spacing: AppSpacing.xs) {
                            Text("Puzzle by")
                                .font(AppFonts.small)
                                .foregroundStyle(AppColors.textMuted)
                            Text("Chess.com")
                                .font(AppFonts.captionBold)
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            if viewModel.puzzleCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.best)
                Text("Puzzle Complete!")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.best)
            } else if viewModel.wrongMove {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppColors.blunder)
                Text("Wrong move — try again")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.blunder)
            } else if viewModel.isUserTurn {
                Circle()
                    .fill(viewModel.sideToMove == .white ? Color.white : Color.black)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(AppColors.surfaceLight, lineWidth: 1))
                Text("Your move")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
            } else {
                ProgressView().scaleEffect(0.6).tint(AppColors.textMuted)
                Text("Opponent's move...")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 28)
    }

    // MARK: - Helpers

    private var hintArrows: [PieceAnalysis.BoardArrow] {
        guard showHint, let uci = hintMoveUCI,
              let parsed = UCIParser.parseUCIMove(uci),
              let from = Square(algebraic: parsed.from),
              let to = Square(algebraic: parsed.to) else { return [] }
        return [PieceAnalysis.BoardArrow(from: from, to: to, type: .bestMove)]
    }

    private func toggleHint() {
        showHint.toggle()
        if showHint && viewModel.isUserTurn && !viewModel.puzzleCompleted {
            // Show the correct move as a hint
            if viewModel.currentSolutionIndex < viewModel.solutionMoves.count {
                hintMoveUCI = viewModel.solutionMoves[viewModel.currentSolutionIndex]
            }
        } else {
            hintMoveUCI = nil
        }
    }

    private var lastMove: (from: String, to: String)? {
        if let f = viewModel.lastMoveFrom, let t = viewModel.lastMoveTo {
            return (f, t)
        }
        return nil
    }

    private func loadPuzzle() {
        Task {
            if mode == .today {
                await viewModel.loadTodaysPuzzle()
            } else {
                await viewModel.loadRandomPuzzle()
            }
            hasLoadedOnce = true
        }
    }
}
