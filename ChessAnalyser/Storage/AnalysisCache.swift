import Foundation

@Observable
final class AnalysisCache {
    private let cacheDirectory: URL
    private(set) var cachedGameIds: Set<String> = []

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        cacheDirectory = docs.appendingPathComponent("analysis_cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        loadIndex()
    }

    // MARK: - Save / Load

    func save(_ analysis: GameAnalysis) {
        let fileName = sanitizeFilename(analysis.id)
        let url = cacheDirectory.appendingPathComponent("\(fileName).json")
        guard let data = try? JSONEncoder().encode(analysis) else { return }
        try? data.write(to: url)
        cachedGameIds.insert(analysis.id)
    }

    func load(id: String) -> GameAnalysis? {
        let fileName = sanitizeFilename(id)
        let url = cacheDirectory.appendingPathComponent("\(fileName).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(GameAnalysis.self, from: data)
    }

    func isCached(_ id: String) -> Bool {
        cachedGameIds.contains(id)
    }

    func recentAnalyses(limit: Int = 20) -> [GameAnalysis] {
        var analyses: [GameAnalysis] = []
        let files = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []

        let sorted = files
            .filter { $0.pathExtension == "json" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return date1 > date2
            }
            .prefix(limit)

        for url in sorted {
            if let data = try? Data(contentsOf: url),
               let analysis = try? JSONDecoder().decode(GameAnalysis.self, from: data) {
                analyses.append(analysis)
            }
        }

        return analyses
    }

    func delete(id: String) {
        let fileName = sanitizeFilename(id)
        let url = cacheDirectory.appendingPathComponent("\(fileName).json")
        try? FileManager.default.removeItem(at: url)
        cachedGameIds.remove(id)
    }

    // MARK: - Helpers

    private func loadIndex() {
        let files = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        cachedGameIds = Set(files.filter { $0.pathExtension == "json" }.map {
            $0.deletingPathExtension().lastPathComponent
        })
    }

    private func sanitizeFilename(_ id: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return id.unicodeScalars.map { allowed.contains($0) ? String($0) : "_" }.joined()
    }
}
