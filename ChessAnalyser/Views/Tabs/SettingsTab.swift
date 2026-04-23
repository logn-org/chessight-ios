import SwiftUI

struct SettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var config = appState.engineConfig

        NavigationStack {
            List {
                premiumSection

                Section("Engine") {
                    Picker("Analysis Depth", selection: $config.depthPreset) {
                        ForEach(AnalysisDepthPreset.allCases) { preset in
                            VStack(alignment: .leading) {
                                Text(preset.label)
                                Text(preset.description)
                                    .font(AppFonts.caption)
                                    .foregroundStyle(AppColors.textMuted)
                            }
                            .tag(preset)
                        }
                    }
                    .listRowBackground(AppColors.surface)

                    HStack {
                        Text("Threads")
                        Spacer()
                        Stepper("\(config.threads)", value: $config.threads, in: 1...4)
                    }
                    .listRowBackground(AppColors.surface)

                    HStack {
                        Text("Hash (MB)")
                        Spacer()
                        Stepper("\(config.hashMB)", value: $config.hashMB, in: 16...256, step: 16)
                    }
                    .listRowBackground(AppColors.surface)

                    HStack {
                        Text("Engine Lines")
                        Spacer()
                        Stepper("\(config.multiPV)", value: $config.multiPV, in: 1...5)
                    }
                    .listRowBackground(AppColors.surface)
                }

                Section("Board Arrows") {
                    Toggle(isOn: $config.showBestMoveArrow) {
                        HStack(spacing: AppSpacing.sm) {
                            Circle().fill(AppColors.bestMoveArrow).frame(width: 12, height: 12)
                            Text("Best Move")
                        }
                    }
                    .listRowBackground(AppColors.surface)
                    .tint(AppColors.accent)

                    Toggle(isOn: $config.showAttackArrows) {
                        HStack(spacing: AppSpacing.sm) {
                            Circle().fill(AppColors.attackArrow).frame(width: 12, height: 12)
                            Text("Threats (opponent attacks)")
                        }
                    }
                    .listRowBackground(AppColors.surface)
                    .tint(AppColors.accent)

                    Toggle(isOn: $config.showDefenseArrows) {
                        HStack(spacing: AppSpacing.sm) {
                            Circle().fill(AppColors.defenseArrow).frame(width: 12, height: 12)
                            Text("Defenders (your pieces)")
                        }
                    }
                    .listRowBackground(AppColors.surface)
                    .tint(AppColors.accent)
                }

                Section("Board") {
                    Toggle("Show Coordinates", isOn: $config.showBoardCoordinates)
                        .listRowBackground(AppColors.surface)
                        .tint(AppColors.accent)
                }

                Section("Sound") {
                    Toggle("Piece Sounds", isOn: Binding(
                        get: { SoundManager.shared.soundEnabled },
                        set: { SoundManager.shared.soundEnabled = $0 }
                    ))
                    .listRowBackground(AppColors.surface)
                    .tint(AppColors.accent)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        HStack(spacing: AppSpacing.xs) {
                            Text("1.0.0")
                                .foregroundStyle(AppColors.textSecondary)
                            Text("BETA")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(AppColors.inaccuracy)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    .listRowBackground(AppColors.surface)

                    HStack {
                        Text("Engine")
                        Spacer()
                        Text("Stockfish 18")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .listRowBackground(AppColors.surface)

                    HStack {
                        Text("NNUE Model")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("nn-7bf13f9655c8")
                                .font(AppFonts.small)
                                .foregroundStyle(AppColors.textSecondary)
                            Text("nn-47fc8b7fff06 (small)")
                                .font(AppFonts.small)
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                    .listRowBackground(AppColors.surface)

                    HStack {
                        Text("Developer")
                        Spacer()
                        Text("LogNComplexity")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .listRowBackground(AppColors.surface)

                    Link(destination: URL(string: "https://logn-org.github.io/policies/chessight/privacy-policy.html") ?? URL(fileURLWithPath: "/")) {
                        HStack {
                            Text("Privacy Policy")
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                    .listRowBackground(AppColors.surface)

                    NavigationLink {
                        LicensesView()
                    } label: {
                        HStack {
                            Text("Open Source Licenses")
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                    .listRowBackground(AppColors.surface)
                }

                Section("Help & Feedback") {
                    Link(destination: URL(string: "https://tally.so/r/vGO5NQ") ?? URL(fileURLWithPath: "/")) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "ladybug.fill")
                                .foregroundStyle(AppColors.blunder)
                                .frame(width: 24)
                            Text("Report a Bug")
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                    .listRowBackground(AppColors.surface)

                    Link(destination: URL(string: "https://tally.so/r/44olMo") ?? URL(fileURLWithPath: "/")) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(AppColors.inaccuracy)
                                .frame(width: 24)
                            Text("Request a Feature")
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                    .listRowBackground(AppColors.surface)

                    Link(destination: URL(string: "https://tally.so/r/yPE5x0") ?? URL(fileURLWithPath: "/")) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(AppColors.accent)
                                .frame(width: 24)
                            Text("Rate Chessight")
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                    .listRowBackground(AppColors.surface)

                    Link(destination: URL(string: "mailto:help@chessight.app") ?? URL(fileURLWithPath: "/")) {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(AppColors.great)
                                .frame(width: 24)
                            Text("Contact Us")
                                .foregroundStyle(AppColors.textPrimary)
                            Spacer()
                            Text("help@chessight.app")
                                .font(AppFonts.caption)
                                .foregroundStyle(AppColors.textMuted)
                        }
                    }
                    .listRowBackground(AppColors.surface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                Analytics.screenViewed("settings")
            }
        }
    }

    // MARK: - Premium

    @ViewBuilder
    private var premiumSection: some View {
        if appState.premium.isPremium {
            Section("Premium") {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(AppColors.accent)
                    Text("Premium")
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Text("Active")
                        .font(AppFonts.captionBold)
                        .foregroundStyle(AppColors.best)
                }
                .listRowBackground(AppColors.surface)
            }
        } else {
            Section {
                Button {
                    Task { _ = await appState.premium.purchase() }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(AppColors.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Premium")
                                .font(AppFonts.bodyBold)
                                .foregroundStyle(AppColors.textPrimary)
                            Text("Unlimited analyses · No ads")
                                .font(AppFonts.small)
                                .foregroundStyle(AppColors.textMuted)
                        }
                        Spacer()
                        if appState.premium.isPurchasing {
                            ProgressView().tint(AppColors.accent)
                        } else if !appState.premium.displayPrice.isEmpty {
                            Text(appState.premium.displayPrice)
                                .font(AppFonts.captionBold)
                                .foregroundStyle(AppColors.accent)
                        }
                    }
                }
                .disabled(appState.premium.isPurchasing)
                .listRowBackground(AppColors.surface)

                Button {
                    Task { await appState.premium.restore() }
                } label: {
                    HStack {
                        Text("Restore Purchases")
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
                .listRowBackground(AppColors.surface)
            }
        }
    }
}
