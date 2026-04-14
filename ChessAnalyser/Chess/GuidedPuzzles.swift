import Foundation

/// Guided puzzles — each has a starting FEN and a solution PGN.
/// User must play the correct moves, opponent auto-responds.
enum GuidedPuzzles {

    // MARK: - Tactics

    static let pins: [GuidedPuzzle] = [
        GuidedPuzzle(name: "Bishop Pin to King", description: "Pin the knight to the king with your bishop", fen: "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1", pgn: "1. Bb5"),
        GuidedPuzzle(name: "Rook Pin on File", description: "Use the rook to pin the piece to the king", fen: "r2qk2r/ppp2ppp/2n1bn2/3pp3/8/2NP1N2/PPP1PPPP/R1BQK2R w KQkq - 0 1", pgn: "1. Bg5"),
        GuidedPuzzle(name: "Queen Pin", description: "Pin the defender with your queen", fen: "rn1qkbnr/ppp1pppp/8/3p4/4P1b1/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 1", pgn: "1. Qb3"),
        GuidedPuzzle(name: "Pin and Win Material", description: "Pin the piece then capture it", fen: "r1bqkb1r/ppppnppp/5n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1", pgn: "1. Ng5 d5 2. Bxd5"),
        GuidedPuzzle(name: "Absolute Pin", description: "The pinned piece cannot move at all", fen: "rnbqk2r/pppp1ppp/4pn2/8/1bPP4/2N5/PP2PPPP/R1BQKBNR w KQkq - 0 1", pgn: "1. Bd2"),
    ]

    static let forks: [GuidedPuzzle] = [
        GuidedPuzzle(name: "Knight Fork", description: "Fork the king and queen with your knight", fen: "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2NP1N2/PPP2PPP/R1BQK2R w KQkq - 0 1", pgn: "1. Nd5 Nxd5 2. Bxd5"),
        GuidedPuzzle(name: "Royal Fork", description: "Fork the king and queen", fen: "r2qk2r/ppp2ppp/2np1n2/2b1p3/2B1P1b1/3P1N2/PPP2PPP/RNBQ1RK1 w kq - 0 1", pgn: "1. Bxf7+ Kf8 2. Bb3"),
        GuidedPuzzle(name: "Pawn Fork", description: "Fork two pieces with a pawn", fen: "rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 1", pgn: "1. exd5 Qxd5 2. Nc3"),
        GuidedPuzzle(name: "Queen Fork", description: "Attack two pieces at once with the queen", fen: "r1bqkbnr/pppppppp/2n5/8/3PP3/8/PPP2PPP/RNBQKBNR w KQkq - 0 1", pgn: "1. d5 Nb8 2. Qd4"),
        GuidedPuzzle(name: "Bishop Fork", description: "Fork rook and knight with your bishop", fen: "rnb1kbnr/pppppppp/8/8/4q3/2N5/PPPPPPPP/R1BQKBNR w KQkq - 0 1", pgn: "1. Nd5"),
    ]

    static let skewers: [GuidedPuzzle] = [
        GuidedPuzzle(name: "Bishop Skewer", description: "Attack the king to win the rook behind", fen: "4k3/8/8/8/8/1b6/8/R3K3 b - - 0 1", pgn: "1... Bd1"),
        GuidedPuzzle(name: "Rook Skewer", description: "Skewer king and queen on the same rank", fen: "4k3/8/8/q7/8/8/8/R3K3 w - - 0 1", pgn: "1. Ra8+ Kd7 2. Rxa5" ),
        GuidedPuzzle(name: "Queen Skewer", description: "Use the queen to skewer two pieces", fen: "r3k3/8/8/4Q3/8/8/8/4K3 w - - 0 1", pgn: "1. Qa5+"),
    ]

    static let discoveredAttacks: [GuidedPuzzle] = [
        GuidedPuzzle(name: "Discovered Check", description: "Move the blocking piece to reveal check", fen: "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1", pgn: "1. Bxf7+ Kxf7 2. Nxe5+"),
        GuidedPuzzle(name: "Discovered Attack on Queen", description: "Reveal an attack on the queen", fen: "rnbqkb1r/pppppppp/5n2/8/3PP3/8/PPP2PPP/RNBQKBNR w KQkq - 0 1", pgn: "1. e5 Nd5 2. c4"),
        GuidedPuzzle(name: "Bishop Discovery", description: "Move the knight to unleash the bishop", fen: "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 1", pgn: "1. Bc4 Nf6 2. Ng5"),
    ]

    static let doubleChecks: [GuidedPuzzle] = [
        GuidedPuzzle(name: "Knight + Bishop Double Check", description: "Two pieces check simultaneously — king must move", fen: "r1bqkbnr/pppp1ppp/2n5/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1", pgn: "1. Bxf7+ Kxf7 2. Ng5+ Kg8"),
        GuidedPuzzle(name: "Rook + Bishop Discovery", description: "Discover check with both pieces", fen: "rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 1", pgn: "1. Bxf7+ Kf8 2. Bb3"),
    ]

    // MARK: - Checkmate Patterns

