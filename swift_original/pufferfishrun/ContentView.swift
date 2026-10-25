//
//  ContentView.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    var body: some View {
        SpriteKitContainer(
            scene: createGameScene(),
            showsFPS: false,
            showsNodeCount: false
        )
        .statusBar(hidden: true)
    }
    
    private func createGameScene() -> SKScene {
        let scene = StudioSplashScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .aspectFill
        return scene
    }
}

#Preview {
    ContentView()
}
