import SwiftUI

/// Sheet that shows the current FEN and PGN with copy buttons.
struct SharePositionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let fen: String
    let pgn: String

    @State private var copiedFEN = false
    @State private var copiedPGN = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // FEN Section
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Position (FEN)")
                                .font(AppFonts.bodyBold)
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = fen
                                Analytics.shareCopied(contentType: "fen", source: "share_sheet")
                                copiedFEN = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedFEN = false }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedFEN ? "checkmark" : "doc.on.doc")
                                    Text(copiedFEN ? "Copied" : "Copy")
                                        .font(AppFonts.captionBold)
                                }
                                .foregroundStyle(copiedFEN ? AppColors.accent : AppColors.textSecondary)
                            }
                        }

                        Text(fen)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(AppSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.surfaceLight)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                            .textSelection(.enabled)
                    }

                    // PGN Section
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Game (PGN)")
                                .font(AppFonts.bodyBold)
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = pgn
                                Analytics.shareCopied(contentType: "pgn", source: "share_sheet")
                                copiedPGN = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedPGN = false }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedPGN ? "checkmark" : "doc.on.doc")
                                    Text(copiedPGN ? "Copied" : "Copy")
                                        .font(AppFonts.captionBold)
                                }
                                .foregroundStyle(copiedPGN ? AppColors.accent : AppColors.textSecondary)
                            }
                        }

                        Text(pgn.isEmpty ? "No moves yet" : pgn)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(pgn.isEmpty ? AppColors.textMuted : AppColors.textSecondary)
                            .padding(AppSpacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.surfaceLight)
                            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                            .textSelection(.enabled)
                    }
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("Share Position")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.accent)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
