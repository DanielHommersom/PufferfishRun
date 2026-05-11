//
//  GameViewController.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = self.view as! SKView
        view.ignoresSiblingOrder = true
        view.showsFPS = true      // remove before release
        view.showsNodeCount = true // remove before release
        
        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .aspectFill
        view.presentScene(scene)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
