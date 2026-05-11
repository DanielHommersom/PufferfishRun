//
//  GameOverScene.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SpriteKit

class GameOverScene: SKScene {

    // MARK: - Properties
    private let finalScore: Int
    private let highScore: Int
    private var soundButton: SoundButton!

    init(size: CGSize, score: Int) {
        self.finalScore = score
        self.highScore = max(
            score,
            UserDefaults.standard.integer(forKey: "highScore")
        )
        super.init(size: size)

        // Save high score
        if score >= UserDefaults.standard
            .integer(forKey: "highScore") {
            UserDefaults.standard.set(
                score, forKey: "highScore")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func didMove(to view: SKView) {
        // Show ad on game over
        if let vc = view.window?.rootViewController {
            AdManager.shared.onPlayerDied(from: vc)
        }
        
        backgroundColor = SKColor(
            red: 0.02, green: 0.08, blue: 0.16, alpha: 1.0)

        setupDarkOverlay()
        setupTitle()
        setupScorePanel()
        setupButtons()
        setupBubbles()
        
        soundButton = SoundButton(
            position: CGPoint(
                x: size.width - 50,
                y: 50
            )
        )
        soundButton.zPosition = 20
        addChild(soundButton)
    }

    private func setupDarkOverlay() {
        let overlay = SKSpriteNode(
            color: UIColor.black.withAlphaComponent(0.55),
            size: size)
        overlay.position = CGPoint(
            x: size.width/2, y: size.height/2)
        overlay.zPosition = -1
        addChild(overlay)
    }

    private func setupTitle() {
        let shadow = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        shadow.text = "GAME OVER"
        shadow.fontSize = 36
        shadow.fontColor = UIColor.black.withAlphaComponent(0.4)
        shadow.position = CGPoint(
            x: size.width/2 + 4,
            y: size.height * 0.80 - 4
        )
        addChild(shadow)

        let title = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        title.text = "GAME OVER"
        title.fontSize = 36
        title.fontColor = SKColor(
            red: 1.0, green: 0.267, blue: 0.267, alpha: 1.0)
        title.position = CGPoint(
            x: size.width/2,
            y: size.height * 0.80
        )
        title.setScale(2.0)
        title.alpha = 0
        title.zPosition = 10
        addChild(title)

        title.run(SKAction.group([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.4)
        ]))
    }

    private func setupScorePanel() {
        let panelW: CGFloat = 300
        let panelH: CGFloat = 220
        let panelX = size.width/2 - panelW/2
        let panelY = size.height * 0.46

        // Outer glow
        let glow = SKShapeNode(
            rect: CGRect(x: panelX - 4, y: panelY - 4,
                         width: panelW + 8, height: panelH + 8),
            cornerRadius: 22)
        glow.fillColor = SKColor(
            red: 0.102, green: 0.416, blue: 0.478, alpha: 1.0)
        glow.lineWidth = 0
        addChild(glow)

        // Panel
        let panel = SKShapeNode(
            rect: CGRect(x: panelX, y: panelY,
                         width: panelW, height: panelH),
            cornerRadius: 20)
        panel.fillColor = SKColor(
            red: 0.039, green: 0.165, blue: 0.290, alpha: 1.0)
        panel.lineWidth = 4
        panel.strokeColor = .black
        addChild(panel)

        // Score label
        let scoreTitle = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        scoreTitle.text = "SCORE"
        scoreTitle.fontSize = 13
        scoreTitle.fontColor = SKColor(
            red: 0.533, green: 0.667, blue: 0.733, alpha: 1.0)
        scoreTitle.position = CGPoint(
            x: size.width/2,
            y: panelY + panelH - 36
        )
        addChild(scoreTitle)

        // Animated score count up
        let scoreValue = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        scoreValue.text = "0"
        scoreValue.fontSize = 52
        scoreValue.fontColor = .white
        scoreValue.position = CGPoint(
            x: size.width/2,
            y: panelY + panelH * 0.55
        )
        scoreValue.zPosition = 10
        addChild(scoreValue)

        // Count up animation
        var currentCount = 0
        let countAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    if currentCount < self.finalScore {
                        currentCount += max(
                            1, self.finalScore / 20)
                        currentCount = min(
                            currentCount, self.finalScore)
                        scoreValue.text = "\(currentCount)"
                    }
                },
                SKAction.wait(forDuration: 0.04)
            ])
        )
        scoreValue.run(countAction)

        // Divider
        let divider = SKShapeNode(
            rect: CGRect(
                x: panelX + 20,
                y: panelY + panelH * 0.48,
                width: panelW - 40, height: 2
            )
        )
        divider.fillColor = SKColor(
            red: 0.102, green: 0.290, blue: 0.416, alpha: 1.0)
        divider.lineWidth = 0
        addChild(divider)

        // Best label
        let bestTitle = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        bestTitle.text = "BEST"
        bestTitle.fontSize = 13
        bestTitle.fontColor = SKColor(
            red: 0.533, green: 0.667, blue: 0.733, alpha: 1.0)
        bestTitle.position = CGPoint(
            x: size.width/2,
            y: panelY + panelH * 0.36
        )
        addChild(bestTitle)

        let isNewRecord = finalScore >= UserDefaults.standard
            .integer(forKey: "highScore")

        let bestValue = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        bestValue.text = "\(highScore)"
        bestValue.fontSize = 42
        bestValue.fontColor = isNewRecord
            ? SKColor(red:0.957,green:0.659,blue:0.196,alpha:1)
            : .white
        bestValue.position = CGPoint(
            x: size.width/2,
            y: panelY + panelH * 0.12
        )
        addChild(bestValue)

        if isNewRecord {
            let newRecord = SKLabelNode(
                fontNamed: "CourierNewPS-BoldMT")
            newRecord.text = "NEW BEST!"
            newRecord.fontSize = 11
            newRecord.fontColor = SKColor(
                red:0.957,green:0.659,blue:0.196,alpha:1)
            newRecord.position = CGPoint(
                x: size.width/2,
                y: panelY + panelH * 0.06
            )
            addChild(newRecord)

            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3),
            ])
            newRecord.run(SKAction.repeatForever(pulse))
        }

        // Medal
        let medal = medalForScore(finalScore)
        if let (color, label) = medal {
            let medalCircle = SKShapeNode(circleOfRadius: 24)
            medalCircle.position = CGPoint(
                x: panelX + 44,
                y: panelY + panelH * 0.30
            )
            medalCircle.fillColor = color
            medalCircle.lineWidth = 3
            medalCircle.strokeColor = .black
            addChild(medalCircle)

            let medalLabel = SKLabelNode(
                fontNamed: "CourierNewPS-BoldMT")
            medalLabel.text = label
            medalLabel.fontSize = 9
            medalLabel.fontColor = .black
            medalLabel.verticalAlignmentMode = .center
            medalLabel.position = medalCircle.position
            addChild(medalLabel)
        }
    }

    private func medalForScore(
        _ score: Int
    ) -> (SKColor, String)? {
        if score >= 40 {
            return (SKColor(
                red:0.969,green:0.761,blue:0.204,alpha:1), "GOLD")
        } else if score >= 20 {
            return (SKColor(
                red:0.753,green:0.753,blue:0.753,alpha:1), "SILVER")
        } else if score >= 10 {
            return (SKColor(
                red:0.804,green:0.498,blue:0.196,alpha:1), "BRONZE")
        }
        return nil
    }

    private func setupButtons() {
        // PLAY AGAIN
        makeButton(
            text: "PLAY AGAIN",
            color: SKColor(
                red:0.267,green:0.800,blue:0.267,alpha:1),
            y: size.height * 0.34,
            name: "retry"
        )

        // MAIN MENU
        makeButton(
            text: "MAIN MENU",
            color: SKColor(
                red:0.102,green:0.290,blue:0.416,alpha:1),
            y: size.height * 0.24,
            name: "menu"
        )
    }

    private func makeButton(
        text: String,
        color: SKColor,
        y: CGFloat,
        name: String
    ) {
        let w: CGFloat = 280
        let h: CGFloat = 62
        let x = size.width/2 - w/2

        let shadow = SKShapeNode(
            rect: CGRect(x: x+4, y: y-4,
                         width: w, height: h),
            cornerRadius: 14)
        shadow.fillColor = .black
        shadow.lineWidth = 0
        addChild(shadow)

        let btn = SKShapeNode(
            rect: CGRect(x: x, y: y, width: w, height: h),
            cornerRadius: 12)
        btn.fillColor = color
        btn.lineWidth = 3
        btn.strokeColor = .black
        btn.name = name
        addChild(btn)

        let label = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        label.text = text
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(
            x: size.width/2, y: y + h/2)
        label.name = name
        addChild(label)

        // Entrance animation
        btn.alpha = 0
        btn.position.y -= 30
        label.alpha = 0
        label.position.y -= 30

        let delay = name == "retry" ? 0.9 : 1.1
        let slideUp = SKAction.moveBy(
            x: 0, y: 30, duration: 0.4)
        slideUp.timingMode = .easeOut

        btn.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.4),
                slideUp
            ])
        ]))
        label.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.4),
                slideUp.copy() as! SKAction
            ])
        ]))
    }

    private func setupBubbles() {
        for _ in 0..<5 {
            let r = CGFloat.random(in: 5...12)
            let bubble = SKShapeNode(circleOfRadius: r)
            bubble.fillColor = UIColor.white
                .withAlphaComponent(0.10)
            bubble.lineWidth = 1
            bubble.strokeColor = .black
            bubble.position = CGPoint(
                x: CGFloat.random(in: 20...(size.width-20)),
                y: -20
            )
            bubble.zPosition = -2
            addChild(bubble)

            let moveUp = SKAction.moveBy(
                x: 0, y: size.height + 40,
                duration: Double.random(in: 4...7))
            bubble.run(SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.wait(forDuration:
                        Double.random(in: 0...3)),
                    moveUp
                ])
            ))
        }
    }

    // MARK: - Touch
    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        for node in tapped {
            if node.name == "retry" {
                let scene = GameScene(size: size)
                scene.scaleMode = scaleMode
                view?.presentScene(scene,
                                  transition: SKTransition.fade(
                                    withDuration: 0.3))
                return
            }
            if node.name == "menu" {
                let scene = MenuScene(size: size)
                scene.scaleMode = scaleMode
                view?.presentScene(scene,
                                  transition: SKTransition.fade(
                                    withDuration: 0.3))
                return
            }
        }
    }
}
