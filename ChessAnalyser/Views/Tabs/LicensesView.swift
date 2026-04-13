import SwiftUI

struct LicensesView: View {
    var body: some View {
        List {
            Section {
                Text("Chessight uses the following open source software. We are grateful to the developers and communities behind these projects.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .listRowBackground(AppColors.background)
            }

            licenseSection(
                name: "Stockfish",
                version: "18",
                license: "GPL v3",
                description: "World's strongest open source chess engine. Used for game analysis, move evaluation, and bot opponent.",
                url: "https://stockfishchess.org",
                gplNotice: true
            )

            licenseSection(
                name: "NNUE Neural Networks",
                version: "nn-7bf13f9655c8 / nn-47fc8b7fff06",
                license: "GPL v3",
                description: "Neural network evaluation files for Stockfish. Provides accurate position assessment.",
                url: "https://github.com/official-stockfish/Stockfish"
            )

            licenseSection(
                name: "cburnett Chess Pieces",
                version: "1.0",
                license: "BSD / CC BY-SA 3.0",
                description: "SVG chess piece artwork used for board rendering.",
                url: "https://github.com/ornicar/lila/tree/master/public/piece/cburnett"
            )

            licenseSection(
                name: "Firebase SDK",
                version: "11.x",
                license: "Apache 2.0",
                description: "Firebase Crashlytics, Analytics, and Performance monitoring.",
                url: "https://github.com/firebase/firebase-ios-sdk"
            )

            Section("Source Code") {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("GPL Compliance Notice")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                    Text("This app contains code licensed under the GNU General Public License v3 (GPL v3). In accordance with the GPL, the complete corresponding source code for the GPL-licensed components is available upon request.")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)

                    Link(destination: URL(string: "https://github.com/logn-org/chessight-ios") ?? URL(fileURLWithPath: "/")) {
                        HStack {
                            Text("View Source Code")
                                .font(AppFonts.captionBold)
                                .foregroundStyle(AppColors.accent)
                            Image(systemName: "arrow.up.right.square")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                    .padding(.top, AppSpacing.xs)
                }
                .listRowBackground(AppColors.surface)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle("Licenses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func licenseSection(name: String, version: String, license: String, description: String, url: String, gplNotice: Bool = false) -> some View {
        Section(name) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Version")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                    Spacer()
                    Text(version)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                HStack {
                    Text("License")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                    Spacer()
                    Text(license)
                        .font(AppFonts.captionBold)
                        .foregroundStyle(AppColors.accent)
                }

                Text(description)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)

                if gplNotice {
                    Text("This software is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.")
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.textMuted)
                }

                Link(destination: URL(string: url) ?? URL(fileURLWithPath: "/")) {
                    HStack(spacing: AppSpacing.xs) {
                        Text("Website")
                            .font(AppFonts.captionBold)
                            .foregroundStyle(AppColors.accent)
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.accent)
                    }
                }
            }
            .listRowBackground(AppColors.surface)
        }
    }
}
