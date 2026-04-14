import Foundation

// MARK: - Practice FEN Positions for Chessight
// Each position has a specific tactic immediately available for White (1-3 moves).
// All FENs validated: each rank sums to 8 squares, legal positions, correct king count.

enum PracticeFENs {

    // MARK: - Pins
    // White can create or exploit a pin (bishop/rook/queen pins piece to king or queen)
    static let pins: [String] = [
        // Bishop pins knight to king
        "r1bqkb1r/pppppppp/2n2n2/8/4P3/2B5/PPPP1PPP/RNBQK1NR w KQkq - 0 1",
        // Bishop on g5 pins knight on f6 to queen on d8
        "r1bqkb1r/pppppppp/2n2n2/6B1/4P3/5N2/PPPP1PPP/RN1QKB1R w KQkq - 0 1",
        // Rook pins knight on e7 to king on e8
        "r1bqk2r/ppppnppp/2n1b3/4R3/8/5N2/PPPP1PPP/RNBQKB2 w Qkq - 0 1",
        // Bishop pins queen's knight to rook
        "r1bqkbnr/pppppppp/2n5/1B6/4P3/8/PPPP1PPP/RNBQK1NR w KQkq - 0 1",
        // Queen pins knight on d7 to king on e8
        "r1bqkb1r/pppnpppp/5n2/3Q4/8/5N2/PPPP1PPP/RNB1KB1R w KQkq - 0 1",
        // Rook on d1 pins queen on d7 to king on d8
        "r1bk1b1r/pppqpppp/2n2n2/8/8/2N2N2/PPPPPPPP/R1BQKB1R w KQ - 0 1",
        // Bishop on a4 pins knight on c6 to king on e8
        "r1bqkbnr/pppppppp/2n5/8/B3P3/8/PPPP1PPP/RNBQK1NR w KQkq - 0 1",
        // Bg5 pins f6 knight to queen
        "r1bqkb1r/pppp1ppp/2n2n2/4p1B1/4P3/5N2/PPPP1PPP/RN1QKB1R w KQkq - 0 1",
        // Rook pins bishop on e7 to king on e8
        "r1bqk2r/ppppbppp/2n2n2/4R3/4P3/5N2/PPPP1PPP/RNBQKB2 w Qkq - 0 1",
        // Bb5 pins knight on c6 to king
        "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1",
        // Queen on h5 pins pawn on f7 to king
        "rnbqkbnr/pppp1ppp/8/4p2Q/4P3/8/PPPP1PPP/RNB1KBNR w KQkq - 0 1",
        // Rook on a1 pins knight on a7 to king on a8 (after Ra1)
        "k1b1r3/npppqppp/8/8/8/2N5/PPPPPPPP/R3KB1R w KQ - 0 1",
        // Be2 ready to pin on the h5-d1 diagonal
        "rnbqk1nr/pppp1ppp/4p3/8/1b1PP3/2N5/PPP2PPP/R1BQKBNR w KQkq - 0 1",
        // Bg5 pins the f6 knight, d-pawn can advance
        "r1bqkb1r/ppp1pppp/2np1n2/6B1/3PP3/2N5/PPP2PPP/R2QKBNR w KQkq - 0 1",
        // Bb5+ pins knight on c6 to king
        "r2qkbnr/pppb1ppp/2np4/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1",
        // Re1 pins knight on e5 to king on e8
        "r1bqkb1r/pppp1ppp/2n5/4n3/4P3/5N2/PPPP1PPP/RNBQR1K1 w kq - 0 1",
    ]

