//
//  pufferfishrunApp.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SwiftUI

@main
struct pufferfishrunApp: App {
    // AdMob setup with AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
