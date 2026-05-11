//
//  AdManager.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 10/05/2026.
//

import GoogleMobileAds
import UIKit

class AdManager: NSObject, GADFullScreenContentDelegate {

    static let shared = AdManager()

    private var interstitial: GADInterstitialAd?
    private var deathCount: Int = 0

    // TEST ID — replace before App Store submission:
    // ca-app-pub-3366446717708247/xxxxxxxxxx
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910"

    private override init() {
        super.init()
        loadAd()
    }

    func loadAd() {
        let request = GADRequest()
        GADInterstitialAd.load(
            withAdUnitID: adUnitID,
            request: request
        ) { [weak self] ad, error in
            if let error = error {
                print("AdMob load error: \(error)")
                return
            }
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
        }
    }

    func onPlayerDied(from viewController: UIViewController) {
        deathCount += 1
        if deathCount >= 3 {
            deathCount = 0
            showAd(from: viewController)
        }
    }

    private func showAd(from viewController: UIViewController) {
        guard let ad = interstitial else {
            print("Ad not ready — preloading next")
            loadAd()
            return
        }
        ad.present(fromRootViewController: viewController)
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        loadAd()
    }

    func ad(
        _ ad: GADFullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("Ad failed: \(error)")
        loadAd()
    }
}