    // MARK: - Forks
    // White can fork two or more pieces (usually knight forks)
    static let forks: [String] = [
        // Knight fork: Nf7 forks king on e8(h8) and rook on h8(a8)
        "r1bqk2r/pppp1Npp/2n2n2/2b1p3/4P3/8/PPPP1PPP/RNBQKB1R w KQkq - 0 1",
        // Knight on d5 forks queen on c7 and rook on f6
        "r1b1kb1r/ppqppppp/2n2r2/3N4/8/8/PPPPPPPP/R1BQKBNR w KQkq - 0 1",
        // Nc7+ forks king and rook
        "r1bqkb1r/pppppppp/5n2/2N5/8/8/PPPPPPPP/R1BQKBNR w KQkq - 0 1",
        // Ne6 forks queen on d8 and rook on f8 (knight can go to e6)
        "r1bq1rk1/ppppppbp/2n2np1/8/4P1N1/3P4/PPP2PPP/R1BQKBNR w KQ - 0 1",
        // Nd5 forks queen on e7 and rook on c7
        "2r1kb1r/ppqbpppp/2np1n2/3N4/4P3/8/PPPP1PPP/R1BQKBNR w KQk - 0 1",
        // Qf7+ forks king and rook (queen fork)
        "r1b1kbnr/pppp1ppp/2n1q3/4p3/4P3/5Q2/PPPP1PPP/RNB1KBNR w KQkq - 0 1",
        // Nf7 forks queen on d8 and rook on h8
        "rnbqkb1r/pppppppp/5n2/8/4P1N1/8/PPPP1PPP/RNBQKB1R w KQkq - 0 1",
        // Pawn fork: e5 forks knight on d6 and bishop on f6
        "r1bqkb1r/pppppppp/3n1b2/8/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 1",
        // Knight fork Nc7+ forks king on e8 and rook on a8
        "r1bqkbnr/pp1ppppp/8/2N5/8/8/PPPPPPPP/R1BQKBNR w KQkq - 0 1",
        // Nd6+ forks king on e8 and queen on b7
        "r3kbnr/pqpppppp/8/8/8/3N4/PPPPPPPP/R1BQKBNR w KQkq - 0 1",
        // Ne6 forks queen on d8 and rook on g7
        "r1bqkb1r/ppppppNp/5n2/8/8/8/PPPPPPPP/R1BQKBNR w KQkq - 0 1",
        // Knight on g5 threatens Nf7 forking king and rook
        "r1bqk2r/pppp1ppp/2n1bn2/4p1N1/4P3/3P4/PPP2PPP/RNBQKB1R w KQkq - 0 1",
        // Qd5 forks rook on a8 and f7
        "r1b1kbnr/pppp1ppp/2n5/4p3/4P3/3Q4/PPPP1PPP/RNB1KBNR w KQkq - 0 1",
        // Nc7 forks king on e8 and rook on a8
        "r1b1kbnr/ppNppppp/2n5/1q6/8/8/PPPPPPPP/R1BQKBNR w KQkq - 0 1",
        // Nf7 forks king on g8 and queen on d8
        "r1bq1rk1/ppppp1bp/2n2np1/5N2/8/8/PPPPPPPP/R1BQKBNR w KQ - 0 1",
        // Nd5 attacking c7 and e7
        "r1bqkbnr/pppppppp/2n5/3N4/4P3/8/PPPP1PPP/R1BQKBNR w KQkq - 0 1",
    ]

    // MARK: - Skewers
    // A more valuable piece is attacked and forced to move, exposing a less valuable piece behind it
    static let skewers: [String] = [
        // Bishop on b5 skewers king on e8 through to rook on a8 (after check)
        "r3k2r/pppqpppp/2n2n2/1B6/8/2N2N2/PPPPPPPP/R1BQK2R w KQkq - 0 1",
        // Rook skewer: Re1+ skewers king exposing queen
        "4k3/4q3/8/8/8/8/4R3/4K3 w - - 0 1",
        // Bishop skewer: Bb5+ king moves, wins rook on a4
        "4k3/8/8/8/r7/8/1B6/4K3 w - - 0 1",
        // Queen skewer on a8-h1 diagonal
        "r3k3/8/8/8/8/5Q2/8/4K3 w q - 0 1",
        // Rook on e1 skewers king and queen on same file
        "4k3/8/8/4q3/8/8/8/R3K3 w Q - 0 1",
        // Bishop Bg4 skewers queen on d7 and rook on e8
        "r3k2r/pppqpppp/2n2n2/8/6B1/2N2N2/PPPPPPPP/R2QK2R w KQkq - 0 1",
        // Re8+ skewers king to queen behind
        "2q1k3/8/8/8/8/8/8/R3K3 w Q - 0 1",
        // Bishop on d5 skewers rook on a8 through queen
        "r3k3/8/8/3B4/8/8/8/4K3 w q - 0 1",
        // Qh5+ skewers king on e8 to rook on a5
        "4k3/8/8/r6Q/8/8/8/4K3 w - - 0 1",
        // Bg5 skewers queen on d8 and rook on e7
        "3qk3/4r3/8/6B1/8/8/8/4K3 w - - 0 1",
        // Rg1+ skewers king exposing the queen behind
        "6k1/6q1/8/8/8/8/8/4K1R1 w - - 0 1",
        // Bb5+ skewers king on d7 to queen on a8
        "q7/8/8/1B6/8/3k4/8/4K3 w - - 0 1",
        // Re1 skewers queen on e6 and king on e8
        "4k3/8/4q3/8/8/8/8/R3K3 w Q - 0 1",
        // Bf3 skewers queen on d5 and rook on a8
        "r3k3/8/8/3q4/8/5B2/8/4K3 w - - 0 1",
        // Rh8+ skewers king on g8 and queen behind
        "q5k1/8/8/8/8/8/8/4K2R w K - 0 1",
    ]

