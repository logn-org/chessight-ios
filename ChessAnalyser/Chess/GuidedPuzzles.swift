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

    static let swallowTailMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Swallow's Tail Mate",
            description: "King's retreat blocked by its own pieces standing diagonally backward",
            fen: "6k1/5p2/4q1p1/7p/1P4r1/PB5K/2Q2P1P/2R3R1 b - - 0 1",
            pgn: "1... Rg3+ 2. Kxg3 Qg4#",
            previewFEN: "8/5p1p/6k1/6Q1/7P/8/8/4K3 w - - 0 1",
            detailed: "In this mating pattern, the King's retreating squares are blocked by its own pieces, standing diagonally backward. The mating pattern resembles a swallow's tail."
        ),
    ]

    static let cozioMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Cozio's Mate",
            description: "King blocked by pieces standing horizontally and vertically",
            fen: "7R/1Q3r2/1b2rkp1/5p2/3q1P2/8/6R1/7K w - - 0 1",
            pgn: "1. Rxg6+ Kxg6 2. Qg2+ Kf6 3. Qg5#",
            previewFEN: "8/8/8/6p1/5qk1/7Q/6K1/8 w - - 0 1",
            detailed: "This mating pattern is named after Carlos Cozio, who published a study on it in 1766. The King's retreating squares are blocked by its own pieces — one standing horizontally and the other standing vertically."
        ),
    ]

    static let killBoxMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Kill Box Mate",
            description: "Rook and Queen trap the King in a 3×3 box",
            fen: "1k5r/1pp2p1r/p4bp1/8/2P2B2/1P2Pq2/P2Q2B1/3RR1K1 b - - 0 1",
            pgn: "1... Rh1+ 2. Bxh1 Rxh1#",
            previewFEN: "6kR/8/5Q2/8/8/8/6K1/8 w - - 0 1",
            detailed: "This checkmate pattern occurs when a Rook and Queen work together to checkmate the enemy King in a 3×3 box shape, from which the enemy King cannot escape. The Rook delivers the checkmate while the Queen assists it."
        ),
    ]

    static let triangleMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Triangle Mate",
            description: "Queen, Rook, and King form a triangle",
            fen: "3rrb2/1R3pk1/3p1n1p/2p1pQ2/2P1Pqp1/3P2R1/5NP1/6K1 w - - 0 1",
            pgn: "1. Rxg4+ Nxg4 2. Rxf7+ Kg8 3. Qh7#",
            previewFEN: "6k1/5Q1R/8/8/8/8/6K1/8 w - - 0 1",
            detailed: "This checkmate looks like a triangle formed by the Queen, the Rook, and the enemy King. The White Queen and Rook checkmate the Black monarch — together, these 3 pieces form a triangle."
        ),
    ]

    static let epauletteMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Epaulette Mate",
            description: "Pieces on both sides trap the king like shoulder epaulettes",
            fen: "7r/6pk/4Q2p/2q1p3/8/7R/5PPP/6K1 w - - 0 1",
            pgn: "1. Rxh6+ gxh6 2. Qf7#",
            previewFEN: "3rkr2/8/4Q3/8/8/8/8/4K3 w - - 0 1",
            detailed: "The Epaulette Mate resembles decorative shoulder pieces on a military uniform. The king is checked and has no escape — pieces on either side block its retreat, looking like epaulettes on the king's shoulders."
        ),
    ]
}
