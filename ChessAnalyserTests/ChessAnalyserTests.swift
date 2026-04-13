import XCTest
@testable import ChessAnalyser

final class PGNParserTests: XCTestCase {

    func testParseHeaders() {
        let pgn = """
        [Event "Live Chess"]
        [Site "Chess.com"]
        [White "player1"]
        [Black "player2"]
        [Result "1-0"]

        1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 1-0
        """

        let headers = PGNParser.parseHeaders(pgn)
        XCTAssertEqual(headers["Event"], "Live Chess")
        XCTAssertEqual(headers["White"], "player1")
        XCTAssertEqual(headers["Black"], "player2")
        XCTAssertEqual(headers["Result"], "1-0")
    }

    func testExtractMoveText() {
        let pgn = """
        [Event "Test"]
        [White "W"]
        [Black "B"]
        [Result "1-0"]

        1. e4 e5 2. Nf3 Nc6 1-0
        """

        let moveText = PGNParser.extractMoveText(pgn)
        XCTAssertFalse(moveText.contains("["))
        XCTAssertFalse(moveText.contains("1-0"))
        XCTAssertTrue(moveText.contains("e4"))
    }

    func testParseMoveText() {
        let moveText = "1. e4 e5 2. Nf3 Nc6 3. Bb5 a6"
        let moves = PGNParser.parseMoveText(moveText)
        XCTAssertEqual(moves, ["e4", "e5", "Nf3", "Nc6", "Bb5", "a6"])
    }

    func testValidatePGN_ValidGame() {
        let pgn = """
        [Event "Test"]
        [Result "1-0"]

        1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 1-0
        """
        XCTAssertNil(PGNParser.validate(pgn), "Valid PGN should return nil")
    }

    func testValidatePGN_InvalidAmbiguousRookMove() {
        // The old Kasparov PGN had "Re1" instead of "Rhe1" — ambiguous with two rooks
        let pgn = """
        [Event "Hoogovens A Tournament"]
        [White "Garry Kasparov"]
        [Black "Veselin Topalov"]
        [Result "1-0"]

        1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. Be3 Bg7 5. Qd2 c6 6. f3 b5 7. Nge2 Nbd7 8. Bh6 Bxh6 9. Qxh6 Bb7 10. a3 e5 11. O-O-O Qe7 12. Kb1 a6 13. Nc1 O-O-O 14. Nb3 exd4 15. Rxd4 c5 16. Rd1 Nb6 17. g3 Kb8 18. Na5 Ba8 19. Bh3 d5 20. Qf4+ Ka7 21. Re1 d4 22. Nd5 Nbxd5 23. exd5 Qd6 1-0
        """
        let result = PGNParser.validate(pgn)
        XCTAssertNotNil(result, "Ambiguous 'Re1' should be caught as invalid")
    }

    func testValidatePGN_CorrectKasparov() {
        let pgn = """
        [Event "Hoogovens A Tournament"]
        [White "Garry Kasparov"]
        [Black "Veselin Topalov"]
        [Result "1-0"]

        1. e4 d6 2. d4 Nf6 3. Nc3 g6 4. Be3 Bg7 5. Qd2 c6 6. f3 b5 7. Nge2 Nbd7 8. Bh6 Bxh6 9. Qxh6 Bb7 10. a3 e5 11. O-O-O Qe7 12. Kb1 a6 13. Nc1 O-O-O 14. Nb3 exd4 15. Rxd4 c5 16. Rd1 Nb6 17. g3 Kb8 18. Na5 Ba8 19. Bh3 d5 20. Qf4+ Ka7 21. Rhe1 d4 22. Nd5 Nbxd5 23. exd5 Qd6 24. Rxd4 cxd4 25. Re7+ Kb6 26. Qxd4+ Kxa5 27. b4+ Ka4 28. Qc3 Qxd5 29. Ra7 Bb7 30. Rxb7 Qc4 31. Qxf6 Kxa3 32. Qxa6+ Kxb4 33. c3+ Kxc3 34. Qa1+ Kd2 35. Qb2+ Kd1 36. Bf1 Rd2 37. Rd7 Rxd7 38. Bxc4 bxc4 39. Qxh8 Rd3 40. Qa8 c3 41. Qa4+ Ke1 42. f4 f5 43. Kc1 Rd2 44. Qa7 1-0
        """
        XCTAssertNil(PGNParser.validate(pgn), "Correct Kasparov PGN should be valid")
    }

    func testValidatePGN_OperaGame() {
        let result = PGNParser.validate(SampleGames.operaGame)
        XCTAssertNil(result, "Opera Game PGN should be valid but got: \(result ?? "")")
    }

