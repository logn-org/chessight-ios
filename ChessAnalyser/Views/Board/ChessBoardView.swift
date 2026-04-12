import SwiftUI

struct ChessBoardView: View {
    let board: ChessBoard
    var lastMove: (from: String, to: String)?
    var arrows: [PieceAnalysis.BoardArrow] = []
    var flipped: Bool = false
    var moveClassification: MoveClassification?
    var onSwipeForward: (() -> Void)?
    var onSwipeBack: (() -> Void)?

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let squareSize = size / 8

            ZStack {
                boardGrid(squareSize: squareSize)
                piecesOverlay(squareSize: squareSize)

                // Arrows (defense first, then attack, then best move on top)
                ForEach(Array(arrows.enumerated()), id: \.offset) { _, arrow in
                    ArrowView(
                        from: squareCenter(arrow.from, squareSize: squareSize),
                        to: squareCenter(arrow.to, squareSize: squareSize),
                        color: arrowColor(arrow.type),
                        lineWidth: squareSize * (arrow.type == .bestMove ? 0.15 : 0.10)
                    )
                }

                // Classification badge
                if let classification = moveClassification,
                   let lastTo = lastMove?.to,
                   let toSquare = Square(algebraic: lastTo),
                   classification != .none {
                    classificationBadge(
                        classification: classification,
                        at: toSquare,
                        squareSize: squareSize
                    )
                }

                coordinateLabels(squareSize: squareSize)
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.width < -30 { onSwipeForward?() }
                        else if value.translation.width > 30 { onSwipeBack?() }
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func arrowColor(_ type: PieceAnalysis.ArrowType) -> Color {
        switch type {
        case .bestMove: return AppColors.bestMoveArrow
        case .defense: return AppColors.defenseArrow
        case .attack: return AppColors.attackArrow
        }
    }

    // MARK: - Board Grid

    private func boardGrid(squareSize: CGFloat) -> some View {
        Canvas { context, _ in
            for rank in 0..<8 {
                for file in 0..<8 {
                    let displayRank = flipped ? rank : 7 - rank
                    let displayFile = flipped ? 7 - file : file
                    let isLight = (displayFile + displayRank) % 2 != 0
                    let isHighlighted = isLastMoveSquare(file: displayFile, rank: displayRank)

                    let color: Color
                    if isHighlighted {
                        color = isLight ? AppColors.boardHighlightLight : AppColors.boardHighlightDark
                    } else {
                        color = isLight ? AppColors.boardLight : AppColors.boardDark
                    }

                    let rect = CGRect(
                        x: CGFloat(file) * squareSize,
                        y: CGFloat(rank) * squareSize,
                        width: squareSize, height: squareSize
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }

    // MARK: - Pieces

    private func piecesOverlay(squareSize: CGFloat) -> some View {
        ForEach(0..<8, id: \.self) { rank in
            ForEach(0..<8, id: \.self) { file in
                let square = Square(file: file, rank: rank)
                if let piece = board.piece(at: square) {
                    let position = squarePosition(square, squareSize: squareSize)
                    Image(piece.assetName)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: squareSize * 0.85, height: squareSize * 0.85)
                        .position(x: position.x + squareSize / 2,
                                  y: position.y + squareSize / 2)
                        .animation(.easeInOut(duration: 0.25), value: board.toFEN())
                }
            }
        }
    }

    // MARK: - Classification Badge

    private func classificationBadge(classification: MoveClassification, at square: Square, squareSize: CGFloat) -> some View {
        let pos = squarePosition(square, squareSize: squareSize)
        return Image(systemName: classification.iconName)
            .font(.system(size: squareSize * 0.3, weight: .bold))
            .foregroundStyle(classification.color)
            .background(
                Circle().fill(AppColors.surface)
                    .frame(width: squareSize * 0.35, height: squareSize * 0.35)
            )
            .position(
                x: pos.x + squareSize - squareSize * 0.15,
                y: pos.y + squareSize * 0.15
            )
    }

    // MARK: - Coordinate Labels

    private func coordinateLabels(squareSize: CGFloat) -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { file in
                let displayFile = flipped ? 7 - file : file
                let label = String(Character(UnicodeScalar(97 + displayFile)!))
                let isLight = flipped ? (7 - file + 0) % 2 != 0 : (file + 0) % 2 != 0
                Text(label)
                    .font(AppFonts.coordinate)
                    .foregroundStyle(isLight ? AppColors.boardDark : AppColors.boardLight)
                    .position(x: CGFloat(file) * squareSize + squareSize - 4, y: 8 * squareSize - 4)
            }
            ForEach(0..<8, id: \.self) { rank in
                let displayRank = flipped ? rank : 7 - rank
                let label = "\(displayRank + 1)"
                let isLight = (0 + displayRank) % 2 != 0
                Text(label)
                    .font(AppFonts.coordinate)
                    .foregroundStyle(isLight ? AppColors.boardDark : AppColors.boardLight)
                    .position(x: 4, y: CGFloat(rank) * squareSize + 6)
            }
        }
    }

    // MARK: - Helpers

    private func squarePosition(_ square: Square, squareSize: CGFloat) -> CGPoint {
        let file = flipped ? 7 - square.file : square.file
        let rank = flipped ? square.rank : 7 - square.rank
        return CGPoint(x: CGFloat(file) * squareSize, y: CGFloat(rank) * squareSize)
    }

    private func squareCenter(_ square: Square, squareSize: CGFloat) -> CGPoint {
        let pos = squarePosition(square, squareSize: squareSize)
        return CGPoint(x: pos.x + squareSize / 2, y: pos.y + squareSize / 2)
    }

    private func isLastMoveSquare(file: Int, rank: Int) -> Bool {
        guard let lastMove = lastMove else { return false }
        let sq = Square(file: file, rank: rank).algebraic
        return sq == lastMove.from || sq == lastMove.to
    }
}

// MARK: - Arrow View (chess.com style — wide shaft with clean arrowhead)

struct ArrowView: View {
    let from: CGPoint
    let to: CGPoint
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        Canvas { context, _ in
            let angle = atan2(to.y - from.y, to.x - from.x)
            let headLength = lineWidth * 2.5
            let headWidth = lineWidth * 2.2
            let shaftWidth = lineWidth * 0.7

            // Shorten the shaft so it doesn't poke through the arrowhead
            let shaftEnd = CGPoint(
                x: to.x - headLength * cos(angle),
                y: to.y - headLength * sin(angle)
            )

            let perpAngle = angle + .pi / 2

            // Shaft (wide rectangle)
            let shaftHalf = shaftWidth / 2
            var shaftPath = Path()
            shaftPath.move(to: CGPoint(
                x: from.x + shaftHalf * cos(perpAngle),
                y: from.y + shaftHalf * sin(perpAngle)
            ))
            shaftPath.addLine(to: CGPoint(
                x: shaftEnd.x + shaftHalf * cos(perpAngle),
                y: shaftEnd.y + shaftHalf * sin(perpAngle)
            ))
            shaftPath.addLine(to: CGPoint(
                x: shaftEnd.x - shaftHalf * cos(perpAngle),
                y: shaftEnd.y - shaftHalf * sin(perpAngle)
            ))
            shaftPath.addLine(to: CGPoint(
                x: from.x - shaftHalf * cos(perpAngle),
                y: from.y - shaftHalf * sin(perpAngle)
            ))
            shaftPath.closeSubpath()
            context.fill(shaftPath, with: .color(color))

            // Arrowhead (wide triangle)
            let headHalf = headWidth / 2
            var headPath = Path()
            headPath.move(to: to) // Tip
            headPath.addLine(to: CGPoint(
                x: shaftEnd.x + headHalf * cos(perpAngle),
                y: shaftEnd.y + headHalf * sin(perpAngle)
            ))
            headPath.addLine(to: CGPoint(
                x: shaftEnd.x - headHalf * cos(perpAngle),
                y: shaftEnd.y - headHalf * sin(perpAngle)
            ))
            headPath.closeSubpath()
            context.fill(headPath, with: .color(color))
        }
    }
}
