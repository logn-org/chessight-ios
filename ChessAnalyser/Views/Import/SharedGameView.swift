import SwiftUI

struct SharedGameView: View {
    @Environment(AppState.self) private var appState
    let sharedText: String

    @State private var isLoading = true
    @State private var error: String?
    @State private var resolvedPGN: String?
    @State private var statusText = "Connecting..."
    @State private var animatePulse = false

    private let resolver = ChessComGameResolver()

    var body: some View {
        if let pgn = resolvedPGN {
            AnalysisView(pgn: pgn)
        } else {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: AppSpacing.xl) {
                    Spacer()

                    // Animated chess board icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppColors.surface)
                            .frame(width: 100, height: 100)
                            .shadow(color: AppColors.accent.opacity(animatePulse ? 0.3 : 0.1), radius: animatePulse ? 20 : 8)

                        // Mini chess grid
                        VStack(spacing: 0) {
                            ForEach(0..<4, id: \.self) { row in
                                HStack(spacing: 0) {
                                    ForEach(0..<4, id: \.self) { col in
                                        Rectangle()
                                            .fill((row + col) % 2 == 0 ? AppColors.boardLight : AppColors.boardDark)
                                            .frame(width: 18, height: 18)
                                    }
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Knight piece overlay
                        Image("wN")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .offset(y: -2)
                    }
                    .scaleEffect(animatePulse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animatePulse)

                    VStack(spacing: AppSpacing.sm) {
                        if isLoading {
                            Text("Loading Game")
                                .font(.title3.bold())
                                .foregroundStyle(AppColors.textPrimary)

                            Text(statusText)
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textMuted)
                                .transition(.opacity)

                            ProgressView()
                                .tint(AppColors.accent)
                                .scaleEffect(0.9)
                                .padding(.top, AppSpacing.sm)
                        } else if let error = error {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(AppColors.mistake)
                                .padding(.bottom, AppSpacing.xs)

                            Text("Could not load game")
                                .font(.title3.bold())
                                .foregroundStyle(AppColors.textPrimary)

                            Text(error)
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppSpacing.xxl)

                            Button {
                                loadGame()
                            } label: {
                                Label("Try Again", systemImage: "arrow.clockwise")
                                    .font(AppFonts.bodyBold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, AppSpacing.xl)
                                    .padding(.vertical, AppSpacing.md)
                                    .background(AppColors.accent)
                                    .clipShape(Capsule())
                            }
                            .padding(.top, AppSpacing.sm)
                        }
                    }

                    Spacer()
                    Spacer()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                animatePulse = true
                loadGame()
            }
        }
    }

    private func loadGame() {
        isLoading = true
        error = nil

        Task {
            let content = SharedContent.parse(sharedText)

            switch content {
            case .pgn(let pgn):
                Analytics.shareExtensionUsed(contentType: "pgn")
                statusText = "Parsing PGN..."
                try? await Task.sleep(for: .milliseconds(300))
                resolvedPGN = pgn

            case .chessComLink(let gameId):
                Analytics.shareExtensionUsed(contentType: "link")
                statusText = "Fetching from chess.com..."
                do {
                    let game = try await resolver.resolveGame(gameId: gameId)
                    statusText = "Loading game..."
                    try? await Task.sleep(for: .milliseconds(200))
                    resolvedPGN = game.pgn
                } catch {
                    self.error = error.localizedDescription
                    isLoading = false
                }

            case .unknown:
                Analytics.shareExtensionUsed(contentType: "unknown")
                self.error = "No valid chess game or chess.com link found"
                isLoading = false
            }
        }
    }
}
