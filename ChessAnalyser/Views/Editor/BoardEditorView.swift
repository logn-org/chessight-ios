import SwiftUI

struct BoardEditorView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = BoardEditorViewModel()
    @State private var navigateToFreePlay = false
    @State private var navigateToBotGame = false
    @State private var fenToPlay = ""
    @State private var validationError: String?
    @State private var showRules = false
    @State private var showFENInput = false
    @State private var fenInput = ""
    @State private var showShareSheet = false

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let isIPad = AppSpacing.isIPad(screenWidth)
            let boardSize = isIPad
                ? AppSpacing.boardSize(for: screenWidth, screenHeight: geometry.size.height)
                : max(1, screenWidth - AppSpacing.sm * 2)

            if isIPad {
                HStack(alignment: .top, spacing: AppSpacing.lg) {
                    // Left: Board
                    VStack(spacing: AppSpacing.sm) {
                        EditorBoardView(
                            board: viewModel.board,
                            pickedUpSquare: viewModel.pickedUpSquare,
                            editorMode: viewModel.editorMode,
                            flipped: viewModel.isFlipped,
                            onTapSquare: { viewModel.tapSquare($0) },
                            onDragMove: { from, to in viewModel.dragMove(from: from, to: to) }
                        )
                        .frame(width: boardSize, height: boardSize)
                        .padding(.horizontal, AppSpacing.sm)
                    }
                    .frame(width: boardSize + AppSpacing.sm * 2)

                    // Right: Controls panel
                    ScrollView {
                        VStack(spacing: AppSpacing.md) {
                            editorModeSelector
                            editorPiecePalettes
                            editorActionButtons
                            editorFENBar
                            editorPlayButtons
                        }
                        .padding(.top, AppSpacing.md)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        // Mode selector
                        modeSelector

                        // Board
                        EditorBoardView(
                            board: viewModel.board,
                            pickedUpSquare: viewModel.pickedUpSquare,
                            editorMode: viewModel.editorMode,
                            flipped: viewModel.isFlipped,
                            onTapSquare: { viewModel.tapSquare($0) },
                            onDragMove: { from, to in viewModel.dragMove(from: from, to: to) }
                        )
                        .frame(width: boardSize, height: boardSize)
                        .padding(.horizontal, AppSpacing.sm)

                        editorPiecePalettes
                        editorActionButtons
                        editorFENBar
                        editorPlayButtons
                    }
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle("Board Editor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            SharePositionSheet(
                fen: viewModel.currentFEN,
                pgn: "[FEN \"\(viewModel.currentFEN)\"]"
            )
        }
        .navigationDestination(isPresented: $navigateToFreePlay) {
            AnalysisViewForFEN(fen: fenToPlay, initialFlip: viewModel.isFlipped)
        }
        .navigationDestination(isPresented: $navigateToBotGame) {
            BotGameView(customFEN: fenToPlay, initialFlip: viewModel.isFlipped)
        }
        .onAppear {
            Analytics.screenViewed("board_editor")
        }
        .sheet(isPresented: $showRules) {
            rulesSheet
        }
        .alert("Invalid Position", isPresented: Binding(
            get: { validationError != nil },
            set: { if !$0 { validationError = nil } }
        )) {
            Button("OK") { validationError = nil }
        } message: {
            Text(validationError ?? "")
        }
        .sheet(isPresented: $showFENInput) {
            fenInputSheet
        }
    }

    // MARK: - FEN Input Sheet

    private var fenInputSheet: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.lg) {
                Text("Paste a FEN string to load a position onto the board.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.md)

                TextField("Paste FEN here...", text: $fenInput, axis: .vertical)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                    .lineLimit(3)
                    .padding(.horizontal, AppSpacing.md)

                Button {
                    if let clipboard = UIPasteboard.general.string, !clipboard.isEmpty {
                        fenInput = clipboard
                    }
                } label: {
                    Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                        .font(AppFonts.captionBold)
                        .foregroundStyle(AppColors.accent)
                }

                Spacer()

                Button {
                    if let error = viewModel.loadFEN(fenInput) {
                        validationError = error
                    }
                    showFENInput = false
                } label: {
                    Text("Load Position")
                        .font(AppFonts.subtitle)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(fenInput.isEmpty ? AppColors.surfaceLight : AppColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                }
                .disabled(fenInput.isEmpty)
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
            }
            .padding(.top, AppSpacing.md)
            .background(AppColors.background)
            .navigationTitle("Import FEN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showFENInput = false }
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Extracted Subviews

    private var editorModeSelector: some View {
        modeSelector
    }

    private var editorPiecePalettes: some View {
        Group {
            if viewModel.editorMode == .place {
                piecePalette(pieces: viewModel.whitePieces)
                piecePalette(pieces: viewModel.blackPieces)
            }
        }
    }

    private var editorActionButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Button { viewModel.toggleSideToMove() } label: {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(viewModel.sideToMove == .white ? Color.white : Color.black)
                            .frame(width: 18, height: 18)
                            .overlay(Circle().stroke(AppColors.surfaceLight, lineWidth: 1))
                        Text(viewModel.sideToMove == .white ? "White" : "Black")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                }

                editorBlockButton(icon: "arrow.uturn.backward", label: "Undo") {
                    viewModel.undo()
                }
                .opacity(viewModel.canUndo ? 1 : 0.4)
                .disabled(!viewModel.canUndo)

                editorBlockButton(icon: "arrow.up.arrow.down", label: "Flip") {
                    viewModel.isFlipped.toggle()
                }
            }

            HStack(spacing: AppSpacing.sm) {
                editorBlockButton(icon: "trash", label: "Clear") {
                    viewModel.clearBoard()
                }

                editorBlockButton(icon: "arrow.counterclockwise", label: "Reset") {
                    viewModel.resetToDefault()
                }

                editorBlockButton(icon: "shuffle", label: "960") {
                    viewModel.shuffleChess960()
                }

                editorBlockButton(icon: "square.and.arrow.up", label: "Share") {
                    Analytics.shareOpened(source: "board_editor"); showShareSheet = true
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
    }

    private func editorBlockButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
    }

    private var editorFENBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(viewModel.currentFEN)
                .font(AppFonts.small)
                .foregroundStyle(AppColors.textMuted)
                .lineLimit(1)
            Spacer()
            Button {
                showFENInput = true
                fenInput = ""
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.accent)
            }
            Button {
                UIPasteboard.general.string = viewModel.currentFEN
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.accent)
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private var editorPlayButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            // Engine compatibility warning
            if !viewModel.isEngineCompatible {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppColors.inaccuracy)
                        .font(.system(size: 13))
                    Text("Engine analysis not available for this board")
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.inaccuracy)
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.md)
            }

            HStack(spacing: AppSpacing.sm) {
                Button {
                    if let error = viewModel.validatePlayable() {
                        validationError = error
                    } else {
                        fenToPlay = viewModel.currentFEN
                        Analytics.boardEditorUsed(action: "free_play", loadedFEN: viewModel.didLoadFEN)
                        navigateToFreePlay = true
                    }
                } label: {
                    Label("Free Play", systemImage: "play.fill")
                        .font(AppFonts.captionBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                }

                Button {
                    if let error = viewModel.validatePlayable() {
                        validationError = error
                    } else if !viewModel.isEngineCompatible {
                        validationError = "Engine analysis is not available for this board. Use Free Play instead."
                    } else {
                        fenToPlay = viewModel.currentFEN
                        Analytics.boardEditorUsed(action: "bot", loadedFEN: viewModel.didLoadFEN)
                        navigateToBotGame = true
                    }
                } label: {
                    Label("vs Bot", systemImage: "cpu")
                        .font(AppFonts.captionBold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(viewModel.isEngineCompatible ? AppColors.great : AppColors.surfaceLight)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                }

                Button { showRules = true } label: {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundStyle(AppColors.textMuted)
                        .padding(AppSpacing.md)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        HStack(spacing: AppSpacing.sm) {
            modeButton(.move, icon: "hand.draw.fill", label: "Move")
            modeButton(.place, icon: "plus.circle.fill", label: "Place")
            modeButton(.erase, icon: "eraser.fill", label: "Erase")
        }
        .padding(.horizontal, AppSpacing.md)
    }

    private func modeButton(_ mode: EditorMode, icon: String, label: String) -> some View {
        let isActive = viewModel.editorMode == mode
        return Button { viewModel.setMode(mode) } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 13))
                Text(label).font(AppFonts.captionBold)
            }
            .foregroundStyle(isActive ? .white : AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(isActive ? AppColors.accent : AppColors.surface)
            .clipShape(Capsule())
        }
    }

    // MARK: - Rules Sheet

    private var rulesSheet: some View {
        NavigationStack {
            List {
                Section {
                    Text("The board must meet these criteria for the engine to analyze it correctly.")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .listRowBackground(AppColors.background)
                }

                Section("Required") {
                    ruleRow(icon: "crown.fill", color: .white, text: "Exactly one white king")
                    ruleRow(icon: "crown.fill", color: .black, text: "Exactly one black king")
                    ruleRow(icon: "number", color: AppColors.accent, text: "Maximum 16 pieces per side")
                    ruleRow(icon: "number", color: AppColors.accent, text: "Maximum 8 pawns per side")
                    ruleRow(icon: "xmark.circle", color: AppColors.blunder, text: "No pawns on rank 1 or 8")
                }

                Section("Piece Limits (for engine analysis)") {
                    ruleRow(icon: "checkmark.shield", color: AppColors.best, text: "Queens: 1 + promoted pawns")
                    ruleRow(icon: "checkmark.shield", color: AppColors.best, text: "Rooks: 2 + promoted pawns")
                    ruleRow(icon: "checkmark.shield", color: AppColors.best, text: "Bishops: 2 + promoted pawns")
                    ruleRow(icon: "checkmark.shield", color: AppColors.best, text: "Knights: 2 + promoted pawns")
                    ruleRow(icon: "exclamationmark.triangle", color: AppColors.inaccuracy, text: "Extra pieces + pawns cannot exceed 8")
                }

                Section("Tips") {
                    ruleRow(icon: "lightbulb", color: AppColors.inaccuracy, text: "Set the correct side to move")
                    ruleRow(icon: "lightbulb", color: AppColors.inaccuracy, text: "Use 'Reset' for standard position")
                    ruleRow(icon: "shuffle", color: AppColors.accent, text: "Use 'Shuffle' for Chess960 position")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Board Rules")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showRules = false }
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func ruleRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon).foregroundStyle(color).frame(width: 20)
            Text(text).font(AppFonts.body).foregroundStyle(AppColors.textPrimary)
        }
        .listRowBackground(AppColors.surface)
    }

    // MARK: - Piece Palette

    private func piecePalette(pieces: [ChessPiece]) -> some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(pieces, id: \.assetName) { piece in
                let isSelected = viewModel.selectedPieceToPlace == piece
                Button { viewModel.selectPiece(piece) } label: {
                    Image(piece.assetName)
                        .resizable()
                        .frame(width: 36, height: 36)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSelected ? AppColors.accent.opacity(0.3) : Color.clear)
                                .stroke(isSelected ? AppColors.accent : Color.clear, lineWidth: 2)
                        )
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Editor Board View

struct EditorBoardView: View {
    let board: ChessBoard
    let pickedUpSquare: Square?
    let editorMode: EditorMode
    let flipped: Bool
    let onTapSquare: (Square) -> Void
    let onDragMove: (Square, Square) -> Void

    @State private var draggingSquare: Square?
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let squareSize = size / 8

            ZStack {
                ForEach(0..<8, id: \.self) { visualRank in
                    ForEach(0..<8, id: \.self) { visualFile in
                        let rank = flipped ? visualRank : 7 - visualRank
                        let file = flipped ? 7 - visualFile : visualFile
                        let square = Square(file: file, rank: rank)
                        let isLight = (file + rank) % 2 != 0
                        let isPickedUp = square == pickedUpSquare

                        Rectangle()
                            .fill(isPickedUp ? Color.yellow.opacity(0.5) : (isLight ? AppColors.boardLight : AppColors.boardDark))
                            .frame(width: squareSize, height: squareSize)
                            .position(x: CGFloat(visualFile) * squareSize + squareSize / 2,
                                      y: CGFloat(visualRank) * squareSize + squareSize / 2)
                            .onTapGesture { onTapSquare(square) }
                    }
                }

                ForEach(0..<8, id: \.self) { rank in
                    ForEach(0..<8, id: \.self) { file in
                        let square = Square(file: file, rank: rank)
                        if let piece = board.piece(at: square) {
                            let isDragging = draggingSquare == square
                            let vf = flipped ? 7 - file : file
                            let vr = flipped ? rank : 7 - rank
                            let baseX = CGFloat(vf) * squareSize + squareSize / 2
                            let baseY = CGFloat(vr) * squareSize + squareSize / 2

                            Image(piece.assetName)
                                .resizable()
                                .interpolation(.high)
                                .frame(width: squareSize * (isDragging ? 1.0 : 0.85),
                                       height: squareSize * (isDragging ? 1.0 : 0.85))
                                .offset(isDragging ? dragOffset : .zero)
                                .position(x: baseX, y: baseY)
                                .zIndex(isDragging ? 100 : 1)
                                .shadow(color: isDragging ? .black.opacity(0.3) : .clear, radius: 8)
                                .onTapGesture { onTapSquare(square) }
                                .gesture(
                                    editorMode == .move ?
                                    DragGesture(minimumDistance: 5)
                                        .onChanged { value in
                                            if draggingSquare == nil { draggingSquare = square }
                                            dragOffset = value.translation
                                        }
                                        .onEnded { value in
                                            let dropX = baseX + value.translation.width
                                            let dropY = baseY + value.translation.height
                                            let vf2 = Int(dropX / squareSize)
                                            let vr2 = Int(dropY / squareSize)
                                            if (0..<8).contains(vf2), (0..<8).contains(vr2) {
                                                let f = flipped ? 7 - vf2 : vf2
                                                let r = flipped ? vr2 : 7 - vr2
                                                let target = Square(file: f, rank: r)
                                                if target != square { onDragMove(square, target) }
                                            }
                                            draggingSquare = nil
                                            dragOffset = .zero
                                        }
                                    : nil
                                )
                        }
                    }
                }

                // Coordinates
                ZStack {
                    ForEach(0..<8, id: \.self) { vf in
                        let file = flipped ? 7 - vf : vf
                        let bottomRank = flipped ? 7 : 0
                        let isLight = (file + bottomRank) % 2 != 0
                        Text(String(Character(UnicodeScalar(97 + file)!)))
                            .font(.system(size: squareSize * 0.16, weight: .bold))
                            .foregroundStyle(isLight ? AppColors.boardDark : AppColors.boardLight)
                            .position(x: CGFloat(vf) * squareSize + squareSize - squareSize * 0.12,
                                      y: 8 * squareSize - squareSize * 0.12)
                            .allowsHitTesting(false)
                    }
                    ForEach(0..<8, id: \.self) { vr in
                        let rank = flipped ? vr : 7 - vr
                        let leftFile = flipped ? 7 : 0
                        let isLight = (leftFile + rank) % 2 != 0
                        Text("\(rank + 1)")
                            .font(.system(size: squareSize * 0.16, weight: .bold))
                            .foregroundStyle(isLight ? AppColors.boardDark : AppColors.boardLight)
                            .position(x: squareSize * 0.12, y: CGFloat(vr) * squareSize + squareSize * 0.14)
                            .allowsHitTesting(false)
                    }
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
