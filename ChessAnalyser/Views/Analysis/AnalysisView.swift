import SwiftUI

struct AnalysisView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AnalysisViewModel()
    @State private var showEngineDetail = false
    @State private var showPlayerInfo = false
    @State private var showEngineHints = false
    @State private var playerInfoUsername = ""
    @State private var playerInfoRating: Int?
    @State private var loggedIPadLayout = false

    let pgn: String?
    let fen: String?
    let chessComGame: ChessComGame?
    let profileUsername: String?
    let initialFlip: Bool
    let studyMode: Bool

    init(pgn: String, studyMode: Bool = false) {
        self.pgn = pgn; self.fen = nil; self.chessComGame = nil
        self.profileUsername = nil; self.initialFlip = false; self.studyMode = studyMode
    }

    init(fen: String, initialFlip: Bool = false, studyMode: Bool = false) {
        self.pgn = nil; self.fen = fen; self.chessComGame = nil
        self.profileUsername = nil; self.initialFlip = initialFlip; self.studyMode = studyMode
    }

    init(game: ChessComGame, profileUsername: String? = nil) {
        self.pgn = nil; self.fen = nil; self.chessComGame = game
        self.profileUsername = profileUsername; self.initialFlip = false; self.studyMode = false
    }

    var isFENMode: Bool { fen != nil }

    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width > 700
            ZStack {
                if isIPad {
                    iPadLayout(geometry: geometry)
                } else {
                    iPhoneLayout(geometry: geometry)
                }

                // Frozen overlay while analysis is running
                if hasLoadedGame && viewModel.analysisEngine.progress.isAnalyzing {
                    analysisOverlay
                }
            }
        }
        .background(AppColors.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(viewModel.gameState.result)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .onAppear {
            Analytics.screenViewed("analysis")
            loadGame()
        }
        .onDisappear { viewModel.cleanup() }
        .onChange(of: viewModel.gameState.currentMoveIndex) { _, _ in
            viewModel.onMoveChanged()
        }
        .sheet(isPresented: $showEngineDetail) {
            engineDetailSheet
        }
        .sheet(isPresented: $showPlayerInfo) {
            PlayerInfoSheet(username: playerInfoUsername, rating: playerInfoRating)
        }
    }

    // MARK: - iPhone Layout (nothing scrolls except the move strip)

    private func iPhoneLayout(geometry: GeometryProxy) -> some View {
        let screenWidth = geometry.size.width
        let showEvalBar = !isFENMode || showEngineHints
        let boardSize = max(1, showEvalBar
            ? screenWidth - AppSpacing.evalBarWidth - AppSpacing.sm * 2 - AppSpacing.xs
            : screenWidth - AppSpacing.sm * 2)

        let flipped = viewModel.isFlipped
        // Top player = the side at the top of the board
        let topIsWhite = flipped   // When flipped, white is on top
        let bottomIsWhite = !flipped

        return VStack(spacing: 0) {
            // 1. Top player
            playerHeader(
                name: topIsWhite ? viewModel.displayWhiteName : viewModel.displayBlackName,
                isWhite: topIsWhite,
                accuracy: topIsWhite
                    ? viewModel.analysisEngine.gameAnalysis?.whiteAccuracy
                    : viewModel.analysisEngine.gameAnalysis?.blackAccuracy
            )

            // 2. Board + eval bar (FIXED size, always interactive)
            HStack(spacing: 0) {
                if showEvalBar {
                    EvalBarView(eval: viewModel.currentEval, sideToMoveIsWhite: evalSideIsWhite)
                        .frame(height: boardSize)
                }

                ZStack {
                    InteractiveBoardView(
                        board: viewModel.displayBoard,
                        selectedSquare: viewModel.selectedSquare,
                        legalMoveTargets: viewModel.legalMoveTargets,
                        lastMove: displayLastMove,
                        arrows: boardArrows,
                        moveClassification: displayClassification,
                        showCoordinates: appState.engineConfig.showBoardCoordinates,
                        flipped: viewModel.isFlipped,
                        onTapSquare: { viewModel.tapSquare($0) }
                    )

                    if viewModel.showPromotionPicker {
                        PromotionPickerView(
                            color: viewModel.displayBoard.sideToMove,
                            onSelect: { viewModel.completePromotion(piece: $0) }
                        )
                    }

                    if let endStatus = viewModel.boardGameEndStatus {
                        gameEndOverlay(endStatus)
                    }
                }
                .frame(width: boardSize, height: boardSize)
                .padding(.leading, AppSpacing.xs)
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            if value.translation.width < -30 { viewModel.goForward() }
                            else if value.translation.width > 30 { viewModel.goBack() }
                        }
                )
            }
            .padding(.horizontal, AppSpacing.sm)

            // 3. Bottom player
            playerHeader(
                name: bottomIsWhite ? viewModel.displayWhiteName : viewModel.displayBlackName,
                isWhite: bottomIsWhite,
                accuracy: bottomIsWhite
                    ? viewModel.analysisEngine.gameAnalysis?.whiteAccuracy
                    : viewModel.analysisEngine.gameAnalysis?.blackAccuracy
            )

            // 4. Variation/exploration bar
            if viewModel.isExploring || viewModel.hasParkedVariation || isFENMode {
                let variationMoves = viewModel.displayVariationMoves

                HStack(spacing: AppSpacing.sm) {
                    if viewModel.isExploring || isFENMode {
                        // Hint toggle for FEN/free play mode
                        if isFENMode {
                            Button {
                                showEngineHints.toggle()
                                viewModel.explorationAnalysisEnabled = showEngineHints
                                if showEngineHints {
                                    viewModel.analyzeExplorationPositionPublic()
                                } else {
                                    viewModel.clearExplorationAnalysis()
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: showEngineHints ? "lightbulb.fill" : "lightbulb")
                                        .font(.system(size: 14))
                                    if !showEngineHints {
                                        Text("Show hints")
                                            .font(AppFonts.captionBold)
                                    }
                                }
                                .foregroundStyle(showEngineHints ? AppColors.accent : AppColors.textMuted)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, AppSpacing.xs)
                                .background(showEngineHints ? AppColors.accent.opacity(0.15) : AppColors.surfaceLight)
                                .clipShape(Capsule())
                            }
                        }

                        if showEngineHints || !isFENMode {
                            if let classification = viewModel.lastExplorationClassification,
                               classification != .none {
                                Image(systemName: classification.iconName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(classification.color)
                            }

                            if let bestSAN = viewModel.explorationBestMoveSAN {
                                Text("Best: \(bestSAN)")
                                    .font(AppFonts.captionBold)
                                    .foregroundStyle(AppColors.best)
                            }
                        }
                    } else {
                        // Parked variation indicator
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.textMuted)
                    }

                    // Variation moves (tappable)
                    if !variationMoves.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 2) {
                                ForEach(variationMoves) { move in
                                    if move.isWhite {
                                        Text("\(move.moveNumber).")
                                            .font(AppFonts.caption)
                                            .foregroundStyle(AppColors.textMuted)
                                    }

                                    let isCurrent = viewModel.isExploring
                                        && move.moveIndex == viewModel.explorationViewIndex

                                    Button {
                                        viewModel.goToExplorationMove(move.moveIndex)
                                    } label: {
                                        Text(move.san)
                                            .font(AppFonts.moveText)
                                            .foregroundStyle(
                                                isCurrent ? AppColors.background :
                                                viewModel.isExploring ? AppColors.textPrimary : AppColors.textMuted
                                            )
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(isCurrent ? AppColors.accent : Color.clear)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    Spacer()

                    if viewModel.isExploring {
                        // Show Resume only for loaded games (not FEN/free play)
                        if hasLoadedGame {
                            Button { viewModel.exitExploration() } label: {
                                Text("Resume")
                                    .font(AppFonts.captionBold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, AppSpacing.xs)
                                    .background(AppColors.accent)
                                    .clipShape(Capsule())
                            }
                        }
                    } else {
                        Button { viewModel.clearParkedVariation() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.surface)
            }

            // 5. Controls (unified — works for both game and variation)
            AnalysisControlsView(
                isFlipped: viewModel.isFlipped,
                isAtStart: !viewModel.canGoBack,
                isAtEnd: !viewModel.canGoForward,
                autoPlay: viewModel.autoPlay,
                isAnalyzing: viewModel.analysisEngine.progress.isAnalyzing,
                showReEvaluate: hasLoadedGame,
                onGoToStart: { viewModel.goToStart() },
                onGoBack: { viewModel.goBack() },
                onGoForward: { viewModel.goForward() },
                onGoToEnd: { viewModel.goToEnd() },
                onToggleAutoPlay: { viewModel.toggleAutoPlay() },
                onFlipBoard: { viewModel.flipBoard() },
                onReEvaluate: { viewModel.reEvaluate(config: appState.engineConfig) }
            )
            .padding(.vertical, 2)

            // 5. Classification summary (when analysis has results)
            if !viewModel.analysisEngine.cache.isEmpty {
                ClassificationSummaryView(
                    cache: viewModel.analysisEngine.cache,
                    currentMoveIndex: viewModel.gameState.currentMoveIndex,
                    onNavigateToMove: { viewModel.gameState.goToMove($0) }
                )
                .padding(.horizontal, AppSpacing.sm)
            }

            // 6. Horizontal move list (chess.com style)
            MoveListView(
                moves: viewModel.gameState.game?.moves ?? [],
                analysisCache: viewModel.analysisEngine.cache,
                currentMoveIndex: viewModel.gameState.currentMoveIndex,
                onTapMove: { viewModel.gameState.goToMove($0) }
            )
            .padding(.horizontal, AppSpacing.sm)

            // 7. Compact info bar (explanation + best move)
            compactInfoBar
                .padding(.horizontal, AppSpacing.sm)
                .padding(.top, AppSpacing.xs)

            // 8. Progress (if analyzing)
            if viewModel.analysisEngine.progress.isAnalyzing {
                analysisProgressBar
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.top, 2)
            }

            // 9. Engine lines (fills remaining space, scrollable independently)
            engineLinesPanel
                .padding(.horizontal, AppSpacing.sm)
                .padding(.top, AppSpacing.xs)
                .padding(.bottom, AppSpacing.xs)
        }
    }

    // MARK: - iPad Layout

    private func iPadLayout(geometry: GeometryProxy) -> some View {
        if !loggedIPadLayout {
            DispatchQueue.main.async {
                loggedIPadLayout = true
                Analytics.iPadLayoutUsed(screenName: "analysis")
            }
        }
        let screenH = geometry.size.height
        let screenW = geometry.size.width
        // Board: fit within height (minus headers+controls ~140pt) and cap at 55% width
        let boardSize = max(1, min(screenH - 140, screenW * 0.55))
        let flipped = viewModel.isFlipped
        let topIsWhite = flipped
        let bottomIsWhite = !flipped
        let showEvalBar = !isFENMode || showEngineHints

        return HStack(spacing: 0) {
            // Left: Board column — vertically centered
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                playerHeader(
                    name: topIsWhite ? viewModel.displayWhiteName : viewModel.displayBlackName,
                    isWhite: topIsWhite,
                    accuracy: topIsWhite
                        ? viewModel.analysisEngine.gameAnalysis?.whiteAccuracy
                        : viewModel.analysisEngine.gameAnalysis?.blackAccuracy
                )
                .padding(.horizontal, AppSpacing.sm)

                HStack(spacing: 0) {
                    if showEvalBar {
                        EvalBarView(eval: viewModel.currentEval, sideToMoveIsWhite: evalSideIsWhite)
                            .frame(height: boardSize)
                    }

                    ZStack {
                        InteractiveBoardView(
                            board: viewModel.displayBoard,
                            selectedSquare: viewModel.selectedSquare,
                            legalMoveTargets: viewModel.legalMoveTargets,
                            lastMove: displayLastMove,
                            arrows: boardArrows,
                            moveClassification: displayClassification,
                            showCoordinates: appState.engineConfig.showBoardCoordinates,
                            flipped: viewModel.isFlipped,
                            onTapSquare: { viewModel.tapSquare($0) }
                        )

                        if viewModel.showPromotionPicker {
                            PromotionPickerView(
                                color: viewModel.displayBoard.sideToMove,
                                onSelect: { viewModel.completePromotion(piece: $0) }
                            )
                        }

                        if let endStatus = viewModel.boardGameEndStatus {
                            gameEndOverlay(endStatus)
                        }
                    }
                    .frame(width: boardSize, height: boardSize)
                    .gesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { value in
                                if value.translation.width < -30 { viewModel.goForward() }
                                else if value.translation.width > 30 { viewModel.goBack() }
                            }
                    )
                }

                playerHeader(
                    name: bottomIsWhite ? viewModel.displayWhiteName : viewModel.displayBlackName,
                    isWhite: bottomIsWhite,
                    accuracy: bottomIsWhite
                        ? viewModel.analysisEngine.gameAnalysis?.whiteAccuracy
                        : viewModel.analysisEngine.gameAnalysis?.blackAccuracy
                )
                .padding(.horizontal, AppSpacing.sm)

                AnalysisControlsView(
                    isFlipped: viewModel.isFlipped,
                    isAtStart: !viewModel.canGoBack,
                    isAtEnd: !viewModel.canGoForward,
                    autoPlay: viewModel.autoPlay,
                    isAnalyzing: viewModel.analysisEngine.progress.isAnalyzing,
                    showReEvaluate: hasLoadedGame,
                    onGoToStart: { viewModel.goToStart() },
                    onGoBack: { viewModel.goBack() },
                    onGoForward: { viewModel.goForward() },
                    onGoToEnd: { viewModel.goToEnd() },
                    onToggleAutoPlay: { viewModel.toggleAutoPlay() },
                    onFlipBoard: { viewModel.flipBoard() },
                    onReEvaluate: { viewModel.reEvaluate(config: appState.engineConfig) }
                )
                .padding(.vertical, AppSpacing.xs)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.sm)

            // Right: Info panel
            VStack(spacing: 0) {
                // Classification summary
                if !viewModel.analysisEngine.cache.isEmpty {
                    ClassificationSummaryView(
                        cache: viewModel.analysisEngine.cache,
                        currentMoveIndex: viewModel.gameState.currentMoveIndex,
                        onNavigateToMove: { viewModel.gameState.goToMove($0) }
                    )
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.top, AppSpacing.sm)
                }

                // Move explanation + eval
                compactInfoBar
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.top, AppSpacing.sm)

                // Progress
                if viewModel.analysisEngine.progress.isAnalyzing {
                    analysisProgressBar
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.top, AppSpacing.xs)
                }

                // Engine lines
                engineLinesPanel
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.top, AppSpacing.sm)

                // Variation moves (when exploring)
                iPadVariationBar
                    .padding(.horizontal, AppSpacing.sm)

                Divider()
                    .background(AppColors.surfaceLight)
                    .padding(.vertical, AppSpacing.sm)

                // Moves header
                Text("Moves")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppSpacing.md)

                // Move list — fills all remaining space, only this scrolls
                ScrollView {
                    MoveListView(
                        moves: viewModel.gameState.game?.moves ?? [],
                        analysisCache: viewModel.analysisEngine.cache,
                        currentMoveIndex: viewModel.gameState.currentMoveIndex,
                        onTapMove: { viewModel.gameState.goToMove($0) },
                        vertical: true
                    )
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                }
            }
            .frame(maxWidth: .infinity)
            .background(AppColors.surface)
        }
    }

    // MARK: - Compact Info Bar

    private var compactInfoBar: some View {
        Group {
            if let endStatus = viewModel.boardGameEndStatus {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.accent)
                    Text(endStatus.displayText)
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            } else if let analysis = viewModel.currentMoveAnalysis, analysis.classification != .none {
                Button { showEngineDetail = true } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: analysis.classification.iconName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(analysis.classification.color)

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: AppSpacing.xs) {
                                if analysis.classification == .book,
                                   let name = OpeningBook.shared.openingName(for: analysis.fen) {
                                    Text("Book")
                                        .font(AppFonts.captionBold)
                                        .foregroundStyle(analysis.classification.color)
                                    Text(name)
                                        .font(AppFonts.captionBold)
                                        .foregroundStyle(AppColors.textPrimary)
                                        .lineLimit(1)
                                } else {
                                    Text(analysis.classification.label)
                                        .font(AppFonts.captionBold)
                                        .foregroundStyle(analysis.classification.color)

                                    if !analysis.classification.isPositive {
                                        Text("Best: \(analysis.bestMoveSAN)")
                                            .font(AppFonts.captionBold)
                                            .foregroundStyle(AppColors.best)
                                    }
                                }
                            }

                            Text(MoveExplainer.explainShort(analysis))
                                .font(AppFonts.small)
                                .foregroundStyle(AppColors.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Text(analysis.evalAfter.displayText)
                            .font(AppFonts.evalText)
                            .foregroundStyle(AppColors.textPrimary)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(AppSpacing.sm)
                    .background(analysis.classification.color.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    if viewModel.analysisEngine.progress.isAnalyzing {
                        ProgressView().scaleEffect(0.6).tint(AppColors.accent)
                    }
                    Text("Eval").font(AppFonts.captionBold).foregroundStyle(AppColors.textSecondary)
                    Text(viewModel.currentEval.displayText)
                        .font(AppFonts.evalText).foregroundStyle(AppColors.textPrimary)
                    Spacer()
                }
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
            }
        }
    }

    // MARK: - Engine Detail Sheet

    private var engineDetailSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    if let analysis = viewModel.currentMoveAnalysis {
                        MoveExplanationView(analysis: analysis)

                        if !analysis.classification.isPositive {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(AppColors.best)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Best move: \(analysis.bestMoveSAN)")
                                        .font(AppFonts.bodyBold)
                                        .foregroundStyle(AppColors.best)
                                    Text("Eval after best: \(analysis.bestMoveEval.displayText)")
                                        .font(AppFonts.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                    Text("Eval after played: \(analysis.evalAfter.displayText)")
                                        .font(AppFonts.caption)
                                        .foregroundStyle(AppColors.textMuted)
                                }
                                Spacer()
                            }
                            .padding(AppSpacing.sm)
                            .background(AppColors.best.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                        }

                        if !analysis.engineLines.isEmpty {
                            EngineLinesView(
                                lines: analysis.engineLines,
                                sideToMoveIsWhite: !analysis.isWhite // After the move, opponent is to move
                            )
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.background)
            .navigationTitle("Move Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showEngineDetail = false }
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Board Arrows

    private var boardArrows: [PieceAnalysis.BoardArrow] {
        let config = appState.engineConfig

        // In exploration mode, show best move from exploration analysis
        if viewModel.isExploring {
            var arrows: [PieceAnalysis.BoardArrow] = []

            // Only show engine arrows if hints enabled (for FEN mode) or always (for loaded games)
            let showBestArrow = isFENMode ? showEngineHints : true
            if showBestArrow,
               let bestMove = viewModel.explorationBestMove,
               let parsed = UCIParser.parseUCIMove(bestMove),
               let from = Square(algebraic: parsed.from),
               let to = Square(algebraic: parsed.to) {
                arrows.append(PieceAnalysis.BoardArrow(from: from, to: to, type: .bestMove))
            }

            // Show attack/defense arrows if enabled
            if config.showAttackArrows || config.showDefenseArrows {
                let board = viewModel.displayBoard
                let sideToMove: PieceColor = board.sideToMove
                if config.showAttackArrows {
                    let unsafe = PieceAnalysis.getUnsafePieces(board: board, color: sideToMove)
                    for (sq, _) in unsafe.prefix(3) {
                        let attackers = PieceAnalysis.getDirectAttackers(board: board, target: sq, targetColor: sideToMove)
                        for a in attackers.prefix(2) {
                            arrows.append(PieceAnalysis.BoardArrow(from: a.from, to: sq, type: .attack))
                        }
                    }
                }
                if config.showDefenseArrows {
                    let unsafe = PieceAnalysis.getUnsafePieces(board: board, color: sideToMove)
                    for (sq, _) in unsafe.prefix(3) {
                        let defenders = PieceAnalysis.getDefenders(board: board, target: sq, targetColor: sideToMove)
                        for d in defenders.prefix(2) {
                            arrows.append(PieceAnalysis.BoardArrow(from: d.from, to: sq, type: .defense))
                        }
                    }
                }
            }
            return arrows
        }

        // Normal mode
        let analysis = viewModel.currentMoveAnalysis
        let showBest = config.showBestMoveArrow
            || (analysis?.classification.isPositive == false)

        return PieceAnalysis.generateArrows(
            board: viewModel.displayBoard,
            analysis: analysis,
            showBestMove: showBest,
            showAttacks: config.showAttackArrows,
            showDefenses: config.showDefenseArrows
        )
    }

    // MARK: - Components

    private func playerHeader(name: String, isWhite: Bool, accuracy: Double?) -> some View {
        let rawUsername = isWhite
            ? (viewModel.whiteUsername ?? viewModel.gameState.whiteName)
            : (viewModel.blackUsername ?? viewModel.gameState.blackName)
        let rating = isWhite ? viewModel.whiteRating : viewModel.blackRating

        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Circle()
                    .fill(isWhite ? Color.white : Color.black)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(AppColors.surfaceLight, lineWidth: 1))

                Button {
                    playerInfoUsername = rawUsername
                    playerInfoRating = rating
                    showPlayerInfo = true
                } label: {
                    Text(name).font(AppFonts.bodyBold).foregroundStyle(AppColors.textPrimary).lineLimit(1)
                }
                .buttonStyle(.plain)

                Spacer()
                if let accuracy = accuracy {
                    Text(String(format: "%.1f%%", accuracy))
                        .font(AppFonts.captionBold)
                        .foregroundStyle(accuracyColor(accuracy))
                        .padding(.horizontal, AppSpacing.sm).padding(.vertical, AppSpacing.xs)
                        .background(accuracyColor(accuracy).opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            // Captured pieces (shown under opponent's name = pieces they lost)
            // Under black's name: show pieces black captured (white's lost pieces)
            // Under white's name: show pieces white captured (black's lost pieces)
            CapturedPiecesView(
                board: viewModel.displayBoard,
                initialBoard: viewModel.gameState.boards.first ?? ChessBoard(),
                capturedByWhite: isWhite
            )
            .padding(.leading, 24) // Align with name text (past the circle)
        }
        .padding(.horizontal, AppSpacing.md).padding(.vertical, AppSpacing.xs)
    }

    /// Engine lines panel — fills remaining space, scrollable independently
    private var engineLinesPanel: some View {
        Group {
            let lines = viewModel.currentMoveAnalysis?.engineLines ?? []
            if !lines.isEmpty {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                            HStack(spacing: AppSpacing.sm) {
                                Text(line.eval.displayTextWhitePerspective(
                                    sideToMoveIsWhite: viewModel.displayBoard.sideToMove == .white
                                ))
                                .font(AppFonts.evalText)
                                .foregroundStyle(evalLineColor(line.eval))
                                .frame(width: 44, alignment: .trailing)

                                Text(line.moves.prefix(10).joined(separator: " "))
                                    .font(AppFonts.moveText)
                                    .foregroundStyle(index == 0 ? AppColors.textPrimary : AppColors.textSecondary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 3)
                            .padding(.horizontal, AppSpacing.sm)

                            if index < lines.count - 1 {
                                Divider().background(AppColors.surfaceLight)
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
            } else {
                Spacer(minLength: 0)
            }
        }
    }

    private func evalLineColor(_ eval: EngineEval) -> Color {
        let whiteCP = MoveClassifier.toWhiteCP(eval, sideToMoveIsWhite: viewModel.displayBoard.sideToMove == .white)
        if whiteCP > 50 { return AppColors.win }
        if whiteCP < -50 { return AppColors.loss }
        return AppColors.textSecondary
    }

    private func gameEndOverlay(_ status: AnalysisViewModel.GameEndStatus) -> some View {
        let icon: String
        let color: Color
        switch status {
        case .checkmate: icon = "crown.fill"; color = AppColors.accent
        case .gameResult(_, let winner): icon = winner != nil ? "flag.fill" : "equal.circle.fill"; color = winner != nil ? AppColors.accent : AppColors.textSecondary
        case .stalemate: icon = "equal.circle.fill"; color = AppColors.textSecondary
        case .insufficientMaterial: icon = "xmark.circle.fill"; color = AppColors.textMuted
        case .threefoldRepetition: icon = "repeat.circle.fill"; color = AppColors.textSecondary
        case .fiftyMoveRule: icon = "clock.fill"; color = AppColors.textMuted
        }

        return VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(color)

            Text(status.displayText)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xl)
        .background(.black.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    private var analysisProgressBar: some View {
        ProgressView(value: viewModel.analysisEngine.progress.percentage)
            .tint(AppColors.accent)
    }

    private var iPadVariationBar: some View {
        Group {
            let variationMoves = viewModel.displayVariationMoves
            if !variationMoves.isEmpty || viewModel.isExploring {
                VStack(spacing: AppSpacing.xs) {
                    HStack {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.accent)
                        Text("Variation")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        if viewModel.isExploring && hasLoadedGame {
                            Button { viewModel.exitExploration() } label: {
                                Text("Resume")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, AppSpacing.sm)
                                    .padding(.vertical, 3)
                                    .background(AppColors.accent)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    if !variationMoves.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 2) {
                                ForEach(variationMoves) { move in
                                    if move.isWhite {
                                        Text("\(move.moveNumber).")
                                            .font(AppFonts.caption)
                                            .foregroundStyle(AppColors.textMuted)
                                    }
                                    let isCurrent = viewModel.isExploring
                                        && move.moveIndex == viewModel.explorationViewIndex
                                    Button {
                                        viewModel.goToExplorationMove(move.moveIndex)
                                    } label: {
                                        Text(move.san)
                                            .font(AppFonts.moveText)
                                            .foregroundStyle(isCurrent ? AppColors.background : AppColors.textPrimary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(isCurrent ? AppColors.accent : Color.clear)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(height: 28)
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.surfaceLight.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.top, AppSpacing.sm)
            }
        }
    }

    private var analysisOverlay: some View {
        Color.black.opacity(0.6)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: AppSpacing.md) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.2)

                    Text("Analyzing game...")
                        .font(AppFonts.subtitle)
                        .foregroundStyle(.white)

                    let p = viewModel.analysisEngine.progress
                    Text("\(p.currentMove) / \(p.totalMoves) moves")
                        .font(AppFonts.body)
                        .foregroundStyle(.white.opacity(0.8))

                    ProgressView(value: p.percentage)
                        .tint(AppColors.accent)
                        .frame(width: 200)
                }
                .padding(AppSpacing.xl)
                .background(AppColors.surface.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
            }
    }

    /// Which side is to move in the position whose eval is displayed.
    /// After a white move, black is to move (eval is from black's perspective).
    /// True if this is a loaded game (PGN/chess.com) with actual moves, not a FEN-only/free-play position
    private var hasLoadedGame: Bool {
        (viewModel.gameState.game?.moves.count ?? 0) > 0
    }

    private var evalSideIsWhite: Bool {
        viewModel.displayBoard.sideToMove == .white
    }

    private var displayClassification: MoveClassification? {
        if viewModel.isExploring {
            // In FEN mode, only show classification when hints are enabled
            if isFENMode && !showEngineHints { return nil }
            return viewModel.lastExplorationClassification
        }
        return viewModel.currentMoveAnalysis?.classification
    }

    private var displayLastMove: (from: String, to: String)? {
        if viewModel.isExploring {
            let idx = viewModel.explorationViewIndex
            if idx >= 0 && idx < viewModel.explorationMoves.count {
                let move = viewModel.explorationMoves[idx]
                return (move.from, move.to)
            }
            // At the branch point (before any variation move), show the game's current move
            return viewModel.gameState.currentMove.map { ($0.from, $0.to) }
        }
        guard let move = viewModel.gameState.currentMove else { return nil }
        return (move.from, move.to)
    }

    private func accuracyColor(_ accuracy: Double) -> Color {
        if accuracy >= 90 { return AppColors.best }
        if accuracy >= 70 { return AppColors.good }
        if accuracy >= 50 { return AppColors.inaccuracy }
        return AppColors.mistake
    }

    private func loadGame() {
        if let game = chessComGame { viewModel.loadChessComGame(game, profileUsername: profileUsername) }
        else if let pgn = pgn { viewModel.loadPGN(pgn) }
        else if let fen = fen {
            viewModel.loadFEN(fen)
            viewModel.isFlipped = initialFlip
            viewModel.explorationAnalysisEnabled = !studyMode
            viewModel.enterExploration()
            if !studyMode {
                Task { try? await EngineManager.shared.ensureInitialized(config: appState.engineConfig) }
            }
            return
        }
        if !studyMode {
            Task {
                await viewModel.startAnalysis(config: appState.engineConfig)
            }
        }
    }
}
