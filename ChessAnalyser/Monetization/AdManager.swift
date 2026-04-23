import Foundation
import UIKit
import GoogleMobileAds

/// Rewarded-ad manager. Auto-preloads the next ad so the user taps "Watch Ad" and it shows instantly.
/// Uses Google's official test ad unit during development; swap to your real unit before shipping.
@MainActor
@Observable
final class AdManager: NSObject {
    // Debug builds use Google's test rewarded unit so developers can click ads safely.
    // Release builds use the real AdMob unit. Clicking your own real ads in production
    // can get the AdMob account banned, so keep DEBUG on the test ID.
    #if DEBUG
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    static let rewardedAdUnitID = "ca-app-pub-9677620056723030/1295268970"
    #endif

    var isReady: Bool = false
    var isLoading: Bool = false

    private var rewardedAd: RewardedAd?
    private var rewardContinuation: CheckedContinuation<Bool, Never>?
    private var didEarnReward = false

    /// Call once after `MobileAds.shared.start(...)`.
    func preload() {
        Task { await loadRewardedAd() }
    }

    private func loadRewardedAd() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let ad = try await RewardedAd.load(
                with: Self.rewardedAdUnitID,
                request: Request()
            )
            ad.fullScreenContentDelegate = self
            rewardedAd = ad
            isReady = true
        } catch {
            rewardedAd = nil
            isReady = false
        }
    }

    /// Present the rewarded ad. Returns `true` if user earned the reward (watched to completion).
    func showRewardedAd() async -> Bool {
        guard let ad = rewardedAd,
              let root = Self.topViewController() else {
            // Try one load and fail fast; the caller will show an error message.
            await loadRewardedAd()
            guard let ad = rewardedAd,
                  let root = Self.topViewController() else {
                return false
            }
            return await present(ad, from: root)
        }
        return await present(ad, from: root)
    }

    private func present(_ ad: RewardedAd, from root: UIViewController) async -> Bool {
        didEarnReward = false
        isReady = false
        return await withCheckedContinuation { continuation in
            self.rewardContinuation = continuation
            ad.present(from: root) { [weak self] in
                self?.didEarnReward = true
            }
        }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first else {
            return nil
        }
        var top = window.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            let earned = self.didEarnReward
            self.rewardContinuation?.resume(returning: earned)
            self.rewardContinuation = nil
            self.rewardedAd = nil
            // Preload next one
            await self.loadRewardedAd()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            self.rewardContinuation?.resume(returning: false)
            self.rewardContinuation = nil
            self.rewardedAd = nil
            await self.loadRewardedAd()
        }
    }
}
