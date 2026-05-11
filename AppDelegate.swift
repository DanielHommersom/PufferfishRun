//
//  AppDelegate.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 10/05/2026.
//

import UIKit
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Google Mobile Ads SDK
        MobileAds.shared.start()
        
        // OPTIONAL: Enable test mode for simulator
        #if DEBUG
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["SIMULATOR"]
        #endif
        
        return true
    }
}
