import SwiftUI

struct AnalysisPaywallView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let onPremium: () -> Void
    let onWatchAd: () -> Void
    let onViewFree: () -> Void

    @State private var isPurchasing = false
    @State private var isLoadingAd = false
    @State private var tick = 0
    private let countdownTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(AppColors.surfaceLight)
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            VStack(spacing: AppSpacing.lg) {
                // Header
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(AppColors.accent)

                    Text("You've used today's free analysis")
                        .font(AppFonts.title)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(appState.analysisQuota.resetCountdownText)
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textMuted)
                        .id(tick) // forces recompute each timer tick
                }
                .padding(.top, AppSpacing.md)

                // Options
                VStack(spacing: AppSpacing.sm) {
                    premiumButton
                    watchAdButton
                    viewFreeButton
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xl)
        }
        .background(AppColors.background)
        .onReceive(countdownTimer) { _ in tick &+= 1 }
    }

    // MARK: - Buttons

    private var premiumButton: some View {
        Button {
            guard !isPurchasing else { return }
            isPurchasing = true
            Task {
                let ok = await appState.premium.purchase()
                isPurchasing = false
                if ok {
                    onPremium()
                    dismiss()
                }
            }
        } label: {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                    Text("Go Premium")
                        .font(AppFonts.bodyBold)
                    Spacer()
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else if !appState.premium.displayPrice.isEmpty {
                        Text(appState.premium.displayPrice)
                            .font(AppFonts.bodyBold)
                    }
                }
                HStack {
                    Text("Unlimited analyses · No ads · One-time purchase")
                        .font(AppFonts.small)
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                }
            }
            .foregroundStyle(.white)
            .padding(AppSpacing.md)
            .background(
                LinearGradient(
                    colors: [AppColors.accent, AppColors.accent.opacity(0.8)],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    private var watchAdButton: some View {
        Button {
            guard !isLoadingAd else { return }
            isLoadingAd = true
            Task {
                let earned = await appState.ads.showRewardedAd()
                isLoadingAd = false
                if earned {
                    onWatchAd()
                    dismiss()
                }
            }
        } label: {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Watch Ad")
                        .font(AppFonts.bodyBold)
                    Text("Unlock this analysis")
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.textMuted)
                }
                Spacer()
                if isLoadingAd {
                    ProgressView().tint(AppColors.accent)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.textMuted)
                }
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(isLoadingAd)
    }

    private var viewFreeButton: some View {
        Button {
            onViewFree()
            dismiss()
        } label: {
            HStack {
                Image(systemName: "eye")
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text("View Game Free")
                        .font(AppFonts.bodyBold)
                    Text("Navigate moves · No engine insights")
                        .font(AppFonts.small)
                        .foregroundStyle(AppColors.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
            }
            .foregroundStyle(AppColors.textSecondary)
            .padding(AppSpacing.md)
            .background(AppColors.surface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}