    func testValidatePGN_AllSampleGames() {
        for sample in SampleGames.all {
            let result = PGNParser.validate(sample.pgn)
            XCTAssertNil(result, "\(sample.name) PGN is invalid: \(result ?? "")")
        }
    }

    func testIsValidSAN() {
        XCTAssertTrue(PGNParser.isValidSAN("e4"))
        XCTAssertTrue(PGNParser.isValidSAN("Nf3"))
        XCTAssertTrue(PGNParser.isValidSAN("Bb5"))
        XCTAssertTrue(PGNParser.isValidSAN("O-O"))
        XCTAssertTrue(PGNParser.isValidSAN("O-O-O"))
        XCTAssertTrue(PGNParser.isValidSAN("exd5"))
        XCTAssertTrue(PGNParser.isValidSAN("Qxd7+"))
        XCTAssertTrue(PGNParser.isValidSAN("e8=Q"))
        XCTAssertFalse(PGNParser.isValidSAN(""))
        XCTAssertFalse(PGNParser.isValidSAN("1."))
    }
}

final class ChessBoardTests: XCTestCase {

    func testStartingPosition() {
        let board = ChessBoard()
        let fen = board.toFEN()
        XCTAssertEqual(fen, "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    }

    func testFENParsing() {
        let fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
        let board = ChessBoard(fen: fen)
        XCTAssertEqual(board.toFEN(), fen)
    }

    func testMakeMovePawnE4() {
        var board = ChessBoard()
        let result = board.makeMoveSAN("e4")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.piece, .pawn)
        XCTAssertEqual(result?.from.algebraic, "e2")
        XCTAssertEqual(result?.to.algebraic, "e4")
    }

    func testMakeMoveKnightF3() {
        var board = ChessBoard()
        _ = board.makeMoveSAN("e4")
        _ = board.makeMoveSAN("e5")
        let result = board.makeMoveSAN("Nf3")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.piece, .knight)
        XCTAssertEqual(result?.from.algebraic, "g1")
        XCTAssertEqual(result?.to.algebraic, "f3")
    }

    func testCastling() {
        // Setup a position where white can castle kingside
        let fen = "r1bqk2r/ppppbppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4"
        var board = ChessBoard(fen: fen)
        let result = board.makeMoveSAN("O-O")
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.isCastling ?? false)
    }

    func testBothSidesCanCastle() {
        // Both sides have clear kingside, both should be able to O-O
        let fen = "r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1"
        var board = ChessBoard(fen: fen)

        // White castles kingside
        let whiteResult = board.makeMoveSAN("O-O")
        XCTAssertNotNil(whiteResult, "White should be able to castle")
        XCTAssertTrue(whiteResult?.isCastling ?? false)

        // Black should still have castling rights
        XCTAssertTrue(board.castlingRights.contains(.blackKingside), "Black kingside rights should remain")
        XCTAssertTrue(board.castlingRights.contains(.blackQueenside), "Black queenside rights should remain")

        // Black castles kingside
        let blackResult = board.makeMoveSAN("O-O")
        XCTAssertNotNil(blackResult, "Black should be able to castle after white castled")
        XCTAssertTrue(blackResult?.isCastling ?? false)
    }

    func testBothSidesCanCastleQueenside() {
        let fen = "r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1"
        var board = ChessBoard(fen: fen)

        let whiteResult = board.makeMoveSAN("O-O-O")
        XCTAssertNotNil(whiteResult, "White should be able to castle queenside")

        let blackResult = board.makeMoveSAN("O-O-O")
        XCTAssertNotNil(blackResult, "Black should be able to castle queenside after white castled")
    }

    func testInsufficientMaterial_KingVsKing() {
        let board = ChessBoard(fen: "8/8/4k3/8/8/4K3/8/8 w - - 0 1")
        XCTAssertTrue(board.isInsufficientMaterial(), "K vs K is insufficient")
    }

    func testInsufficientMaterial_KingBishopVsKing() {
        let board = ChessBoard(fen: "8/8/4k3/8/8/4K3/3B4/8 w - - 0 1")
        XCTAssertTrue(board.isInsufficientMaterial(), "K+B vs K is insufficient")
    }

    func testInsufficientMaterial_KingKnightVsKing() {
        let board = ChessBoard(fen: "8/8/4k3/8/8/4K3/3N4/8 w - - 0 1")
        XCTAssertTrue(board.isInsufficientMaterial(), "K+N vs K is insufficient")
    }

    func testInsufficientMaterial_KingBishopVsKingBishopSameColor() {
        // Both bishops on light squares (c1=dark, f4=dark → use light: d3=light, e6=light)
        let board = ChessBoard(fen: "8/8/4kb2/8/8/3BK3/8/8 w - - 0 1")
        // d3: file=3,rank=2 → 3+2=5 odd=light; f6: file=5,rank=5 → 5+5=10 even=dark
        // Need same color. Let's use c4 (2+3=5 light) and f7 (5+6=11 light)
        let board2 = ChessBoard(fen: "8/5b2/4k3/8/2B5/4K3/8/8 w - - 0 1")
        XCTAssertTrue(board2.isInsufficientMaterial(), "K+B vs K+B same color bishops is insufficient")
    }

    func testSufficientMaterial_KingRookVsKing() {
        let board = ChessBoard(fen: "8/8/4k3/8/8/4K3/3R4/8 w - - 0 1")
        XCTAssertFalse(board.isInsufficientMaterial(), "K+R vs K is sufficient")
    }

    func testSufficientMaterial_KingPawnVsKing() {
        let board = ChessBoard(fen: "8/8/4k3/8/8/4K3/3P4/8 w - - 0 1")
        XCTAssertFalse(board.isInsufficientMaterial(), "K+P vs K is sufficient")
    }

    func testMaterialCount() {
        let board = ChessBoard()
        // Starting position: Q(9) + 2R(10) + 2B(6) + 2N(6) + 8P(8) = 39
        XCTAssertEqual(board.materialCount(for: .white), 39)
        XCTAssertEqual(board.materialCount(for: .black), 39)
    }
}

