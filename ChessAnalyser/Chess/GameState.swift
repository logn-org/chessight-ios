import Foundation

/// Manages game replay — stepping through moves, tracking position at each step.
@Observable
final class GameState {
    private(set) var game: ParsedGame?
    private(set) var currentMoveIndex: Int = -1  // -1 = starting position
    private(set) var boards: [ChessBoard] = []   // Board state at each position (index 0 = start)

    var currentFEN: String {
        if currentMoveIndex < 0 {
            return boards.first?.toFEN() ?? ChessBoard().toFEN()
        }
        guard currentMoveIndex < boards.count - 1 else {
            return boards.last?.toFEN() ?? ChessBoard().toFEN()
        }
        return boards[currentMoveIndex + 1].toFEN()
    }

    var currentBoard: ChessBoard {
        let index = currentMoveIndex + 1
        guard index >= 0 && index < boards.count else {
            return boards.first ?? ChessBoard()
        }
        return boards[index]
    }

    var currentMove: GameMove? {
        guard let game = game,
              currentMoveIndex >= 0,
              currentMoveIndex < game.moves.count else { return nil }
        return game.moves[currentMoveIndex]
    }

    var totalMoves: Int {
        game?.moves.count ?? 0
    }

    var isAtStart: Bool { currentMoveIndex < 0 }
    var isAtEnd: Bool { currentMoveIndex >= totalMoves - 1 }

    var whiteName: String { game?.white ?? "White" }
    var blackName: String { game?.black ?? "Black" }
    var whiteElo: String? { game?.whiteElo }
    var blackElo: String? { game?.blackElo }
    var result: String { game?.result ?? "*" }

    // MARK: - Load Game

    func loadGame(_ parsedGame: ParsedGame) {
        game = parsedGame
        currentMoveIndex = -1
        rebuildBoards()
    }

    func loadPGN(_ pgn: String) throws {
        let trace = PerformanceTracer.tracePGNParse()
        if let validationError = PGNParser.validate(pgn) {
            trace?.stop()
            throw PGNParserError.invalidPGN(validationError)
        }
        let parsedGame = try PGNParser.parse(pgn)
        trace?.setValue(Int64(parsedGame.moves.count), forMetric: "move_count")
        trace?.stop()
        loadGame(parsedGame)
    }

    /// Load directly from a FEN (no PGN, no moves — just a position to explore).
    func loadFromFEN(_ fen: String) {
        let board = ChessBoard(fen: fen)
        let parsedGame = ParsedGame(
            id: "fen_\(fen.hashValue)",
            headers: ["FEN": fen, "SetUp": "1"],
            moves: [],
            pgn: ""
        )
        game = parsedGame
        currentMoveIndex = -1
        boards = [board]
    }

    // MARK: - Navigation

    func goToStart() {
        currentMoveIndex = -1
    }

    func goToEnd() {
        currentMoveIndex = totalMoves - 1
    }

    func goForward() {
        guard currentMoveIndex < totalMoves - 1 else { return }
        currentMoveIndex += 1
    }

    func goBack() {
        guard currentMoveIndex >= 0 else { return }
        currentMoveIndex -= 1
    }

    func goToMove(_ index: Int) {
        let clamped = max(-1, min(index, totalMoves - 1))
        currentMoveIndex = clamped
    }

    // MARK: - Board Rebuild

    private func rebuildBoards() {
        guard let game = game else {
            boards = [ChessBoard()]
            return
        }

        var board: ChessBoard
        if let fen = game.headers["FEN"], !fen.isEmpty {
            board = ChessBoard(fen: fen)
        } else {
            board = ChessBoard()
        }
        boards = [board]

        for move in game.moves {
            _ = board.makeMoveSAN(move.san)
            boards.append(board)
        }
    }

    // MARK: - Position Info

    func fenAtMove(_ index: Int) -> String {
        let boardIndex = index + 1
        guard boardIndex >= 0 && boardIndex < boards.count else {
            return boards.first?.toFEN() ?? ChessBoard().toFEN()
        }
        return boards[boardIndex].toFEN()
    }

    func fenBeforeMove(_ index: Int) -> String {
        guard index >= 0 && index < boards.count else {
            return boards.first?.toFEN() ?? ChessBoard().toFEN()
        }
        return boards[index].toFEN()
    }

    /// Calculate material difference (positive = white advantage)
    func materialDifference(at moveIndex: Int) -> Int {
        let board = moveIndex < 0 ? boards[0] : boards[min(moveIndex + 1, boards.count - 1)]
        return board.materialCount(for: .white) - board.materialCount(for: .black)
    }
}