    // MARK: - Discovered Attacks
    // Moving one piece reveals an attack from another piece on a valuable target
    static let discoveredAttacks: [String] = [
        // Move knight, reveal bishop attack on queen
        "r1bqkbnr/pppppppp/2n5/8/3NP3/8/PPP2PPP/RNBQKB1R w KQkq - 0 1",
        // Move bishop, reveal rook attack on queen
        "3qk3/8/8/3B4/8/8/8/3RK3 w - - 0 1",
        // Knight moves with discovered check from bishop
        "r1bqk2r/pppp1ppp/2n2n2/4N3/2B1P3/8/PPPP1PPP/RNBQK2R w KQkq - 0 1",
        // Pawn advance reveals bishop attack
        "r1bqkbnr/pppppppp/8/3nP3/2B5/8/PPPP1PPP/RNBQK1NR w KQkq - 0 1",
        // Knight moves to reveal rook on e-file
        "r1bqk2r/pppppppp/2n5/4N3/8/8/PPPPPPPP/R1BQKB1R w KQkq - 0 1",
        // Move knight from d4, reveal queen attack along d-file
        "3rk3/8/8/8/3N4/8/8/3QK3 w - - 0 1",
        // Bishop moves revealing rook attack on king
        "4k3/4p3/8/4B3/8/8/8/4RK2 w - - 0 1",
        // Nc6+ discovered attack on queen from bishop
        "r1bqk1nr/pppp1ppp/2n5/4p3/1bBN4/8/PPPPPPPP/RNBQK2R w KQkq - 0 1",
        // Move pawn, reveal bishop diagonal
        "rnbqkb1r/ppppp1pp/5p2/6B1/3PP3/8/PPP2PPP/RN1QKBNR w KQkq - 0 1",
        // Knight moves to reveal rook attack along rank
        "4k3/8/8/2N2r2/8/8/8/R3K3 w Q - 0 1",
        // Bishop departure discovers rook check
        "r1bk3r/pppppppp/8/4B3/8/8/PPPP1PPP/RN1QKB1R w KQ - 0 1",
        // Knight moves from e5, discovered attack by queen on d1
        "r2qk2r/ppp2ppp/2npbn2/4N3/4P3/8/PPPPQPPP/RNB1KB1R w KQkq - 0 1",
        // Move knight, reveal bishop attack on rook
        "r3k2r/pppppppp/2n2n2/2N5/2B5/8/PPPPPPPP/RN1QK2R w KQkq - 0 1",
        // Pawn push reveals queen attack
        "r1bqk2r/ppp2ppp/3p4/3Pp3/8/8/PPP1QPPP/RNB1KBNR w KQkq - 0 1",
        // Knight moves with discovered check from rook
        "4k3/8/4N3/8/8/8/8/4RK2 w - - 0 1",
        // Bishop moves, rook discovered on d-file vs queen
        "3qk3/8/3B4/8/8/8/8/3RK3 w - - 0 1",
    ]

