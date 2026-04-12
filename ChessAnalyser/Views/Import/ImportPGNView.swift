import SwiftUI
import UniformTypeIdentifiers

struct ImportPGNView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ImportViewModel()
    @State private var showFilePicker = false
    @State private var navigateToAnalysis = false
    @State private var selectedGame: ParsedGame?
    @State private var isResolvingLink = false
    @State private var resolvedPGN: String?

    private let resolver = ChessComGameResolver()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Quick actions
                    VStack(spacing: AppSpacing.md) {
                        Button { pasteFromClipboard() } label: {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.title3)
                                    .foregroundStyle(AppColors.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Paste from Clipboard")
                                        .font(AppFonts.bodyBold)
                                        .foregroundStyle(AppColors.textPrimary)
                                    Text("PGN text or chess.com game link")
                                        .font(AppFonts.small)
                                        .foregroundStyle(AppColors.textMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppColors.textMuted)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                        }

                        Button { showFilePicker = true } label: {
                            HStack {
                                Image(systemName: "folder")
                                    .font(.title3)
                                    .foregroundStyle(AppColors.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Choose from Files")
                                        .font(AppFonts.bodyBold)
                                        .foregroundStyle(AppColors.textPrimary)
                                    Text(".pgn or .txt files")
                                        .font(AppFonts.small)
                                        .foregroundStyle(AppColors.textMuted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(AppColors.textMuted)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                        }
                    }

                    // Info note
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(AppColors.textMuted)
                        Text("Game links: only chess.com links are supported. Paste the link or share message from chess.com.")
                            .font(AppFonts.small)
                            .foregroundStyle(AppColors.textMuted)
                    }
                    .padding(AppSpacing.sm)
                    .background(AppColors.surfaceLight)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))

                    // Manual PGN input
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Or paste PGN manually")
                            .font(AppFonts.captionBold)
                            .foregroundStyle(AppColors.textSecondary)

                        TextEditor(text: $viewModel.pgnText)
                            .font(AppFonts.moveText)
                            .foregroundStyle(AppColors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 150)
                            .padding(AppSpacing.sm)
                            .background(AppColors.surfaceLight)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                            .onChange(of: viewModel.pgnText) { _, _ in
                                viewModel.parsePGN()
                            }
                    }

                    // Loading state (resolving chess.com link)
                    if isResolvingLink {
                        HStack {
                            ProgressView().tint(AppColors.accent)
                            Text("Fetching game from chess.com...")
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .padding(AppSpacing.md)
                    }

                    // Error
                    if let error = viewModel.error {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(AppColors.blunder)
                            Text(error)
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.blunder)
                        }
                        .padding(AppSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.blunder.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
                    }

                    // Parsed games
                    if !viewModel.parsedGames.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("\(viewModel.parsedGames.count) game(s) found")
                                .font(AppFonts.captionBold)
                                .foregroundStyle(AppColors.accent)

                            ForEach(viewModel.parsedGames) { game in
                                Button {
                                    selectedGame = game
                                    navigateToAnalysis = true
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(game.white) vs \(game.black)")
                                                .font(AppFonts.bodyBold)
                                                .foregroundStyle(AppColors.textPrimary)
                                            Text("\(game.result) · \(game.moves.count) moves")
                                                .font(AppFonts.caption)
                                                .foregroundStyle(AppColors.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(AppColors.accent)
                                    }
                                    .padding(AppSpacing.md)
                                    .background(AppColors.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                                }
                            }
                        }
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Import Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [
                    .plainText,
                    UTType(filenameExtension: "pgn") ?? .plainText
                ]
            ) { result in
                switch result {
                case .success(let url):
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        if let data = try? Data(contentsOf: url) {
                            viewModel.loadFromFile(data: data)
                        }
                    }
                case .failure:
                    viewModel.error = "Failed to load file"
                }
            }
            .navigationDestination(isPresented: $navigateToAnalysis) {
                if let game = selectedGame {
                    AnalysisView(pgn: game.pgn)
                }
            }
        }
    }

    // MARK: - Paste from Clipboard

    private func pasteFromClipboard() {
        guard let clip = UIPasteboard.general.string, !clip.isEmpty else {
            viewModel.error = "Clipboard is empty"
            return
        }

        viewModel.error = nil
        viewModel.parsedGames = []

        let content = SharedContent.parse(clip)

        switch content {
        case .pgn(let pgn):
            viewModel.pgnText = pgn
            viewModel.parsePGN()
            if viewModel.parsedGames.isEmpty {
                viewModel.error = "No valid chess game found in the pasted text"
            }

        case .chessComLink(let gameId):
            resolveChessComGame(gameId: gameId)

        case .unknown:
            // Try as PGN anyway
            viewModel.pgnText = clip
            viewModel.parsePGN()
            if viewModel.parsedGames.isEmpty {
                viewModel.error = "No valid chess game or chess.com link found in the pasted text"
            }
        }
    }

    private func resolveChessComGame(gameId: String) {
        isResolvingLink = true
        viewModel.error = nil

        Task {
            do {
                let game = try await resolver.resolveGame(gameId: gameId)
                viewModel.pgnText = game.pgn
                viewModel.parsePGN()
                if viewModel.parsedGames.isEmpty {
                    viewModel.error = "Game found but PGN could not be parsed"
                }
            } catch {
                viewModel.error = "Could not load game: \(error.localizedDescription)"
            }
            isResolvingLink = false
        }
    }
}
