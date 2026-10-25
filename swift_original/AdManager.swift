//
//  AdManager.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 10/05/2026.
//

import UIKit
import GoogleMobileAds

class AdManager: NSObject {
    static let shared = AdManager()
    
    private var interstitialAd: InterstitialAd?
    private var adLoadAttempts = 0
    private let maxLoadAttempts = 3
    
    // MARK: - Ad Unit IDs
    
    // 🧪 TEST AD UNITS - Use these during development
    private let testInterstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    
    // 🚀 PRODUCTION AD UNITS - Your real AdMob ad unit
    private let productionInterstitialAdUnitID = "ca-app-pub-3366446717708247/8765817424"
    
    // Toggle this to switch between test and production
    // ✅ Set to FALSE for App Store submission to use real ads
    private let useTestAds = false  // PRODUCTION MODE - Real ads enabled
    
    private var interstitialAdUnitID: String {
        return useTestAds ? testInterstitialAdUnitID : productionInterstitialAdUnitID
    }
    
    // MARK: - Properties
    private var gamesPlayedSinceLastAd = 0
    private let gamesBeforeAd = 3  // Show ad every 3 games
    
    private override init() {
        super.init()
        loadInterstitialAd()
    }
    
    // MARK: - Load Ad
    
    private func loadInterstitialAd() {
        guard adLoadAttempts < maxLoadAttempts else {
            print("❌ AdManager: Max load attempts reached")
            return
        }
        
        adLoadAttempts += 1
        print("📱 AdManager: Loading interstitial ad (attempt \(adLoadAttempts)/\(maxLoadAttempts))")
        
        let request = Request()
        
        InterstitialAd.load(
            with: interstitialAdUnitID,
            request: request
        ) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ AdManager: Failed to load ad - \(error.localizedDescription)")
                // Retry with exponential backoff
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(self.adLoadAttempts)) {
                    self.loadInterstitialAd()
                }
                return
            }
            
            print("✅ AdManager: Ad loaded successfully")
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.adLoadAttempts = 0  // Reset counter on success
        }
    }
    
    // MARK: - Show Ad
    
    func onPlayerDied(from viewController: UIViewController) {
        gamesPlayedSinceLastAd += 1
        
        print("🎮 Games since last ad: \(gamesPlayedSinceLastAd)/\(gamesBeforeAd)")
        
        guard gamesPlayedSinceLastAd >= gamesBeforeAd else {
            print("⏭️ AdManager: Not showing ad yet")
            return
        }
        
        guard let interstitialAd = interstitialAd else {
            print("⚠️ AdManager: Ad not ready, reloading...")
            loadInterstitialAd()
            gamesPlayedSinceLastAd = 0  // Reset anyway to avoid spam
            return
        }
        
        print("📺 AdManager: Presenting interstitial ad")
        interstitialAd.present(from: viewController)
        gamesPlayedSinceLastAd = 0
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("✅ AdManager: Ad dismissed")
        loadInterstitialAd()  // Load next ad
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ AdManager: Failed to present ad - \(error.localizedDescription)")
        loadInterstitialAd()  // Try to load another ad
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📺 AdManager: Ad will present")
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("👁️ AdManager: Ad impression recorded")
    }
}
