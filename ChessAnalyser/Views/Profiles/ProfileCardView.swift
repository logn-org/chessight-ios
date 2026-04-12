import SwiftUI

struct ProfileCardView: View {
    let profile: ChessComProfile

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Avatar placeholder
            Circle()
                .fill(AppColors.surfaceLight)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(profile.username.prefix(1)).uppercased())
                        .font(AppFonts.subtitle)
                        .foregroundStyle(AppColors.textPrimary)
                )

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(profile.username)
                    .font(AppFonts.bodyBold)
                    .foregroundStyle(AppColors.textPrimary)

                if let best = profile.ratings?.bestRating {
                    HStack(spacing: AppSpacing.xs) {
                        Text(best.category)
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textMuted)
                        Text("\(best.rating)")
                            .font(AppFonts.captionBold)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }

            Spacer()

            // Rating chips
            if let ratings = profile.ratings {
                VStack(alignment: .trailing, spacing: 2) {
                    if let rapid = ratings.rapid {
                        ratingChip("R", rating: rapid.rating)
                    }
                    if let blitz = ratings.blitz {
                        ratingChip("B", rating: blitz.rating)
                    }
                    if let bullet = ratings.bullet {
                        ratingChip("U", rating: bullet.rating)
                    }
                }
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private func ratingChip(_ label: String, rating: Int) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(AppFonts.small)
                .foregroundStyle(AppColors.textMuted)
            Text("\(rating)")
                .font(AppFonts.small)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
