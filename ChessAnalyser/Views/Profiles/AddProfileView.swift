import SwiftUI

struct AddProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ProfileViewModel()
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Chess.com Username")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)

                    TextField("Enter username", text: $viewModel.searchUsername)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(AppFonts.body)
                        .padding(AppSpacing.md)
                        .background(AppColors.surfaceLight)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                        .focused($isFocused)
                }

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

                Button {
                    Task {
                        await viewModel.addProfile(to: appState.profileStore)
                        if viewModel.error == nil {
                            dismiss()
                        }
                    }
                } label: {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(viewModel.isLoading ? "Checking..." : "Add Profile")
                            .font(AppFonts.bodyBold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        viewModel.searchUsername.isEmpty ? AppColors.surfaceLight : AppColors.accent
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
                }
                .disabled(viewModel.searchUsername.isEmpty || viewModel.isLoading)

                Spacer()
            }
            .padding(AppSpacing.lg)
            .background(AppColors.background)
            .navigationTitle("Add Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}