    static let backRankMates: [GuidedPuzzle] = [
        GuidedPuzzle(name: "Classic Back Rank", description: "Deliver checkmate on the 8th rank", fen: "6k1/5ppp/8/8/8/8/8/R3K3 w - - 0 1", pgn: "1. Ra8#"),
        GuidedPuzzle(name: "Rook Sacrifice Back Rank", description: "Sacrifice to open the back rank", fen: "2r3k1/5ppp/8/8/8/8/5PPP/1R2R1K1 w - - 0 1", pgn: "1. Re8+ Rxe8 2. Rxe8#"),
        GuidedPuzzle(name: "Queen Back Rank", description: "Use the queen for back rank mate", fen: "5rk1/5ppp/8/8/8/4Q3/5PPP/6K1 w - - 0 1", pgn: "1. Qe8"),
        GuidedPuzzle(name: "Double Rook Back Rank", description: "Two rooks combine for the kill", fen: "4r1k1/5ppp/8/8/8/8/5PPP/RR4K1 w - - 0 1", pgn: "1. Rb8 Rxb8 2. Rxb8#"),
        GuidedPuzzle(name: "Back Rank with Deflection", description: "Deflect the defender then mate", fen: "3r2k1/5ppp/8/1Q6/8/8/5PPP/6K1 w - - 0 1", pgn: "1. Qb8"),
    ]

    static let smotheredMates: [GuidedPuzzle] = [
        GuidedPuzzle(name: "Classic Smothered Mate", description: "Knight mates the trapped king", fen: "6rk/5Npp/8/8/8/8/8/4K3 w - - 0 1", pgn: "1. Nh6"),
        GuidedPuzzle(name: "Philidor's Legacy", description: "The famous queen sacrifice into smothered mate", fen: "r4rk1/5ppp/8/1N6/8/8/5PPP/4Q1K1 w - - 0 1", pgn: "1. Nd6 Rf6 2. Qe8+ Rf8 3. Qxf8+"),
        GuidedPuzzle(name: "Smothered by Own Pieces", description: "The king has no escape squares", fen: "r5rk/5Npp/8/8/8/8/6PP/6K1 w - - 0 1", pgn: "1. Nh6"),
    ]

    static let arabianMates: [GuidedPuzzle] = [
        GuidedPuzzle(name: "Classic Arabian Mate", description: "Knight and rook deliver corner checkmate", fen: "7k/5N2/6R1/8/8/8/8/4K3 w - - 0 1", pgn: "1. Rh6"),
        GuidedPuzzle(name: "Arabian Mate Setup", description: "Position the rook for the kill", fen: "7k/5N2/8/8/8/8/8/4K2R w - - 0 1", pgn: "1. Rh6"),
        GuidedPuzzle(name: "Corner Arabian Mate", description: "Trap the king in the corner", fen: "k7/2N5/1R6/8/8/8/8/4K3 w - - 0 1", pgn: "1. Ra6#"),
    ]

    static let queenKnightMates: [GuidedPuzzle] = [
        GuidedPuzzle(name: "Queen + Knight Mate", description: "Queen and knight combine for checkmate", fen: "6k1/8/5N2/8/8/8/8/4K2Q w - - 0 1", pgn: "1. Qh7#"),
        GuidedPuzzle(name: "Knight Covers Escape", description: "Knight blocks the king's escape route", fen: "7k/8/5N2/8/8/8/6Q1/4K3 w - - 0 1", pgn: "1. Qg8#"),
        GuidedPuzzle(name: "Setup the Mate", description: "Maneuver into the mating position", fen: "6k1/6pp/5N2/8/8/8/6PP/4Q1K1 w - - 0 1", pgn: "1. Qe8+ Kf8 2. Qf7#"),
    ]

    static let epauletteMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Classic Epaulette Mate",
            description: "Pieces on both sides trap the king like shoulder epaulettes",
            fen: "7r/6pk/4Q2p/2q1p3/8/7R/5PPP/6K1 w - - 0 1",
            pgn: "1. Rxh6+ gxh6 2. Qf7#",
            previewFEN: "3rkr2/8/4Q3/8/8/8/8/4K3 w - - 0 1",
            detailed: "The Epaulette Mate resembles decorative shoulder pieces on a military uniform. The king is checked and has no escape — pieces on either side block its retreat, looking like epaulettes on the king's shoulders."
        ),
        GuidedPuzzle(
            name: "Epaulette with Rooks",
            description: "Rooks on each side block the king's escape",
            fen: "3rkr2/8/4Q3/8/8/8/8/4K3 w - - 0 1",
            pgn: "1. Qe7#",
            detailed: "The black king is trapped between its own rooks on d8 and f8. The queen delivers checkmate from e7 — the king has no escape squares."
        ),
        GuidedPuzzle(
            name: "Epaulette with Queen",
            description: "Queen and rook create the epaulette pattern",
            fen: "2rqkr2/8/4Q3/8/8/8/8/4K3 w - - 0 1",
            pgn: "1. Qe7#",
            detailed: "Even with the black queen on d8, the king is trapped. The pieces on both sides form the classic epaulette pattern — the queen checkmates from e7."
        ),
    ]
}
