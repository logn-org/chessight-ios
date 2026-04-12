import SwiftUI

/// Play a new game with real-time analysis.
struct PlayView: View {
    var body: some View {
        AnalysisView(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    }
}

/// Interactive board with smooth piece animation and sounds.
struct InteractiveBoardView: View {
    let board: ChessBoard
    let selectedSquare: Square?
    let legalMoveTargets: [Square]
    let lastMove: (from: String, to: String)?
    var arrows: [PieceAnalysis.BoardArrow] = []
    var moveClassification: MoveClassification? = nil
    var showCoordinates: Bool = true
    var allowDragDrop: Bool = true
    let flipped: Bool
    let onTapSquare: (Square) -> Void

    /// Track the previous board state for animation
    @State private var animatingFrom: CGPoint?
    @State private var animatingTo: CGPoint?
    @State private var animatingPiece: ChessPiece?
    @State private var animationProgress: CGFloat = 1.0
    @State private var previousFEN: String = ""

    /// Drag state
    @State private var draggingSquare: Square?
    @State private var dragOffset: CGSize = .zero
    @State private var skipNextAnimation = false

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let squareSize = size / 8

            ZStack {
                // Squares
                boardSquares(squareSize: squareSize)

                // Static pieces (skip the animating piece's destination during animation)
                staticPieces(squareSize: squareSize)

                // Animating piece overlay
                if let piece = animatingPiece, let from = animatingFrom, let to = animatingTo {
                    let currentX = from.x + (to.x - from.x) * animationProgress
                    let currentY = from.y + (to.y - from.y) * animationProgress

                    Image(piece.assetName)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: squareSize * 0.85, height: squareSize * 0.85)
                        .position(x: currentX, y: currentY)
                        .zIndex(10)
                        .allowsHitTesting(false)
                }

                // Classification badge
                classificationBadge(squareSize: squareSize)

                // Arrows
                arrowOverlays(squareSize: squareSize)

                // Coordinates (file letters + rank numbers)
                if showCoordinates {
                    coordinateOverlay(squareSize: squareSize)
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
            .onChange(of: board.toFEN()) { oldFEN, newFEN in
                if !previousFEN.isEmpty && previousFEN != newFEN && !skipNextAnimation {
                    triggerMoveAnimation(squareSize: squareSize)
                }
                if skipNextAnimation {
                    skipNextAnimation = false
                }
                previousFEN = newFEN
            }
            .onAppear { previousFEN = board.toFEN() }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Move Animation

    private func triggerMoveAnimation(squareSize: CGFloat) {
        guard let lm = lastMove,
              let fromSq = Square(algebraic: lm.from),
              let toSq = Square(algebraic: lm.to),
              let piece = board.piece(at: toSq) else { return }

        let fromPt = squareCenter(fromSq, squareSize: squareSize)
        let toPt = squareCenter(toSq, squareSize: squareSize)

        // Set up animation
        animatingPiece = piece
        animatingFrom = fromPt
        animatingTo = toPt
        animationProgress = 0

        // Animate piece sliding with spring for natural feel
        withAnimation(.spring(duration: 0.2, bounce: 0.05)) {
            animationProgress = 1.0
        }

        // Clean up after animation — must wait for spring to fully settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.animatingPiece = nil
            self.animatingFrom = nil
            self.animatingTo = nil
            self.animationProgress = 1.0
        }
    }

    // MARK: - Board Squares

    private func boardSquares(squareSize: CGFloat) -> some View {
        ForEach(0..<8, id: \.self) { visualRank in
            ForEach(0..<8, id: \.self) { visualFile in
                let rank = flipped ? visualRank : 7 - visualRank
                let file = flipped ? 7 - visualFile : visualFile
                let square = Square(file: file, rank: rank)
                let isLight = (file + rank) % 2 != 0
                let isSelected = square == selectedSquare
                let isLegalTarget = legalMoveTargets.contains(square)
                let isLM = isLastMoveSquare(square)

                Rectangle()
                    .fill(squareColor(isLight: isLight, isSelected: isSelected, isLastMove: isLM))
                    .frame(width: squareSize, height: squareSize)
                    .overlay {
                        if isLegalTarget {
                            if board.piece(at: square) != nil {
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.black.opacity(0.3), lineWidth: 3)
                                    .frame(width: squareSize, height: squareSize)
                            } else {
                                Circle()
                                    .fill(Color.black.opacity(0.2))
                                    .frame(width: squareSize * 0.3)
                            }
                        }
                    }
                    .position(
                        x: CGFloat(visualFile) * squareSize + squareSize / 2,
                        y: CGFloat(visualRank) * squareSize + squareSize / 2
                    )
                    .onTapGesture { onTapSquare(square) }
                    .simultaneousGesture(
                        allowDragDrop && board.piece(at: square) != nil ?
                        DragGesture(minimumDistance: 12)
                            .onChanged { value in
                                if draggingSquare == nil {
                                    draggingSquare = square
                                    onTapSquare(square)
                                }
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                let vf = flipped ? 7 - square.file : square.file
                                let vr = flipped ? square.rank : 7 - square.rank
                                let baseX = CGFloat(vf) * squareSize + squareSize / 2
                                let baseY = CGFloat(vr) * squareSize + squareSize / 2
                                let dropX = baseX + value.translation.width
                                let dropY = baseY + value.translation.height
                                if let target = screenToSquare(x: dropX, y: dropY, squareSize: squareSize),
                                   target != square {
                                    skipNextAnimation = true
                                    onTapSquare(target)
                                }
                                draggingSquare = nil
                                dragOffset = .zero
                            }
                        : nil
                    )
            }
        }
    }