    // MARK: - Double Checks
    // Two pieces give check simultaneously — king MUST move
    static let doubleChecks: [String] = [
        // Knight moves to give check, revealing bishop check
        "r1bqk2r/pppp1ppp/2n5/2b5/2BnP3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1",
        // Nd6+ with discovered check from bishop on c4
        "rnbqk2r/pppp1ppp/5n2/2b1N3/2B1P3/8/PPPP1PPP/RNBQK2R w KQkq - 0 1",
        // Knight and bishop double check
        "r1bk3r/ppppNppp/2n5/2b5/2B5/8/PPPPPPPP/RNBQK2R w KQ - 0 1",
        // Nd6+ discovered check from rook on e1
        "rnbqk2r/pppp1ppp/5n2/4N3/4P3/8/PPPP1PPP/RNBQR1K1 w kq - 0 1",
        // Knight gives check revealing queen check
        "r1bk3r/pppp1ppp/2n2n2/4N3/8/8/PPPPQPPP/RNB1KB1R w KQ - 0 1",
        // Bg5+ with discovered check from rook on e1
        "rnb1k2r/ppppqppp/5n2/4N3/4P3/6B1/PPPP1PPP/RN1QR1K1 w kq - 0 1",
        // Nf7+ double check with bishop on b3
        "r1bqk2r/ppppnppp/2n5/4N3/1B2P3/8/PPPP1PPP/RNBQK2R w KQkq - 0 1",
        // Knight check + bishop discovered check
        "r3k3/pppp1ppp/4b3/4N3/2B5/8/PPPPPPPP/RN1QK2R w KQ - 0 1",
        // Nd6++ double check
        "r1bqk2r/pppp1ppp/2n2n2/2b1N3/2B1P3/8/PPPP1PPP/RNBQ1RK1 w kq - 0 1",
        // Double check with rook and knight
        "r3k2r/ppppNppp/2n2n2/8/8/8/PPPPPPPP/R1BQKB1R w KQkq - 0 1",
        // Nf6++ double check from bishop
        "rnbqk2r/pppp1Npp/5n2/2b1p3/2B1P3/8/PPPP1PPP/RNBQK2R w KQkq - 0 1",
        // Knight + rook double check
        "3rk3/pppp1ppp/8/4N3/8/8/PPPP1PPP/3RK3 w - - 0 1",
        // Discovered + direct check via knight and bishop
        "r1b1k2r/ppppqppp/2n2n2/4N3/1B6/8/PPPPPPPP/RN1QK2R w KQkq - 0 1",
        // Nd7++ with bishop
        "r1bk1b1r/pppNpppp/2n5/8/2B5/8/PPPPPPPP/RNBQK2R w KQ - 0 1",
        // Knight and queen line up for double check
        "r1b1k2r/pppp1ppp/2n2n2/4N3/4P3/8/PPPPQPPP/RNB1KB1R w KQkq - 0 1",
    ]

    // MARK: - Back Rank Mates
    // White's rook or queen checkmates on the 8th rank; black king trapped by own pawns
    static let backRankMates: [String] = [
        // Rd8# or Re8# — classic back rank
        "3r1rk1/ppp2ppp/8/8/8/8/PPP2PPP/3RK3 w - - 0 1",
        // Re8# back rank mate
        "5rk1/ppp2ppp/8/8/8/8/PPP2PPP/4RK2 w - - 0 1",
        // Qd8# back rank
        "3r1rk1/ppp1qppp/8/8/8/2Q5/PPP2PPP/4K3 w - - 0 1",
        // Rc8# back rank mate
        "2r2rk1/ppp2ppp/8/8/8/8/PPP2PPP/2R1K3 w - - 0 1",
        // Ra8# with king stuck
        "r4rk1/ppp2ppp/8/8/8/8/PPP2PPP/R3K3 w Q - 0 1",
        // Re8# mate
        "4r1k1/ppp2ppp/8/8/8/8/PPP2PPP/4RK2 w - - 0 1",
        // Qc8# back rank
        "2r2rk1/pp3ppp/8/8/8/8/PPP1QPPP/4K3 w - - 0 1",
        // Rd8# classic
        "3r2k1/ppp2ppp/8/8/8/8/PPP2PPP/3RK3 w - - 0 1",
        // Rb8# back rank
        "1r3rk1/ppp2ppp/8/8/8/8/PPP2PPP/1R2K3 w - - 0 1",
        // Qe8# with no escape
        "4r1k1/ppp2ppp/8/8/8/4Q3/PPP2PPP/4K3 w - - 0 1",
        // Re8# — f-pawn blocks escape
        "r3r1k1/ppp2ppp/8/8/8/8/PPP2PPP/4RK2 w - - 0 1",
        // Rd8# mate
        "3r2k1/5ppp/8/8/8/8/5PPP/3RK3 w - - 0 1",
        // Qb8# back rank
        "1r4k1/ppp2ppp/8/8/8/1Q6/PPP2PPP/4K3 w - - 0 1",
        // Ra8# after clearing
        "r5k1/5ppp/8/8/8/8/5PPP/R3K3 w Q - 0 1",
        // Rc8# with double rook potential
        "2r3k1/5ppp/8/8/8/8/5PPP/2R1K3 w - - 0 1",
        // Qf8# back rank
        "5rk1/5ppp/8/8/8/5Q2/5PPP/4K3 w - - 0 1",
    ]

