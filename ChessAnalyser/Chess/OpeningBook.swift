import Foundation

/// Opening book loaded from Openings.json.
/// Maps board-only FEN (piece placement) → opening name.
struct OpeningBook {
    static let shared = OpeningBook()

    /// Board FEN → opening name
    private let database: [String: String]

    private init() {
        guard let url = Bundle.main.url(forResource: "Openings", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            database = [:]
            return
        }
        database = dict
    }

    /// Check if a FEN position is a known book position.
    func isBookPosition(_ fen: String) -> Bool {
        let key = boardFEN(from: fen)
        return database[key] != nil
    }

    /// Get the opening name for a position, if known.
    func openingName(for fen: String) -> String? {
        let key = boardFEN(from: fen)
        return database[key]
    }

    /// Extract board-only FEN (piece placement, the part before the first space).
    private func boardFEN(from fen: String) -> String {
        String(fen.split(separator: " ").first ?? Substring(fen))
    }
}