final class SquareTests: XCTestCase {

    func testAlgebraic() {
        let sq = Square(file: 0, rank: 0)
        XCTAssertEqual(sq.algebraic, "a1")

        let sq2 = Square(file: 4, rank: 3)
        XCTAssertEqual(sq2.algebraic, "e4")

        let sq3 = Square(file: 7, rank: 7)
        XCTAssertEqual(sq3.algebraic, "h8")
    }

    func testFromAlgebraic() {
        let sq = Square(algebraic: "e4")
        XCTAssertNotNil(sq)
        XCTAssertEqual(sq?.file, 4)
        XCTAssertEqual(sq?.rank, 3)
    }

    func testIsLight() {
        let a1 = Square(file: 0, rank: 0)
        XCTAssertFalse(a1.isLight) // a1 is dark

        let a2 = Square(file: 0, rank: 1)
        XCTAssertTrue(a2.isLight) // a2 is light
    }
}

final class UCIProtocolTests: XCTestCase {

    func testParseInfoLine() {
        let line = "info depth 18 seldepth 24 multipv 1 score cp 35 nodes 1234567 nps 1000000 time 1234 pv e2e4 e7e5 g1f3"
        let info = UCIParser.parseInfoLine(line)
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.depth, 18)
        XCTAssertEqual(info?.score, 35)
        XCTAssertEqual(info?.multipv, 1)
        XCTAssertEqual(info?.pv, ["e2e4", "e7e5", "g1f3"])
    }

    func testParseMateScore() {
        let line = "info depth 20 score mate 3 pv e2e4"
        let info = UCIParser.parseInfoLine(line)
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.mate, 3)
    }

    func testParseBestMove() {
        let result = UCIParser.parseLine("bestmove e2e4 ponder e7e5")
        if case .bestMove(let move, let ponder) = result {
            XCTAssertEqual(move, "e2e4")
            XCTAssertEqual(ponder, "e7e5")
        } else {
            XCTFail("Expected bestMove")
        }
    }
}

final class MoveClassifierTests: XCTestCase {

    func testExpectedPointsEqual() {
        let eval = EngineEval(score: 0, mate: nil, depth: 18, pv: [], multipv: 1)
        let wp = MoveClassifier.expectedPoints(eval, sideToMoveIsWhite: true, forWhite: true)
        XCTAssertEqual(wp, 0.5, accuracy: 0.01) // Equal position = 50%
    }

    func testExpectedPointsWinning() {
        // Score +300 from white's perspective (white to move)
        let eval = EngineEval(score: 300, mate: nil, depth: 18, pv: [], multipv: 1)
        let wp = MoveClassifier.expectedPoints(eval, sideToMoveIsWhite: true, forWhite: true)
        XCTAssertTrue(wp > 0.6) // +3.0 should be >60% for white
    }

