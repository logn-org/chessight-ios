import SwiftUI

/// Two-step guided puzzle: Learn (preview + arrows) → Practice (solve it)
struct GuidedPuzzleView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = PuzzleViewModel()
    @State private var showHint = false
    @State private var hintMoveUCI: String?
    @State private var mode: Mode = .learn

    enum Mode { case learn, practice }

    let puzzle: GuidedPuzzle
    let allPuzzles: [GuidedPuzzle]
    @State private var currentPuzzleIndex: Int = 0

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let isIPad = AppSpacing.isIPad(screenWidth)
            let boardSize = isIPad
                ? AppSpacing.boardSize(for: screenWidth, screenHeight: geometry.size.height)
                : max(1, screenWidth - AppSpacing.sm * 2)

            let currentPuzzle = currentPuzzleIndex < allPuzzles.count ? allPuzzles[currentPuzzleIndex] : puzzle

            ScrollView {
                VStack(spacing: 0) {
                    if mode == .learn {
                        learnView(boardSize: boardSize, currentPuzzle: currentPuzzle)
                    } else {
                        practiceView(boardSize: boardSize, currentPuzzle: currentPuzzle)
                    }
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle(puzzle.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            Analytics.screenViewed("guided_puzzle")
        }
        .onChange(of: viewModel.currentSolutionIndex) { _, _ in
            // Clear hint after any move is made
            showHint = false
            hintMoveUCI = nil
        }
    }

    // MARK: - Learn Mode (preview + arrows)

    private func learnView(boardSize: CGFloat, currentPuzzle: GuidedPuzzle) -> some View {
        VStack(spacing: AppSpacing.md) {
            // Detailed description
            Text(currentPuzzle.detailedDescription)
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)

            // Preview board with solution arrows
            let previewFEN = currentPuzzle.previewFEN ?? currentPuzzle.fen
            ZStack {
                // Non-interactive board showing the mating position
                MiniBoardPreview(fen: previewFEN)
                    .frame(width: boardSize, height: boardSize)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
                    .padding(.horizontal, AppSpacing.sm)

                // Solution arrows overlay
                solutionArrowsOverlay(boardSize: boardSize)
            }

            // Mate pattern label
            if let previewFEN = currentPuzzle.previewFEN {
                let board = ChessBoard(fen: previewFEN)
                if !board.hasLegalMoves(color: board.sideToMove) && board.isKingInCheck(color: board.sideToMove) {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(AppColors.accent)
                        Text("Checkmate position")
                            .font(AppFonts.captionBold)
                            .foregroundStyle(AppColors.accent)
                    }
                }
            }

            // Try This button
            Button {
                mode = .practice
                viewModel.loadCustomPuzzle(title: currentPuzzle.name, fen: currentPuzzle.fen, pgn: currentPuzzle.pgn)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Try This Checkmate")
                        .font(AppFonts.subtitle)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.accent)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.sm)

            Spacer()
        }
    }

    // MARK: - Solution Arrows Overlay

    private func solutionArrowsOverlay(boardSize: CGFloat) -> some View {
        let previewFEN = puzzle.previewFEN ?? puzzle.fen
        let board = ChessBoard(fen: previewFEN)

        // Find the checking piece(s) → draw arrow from attacker to king
        let sideInCheck = board.sideToMove
        var arrows: [(from: Square, to: Square)] = []

        // Find king position
        var kingSquare: Square?
        for rank in 0..<8 {
            for file in 0..<8 {
                let sq = Square(file: file, rank: rank)
                if let piece = board.piece(at: sq), piece.type == .king, piece.color == sideInCheck {
                    kingSquare = sq
                }
            }
        }

        // Find attackers of king
        if let king = kingSquare {
            for rank in 0..<8 {
                for file in 0..<8 {
                    let sq = Square(file: file, rank: rank)
                    if let piece = board.piece(at: sq), piece.color == sideInCheck.opposite {
                        if board.canAttack(from: sq, to: king, piece: piece) {
                            arrows.append((from: sq, to: king))
                        }
                    }
                }
            }
        }

        let squareSize = boardSize / 8

        return ZStack {
            ForEach(0..<arrows.count, id: \.self) { i in
                let arrow = arrows[i]
                let fromX = CGFloat(arrow.from.file) * squareSize + squareSize / 2
                let fromY = CGFloat(7 - arrow.from.rank) * squareSize + squareSize / 2
                let toX = CGFloat(arrow.to.file) * squareSize + squareSize / 2
                let toY = CGFloat(7 - arrow.to.rank) * squareSize + squareSize / 2

                Path { path in
                    path.move(to: CGPoint(x: fromX, y: fromY))
                    path.addLine(to: CGPoint(x: toX, y: toY))
                }
                .stroke(AppColors.blunder.opacity(0.8), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
        }
        .frame(width: boardSize, height: boardSize)
        .allowsHitTesting(false)
        .padding(.horizontal, AppSpacing.sm)
    }

    // MARK: - Practice Mode (solve the puzzle)

    private func practiceView(boardSize: CGFloat, currentPuzzle: GuidedPuzzle) -> some View {
        VStack(spacing: 0) {
            // Short instruction
            Text("Your turn — find the checkmate!")
                .font(AppFonts.captionBold)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, AppSpacing.sm)

            // Status
            statusBar

            // Board
            ZStack {
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

                if viewModel.puzzleCompleted {
                    completionOverlay
                }
            }
            .frame(width: boardSize, height: boardSize)
            .padding(.horizontal, AppSpacing.sm)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm)
                    .stroke(viewModel.wrongMove ? AppColors.blunder : Color.clear, lineWidth: 3)
                    .padding(.horizontal, AppSpacing.sm)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.wrongMove)
            )

            // Controls — block buttons
            VStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    actionButton(icon: "arrow.up.arrow.down", label: "Flip", color: AppColors.surface) {
                        viewModel.isFlipped.toggle()
                    }

                    actionButton(icon: "arrow.counterclockwise", label: "Reset", color: AppColors.surface) {
                        viewModel.loadCustomPuzzle(title: currentPuzzle.name, fen: currentPuzzle.fen, pgn: currentPuzzle.pgn)
                        showHint = false
                        hintMoveUCI = nil
                    }

                    actionButton(icon: showHint ? "lightbulb.fill" : "lightbulb", label: "Hint", color: showHint ? AppColors.accent.opacity(0.2) : AppColors.surface) {
                        toggleHint()
                    }

                    actionButton(icon: "eye.fill", label: "Preview", color: AppColors.surface) {
                        mode = .learn
                        showHint = false
                        hintMoveUCI = nil
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)

            Spacer()
        }
    }

    // MARK: - Action Button

    private func actionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "crown.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppColors.accent)
            Text("Checkmate!")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Text("Puzzle Complete")
                .font(AppFonts.body)
                .foregroundStyle(.white.opacity(0.8))

            if currentPuzzleIndex + 1 < allPuzzles.count {
                Button {
                    currentPuzzleIndex += 1
                    let next = allPuzzles[currentPuzzleIndex]
                    viewModel.loadCustomPuzzle(title: next.name, fen: next.fen, pgn: next.pgn)
                    showHint = false
                    hintMoveUCI = nil
                } label: {
                    Text("Try Another")
                        .font(AppFonts.captionBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.accent)
                        .clipShape(Capsule())
                }
                .padding(.top, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.xl)
        .background(.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
}
