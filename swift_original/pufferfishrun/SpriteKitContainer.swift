//
//  SpriteKitContainer.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SwiftUI
import SpriteKit

/// A SwiftUI wrapper for SpriteKit views with debug options
struct SpriteKitContainer: View {
    let scene: SKScene
    var showsFPS: Bool = true
    var showsNodeCount: Bool = true
    var ignoresSiblingOrder: Bool = true
    
    var body: some View {
        SpriteView(
            scene: scene,
            options: [.allowsTransparency],
            debugOptions: debugOptions
        )
        .ignoresSafeArea()
    }
    
    private var debugOptions: SpriteView.DebugOptions {
        var options: SpriteView.DebugOptions = []
        if showsFPS {
            options.insert(.showsFPS)
        }
        if showsNodeCount {
            options.insert(.showsNodeCount)
        }
        return options
    }
}