    func testExpectedPointsMate() {
        // Score mate 3 from white's perspective (white to move, white mates)
        let eval = EngineEval(score: 0, mate: 3, depth: 18, pv: [], multipv: 1)
        let wp = MoveClassifier.expectedPoints(eval, sideToMoveIsWhite: true, forWhite: true)
        XCTAssertTrue(wp > 0.99) // White mates = ~100% for white
    }

    func testPointsLossSmall() {
        // White moves, before: +0.50 (white to move), after: +0.40 (now black to move, from black's perspective)
        // After black to move +40 means black has +40 = white has -40 ... actually this test needs rethinking.
        // Let's test: white has +50 (white to move). White plays a move. Now black to move, engine says -40 (black's perspective = +40 for white).
        let before = EngineEval(score: 50, mate: nil, depth: 18, pv: [], multipv: 1)
        let after = EngineEval(score: -40, mate: nil, depth: 18, pv: [], multipv: 1) // black to move, -40 = white +40
        let loss = MoveClassifier.expectedPointsLoss(before: before, after: after, isWhite: true)
        XCTAssertTrue(loss < 0.02) // Small eval drop (50→40 for white)
    }

    func testPointsLossBlunder() {
        // White has +200 (white to move). White blunders. Now black to move, engine says +500 for black.
        let before = EngineEval(score: 200, mate: nil, depth: 18, pv: [], multipv: 1)
        let after = EngineEval(score: 500, mate: nil, depth: 18, pv: [], multipv: 1) // black to move, +500 = black winning
        let loss = MoveClassifier.expectedPointsLoss(before: before, after: after, isWhite: true)
        XCTAssertTrue(loss > 0.20) // Going from +2 white to +5 black = huge loss
    }

    func testAccuracyCalculation() {
        let accuracy = MoveClassifier.calculateAccuracy(averageCPLoss: 0)
        XCTAssertEqual(accuracy, 100.0, accuracy: 1.0)

        let lowAccuracy = MoveClassifier.calculateAccuracy(averageCPLoss: 100)
        XCTAssertTrue(lowAccuracy < 50)
    }
}

// MARK: - Game ID Extraction Tests

final class GameIdExtractionTests: XCTestCase {

    // Direct URLs
    func testExtractGameId_LiveGame() {
        let id = ChessComGameResolver.extractGameId(from: "https://www.chess.com/game/live/123456789")
        XCTAssertEqual(id, "123456789")
    }

    func testExtractGameId_DailyGame() {
        let id = ChessComGameResolver.extractGameId(from: "https://www.chess.com/game/daily/987654321")
        XCTAssertEqual(id, "987654321")
    }

    func testExtractGameId_AnalysisLink() {
        let id = ChessComGameResolver.extractGameId(from: "https://www.chess.com/analysis/game/live/123456789")
        XCTAssertEqual(id, "123456789")
    }

    func testExtractGameId_WithoutWWW() {
        let id = ChessComGameResolver.extractGameId(from: "https://chess.com/game/live/123456789")
        XCTAssertEqual(id, "123456789")
    }

    // Link embedded in text
    func testExtractGameId_LinkInText() {
        let text = "Check out this game https://www.chess.com/game/live/123456789 it was amazing!"
        let id = ChessComGameResolver.extractGameId(from: text)
        XCTAssertEqual(id, "123456789")
    }

    func testExtractGameId_LinkInMultilineText() {
        let text = """
        I just played an amazing game!
        https://www.chess.com/game/live/555666777
        What do you think?
        """
        let id = ChessComGameResolver.extractGameId(from: text)
        XCTAssertEqual(id, "555666777")
    }

    // Invalid inputs
    func testExtractGameId_NotChessCom() {
        let id = ChessComGameResolver.extractGameId(from: "https://lichess.org/game/12345")
        XCTAssertNil(id)
    }

    func testExtractGameId_NoGameId() {
        let id = ChessComGameResolver.extractGameId(from: "https://www.chess.com/member/player1")
        XCTAssertNil(id)
    }

    func testExtractGameId_EmptyString() {
        let id = ChessComGameResolver.extractGameId(from: "")
        XCTAssertNil(id)
    }

    func testExtractGameId_PlainText() {
        let id = ChessComGameResolver.extractGameId(from: "Just some random text about chess")
        XCTAssertNil(id)
    }
}

// MARK: - SharedContent Parsing Tests

final class SharedContentTests: XCTestCase {

    func testParse_DirectChessComLink() {
        let result = SharedContent.parse("https://www.chess.com/game/live/123456789")
        if case .chessComLink(let gameId) = result {
            XCTAssertEqual(gameId, "123456789")
        } else {
            XCTFail("Expected chessComLink, got \(result)")
        }
    }

