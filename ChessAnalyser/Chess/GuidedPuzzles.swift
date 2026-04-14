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

    static let operaMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Opera Mate",
            description: "Rook delivers mate protected by Bishop — not on the edge",
            fen: "4kb1r/p2n1ppp/4q3/4p1B1/4P3/1Q6/PPP2PPP/2KR4 w k - 0 16",
            pgn: "1. Qb8+ Nxb8 2. Rd8#",
            previewFEN: "3Rk3/5p2/8/6B1/8/8/8/6K1 w - - 0 1",
            detailed: "Similar to the h-file mate — both the Rook and Bishop play key roles. The Rook delivers mate while the Bishop protects it. Unlike the h-file mate, the King gets checkmated not on the edges but on the inner files. This is from the famous game played by Paul Morphy."
        ),
    ]

    static let mayetMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Mayet's Mate",
            description: "Rook placed next to the King, supported by a Bishop",
            fen: "r1b2rk1/ppp2ppp/8/bBQ5/5q2/2P2N1P/3N1PP1/4R1K1 w - - 0 22",
            pgn: "1. Qxf8+ Kxf8 2. Re8#",
            previewFEN: "4Rk2/5pp1/2B5/8/8/8/8/6K1 w - - 0 1",
            detailed: "The Mayet's Mate is a checkmate pattern where a Rook is placed right next to the enemy King while being supported by a Bishop. It's similar to Opera Mate — the difference is that the mate occurs from a different direction. Named after the German player Karl Mayet."
        ),
    ]

    static let retiMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Reti's Mate",
            description: "Bishop delivers the blow while the Rook supports it",
            fen: "rnb1kb1r/pp3ppp/2p5/4q3/4n3/3Q4/PPPB1PPP/2KR1BNR w kq - 0 1",
            pgn: "1. Qd8+ Kxd8 2. Bg5+ Kc7 3. Bd8#",
            previewFEN: "rnbB1b1r/ppk2ppp/2p5/4q3/4n3/8/PPP2PPP/2KR1BNR b - - 3 3",
            detailed: "Richard Reti won a beautiful game against Savielly Tartakower using this checkmate — and that's where the name comes from! The Bishop delivers the final blow while the Rook supports it. The enemy King's flight squares are blocked by its own pieces."
        ),
        GuidedPuzzle(
            name: "Reti's Mate — Knight Clearance",
            description: "Sacrifice the knight to unleash the bishop mate",
            fen: "2kr2nr/pp3ppp/8/4p3/2p1P1b1/2Pn1N2/PPK2PPP/RNB2B1R b - - 0 1",
            pgn: "1... Ne1+ 2. Nxe1 Bd1#",
            detailed: "A stunning knight sacrifice clears the diagonal for the bishop to deliver Reti's Mate. The knight gives itself up with check, and when captured, the bishop slides in for checkmate."
        ),
    ]

    static let pillsburyMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Pillsbury Mate",
            description: "Bishop controls the corner, Rook delivers mate on the file",
            fen: "r6k/pb2n2p/1p3p2/4p3/2PP4/1P6/P1B2PrP/R2Q1R1K b - - 0 1",
            pgn: "1... Rg1+ 2. Kxg1 Rg8+ 3. Qg4 Rxg4#",
            previewFEN: "5rk1/5p1p/8/8/8/8/1B6/6RK w - - 0 1",
            detailed: "Named after Harry Pillsbury, the Bishop controls the corner square of the castled King while the Rook delivers mate on the open file. The escape squares are blocked by the King's own pieces. A brilliant rook sacrifice opens the g-file for the finishing attack."
        ),
    ]

    static let morphyMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Morphy's Mate",
            description: "King trapped in corner — Rook cuts off, Bishop delivers",
            fen: "5rk1/p4ppp/1p1rp3/3qB3/3PR3/5Q1P/PP3PP1/6K1 w - - 0 1",
            pgn: "1. Qf6 gxf6 2. Rg4+ Kh8 3. Bxf6#",
            previewFEN: "7k/7p/8/8/3B2R1/8/8/7K w - - 0 1",
            detailed: "The enemy King is trapped in the corner. The Rook cuts off important escape squares on the file or rank, and the Bishop moves in to deliver checkmate. Named after the legendary American chess player Paul Morphy — a queen sacrifice sets up the beautiful finish."
        ),
    ]

    static let grecoMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Greco Mate",
            description: "King exposed on edge — Bishop controls escape, Rook delivers",
            fen: "1r3r1k/5Bpp/8/p7/P2q4/5R2/1b4PP/1Q3R1K w - - 0 1",
            pgn: "1. Qxh7+ Kxh7 2. Rh3+ Qh4 3. Rxh4#",
            previewFEN: "5r1k/6p1/8/8/2B5/8/8/6KR w - - 0 1",
            detailed: "The enemy King is trapped and exposed on the edge of the board. The Bishop controls one escape square while the other is blocked by its own pieces. The Rook moves in to deliver the final blow. Named after 18th century player Gioachino Greco."
        ),
    ]

    static let cornerMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Corner Mate",
            description: "Rook cuts off escape, Knight delivers in the corner",
            fen: "6k1/3Q1p2/6p1/P5r1/R1q1n3/7B/7P/5R1K b - - 0 1",
            pgn: "1... Qxf1+ 2. Bxf1 Nf2#",
            previewFEN: "7k/5N1p/8/8/8/8/8/6RK w - - 0 1",
            detailed: "As the name suggests, this checkmate is delivered in the corner. The Rook cuts off important escape squares on the file or rank, and the Knight jumps in to deliver the final attack."
        ),
    ]

    static let anastasiaMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Anastasia's Mate",
            description: "Rook mates on the edge, Knight controls two flight squares",
            fen: "5rk1/5ppp/3n4/q2N4/8/1R6/2Q2PPP/6K1 w - - 0 1",
            pgn: "1. Ne7+ Kh8 2. Qxh7+ Kxh7 3. Rh3+ Qh5 4. Rxh5#",
            previewFEN: "8/4N1pk/8/8/8/7R/8/6K1 w - - 0 1",
            detailed: "The enemy king is trapped on the edge of the board. The Rook delivers checkmate while the Knight controls two important flight squares. Another flight square is blocked by the King's own pawn."
        ),
    ]

    static let arabianMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Arabian Mate",
            description: "Knight and Rook combine to trap the King in the corner",
            fen: "3r1b1k/1p3R2/7p/2p4N/p4P2/2K3R1/PP6/3r4 w - - 0 1",
            pgn: "1. Rh7+ Kxh7 2. Nf6+ Kh8 3. Rg8#",
            previewFEN: "6Rk/8/5N2/8/8/8/8/6K1 w - - 0 1",
            detailed: "An important pattern showing the combined power of the Knight and Rook. Together, these pieces cover all of the enemy King's flight squares while it's trapped in the corner. The Rook delivers the checkmate, supported by the Knight."
        ),
    ]

    static let vukovicMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Vukovic Mate",
            description: "Rook, Knight, and pawn combine — Rook delivers the blow",
            fen: "2r4k/p6p/1b1pPNpB/6P1/2p2p2/8/P1r2PK1/7R w - - 0 1",
            pgn: "1. Bg7+ Kxg7 2. Rxh7+ Kf8 3. Rf7#",
            previewFEN: "5k2/5R2/4PN2/8/8/8/8/6K1 w - - 0 1",
            detailed: "Named after IM Vladimir Vukovic from his book 'The Art of Attack in Chess'. Three pieces work together: the Rook lands the final blow while covering escape squares, the Knight guards another set, and a pawn protects the Rook."
        ),
    ]

    static let hookMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Hook Mate",
            description: "Rook delivers mate, supported by Knight, protected by pawn",
            fen: "6rk/pp3Qp1/1q5p/3pNP2/n1p5/2P5/PP6/2K1R3 w - - 0 1",
            pgn: "1. Ng6+ Kh7 2. Qxg8+ Kxg8 3. Re8+ Kf7 4. Rf8#",
            previewFEN: "5R2/5kp1/6N1/5P2/8/8/8/6K1 w - - 0 1",
            detailed: "A Rook, Knight, and pawn work together. The Rook delivers mate supported by the Knight, which is protected by a pawn. This makes it impossible for the enemy king to capture either piece. The remaining escape square is blocked by the enemy King's own pawn."
        ),
    ]

    static let anderssenMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Anderssen's Mate",
            description: "Rook mates on 8th rank, supported by a pawn on the 7th",
            fen: "3r2k1/p4rPp/1b1q3Q/n1p1pP2/1p6/3B1NR1/P4P1P/6RK w - - 0 29",
            pgn: "1. Qxh7+ Kxh7 2. f6+ Kg8 3. Bh7+ Kxh7 4. Rh3+ Kg8 5. Rh8#",
            previewFEN: "6kR/5pP1/5P2/8/8/8/8/6K1 w - - 0 1",
            detailed: "The Rook delivers checkmate on the 8th rank, standing next to the enemy king and supported by a pawn on the 7th rank. Named after Adolf Anderssen, who finished off a beautiful game against Zukerort with this pattern!"
        ),
    ]

    static let diagonalCorridorMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Diagonal Corridor Mate",
            description: "A lone Bishop traps the King on a deadly diagonal",
            fen: "8/p4B2/8/6pp/R7/1P4Pk/P1r4P/3n2K1 w - - 0 43",
            pgn: "1. Rh4+ gxh4 2. Be6#",
            previewFEN: "6bk/7p/8/8/3B4/8/8/6K1 w - - 0 1",
            detailed: "Sometimes just a lone Bishop can finish off the game. In this beautiful mating pattern, the Bishop traps the enemy King with a deadly blow on a diagonal. A rook sacrifice opens the path for the Bishop's killing move."
        ),
    ]

    static let bombardiersMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Bombardiers' Mate",
            description: "Two Bishops bombard down diagonals to trap the King",
            fen: "r3kb1r/pppn1ppp/2b1p3/q5B1/3P4/2PQ2N1/PPB2P1P/2K1R1R1 w kq - 0 13",
            pgn: "1. Rxe6+ fxe6 2. Qg6+ hxg6 3. Bxg6#",
            previewFEN: "7k/7p/8/3BB3/8/8/8/6K1 w - - 0 1",
            detailed: "A rare pattern most chess literature hasn't covered. Two Bishops bombard down their respective diagonals, trapping the enemy King. One delivers the checkmate while the other controls the escape squares. Sacrifices clear the way for the double-bishop finish."
        ),
    ]

    static let bodenMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Boden's Mate",
            description: "Two Bishops work like scissors to trap the King",
            fen: "r1bqk2r/p1pn1pp1/1p2pn1p/8/3P4/B1PB4/P1P1QPPP/R3K1NR w KQkq - 0 10",
            pgn: "1. Qxe6+ fxe6 2. Bg6#",
            previewFEN: "2kr4/3p4/B7/4B3/8/8/8/6K1 w - - 0 1",
            detailed: "Two Bishops work like a pair of scissors to trap the enemy King. Named after Samuel Boden who used it in one of his games. The queen sacrifice opens the diagonal for the bishop to deliver the fatal blow."
        ),
    ]

    static let smotheredMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Smothered Mate",
            description: "A lone Knight mates the King trapped by its own pieces",
            fen: "4r2k/6pp/8/3QN3/8/q7/5PPP/6K1 w - - 0 1",
            pgn: "1. Nf7+ Kg8 2. Nh6+ Kh8 3. Qg8+ Rxg8 4. Nf7#",
            previewFEN: "6rk/5Npp/8/8/8/8/8/6K1 w - - 0 1",
            detailed: "One of the most popular and beautiful checkmates in chess! A lone knight mates the enemy King whose escape squares are all blocked by its own pieces. The queen sacrifice on g8 forces the rook to smother its own king."
        ),
    ]

    static let twoKnightsMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Two Knights Mate",
            description: "Two Knights roll together to finish off the game",
            fen: "2r2r1k/pb2b1p1/1p4Qp/3nN3/2p1N1Pq/3B4/PPP4P/1KR4R w - - 0 1",
            pgn: "1. Qh7+ Kxh7 2. Nf6+ Kh8 3. Ng6#",
            previewFEN: "7k/5Np1/5N2/8/8/8/8/6K1 w - - 0 1",
            detailed: "A beautiful pattern rarely covered in chess literature. As the name suggests, the Knights roll together to finish off the game. The queen sacrifice clears the way for the double-knight coordination."
        ),
    ]

    static let suffocationMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Suffocation Mate",
            description: "Bishop suffocates the King, Knight delivers the blow",
            fen: "r2q1rk1/pb3pbp/np4pQ/3p4/1P1N4/P2BP3/1B3PPP/R3K2R w KQ - 0 16",
            pgn: "1. Qxg7+ Kxg7 2. Nf5+ Kg8 3. Nh6#",
            previewFEN: "5rk1/5p1p/7N/8/3B4/8/8/6K1 w - - 0 1",
            detailed: "The Bishop suffocates the enemy King by controlling important escape squares, while others are blocked by friendly pieces. The Knight lands the final checkmate! The queen sacrifice draws the king out for the knight's finishing move."
        ),
    ]

    static let collaborationMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Collaboration Mate",
            description: "Bishop checkmates while Knight controls escape squares",
            fen: "7r/4Rpk1/6p1/q2p4/P3b3/5NPn/2B1QP1P/7K b - - 0 1",
            pgn: "1... Qe1+ 2. Qxe1 Bxf3#",
            previewFEN: "7k/5p1p/5B1N/8/8/8/8/6K1 w - - 0 1",
            detailed: "The Bishop delivers checkmate while the Knight controls the escape squares — the reverse of the Suffocation Mate. Some escape squares are blocked by the King's own pieces! The queen sacrifice forces a capture that opens the diagonal."
        ),
    ]

    static let blackburneMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "Blackburne's Mate",
            description: "Two Bishops + Knight — minor pieces deliver the finish",
            fen: "r4rk1/p4pp1/1p1b1n1p/7q/1P4bN/P3P1P1/2BB1P1P/1Q2RR1K b - - 0 1",
            pgn: "1... Qxh4 2. gxh4 Bf3+ 3. Kg1 Ng4 4. Rc1 Bxh2#",
            previewFEN: "7k/5B2/8/4B1N1/8/8/8/6K1 w - - 0 1",
            detailed: "This mating pattern features 3 minor pieces — 2 Bishops and 1 Knight. Two minor pieces control the escape squares while the remaining one delivers checkmate. The queen sacrifice starts a beautiful combination."
        ),
    ]

    static let davidGoliathMates: [GuidedPuzzle] = [
        GuidedPuzzle(
            name: "David and Goliath Mate",
            description: "A humble pawn delivers the checkmate!",
            fen: "6r1/p1R5/5pk1/6P1/3r1PK1/6Q1/1q6/5R2 w - - 0 1",
            pgn: "1. Qd3+ Rxd3 2. f5#",
            previewFEN: "7k/6P1/7K/3B4/8/8/8/8 w - - 0 1",
            detailed: "A pawn delivers the checkmate! The enemy King's escape squares are controlled or blocked by its own pieces. Even though it's rare, this is one of the favorite checkmates of many chess players. The queen sacrifice forces the rook to block, then the pawn strikes."
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
