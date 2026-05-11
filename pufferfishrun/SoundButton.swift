//
//  SoundButton.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 10/05/2026.
//

import SpriteKit

class SoundButton: SKNode {

    private var buttonBg: SKShapeNode!
    private var iconLabel: SKLabelNode!
    private var onToggle: ((Bool) -> Void)?

    init(position: CGPoint, onToggle: ((Bool) -> Void)? = nil) {
        self.onToggle = onToggle
        super.init()
        self.position = position
        self.isUserInteractionEnabled = true
        setup()
        updateIcon()
    }

    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }

    private func setup() {
        // Button background
        let outline = SKShapeNode(circleOfRadius: 30)
        outline.fillColor = .black
        outline.lineWidth = 0
        addChild(outline)

        buttonBg = SKShapeNode(circleOfRadius: 27)
        buttonBg.fillColor = SKColor(
            red: 0.102, green: 0.290, blue: 0.416, alpha: 1)
        buttonBg.lineWidth = 2
        buttonBg.strokeColor = .black
        addChild(buttonBg)

        // Speaker icon using emoji/text
        iconLabel = SKLabelNode(fontNamed: "Arial")
        iconLabel.fontSize = 22
        iconLabel.verticalAlignmentMode = .center
        iconLabel.horizontalAlignmentMode = .center
        addChild(iconLabel)
    }

    private func updateIcon() {
        iconLabel.text = SoundManager.shared.isMuted ? "🔇" : "🔊"
    }

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        // Press animation
        run(SKAction.sequence([
            SKAction.scale(to: 0.88, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.08),
        ]))

        // Toggle mute
        SoundManager.shared.isMuted.toggle()
        updateIcon()
        onToggle?(SoundManager.shared.isMuted)
    }
}
