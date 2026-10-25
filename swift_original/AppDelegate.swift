//
//  AppDelegate.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 10/05/2026.
//

import UIKit
import GoogleMobileAds
import AppTrackingTransparency

class AppDelegate: NSObject, UIApplicationDelegate {
    
    private var hasRequestedTracking = false
    private var adMobInitialized = false
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("🚀 App launched - iOS \(UIDevice.current.systemVersion)")
        
        // Check if Info.plist key exists
        if let trackingDescription = Bundle.main.object(forInfoDictionaryKey: "NSUserTrackingUsageDescription") as? String {
            print("✅ NSUserTrackingUsageDescription found: '\(trackingDescription)'")
        } else {
            print("❌❌❌ ERROR: NSUserTrackingUsageDescription NOT FOUND in Info.plist!")
            print("❌ The ATT prompt WILL NOT appear without this key!")
            print("❌ Add it in Xcode: Target → Info → + 'Privacy - Tracking Usage Description'")
        }
        
        // Request ATT after a delay to ensure window is visible
        // This is required for SwiftUI apps
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("📱 2 seconds passed - requesting ATT now")
            self.requestTrackingPermission()
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("📱 App became active (UIKit lifecycle)")
    }
    
    // Public method that SwiftUI can call
    func requestATTFromSwiftUI() {
        print("📱 ATT request triggered from SwiftUI")
        // Small delay to ensure UI is fully loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.requestTrackingPermission()
        }
    }
    
    private func requestTrackingPermission() {
        guard !hasRequestedTracking else {
            print("⏭️ ATT already requested this session")
            return
        }
        
        hasRequestedTracking = true
        
        if #available(iOS 14.5, *) {
            let currentStatus = ATTrackingManager.trackingAuthorizationStatus
            print("📊 Current ATT status: \(currentStatus.rawValue) - \(statusName(currentStatus))")
            
            if currentStatus != .notDetermined {
                print("ℹ️ User already responded to ATT prompt before")
                print("💡 To test again: Delete app, then Settings → General → Reset → Reset Location & Privacy")
                initializeAdMob()
                return
            }
            
            print("✨ Status is .notDetermined - prompt WILL appear")
            print("⏳ Waiting 1 second...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("🔔 REQUESTING ATT AUTHORIZATION NOW - WATCH FOR SYSTEM PROMPT!")
                
                ATTrackingManager.requestTrackingAuthorization { status in
                    print("📥 ATT response received!")
                    
                    DispatchQueue.main.async {
                        switch status {
                        case .authorized:
                            print("✅ ATT: User AUTHORIZED tracking")
                        case .denied:
                            print("❌ ATT: User DENIED tracking")
                        case .notDetermined:
                            print("⚠️ ATT: Status NOT DETERMINED (shouldn't happen)")
                        case .restricted:
                            print("🚫 ATT: RESTRICTED (check Settings → Screen Time)")
                        @unknown default:
                            print("❓ ATT: Unknown status")
                        }
                        
                        self.initializeAdMob()
                    }
                }
            }
        } else {
            print("📱 iOS < 14.5 - ATT not available, initializing AdMob")
            initializeAdMob()
        }
    }
    
    private func initializeAdMob() {
        guard !adMobInitialized else {
            print("⏭️ AdMob already initialized")
            return
        }
        
        adMobInitialized = true
        print("🚀 Initializing Google Mobile Ads SDK...")
        
        MobileAds.shared.start { status in
            print("✅ AdMob initialized successfully")
        }
        
        #if DEBUG
        // Use both the generic simulator ID and your specific device ID
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [
            "SIMULATOR",
            "5538de831287f2fd84dfa736cfdea1d5" // Your actual test device
        ]
        print("🧪 Test ads enabled for simulator and device: 5538de831287f2fd84dfa736cfdea1d5")
        #endif
    }
    
    private func statusName(_ status: ATTrackingManager.AuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        @unknown default: return "Unknown"
        }
    }
}