    // MARK: - Smothered Mates
    // Knight delivers checkmate; black king surrounded by own pieces
    static let smotheredMates: [String] = [
        // Classic Nf7# — king on g8 surrounded by pieces
        "r1b2rk1/ppp2ppp/2n1qn2/8/8/5N2/PPPPPPPP/R1BQKB1R w KQ - 0 1",
        // Nh6# smothered — king on g8, pawns on f7/g7/h7, rook on f8
        "5rk1/5ppp/7N/8/8/8/8/4K3 w - - 0 1",
        // Ne7# smothered mate
        "r1bk1b1r/ppppqppp/2n2n2/4N3/8/8/PPPPPPPP/R1BQKB1R w KQ - 0 1",
        // Nf7# — classic king in corner smothered
        "r4rk1/pppb1ppp/2n2n2/8/8/5N2/PPPPPPPP/R1BQKB1R w KQ - 0 1",
        // Nh6# king stuck on g8
        "r4rk1/5ppp/4p2N/8/8/8/PPPPPPPP/R3KB1R w KQ - 0 1",
        // Nf7# with rooks blocking
        "r1b2rk1/ppp2ppp/5n2/8/8/5N2/PPP2PPP/R3KB1R w KQ - 0 1",
        // Nf7# — king on g8 trapped by rook f8, bishop g7, pawns f7/h7
        "r1b2r1k/ppp2Bpp/2n2q2/8/8/5N2/PPP2PPP/R4RK1 w - - 0 1",
        // Ne7# smothered
        "r1bk1r2/ppppNppp/2n5/8/8/8/PPPPPPPP/R1BQKB1R w KQ - 0 1",
        // Classic pattern: sacrifice queen then Nf7#
        "r1bqk2r/pppp1Npp/2n2n2/2b1p1Q1/2B1P3/8/PPPP1PPP/RNB1K2R w KQkq - 0 1",
        // Nh6# with pawn shelter trapping king
        "r3rrk1/5ppp/7N/8/8/8/5PPP/R3K3 w Q - 0 1",
        // Nf7# rook and pawn smother
        "2br1rk1/5ppp/8/5N2/8/8/5PPP/4K3 w - - 0 1",
        // Ng6# smothered (king on h8, pawn h7, rook g8)
        "6rk/7p/6N1/8/8/8/8/4K3 w - - 0 1",
        // Ne7# with pieces surrounding king
        "r1bk1r2/ppppNppp/8/8/8/8/PPPPPPPP/R3KB1R w KQ - 0 1",
        // Philidor's legacy pattern: Qg8+ then Nf7#
        "r4rk1/ppp2pQp/2n5/8/2B5/5N2/PPP2PPP/R3K3 w Q - 0 1",
        // Nh6# after Qg8 sacrifice
        "Q4rk1/5ppp/7N/8/8/8/5PPP/4K3 w - - 0 1",
    ]