    func testParse_ChessComLinkInShareText() {
        let text = "Check out this chess game I just played on Chess.com! https://www.chess.com/game/live/123456789"
        let result = SharedContent.parse(text)
        if case .chessComLink(let gameId) = result {
            XCTAssertEqual(gameId, "123456789")
        } else {
            XCTFail("Expected chessComLink, got \(result)")
        }
    }

    func testParse_PGNText() {
        let pgn = "[Event \"Test\"]\n[White \"Player1\"]\n[Black \"Player2\"]\n\n1. e4 e5 2. Nf3 Nc6 1-0"
        let result = SharedContent.parse(pgn)
        if case .pgn(let text) = result {
            XCTAssertTrue(text.contains("e4"))
        } else {
            XCTFail("Expected pgn, got \(result)")
        }
    }

    func testParse_PGNWithMoveNumbers() {
        let result = SharedContent.parse("1. e4 e5 2. Nf3 Nc6 3. Bb5 a6")
        if case .pgn = result {
            // Good — detected as PGN
        } else {
            XCTFail("Expected pgn, got \(result)")
        }
    }

    func testParse_UnknownText() {
        let result = SharedContent.parse("Hello world, nothing about games here")
        if case .unknown = result {
            // Good — not recognized
        } else {
            XCTFail("Expected unknown, got \(result)")
        }
    }

    func testParse_ChessComLinkWithSurroundingText() {
        // Real share sheet text from chess.com app
        let text = "I won this chess game! 🎉 https://www.chess.com/game/live/987654321 #chess #chesscom"
        let result = SharedContent.parse(text)
        if case .chessComLink(let gameId) = result {
            XCTAssertEqual(gameId, "987654321")
        } else {
            XCTFail("Expected chessComLink, got \(result)")
        }
    }

    func testParse_AnalysisLinkInText() {
        let text = "Look at the analysis: https://www.chess.com/analysis/game/live/111222333"
        let result = SharedContent.parse(text)
        if case .chessComLink(let gameId) = result {
            XCTAssertEqual(gameId, "111222333")
        } else {
            XCTFail("Expected chessComLink, got \(result)")
        }
    }
}

// MARK: - TCN Decoder Tests

final class TCNDecoderTests: XCTestCase {

    func testDecodeSingleMove() {
        // "mc" = e2e4 (e=4, c=2 → from=12 (e2), to=28 (e4))
        // TCN: 'a'=0...'h'=7 for files, rows are *8
        // Actually let's test with known TCN from chess.com
        // "lN" in TCN = e2-e4: 'l'=index 11 (d2), 'N'=index 27 (d4)
        let moves = TCNDecoder.decode("mC")
        XCTAssertFalse(moves.isEmpty, "Should decode at least one move")
        XCTAssertNotNil(moves.first?.from)
        XCTAssertNotNil(moves.first?.to)
    }

    func testDecodeMultipleMoves() {
        // A typical opening sequence in TCN
        let tcn = "mCYKbsSMvr"  // Several moves
        let moves = TCNDecoder.decode(tcn)
        XCTAssertEqual(moves.count, 5, "5 pairs = 5 moves")
        for move in moves {
            XCTAssertNotNil(move.from, "Regular moves should have from square")
            XCTAssertFalse(move.to.isEmpty, "All moves should have to square")
        }
    }

    func testDecodeEmptyString() {
        let moves = TCNDecoder.decode("")
        XCTAssertTrue(moves.isEmpty)
    }

    func testDecodeOddLength() {
        // Odd-length TCN should just ignore the trailing character
        let moves = TCNDecoder.decode("mC0")
        XCTAssertEqual(moves.count, 1)
    }

    func testMoveSquaresAreValidAlgebraic() {
        let tcn = "mCYKbsSM"
        let moves = TCNDecoder.decode(tcn)
        let validFiles: Set<Character> = ["a","b","c","d","e","f","g","h"]
        let validRanks: Set<Character> = ["1","2","3","4","5","6","7","8"]
        for move in moves {
            if let from = move.from {
                XCTAssertTrue(validFiles.contains(from.first!), "File should be a-h: \(from)")
                XCTAssertTrue(validRanks.contains(from.last!), "Rank should be 1-8: \(from)")
            }
            XCTAssertTrue(validFiles.contains(move.to.first!), "File should be a-h: \(move.to)")
            XCTAssertTrue(validRanks.contains(move.to.last!), "Rank should be 1-8: \(move.to)")
        }
    }
}
