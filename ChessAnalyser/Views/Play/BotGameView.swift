import SwiftUI

struct BotGameView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = BotGameViewModel()
    @State private var showSetup = true
    var customFEN: String? = nil
    var initialFlip: Bool = false
    var studyTitle: String? = nil
    var autoStart: Bool = false
    /// For practice mode: user always plays this color (the winning side)
    var practiceUserColor: PieceColor? = nil
    /// All FENs for this practice pattern (for the Random button)
    var practiceFENs: [String] = []
    @State private var currentPracticeFEN: String? = nil
    @State private var showShareSheet = false

    var body: some View {
        if showSetup && !autoStart {
            setupView
        } else {
            gameView
                .onAppear {
                    if autoStart && showSetup {
                        showSetup = false
                        viewModel.botDepth = 8 // Fast responses for practice
                        let fen = currentPracticeFEN ?? customFEN
                        if let color = practiceUserColor {
                            viewModel.startGame(asColor: color, fen: fen, flipped: nil)
                        } else {
                            viewModel.startRandomGame(fen: fen, flipped: nil)
                        }
                    }
                }
        }
    }

    private func resetPractice() {
        let fen = currentPracticeFEN ?? customFEN
        if let color = practiceUserColor {
            viewModel.startGame(asColor: color, fen: fen, flipped: nil)
        } else {
            viewModel.startRandomGame(fen: fen, flipped: nil)
        }
    }

    private func randomPractice() {
        guard !practiceFENs.isEmpty else { return }
        let newFEN = practiceFENs.randomElement()!
        currentPracticeFEN = newFEN
        if let color = practiceUserColor {
            viewModel.startGame(asColor: color, fen: newFEN, flipped: nil)
        } else {
            viewModel.startRandomGame(fen: newFEN, flipped: nil)
        }
    }

    // MARK: - Setup Screen

    private var setupView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.accent)

            Text("Play vs Stockfish")
                .font(.title2.bold())
                .foregroundStyle(AppColors.textPrimary)

            // Depth slider
            VStack(spacing: AppSpacing.sm) {
                Text("Engine Strength: Depth \(viewModel.botDepth)")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)

                Slider(value: Binding(
                    get: { Double(viewModel.botDepth) },
                    set: { viewModel.botDepth = Int($0) }
                ), in: 1...20, step: 1)
                .tint(AppColors.accent)

                HStack {
                    Text("Easy (~0.1s)").font(AppFonts.small).foregroundStyle(AppColors.textMuted)
                    Spacer()
                    let ms = BotGameViewModel.botDepthToMoveTime(viewModel.botDepth)
                    Text(ms < 1000 ? "~\(ms)ms" : "~\(String(format: "%.1f", Double(ms)/1000))s")
                        .font(AppFonts.small).foregroundStyle(AppColors.accent)
                    Spacer()
                    Text("Hard (~3s)").font(AppFonts.small).foregroundStyle(AppColors.textMuted)
                }
            }
            .padding(.horizontal, AppSpacing.xxl)

            // Color selection
            Text("Choose your side")
                .font(AppFonts.bodyBold)
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: AppSpacing.lg) {
                colorButton(color: .white, label: "White", icon: "circle")
                colorButton(color: nil, label: "Random", icon: "questionmark.circle")
                colorButton(color: .black, label: "Black", icon: "circle.fill")
            }

            Spacer()
        }
        .background(AppColors.background)
        .navigationTitle("Play vs Bot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            Analytics.screenViewed("bot_game")
        }
    }

    private func colorButton(color: PieceColor?, label: String, icon: String) -> some View {
        Button {
            if let color = color {
                viewModel.startGame(asColor: color, fen: customFEN, flipped: customFEN != nil ? initialFlip : nil)
            } else {
                viewModel.startRandomGame(fen: customFEN, flipped: customFEN != nil ? initialFlip : nil)
            }
            showSetup = false
        } label: {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(color == .black ? Color.black :
                                     color == .white ? Color.white : AppColors.textSecondary)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(color == nil ? AppColors.surfaceLight :
                                   color == .white ? AppColors.surfaceElevated : AppColors.surfaceLight)
                            .overlay(Circle().stroke(AppColors.surfaceLight, lineWidth: 1))
                    )

                Text(label)
                    .font(AppFonts.captionBold)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
    }

    // MARK: - Game Screen

    private var gameView: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let isIPad = AppSpacing.isIPad(screenWidth)
            let boardSize: CGFloat = isIPad
                ? AppSpacing.boardSize(for: screenWidth, screenHeight: geometry.size.height, showEvalBar: viewModel.showHints)
                : max(1, viewModel.showHints
                    ? screenWidth - AppSpacing.evalBarWidth - AppSpacing.sm * 2 - AppSpacing.xs
                    : screenWidth - AppSpacing.sm * 2)

            if isIPad {
                HStack(alignment: .top, spacing: AppSpacing.lg) {
                    // Left: Board area
                    VStack(spacing: 0) {
                        botGameBotInfo
                        botGameBoardSection(boardSize: boardSize)
                        botGameClassificationInfo
                        botGamePlayerInfo
                    }
                    .frame(width: boardSize + AppSpacing.sm * 2 + (viewModel.showHints ? AppSpacing.evalBarWidth + AppSpacing.xs : 0))

                    // Right: Controls panel
                    VStack(spacing: AppSpacing.md) {
                        botGameControls
                        botGameMoveHistory
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppSpacing.md)
                }
            } else {
                VStack(spacing: 0) {
                    botGameBotInfo
                    botGameBoardSection(boardSize: boardSize)
                    botGameClassificationInfo
                    botGamePlayerInfo
                    botGameControls
                    botGameMoveHistory
                    Spacer()
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle(studyTitle ?? "vs Stockfish")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            SharePositionSheet(
                fen: viewModel.board.toFEN(),
                pgn: botGamePGN
            )
        }
    }

    private var botGamePGN: String {
        let startFEN = customFEN ?? currentPracticeFEN ?? "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        var pgn = "[FEN \"\(startFEN)\"]\n\n"
        for move in viewModel.moveHistory {
            if move.isWhite { pgn += "\(move.moveNumber). " }
            pgn += "\(move.san) "
        }
        return pgn.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Bot Game Subviews

    private var botGameBotInfo: some View {
        let botColor = viewModel.playerColor.opposite
        return VStack(spacing: 0) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundStyle(AppColors.accent)
                Text("Stockfish (Depth \(viewModel.botDepth))")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                if viewModel.isBotThinking {
                    ProgressView().scaleEffect(0.7).tint(AppColors.accent)
                    Text("Thinking...").font(AppFonts.caption).foregroundStyle(AppColors.textMuted)
                }
            }
            CapturedPiecesView(
                board: viewModel.board,
                initialBoard: viewModel.initialBoard,
                capturedByWhite: botColor == .white
            )
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private func botGameBoardSection(boardSize: CGFloat) -> some View {
        HStack(spacing: 0) {
            if viewModel.showHints {
                EvalBarView(
                    eval: viewModel.currentEval,
                    sideToMoveIsWhite: viewModel.board.sideToMove == .white
                )
                .frame(height: boardSize)
            }

            ZStack {
                InteractiveBoardView(
                    board: viewModel.board,
                    selectedSquare: viewModel.selectedSquare,
                    legalMoveTargets: viewModel.legalMoveTargets,
                    lastMove: lastMove,
                    arrows: gameArrows,
                    moveClassification: viewModel.showHints ? viewModel.lastMoveClassification : nil,
                    showCoordinates: appState.engineConfig.showBoardCoordinates,
                    flipped: viewModel.isFlipped,
                    onTapSquare: { viewModel.tapSquare($0) }
                )

                if viewModel.showPromotionPicker {
                    PromotionPickerView(
                        color: viewModel.playerColor,
                        onSelect: { viewModel.completePromotion(piece: $0) }
                    )
                }

                if viewModel.gameOver, let result = viewModel.gameResult {
                    gameEndOverlay(result)
                }
            }
            .frame(width: boardSize, height: boardSize)
            .padding(.leading, AppSpacing.xs)
        }
        .padding(.horizontal, AppSpacing.sm)
    }

    private var botGameClassificationInfo: some View {
        Group {
            if viewModel.showHints, let classification = viewModel.lastMoveClassification,
               classification != .none {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: classification.iconName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(classification.color)
                    Text(classification.label)
                        .font(AppFonts.captionBold)
                        .foregroundStyle(classification.color)
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.md)
                .frame(height: 24)
            }
        }
    }

    private func gameEndOverlay(_ result: String) -> some View {
        let isWin = result.lowercased().contains("wins") && !result.lowercased().contains("resigned")
            && ((viewModel.playerColor == .white && result.contains("White wins"))
                || (viewModel.playerColor == .black && result.contains("Black wins")))
        let isDraw = result.lowercased().contains("draw") || result.lowercased().contains("stalemate")
            || result.lowercased().contains("insufficient") || result.lowercased().contains("repetition")
            || result.lowercased().contains("fifty")

        let icon: String
        let color: Color
        let title: String
        if isWin {
            icon = "crown.fill"; color = AppColors.accent; title = "You Win!"
        } else if isDraw {
            icon = "equal.circle.fill"; color = AppColors.textSecondary; title = "Draw"
        } else {
            icon = "flag.fill"; color = AppColors.blunder; title = "You Lost"
        }

        return VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
            Text(result)
                .font(AppFonts.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xl)
        .background(.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .allowsHitTesting(false)
    }

    private var botGamePlayerInfo: some View {
        VStack(spacing: 0) {
            HStack {
                Circle()
                    .fill(viewModel.playerColor == .white ? Color.white : Color.black)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(AppColors.surfaceLight, lineWidth: 1))
                if viewModel.gameOver, let result = viewModel.gameResult {
                    Text(result)
                        .font(AppFonts.captionBold)
                        .foregroundStyle(AppColors.accent)
                        .lineLimit(1)
                } else {
                    Text("You")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                }
                Spacer()
            }
            CapturedPiecesView(
                board: viewModel.board,
                initialBoard: viewModel.initialBoard,
                capturedByWhite: viewModel.playerColor == .white
            )
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private var botGameControls: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                botBlockButton(icon: "arrow.up.arrow.down", label: "Flip") {
                    viewModel.isFlipped.toggle()
                }

                botBlockButton(icon: "arrow.uturn.backward", label: "Undo") {
                    viewModel.undoLastTwoMoves()
                }
                .opacity(viewModel.moveHistory.count < 2 || viewModel.isBotThinking ? 0.4 : 1)
                .disabled(viewModel.moveHistory.count < 2 || viewModel.isBotThinking)

                botBlockButton(
                    icon: viewModel.showHints ? "lightbulb.fill" : "lightbulb",
                    label: "Hints",
                    highlight: viewModel.showHints
                ) {
                    viewModel.toggleHints()
                }

                botDepthStepper

                botBlockButton(icon: "square.and.arrow.up", label: "Share") {
                    Analytics.shareOpened(source: "bot_game"); showShareSheet = true
                }
            }

            HStack(spacing: AppSpacing.sm) {
                if autoStart {
                    botBlockButton(icon: "arrow.counterclockwise", label: "Reset") {
                        resetPractice()
                    }
                    if !practiceFENs.isEmpty {
                        botBlockButton(icon: "shuffle", label: "Random", highlight: true) {
                            randomPractice()
                        }
                    }
                }

                if viewModel.gameOver {
                    botBlockButton(
                        icon: "arrow.counterclockwise",
                        label: autoStart ? "Try Again" : "New Game",
                        highlight: true
                    ) {
                        if autoStart { resetPractice() } else { showSetup = true }
                    }
                } else if !autoStart {
                    botBlockButton(icon: "flag.fill", label: "Resign", isDestructive: true) {
                        viewModel.resign()
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.sm)
    }

    /// Single-cell depth stepper: tap the left half to decrease, right half to increase.
    /// Replaces two separate -/+ buttons that were easy to mis-tap.
    private var botDepthStepper: some View {
        HStack(spacing: 0) {
            Button {
                if viewModel.botDepth > 1 { viewModel.botDepth -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(viewModel.botDepth > 1 ? AppColors.textPrimary : AppColors.textMuted.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.botDepth <= 1)

            VStack(spacing: 4) {
                Text("D\(viewModel.botDepth)")
                    .font(.system(size: 14, weight: .bold))
                Text("Depth")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(AppColors.textPrimary)
            .allowsHitTesting(false)

            Button {
                if viewModel.botDepth < 20 { viewModel.botDepth += 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(viewModel.botDepth < 20 ? AppColors.textPrimary : AppColors.textMuted.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.botDepth >= 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
    }

    private func botBlockButton(icon: String, label: String, highlight: Bool = false, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isDestructive ? AppColors.blunder : highlight ? AppColors.accent : AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(highlight ? AppColors.accent.opacity(0.15) : AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
    }

    private var botGameMoveHistory: some View {
        Group {
            if !viewModel.moveHistory.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        ForEach(viewModel.moveHistory) { move in
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
            }
        }
    }

    // MARK: - Helpers

    private var lastMove: (from: String, to: String)? {
        guard let move = viewModel.moveHistory.last else { return nil }
        return (move.from, move.to)
    }

    private var gameArrows: [PieceAnalysis.BoardArrow] {
        var arrows: [PieceAnalysis.BoardArrow] = []

        // Show hint arrow for player (when hints enabled)
        if viewModel.showHints, let hintUCI = viewModel.playerBestMoveUCI,
           let parsed = UCIParser.parseUCIMove(hintUCI),
           let from = Square(algebraic: parsed.from),
           let to = Square(algebraic: parsed.to) {
            arrows.append(PieceAnalysis.BoardArrow(from: from, to: to, type: .bestMove))
        }

        return arrows
    }
}
