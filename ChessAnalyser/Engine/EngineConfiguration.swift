import Foundation

enum AnalysisDepthPreset: String, Codable, CaseIterable, Identifiable {
    case quick
    case standard
    case deep

    var id: String { rawValue }

    var depth: Int {
        switch self {
        case .quick: return 14
        case .standard: return 18
        case .deep: return 22
        }
    }

    var label: String {
        switch self {
        case .quick: return "Quick"
        case .standard: return "Standard"
        case .deep: return "Deep"
        }
    }

    var description: String {
        switch self {
        case .quick: return "Depth 14 — Fast analysis"
        case .standard: return "Depth 18 — Balanced"
        case .deep: return "Depth 22 — Most accurate"
        }
    }
}

@Observable
final class EngineConfiguration {
    private static let storageKey = "engine_configuration"

    var depthPreset: AnalysisDepthPreset = .quick { didSet { save() } }
    var threads: Int = 2 { didSet { save() } }
    var hashMB: Int = 64 { didSet { save() } }
    var multiPV: Int = 3 { didSet { save() } }

    // Arrow display settings
    var showBestMoveArrow: Bool = true { didSet { save() } }
    var showAttackArrows: Bool = false { didSet { save() } }
    var showDefenseArrows: Bool = false { didSet { save() } }
    var showBoardCoordinates: Bool = true { didSet { save() } }

    var depth: Int { depthPreset.depth }

    init() {
        load()
    }

    // MARK: - Persistence

    private func save() {
        let data: [String: Any] = [
            "depthPreset": depthPreset.rawValue,
            "threads": threads,
            "hashMB": hashMB,
            "multiPV": multiPV,
            "showBestMoveArrow": showBestMoveArrow,
            "showAttackArrows": showAttackArrows,
            "showDefenseArrows": showDefenseArrows,
            "showBoardCoordinates": showBoardCoordinates,
        ]
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.dictionary(forKey: Self.storageKey) else { return }

        if let raw = data["depthPreset"] as? String,
           let preset = AnalysisDepthPreset(rawValue: raw) {
            depthPreset = preset
        }
        if let v = data["threads"] as? Int { threads = v }
        if let v = data["hashMB"] as? Int { hashMB = v }
        if let v = data["multiPV"] as? Int { multiPV = v }
        if let v = data["showBestMoveArrow"] as? Bool { showBestMoveArrow = v }
        if let v = data["showAttackArrows"] as? Bool { showAttackArrows = v }
        if let v = data["showDefenseArrows"] as? Bool { showDefenseArrows = v }
        if let v = data["showBoardCoordinates"] as? Bool { showBoardCoordinates = v }
    }
}
