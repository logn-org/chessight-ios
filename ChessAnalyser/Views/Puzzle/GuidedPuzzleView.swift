import SwiftUI

/// A guided puzzle view for learning tactics and checkmates.
/// Reuses PuzzleViewModel with custom FEN + PGN data.
struct GuidedPuzzleView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = PuzzleViewModel()
    @State private var showHint = false
    @State private var hintMoveUCI: String?

    let puzzle: GuidedPuzzle
    let allPuzzles: [GuidedPuzzle]

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let boardSize = max(1, screenWidth - AppSpacing.sm * 2)

            VStack(spacing: 0) {
                // Description
                Text(puzzle.description)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.md)
                    .frame(height: 32)

                // Status
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

                // Controls
                HStack(spacing: AppSpacing.lg) {
                    Button { viewModel.isFlipped.toggle() } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }

                    Button {
                        viewModel.loadCustomPuzzle(title: puzzle.name, fen: puzzle.fen, pgn: puzzle.pgn)
                        showHint = false
                        hintMoveUCI = nil
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }

                    Button { toggleHint() } label: {
                        Image(systemName: showHint ? "lightbulb.fill" : "lightbulb")
                            .foregroundStyle(showHint ? AppColors.accent : AppColors.textPrimary)
                    }

                    if allPuzzles.count > 1 {
                        Button { loadRandomPuzzle() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "shuffle")
                                Text("Next")
                                    .font(AppFonts.captionBold)
                            }
                            .foregroundStyle(AppColors.accent)
                        }
                    }
                }
                .font(.title3)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.vertical, AppSpacing.sm)

                Spacer()
            }
        }
        .background(AppColors.background)
        .navigationTitle(puzzle.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.loadCustomPuzzle(title: puzzle.name, fen: puzzle.fen, pgn: puzzle.pgn)
            Analytics.screenViewed("guided_puzzle")
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            if viewModel.puzzleCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.accent)
                Text("Correct!")
                    .font(AppFonts.captionBold)
                    .foregroundStyle(AppColors.accent)
            } else if viewModel.wrongMove {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppColors.blunder)
                Text("Wrong move — try again")
                    .font(AppFonts.captionBold)
                    .foregroundStyle(AppColors.blunder)
            } else if viewModel.isUserTurn {
                Circle()
                    .fill(viewModel.sideToMove == .white ? Color.white : Color.black)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(AppColors.surfaceLight, lineWidth: 1))
                Text("Your move")
                    .font(AppFonts.captionBold)
                    .foregroundStyle(AppColors.textPrimary)
            } else {
                Text("Opponent's turn...")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textMuted)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 24)
    }

    // MARK: - Last Move

    private var lastMove: (from: String, to: String)? {
        guard let from = viewModel.lastMoveFrom, let to = viewModel.lastMoveTo else { return nil }
        return (from, to)
    }

    // MARK: - Hints

    private var hintArrows: [PieceAnalysis.BoardArrow] {
        guard showHint, let uci = hintMoveUCI,
              let parsed = UCIParser.parseUCIMove(uci),
              let from = Square(algebraic: parsed.from),
              let to = Square(algebraic: parsed.to) else { return [] }
        return [PieceAnalysis.BoardArrow(from: from, to: to, type: .bestMove)]
    }

    private func toggleHint() {
        showHint.toggle()
        if showHint {
            let idx = viewModel.currentSolutionIndex
            if idx < viewModel.solutionMoves.count {
                hintMoveUCI = viewModel.solutionMoves[idx]
            }
        } else {
            hintMoveUCI = nil
        }
    }

    private func loadRandomPuzzle() {
        guard let newPuzzle = allPuzzles.randomElement() else { return }
        viewModel.loadCustomPuzzle(title: newPuzzle.name, fen: newPuzzle.fen, pgn: newPuzzle.pgn)
        showHint = false
        hintMoveUCI = nil
    }
}