    // MARK: - Pieces

    private func staticPieces(squareSize: CGFloat) -> some View {
        ForEach(0..<8, id: \.self) { rank in
            ForEach(0..<8, id: \.self) { file in
                let square = Square(file: file, rank: rank)
                if let piece = board.piece(at: square) {
                    let isAnimatingTarget = animatingPiece != nil
                        && lastMove?.to == square.algebraic
                    let isDragging = draggingSquare == square

                    if !isAnimatingTarget {
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
                            .allowsHitTesting(isDragging) // Only intercept when actively dragging
                    }
                }
            }
        }
    }

    // MARK: - Classification Badge

    private func classificationBadge(squareSize: CGFloat) -> some View {
        Group {
            if let classification = moveClassification,
               classification != .none,
               let lastTo = lastMove?.to,
               let toSquare = Square(algebraic: lastTo) {
                let vf = flipped ? 7 - toSquare.file : toSquare.file
                let vr = flipped ? toSquare.rank : 7 - toSquare.rank
                Image(systemName: classification.iconName)
                    .font(.system(size: squareSize * 0.3, weight: .bold))
                    .foregroundStyle(classification.color)
                    .background(
                        Circle().fill(Color(hex: 0x272421))
                            .frame(width: squareSize * 0.35, height: squareSize * 0.35)
                    )
                    .position(
                        x: CGFloat(vf) * squareSize + squareSize - squareSize * 0.15,
                        y: CGFloat(vr) * squareSize + squareSize * 0.15
                    )
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Coordinates

    private func coordinateOverlay(squareSize: CGFloat) -> some View {
        ZStack {
            // File letters (a-h) along the bottom row
            ForEach(0..<8, id: \.self) { visualFile in
                let file = flipped ? 7 - visualFile : visualFile
                let bottomRank = flipped ? 7 : 0  // The rank at the bottom of the board
                let letter = String(Character(UnicodeScalar(97 + file)!))
                // Color contrasts with the square the label sits on
                let isLight = (file + bottomRank) % 2 != 0

                Text(letter)
                    .font(.system(size: squareSize * 0.16, weight: .bold))
                    .foregroundStyle(isLight ? AppColors.boardDark : AppColors.boardLight)
                    .position(
                        x: CGFloat(visualFile) * squareSize + squareSize - squareSize * 0.12,
                        y: 8 * squareSize - squareSize * 0.12
                    )
                    .allowsHitTesting(false)
            }

            // Rank numbers (1-8) along the left column
            ForEach(0..<8, id: \.self) { visualRank in
                let rank = flipped ? visualRank : 7 - visualRank
                let leftFile = flipped ? 7 : 0  // The file at the left of the board
                let number = "\(rank + 1)"
                let isLight = (leftFile + rank) % 2 != 0

                Text(number)
                    .font(.system(size: squareSize * 0.16, weight: .bold))
                    .foregroundStyle(isLight ? AppColors.boardDark : AppColors.boardLight)
                    .position(
                        x: squareSize * 0.12,
                        y: CGFloat(visualRank) * squareSize + squareSize * 0.14
                    )
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Arrows

    private func arrowOverlays(squareSize: CGFloat) -> some View {
        ForEach(Array(arrows.enumerated()), id: \.offset) { _, arrow in
            ArrowView(
                from: squareCenter(arrow.from, squareSize: squareSize),
                to: squareCenter(arrow.to, squareSize: squareSize),
                color: arrowColor(arrow.type),
                lineWidth: squareSize * (arrow.type == .bestMove ? 0.15 : 0.10)
            )
            .allowsHitTesting(false)
        }
    }

    // MARK: - Helpers

    private func screenToSquare(x: CGFloat, y: CGFloat, squareSize: CGFloat) -> Square? {
        let visualFile = Int(x / squareSize)
        let visualRank = Int(y / squareSize)
        guard (0..<8).contains(visualFile), (0..<8).contains(visualRank) else { return nil }
        let file = flipped ? 7 - visualFile : visualFile
        let rank = flipped ? visualRank : 7 - visualRank
        return Square(file: file, rank: rank)
    }

    private func squareCenter(_ square: Square, squareSize: CGFloat) -> CGPoint {
        let file = flipped ? 7 - square.file : square.file
        let rank = flipped ? square.rank : 7 - square.rank
        return CGPoint(x: CGFloat(file) * squareSize + squareSize / 2,
                       y: CGFloat(rank) * squareSize + squareSize / 2)
    }

    private func arrowColor(_ type: PieceAnalysis.ArrowType) -> Color {
        switch type {
        case .bestMove: return AppColors.bestMoveArrow
        case .defense: return AppColors.defenseArrow
        case .attack: return AppColors.attackArrow
        }
    }

    private func squareColor(isLight: Bool, isSelected: Bool, isLastMove: Bool) -> Color {
        if isSelected { return Color.yellow.opacity(0.5) }
        if isLastMove { return isLight ? AppColors.boardHighlightLight : AppColors.boardHighlightDark }
        return isLight ? AppColors.boardLight : AppColors.boardDark
    }

    private func isLastMoveSquare(_ square: Square) -> Bool {
        guard let lm = lastMove else { return false }
        return square.algebraic == lm.from || square.algebraic == lm.to
    }
}
