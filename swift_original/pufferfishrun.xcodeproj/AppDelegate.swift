//
//  AppDelegate.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 10/05/2026.
//

import UIKit
import GoogleMobileAds
import AppTrackingTransparency

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }

    func applicationDidBecomeActive(
        _ application: UIApplication
    ) {
        if #available(iOS 14.5, *) {
            ATTrackingManager
                .requestTrackingAuthorization { _ in
                    DispatchQueue.main.async {
                        GADMobileAds.sharedInstance()
                            .start(completionHandler: nil)
                    }
                }
        } else {
            GADMobileAds.sharedInstance()
                .start(completionHandler: nil)
        }
    }
}