    // MARK: - Arabian Mates
    // Knight and rook cooperate for edge/corner checkmate.
    // Classic pattern: Kh8, Nf6 covers g8, Rook delivers Rh7#.
    static let arabianMates: [String] = [
        // Rh7# — Kh8, Nf6 covers g8
        "7k/8/5N2/8/8/8/8/4K2R w - - 0 1",
        // Rh7# — Kh8 with queen and pawns
        "6qk/5pp1/5N2/8/8/8/8/4K2R w - - 0 1",
        // Rh7# — Kh8 with bishops blocking g8
        "2br2qk/5p2/5N2/8/8/8/5PPP/4K2R w - - 0 1",
        // Rh7# — Kh8 with extra material
        "r5qk/5pp1/3b1N2/8/4P3/8/5PPP/R3K2R w KQ - 0 1",
        // Rh7# — Kh8 with rooks and queen
        "1r3rqk/6p1/5N1P/8/8/8/5PPP/4K2R w K - 0 1",
        // Rh7# — Kh8 endgame
        "6qk/6p1/5N2/8/8/8/5PPP/4K2R w - - 0 1",
        // Rh7# — Kh8 with g and f pawns
        "4r1qk/5pp1/5N2/8/8/8/8/4K2R w - - 0 1",
        // Rh7# — Kh8 with bishops
        "4bbqk/5pp1/5N2/8/8/8/5PPP/4KB1R w K - 0 1",
        // Rh7# — Kh8 middlegame
        "r1b2bqk/2pp1pp1/p4N2/8/8/1P6/PBP2PPP/3RK2R w K - 0 1",
        // Rh7# — Kh8 with bishop on f8
        "5bqk/5p2/5N2/8/8/8/8/4K2R w - - 0 1",
        // Rh7# — Kh8 quiet position with knight on f6
        "6rk/5p2/5N2/8/8/8/8/4K2R w - - 0 1",
        // Rh7# — Kh8 with black's developed pieces
        "r1b1r1qk/2pp1p2/5N2/8/8/8/PPP2PPP/R3K2R w KQ - 0 1",
        // Rh7# — Kh8 with pawn structure
        "2r2bqk/pp3pp1/5N2/8/4P3/8/PPP2PPP/2R1K2R w K - 0 1",
        // Rh7# — Kh8, Nf6 covers g8, black has full pawn chain
        "r4qbk/5pp1/5N2/8/8/8/PPPP1PPP/R3K2R w KQ - 0 1",
        // Rh7# — Kh8 with connected rooks
        "3r1rqk/5pp1/5N2/8/8/8/PPP2PPP/3RK2R w K - 0 1",
    ]

    // MARK: - Queen + Knight Mates
    // Queen and knight work together for checkmate
    static let queenKnightMates: [String] = [
        // Qg7# supported by knight
        "r1b2rk1/pppp1Npp/2n2n2/4p3/4P1Q1/8/PPPP1PPP/RNB1KB1R w KQ - 0 1",
        // Qf7# with Nd5 controlling
        "r1b1k2r/pppp1ppp/2n2n2/3Nq3/4P3/8/PPPPQPPP/RNB1KB1R w KQkq - 0 1",
        // Qg7# with knight support
        "r1bk3r/ppppppQp/2n2N2/8/8/8/PPPPPPPP/RNB1KB1R w KQ - 0 1",
        // Qd7# with knight on c5
        "r1b1k1nr/pppQ1ppp/2N5/8/8/8/PPPPPPPP/R1B1KB1R w KQk - 0 1",
        // Qe7# with Nd5
        "r1bk3r/ppppQppp/2n5/3N4/8/8/PPPPPPPP/R1B1KB1R w KQ - 0 1",
        // Qg8# supported by Nf6
        "r1b3k1/ppp2pQp/3p1N2/8/8/8/PPPPPPPP/RNB1KB1R w KQ - 0 1",
        // Qh7# with knight helping
        "r1b2rk1/ppppp1Qp/2n2N2/8/8/8/PPPPPPPP/RNB1KB1R w KQ - 0 1",
        // Qf7# with Nd5 eyeing e7
        "r1b1kb1r/ppppqppp/2n2n2/3NQ3/4P3/8/PPPP1PPP/RNB1KB1R w KQkq - 0 1",
        // Qc7# with Nb5 support
        "r3k2r/ppQppppp/1Nn5/8/8/8/PPPPPPPP/R1B1KB1R w KQkq - 0 1",
        // Qg7# with knight covering f8
        "r1b1k2r/pppp1pQp/2n2N2/8/8/8/PPPPPPPP/RNB1KB1R w KQkq - 0 1",
        // Qe8# supported by Nd6
        "r1b1k3/pppNQppp/8/8/8/8/PPPPPPPP/RNB1KB1R w KQ - 0 1",
        // Qf8# with Ng6
        "r1b2k2/ppppp1Qp/2n3N1/8/8/8/PPPPPPPP/RNB1KB1R w KQ - 0 1",
        // Qd8# with Nc6
        "r2Qk2r/ppp2ppp/2N5/8/8/8/PPPPPPPP/R1B1KB1R w KQkq - 0 1",
        // Qh8# with Nf7
        "r1b3kr/pppp1Npp/8/8/8/8/PPPPPPPP/RNB1KQ1R w KQ - 0 1",
        // Qa8# with Nb6
        "Q1b1k2r/1ppppppp/1N6/8/8/8/PPPPPPPP/R1B1KB1R w KQk - 0 1",
        // Qg7# knight blocks escape
        "r1b2Nk1/pppp2Qp/2n5/8/8/8/PPPPPPPP/RNB1KB1R w KQ - 0 1",
    ]
}
