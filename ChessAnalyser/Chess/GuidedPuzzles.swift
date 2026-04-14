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

    static let railroadMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Railroad Mate",
            description: "Queen and Rook drive the king like a train on rails",
            fen: "8/8/8/6k1/8/5Q1R/8/6K1 w - - 0 1",
            pgn: "1. Rh5+ Kg6 2. Qf5+ Kg7 3. Rh7+ Kg8 4. Qf7#",
            previewFEN: "6k1/5Q1R/8/8/8/8/6K1/8 w - - 0 1",
            detailed: "The Railroad Mate is a mix of the Kill Box and Triangle patterns. The Rook and Queen move like an unstoppable train along a rail track to checkmate the enemy King. It's a useful process to know — especially in blitz when you have little time to deliver checkmate."
        ),
        GuidedPuzzle(
            name: "Railroad Mate — Advanced",
            description: "Drive the king across the board with Queen and Rook",
            fen: "2b3k1/1pr4p/p2R2p1/1q6/8/QP5P/P6K/8 w - - 0 30",
            pgn: "1. Rd8+ Kf7 2. Qf8+ Ke6 3. Rd6+ Ke5 4. Qf6+ Ke4 5. Rd4+ Ke3 6. Qf4+ Ke2 7. Rd2+ Ke1 8. Qf2#",
            detailed: "An advanced railroad mate — the Queen and Rook coordinate to push the king across the entire board. Each check forces the king to retreat until there's nowhere left to go."
        ),
    ]

    static let maxLangeMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Max Lange Mate",
            description: "Queen and Bishop combine — named after German player Max Lange",
            fen: "7k/6p1/5p1p/8/Q7/1B6/8/4K3 w - - 0 1",
            pgn: "1. Qe8+ Kh7 2. Bg8+ Kh8 3. Bf7+ Kh7 4. Qg8#",
            previewFEN: "6Q1/5Bpk/5p1p/8/8/8/4K3/8 b - - 0 4",
            detailed: "This checkmate pattern combines the powers of a Queen and a Bishop, named after German chess player Max Lange. The Queen delivers the checkmate while the Bishop protects the Queen and controls a critical escape square."
        ),
        GuidedPuzzle(
            name: "Max Lange Mate — Advanced",
            description: "Bishop and Queen maneuver to the mating position",
            fen: "k7/1p2p3/p1p1pb1p/5q2/2P3pP/P1P1P1B1/3Q2PK/1r6 w - - 0 1",
            pgn: "1. Qd8+ Ka7 2. Bb8+ Ka8 3. Bc7+ Ka7 4. Qb8#",
            detailed: "The Bishop dances around the king, cutting off escape squares while the Queen delivers the final blow. A beautiful demonstration of Queen + Bishop coordination."
        ),
    ]

    static let balestraMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Balestra Mate",
            description: "Bishop and Queen combine like a pair of scissors",
            fen: "6k1/4Qpp1/7p/5q2/3bR3/r4B2/P5PP/5K2 b - - 0 37",
            pgn: "1... Rxf3+ 2. gxf3 Qxf3+ 3. Ke1 Bc3#",
            previewFEN: "3k4/8/1B2Q3/8/8/8/8/5K2 w - - 0 1",
            detailed: "The Balestra Mate features the Bishop-Queen pair. The Queen does a great job of covering most of the enemy King's escape squares, while the Bishop moves in to deliver the checkmate. The final position looks like a pair of scissors."
        ),
    ]

    static let buckingBroncoMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Bucking Bronco Mate",
            description: "Knight jumps in to checkmate while Queen chokes the king",
            fen: "q7/7k/4p1pp/3pN3/3Pb3/2P3QP/r5PK/4R3 w - - 0 1",
            pgn: "1. Rxe4 dxe4 2. Qxg6+ Kh8 3. Nf7#",
            previewFEN: "7k/5N2/6Q1/8/8/8/8/5K2 w - - 0 1",
            detailed: "The Queen-Knight pair is a dangerous attacking duo. In this checkmate, the enemy King is trapped in the corner. The Queen chokes it by controlling all escape squares while the Knight jumps in to deliver the final blow — like a bucking bronco!"
        ),
    ]

    static let sneakyStallionMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Sneaky Stallion Mate",
            description: "Knight sneaks in while the Queen chokes the king on the edge",
            fen: "2kr1b2/Qp1q1pp1/6p1/N1p1p1n1/2P5/4PP1r/P4PK1/R1B2R2 b - - 0 1",
            pgn: "1... Rh2+ 2. Kxh2 Qh3+ 3. Kg1 Nxf3#",
            previewFEN: "6k1/4N2p/5Q2/8/8/8/8/5K2 w - - 0 1",
            detailed: "Similar to the Bucking Bronco, but the enemy King isn't stuck in the corner — it's on the edge of the board, with an escape square blocked by one of its own pieces. The Queen chokes the remaining escape squares, and the Knight sneaks in to deliver the final checkmate."
        ),
    ]

    static let damianoMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Damiano's Mate",
            description: "Queen checkmates on the 7th rank, protected by an ally",
            fen: "r3rqk1/6p1/5pP1/8/8/1pP5/1P6/1KQR3R w - - 0 1",
            pgn: "1. Rh8+ Kxh8 2. Rh1+ Kg8 3. Rh8+ Kxh8 4. Qh1+ Kg8 5. Qh7#",
            previewFEN: "r3rqk1/6pQ/5pP1/8/8/1pP5/1P6/1K6 b - - 3 5",
            detailed: "The Queen delivers checkmate through the 7th rank from the edge of the board, protected by an ally. The King's escape squares are blocked or controlled. First published by Pedro Damiano, a Portuguese chess player in 1512 — one of the oldest mating patterns."
        ),
        GuidedPuzzle(
            name: "Damiano's Mate — Rook Clearance",
            description: "Sacrifice both rooks to clear the way for the Queen",
            fen: "r4rk1/2p1q1p1/5pP1/1p1p1b2/p1nP4/5PB1/PPP3P1/1KQR3R w - - 0 1",
            pgn: "1. Rh8+ Kxh8 2. Rh1+ Kg8 3. Rh8+ Kxh8 4. Qh1+ Kg8 5. Qh7#",
            detailed: "The Rooks clear the way for the Queen by sacrificing themselves. Two rook sacrifices force the king back, then the Queen lands the fatal blow on h7."
        ),
    ]

    static let lolliMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Lolli's Checkmate",
            description: "Queen delivers the blow against a castled King, protected by a pawn",
            fen: "2br1rk1/pp3p1p/2p2Pp1/4B3/3p2Pq/3P3P/PP4P1/R1Q2R1K w - - 0 1",
            pgn: "1. Bg3 Qxg3 2. Qh6 Rd6 3. Qg7#",
            previewFEN: "6k1/5pQp/5Pp1/8/8/8/8/6K1 w - - 0 1",
            detailed: "A common checkmating pattern where the Queen lands the final blow against a castled King while protected by the pawn. The key is deflecting the defender first — then the Queen slides into the deadly g7 square."
        ),
    ]

    static let backRankMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Back Rank Mate",
            description: "King trapped on the last rank behind its own pawns",
            fen: "4r1k1/1p3pp1/2p1b2p/8/QP6/8/P4PPP/6K1 b - - 0 1",
            pgn: "1... Bb3 2. Qxb3 Re1#",
            previewFEN: "4R1k1/5ppp/8/8/8/8/8/6K1 w - - 0 1",
            detailed: "The most popular checkmate pattern! The enemy king is trapped on the last rank behind its own pawns and gets checkmated by a Rook or Queen. The key is often clearing the path — here the bishop sacrifice opens the e-file."
        ),
    ]

    static let blindSwineMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Blind Swine Mate",
            description: "Two Rooks on the 7th rank deliver checkmate",
            fen: "2k5/pp3ppp/2pq4/8/PP6/2P1P1NP/1r1r1P2/2R1QRK1 b - - 0 25",
            pgn: "1... Qxg3+ 2. fxg3 Rg2+ 3. Kh1 Rh2+ 4. Kg1 Rbg2#",
            previewFEN: "r4rk1/6RR/8/8/8/8/8/6K1 w - - 0 1",
            detailed: "A rook is powerful on the 7th rank — and two rooks are devastating. In the Blind Swine mate, two Rooks coordinate on the 7th rank to deliver checkmate. The queen sacrifice clears the way for the rooks to dominate."
        ),
    ]

    static let lawnmowerMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Lawnmower Mate",
            description: "Two major pieces push the king to the edge and checkmate",
            fen: "r3r2k/1p5p/3p1b2/q1p5/2P1Q3/6R1/8/1K3R2 w - - 0 1",
            pgn: "1. Qxh7+ Kxh7 2. Rh1+ Bh4 3. Rxh4#",
            previewFEN: "1R4k1/R7/8/8/8/8/8/6K1 w - - 0 1",
            detailed: "Two major pieces (Rooks or Rook + Queen) work together to push the enemy king towards the edge of the board. Like a lawnmower cutting across the board — methodical and unstoppable."
        ),
    ]

    static let hFileMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "h-File Mate",
            description: "Rook delivers mate along the h-file, protected by a piece",
            fen: "2k4r/ppp3q1/2b3r1/8/2Q5/6P1/PPP1NR1P/5RK1 b - - 0 1",
            pgn: "1... Rxg3+ 2. Nxg3 Qxg3+ 3. hxg3 Rh1#",
            previewFEN: "6kR/5p2/8/8/3B4/8/8/6K1 w - - 0 1",
            detailed: "This mate is usually carried out along the h-file against the castled King. The Rook delivers the checkmate while being protected by another piece. Sacrifices clear the h-file for the finishing blow."
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
