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
                Analytics.pgnValidationFailed(error: validationError, source: "import")
                Analytics.pgnImported(method: "paste", valid: false)
                return
            }

            let allGames = try PGNParser.parseMultiple(text)
            parsedGames = allGames.filter { !$0.moves.isEmpty }
            if parsedGames.isEmpty {
                error = "No valid chess game found"
            } else {
                error = nil
            }
            Analytics.pgnImported(method: "paste", valid: !parsedGames.isEmpty)
        } catch {
            parsedGames = []
            self.error = error.localizedDescription
            Analytics.pgnImported(method: "paste", valid: false)
        }
    }

    func loadFromFile(data: Data) {
        guard let text = String(data: data, encoding: .utf8) else {
            error = "Could not read file"
            Analytics.pgnImported(method: "file", valid: false)
            return
        }
        pgnText = text
        // parsePGN will track its own analytics with "paste" method; override for file
        let textTrimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textTrimmed.isEmpty else {
            parsedGames = []
            error = nil
            Analytics.pgnImported(method: "file", valid: false)
            return
        }

        do {
            if let validationError = PGNParser.validate(textTrimmed) {
                error = validationError
                parsedGames = []
                Analytics.pgnValidationFailed(error: validationError, source: "import")
                Analytics.pgnImported(method: "file", valid: false)
                return
            }

            let allGames = try PGNParser.parseMultiple(textTrimmed)
            parsedGames = allGames.filter { !$0.moves.isEmpty }
            if parsedGames.isEmpty {
                error = "No valid chess game found"
            } else {
                error = nil
            }
            Analytics.pgnImported(method: "file", valid: !parsedGames.isEmpty)
        } catch {
            parsedGames = []
            self.error = error.localizedDescription
            Analytics.pgnImported(method: "file", valid: false)
        }
    }

    func clear() {
        pgnText = ""
        parsedGames = []
        error = nil
    }
}
