import SwiftUI

struct GameListItemView: View {
    let game: ChessComGame
    let username: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Result indicator
            resultBadge

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Opponent name
                HStack(spacing: AppSpacing.xs) {
                    Text("vs \(game.opponent(for: username).username)")
                        .font(AppFonts.bodyBold)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    Text("(\(game.opponent(for: username).rating))")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                }

                // Game info
                HStack(spacing: AppSpacing.sm) {
                    // Time class
                    Label(game.timeClass.label, systemImage: game.timeClass.icon)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    // Side played
                    HStack(spacing: 2) {
                        Circle()
                            .fill(game.userSide(for: username) == .white ? Color.white : Color.black)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(AppColors.surfaceLight, lineWidth: 0.5))
                    }

                    // Date
                    Text(game.endTime.timeAgoDisplay)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                }
            }

            Spacer()
        }
        .padding(.vertical, AppSpacing.xs)
    }

    private var resultBadge: some View {
        let result = game.userResult(for: username)
        return Text(result.symbol)
            .font(AppFonts.captionBold)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(resultColor(result))
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusSm))
    }

    private func resultColor(_ result: GameResult) -> Color {
        switch result {
        case .win: return AppColors.win
        case .loss: return AppColors.loss
        case .draw: return AppColors.draw
        }
    }
}
