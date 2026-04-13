import SwiftUI

struct SettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var config = appState.engineConfig

        NavigationStack {
            List {
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
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            .background(AppColors.background)
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
