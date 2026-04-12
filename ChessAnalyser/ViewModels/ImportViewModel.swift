import Foundation
import UniformTypeIdentifiers

@Observable
final class ImportViewModel {
    var pgnText = ""
    var parsedGames: [ParsedGame] = []
    var error: String?
    var isValidPGN: Bool { !parsedGames.isEmpty }

    func parsePGN() {
        let text = pgnText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            parsedGames = []
            error = nil
            return
        }

        do {
            // Validate each game's PGN before parsing
            if let validationError = PGNParser.validate(text) {
                error = validationError
                parsedGames = []
                return
            }

            let allGames = try PGNParser.parseMultiple(text)
            parsedGames = allGames.filter { !$0.moves.isEmpty }
            if parsedGames.isEmpty {
                error = "No valid chess game found"
            } else {
                error = nil
            }
        } catch {
            parsedGames = []
            self.error = error.localizedDescription
        }
    }

    func loadFromFile(data: Data) {
        guard let text = String(data: data, encoding: .utf8) else {
            error = "Could not read file"
            return
        }
        pgnText = text
        parsePGN()
    }

    func clear() {
        pgnText = ""
        parsedGames = []
        error = nil
    }
}
