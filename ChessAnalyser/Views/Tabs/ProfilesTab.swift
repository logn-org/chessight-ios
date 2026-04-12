import SwiftUI

struct ProfilesTab: View {
    @Environment(AppState.self) private var appState
    @State private var showAddProfile = false
    @State private var profileToDelete: ChessComProfile?

    var body: some View {
        NavigationStack {
            Group {
                if appState.profileStore.profiles.isEmpty {
                    emptyState
                } else {
                    profileList
                }
            }
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            .background(AppColors.background)
            .navigationTitle("Profiles")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddProfile = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showAddProfile) {
                AddProfileView()
            }
            .alert("Delete Profile", isPresented: Binding(
                get: { profileToDelete != nil },
                set: { if !$0 { profileToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { profileToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let profile = profileToDelete {
                        appState.profileStore.removeProfile(profile)
                        profileToDelete = nil
                    }
                }
            } message: {
                if let profile = profileToDelete {
                    Text("Remove \(profile.username) from saved profiles?")
                }
            }
        }
    }

    private var profileList: some View {
        List {
            ForEach(appState.profileStore.profiles) { profile in
                NavigationLink {
                    ProfileDetailView(profile: profile)
                } label: {
                    ProfileCardView(profile: profile)
                }
                .listRowBackground(AppColors.surface)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        profileToDelete = profile
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textMuted)

            Text("No profiles saved")
                .font(AppFonts.subtitle)
                .foregroundStyle(AppColors.textSecondary)

            Text("Add a chess.com username to view and analyze recent games")
                .font(AppFonts.body)
                .foregroundStyle(AppColors.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xxl)

            Button {
                showAddProfile = true
            } label: {
                Label("Add Profile", systemImage: "plus")
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.accent)
                    .clipShape(Capsule())
            }
        }
    }
}
