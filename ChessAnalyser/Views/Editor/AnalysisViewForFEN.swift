import SwiftUI

struct AnalysisViewForFEN: View {
    let fen: String
    var initialFlip: Bool = false

    var body: some View {
        AnalysisView(fen: fen, initialFlip: initialFlip)
    }
}
