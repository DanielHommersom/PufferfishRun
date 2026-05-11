//
//  MenuScene.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SpriteKit

class MenuScene: SKScene {

    // MARK: - Properties
    private var fishNode: SKNode!
    private var fishGraphics: SKShapeNode!
    private var titlePuffer: SKLabelNode!
    private var titleRun: SKLabelNode!
    private var playButton: SKShapeNode!
    private var skinButton: SKShapeNode!
    private var bestLabel: SKLabelNode!
    private var selectedSkinId: String = "default"
    private var soundButton: SoundButton!

    // MARK: - didMove
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(
            red: 0.04, green: 0.16, blue: 0.29, alpha: 1.0)

        setupBackground()
        loadSkinAndSetup()
    }

    // MARK: - Setup
    private func loadSkinAndSetup() {
        // Load selected skin from UserDefaults
        selectedSkinId = UserDefaults.standard
            .string(forKey: "selectedSkin") ?? "default"

        setupFish()
        setupTitle()
        setupTutorialPanel()
        setupButtons()
        setupBestScore()
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

    private func setupBackground() {
        // Ocean gradient layers
        let layers: [(SKColor, CGFloat, CGFloat)] = [
            (SKColor(red:0.306,green:0.753,blue:0.792,alpha:1),
             size.height * 0.45, size.height * 0.55),
            (SKColor(red:0.165,green:0.541,blue:0.604,alpha:1),
             size.height * 0.18, size.height * 0.27),
            (SKColor(red:0.051,green:0.227,blue:0.361,alpha:1),
             0, size.height * 0.18),
        ]

        for (color, y, h) in layers {
            let node = SKSpriteNode(color: color,
                                    size: CGSize(width: size.width, height: h))
            node.anchorPoint = CGPoint(x: 0, y: 0)
            node.position = CGPoint(x: 0, y: y)
            node.zPosition = -10
            addChild(node)
        }

        // Coral decorations bottom
        for (x, h) in [(60, 80), (size.width/2, 60),
                       (size.width - 60, 80)] as [(CGFloat,Int)] {
            drawCoralStump(at: CGPoint(x: x, y: 0), height: CGFloat(h))
        }
    }

    private func drawCoralStump(at pos: CGPoint, height: CGFloat) {
        let outline = SKShapeNode(
            rect: CGRect(x: pos.x - 14, y: pos.y,
                         width: 28, height: height),
            cornerRadius: 4)
        outline.fillColor = .black
        outline.lineWidth = 0
        outline.zPosition = -5
        addChild(outline)

        let fill = SKShapeNode(
            rect: CGRect(x: pos.x - 12, y: pos.y,
                         width: 24, height: height - 2),
            cornerRadius: 3)
        fill.fillColor = COLOR_CORAL_BASE
        fill.lineWidth = 0
        fill.zPosition = -4
        addChild(fill)
    }

    private func setupFish() {
        fishNode = SKNode()
        fishNode.position = CGPoint(
            x: size.width / 2,
            y: size.height * 0.62
        )
        addChild(fishNode)

        // Draw fish using selected skin
        let skin = SKINS.first {
            $0.id == selectedSkinId
        } ?? SKINS[0]

        drawMenuFish(skin: skin, radius: 52)

        // Bob animation
        let bobUp = SKAction.moveBy(
            x: 0, y: 14, duration: 0.9)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = bobUp.reversed()
        fishNode.run(SKAction.repeatForever(
            SKAction.sequence([bobUp, bobDown])
        ))
    }

    private func drawMenuFish(skin: SkinDefinition,
                              radius r: CGFloat) {
        fishNode.removeAllChildren()

        // Tail
        let tailOutline = CGMutablePath()
        tailOutline.move(to: CGPoint(x: -r*1.1, y: r*0.55))
        tailOutline.addLine(to: CGPoint(x: -r*1.1, y: -r*0.55))
        tailOutline.addLine(to: CGPoint(x: -r*1.7, y: 0))
        tailOutline.closeSubpath()
        let tailO = SKShapeNode(path: tailOutline)
        tailO.fillColor = .black
        tailO.lineWidth = 0
        fishNode.addChild(tailO)

        let tailFill = CGMutablePath()
        tailFill.move(to: CGPoint(x: -r*1.0, y: r*0.48))
        tailFill.addLine(to: CGPoint(x: -r*1.0, y: -r*0.48))
        tailFill.addLine(to: CGPoint(x: -r*1.6, y: 0))
        tailFill.closeSubpath()
        let tailF = SKShapeNode(path: tailFill)
        tailF.fillColor = skin.tailColor
        tailF.lineWidth = 0
        fishNode.addChild(tailF)

        // Body
        let bodyOutline = SKShapeNode(ellipseOf: CGSize(
            width: r*2.3+6, height: r*2.0+6))
        bodyOutline.fillColor = .black
        bodyOutline.lineWidth = 0
        fishNode.addChild(bodyOutline)

        let body = SKShapeNode(ellipseOf: CGSize(
            width: r*2.3, height: r*2.0))
        body.fillColor = skin.bodyColor
        body.lineWidth = 0
        fishNode.addChild(body)

        // Highlight
        let hl = SKShapeNode(ellipseOf: CGSize(
            width: r*0.75, height: r*0.42))
        hl.position = CGPoint(x: -r*0.2, y: r*0.35)
        hl.fillColor = UIColor.white.withAlphaComponent(0.45)
        hl.lineWidth = 0
        fishNode.addChild(hl)

        // Spines (8 for menu preview)
        for i in 0..<8 {
            let angle = CGFloat(i) / 8 * .pi * 2
            let sx = cos(angle) * r * 1.08
            let sy = sin(angle) * r * 0.92
            let spineO = SKShapeNode(circleOfRadius: 6)
            spineO.position = CGPoint(x: sx, y: sy)
            spineO.fillColor = .black
            spineO.lineWidth = 0
            fishNode.addChild(spineO)
            let spine = SKShapeNode(circleOfRadius: 4)
            spine.position = CGPoint(x: sx, y: sy)
            spine.fillColor = skin.spineColor
            spine.lineWidth = 0
            fishNode.addChild(spine)
        }

        // Eye
        let eyeO = SKShapeNode(circleOfRadius: r*0.32+3)
        eyeO.position = CGPoint(x: r*0.55, y: r*0.22)
        eyeO.fillColor = .black
        eyeO.lineWidth = 0
        fishNode.addChild(eyeO)

        let eyeW = SKShapeNode(circleOfRadius: r*0.30)
        eyeW.position = CGPoint(x: r*0.55, y: r*0.22)
        eyeW.fillColor = .white
        eyeW.lineWidth = 0
        fishNode.addChild(eyeW)

        let iris = SKShapeNode(circleOfRadius: r*0.18)
        iris.position = CGPoint(x: r*0.58, y: r*0.20)
        iris.fillColor = skin.eyeColor
        iris.lineWidth = 0
        fishNode.addChild(iris)

        let pupil = SKShapeNode(circleOfRadius: r*0.10)
        pupil.position = CGPoint(x: r*0.61, y: r*0.18)
        pupil.fillColor = .black
        pupil.lineWidth = 0
        fishNode.addChild(pupil)

        let eyeHl = SKShapeNode(circleOfRadius: r*0.07)
        eyeHl.position = CGPoint(x: r*0.52, y: r*0.27)
        eyeHl.fillColor = .white
        eyeHl.lineWidth = 0
        fishNode.addChild(eyeHl)
    }

    private func setupTitle() {
        // Shadow
        let shadow1 = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        shadow1.text = "PUFFERFISH"
        shadow1.fontSize = 38
        shadow1.fontColor = UIColor.black.withAlphaComponent(0.4)
        shadow1.position = CGPoint(
            x: size.width/2 + 4,
            y: size.height * 0.44 - 4
        )
        shadow1.zPosition = 8
        addChild(shadow1)

        let shadow2 = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        shadow2.text = "RUN"
        shadow2.fontSize = 52
        shadow2.fontColor = UIColor.black.withAlphaComponent(0.4)
        shadow2.position = CGPoint(
            x: size.width/2 + 4,
            y: size.height * 0.37 - 4
        )
        shadow2.zPosition = 8
        addChild(shadow2)

        // Title
        titlePuffer = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        titlePuffer.text = "PUFFERFISH"
        titlePuffer.fontSize = 38
        titlePuffer.fontColor = .white
        titlePuffer.position = CGPoint(
            x: size.width/2,
            y: size.height * 0.44
        )
        titlePuffer.alpha = 0
        titlePuffer.zPosition = 9
        addChild(titlePuffer)

        titleRun = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        titleRun.text = "RUN"
        titleRun.fontSize = 52
        titleRun.fontColor = SKColor(
            red: 0.957, green: 0.659, blue: 0.196, alpha: 1.0)
        titleRun.position = CGPoint(
            x: size.width/2,
            y: size.height * 0.37
        )
        titleRun.alpha = 0
        titleRun.yScale = 0.7
        titleRun.zPosition = 9
        addChild(titleRun)

        // Entrance animations
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let slideUp = SKAction.moveBy(
            x: 0, y: 20, duration: 0.5)
        slideUp.timingMode = .easeOut

        titlePuffer.run(SKAction.group([fadeIn, slideUp]))
        titleRun.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.group([
                fadeIn,
                SKAction.scaleY(to: 1.0, duration: 0.4)
            ])
        ]))
    }

    private func setupTutorialPanel() {
        // Panel background
        let panelW: CGFloat = 280
        let panelH: CGFloat = 72
        let panelX = size.width/2 - panelW/2
        let panelY = size.height * 0.27

        let panelOutline = SKShapeNode(
            rect: CGRect(x: panelX - 3, y: panelY - 3,
                         width: panelW + 6, height: panelH + 6),
            cornerRadius: 14)
        panelOutline.fillColor = .black
        panelOutline.lineWidth = 0
        addChild(panelOutline)

        let panel = SKShapeNode(
            rect: CGRect(x: panelX, y: panelY,
                         width: panelW, height: panelH),
            cornerRadius: 12)
        panel.fillColor = SKColor(
            red: 0.04, green: 0.165, blue: 0.29, alpha: 1.0)
        panel.lineWidth = 0
        addChild(panel)

        // Pulse animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.03, duration: 0.9),
            SKAction.scale(to: 1.0, duration: 0.9),
        ])
        panel.run(SKAction.repeatForever(pulse))
        panelOutline.run(SKAction.repeatForever(pulse.copy()
                                                 as! SKAction))

        // HOLD label
        let holdLabel = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        holdLabel.text = "HOLD"
        holdLabel.fontSize = 11
        holdLabel.fontColor = .white
        holdLabel.position = CGPoint(
            x: panelX + panelW * 0.25,
            y: panelY + 10
        )
        addChild(holdLabel)

        let upArrow = SKLabelNode(text: "▲")
        upArrow.fontSize = 14
        upArrow.fontColor = .white
        upArrow.position = CGPoint(
            x: panelX + panelW * 0.25,
            y: panelY + 30
        )
        addChild(upArrow)

        // Divider
        let divider = SKShapeNode(
            rect: CGRect(
                x: panelX + panelW/2 - 1,
                y: panelY + 8,
                width: 2,
                height: panelH - 16
            )
        )
        divider.fillColor = SKColor(
            red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)
        divider.lineWidth = 0
        addChild(divider)

        // RELEASE label
        let releaseLabel = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        releaseLabel.text = "RELEASE"
        releaseLabel.fontSize = 11
        releaseLabel.fontColor = .white
        releaseLabel.position = CGPoint(
            x: panelX + panelW * 0.75,
            y: panelY + 10
        )
        addChild(releaseLabel)

        let downArrow = SKLabelNode(text: "▼")
        downArrow.fontSize = 14
        downArrow.fontColor = .white
        downArrow.position = CGPoint(
            x: panelX + panelW * 0.75,
            y: panelY + 30
        )
        addChild(downArrow)
    }

    private func setupButtons() {
        // PLAY button
        playButton = makeButton(
            text: "TAP TO PLAY",
            color: SKColor(
                red: 0.957, green: 0.659, blue: 0.196, alpha: 1.0),
            width: 300, height: 68,
            y: size.height * 0.18
        )

        // SKIN button
        skinButton = makeButton(
            text: "SELECT SKIN",
            color: SKColor(
                red: 0.102, green: 0.290, blue: 0.416, alpha: 1.0),
            width: 220, height: 52,
            y: size.height * 0.10
        )
    }

    private func makeButton(
        text: String,
        color: SKColor,
        width: CGFloat,
        height: CGFloat,
        y: CGFloat
    ) -> SKShapeNode {
        let x = size.width/2 - width/2

        let shadow = SKShapeNode(
            rect: CGRect(x: x+4, y: y-4,
                         width: width, height: height),
            cornerRadius: 14)
        shadow.fillColor = .black
        shadow.lineWidth = 0
        addChild(shadow)

        let btn = SKShapeNode(
            rect: CGRect(x: x, y: y,
                         width: width, height: height),
            cornerRadius: 12)
        btn.fillColor = color
        btn.lineWidth = 3
        btn.strokeColor = .black
        btn.name = text
        btn.isUserInteractionEnabled = false
        addChild(btn)

        // Highlight
        let hl = SKShapeNode(
            rect: CGRect(x: x+2, y: y + height * 0.6,
                         width: width-4, height: height * 0.35),
            cornerRadius: 10)
        hl.fillColor = UIColor.white.withAlphaComponent(0.2)
        hl.lineWidth = 0
        addChild(hl)

        let label = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        label.text = text
        label.fontSize = text == "TAP TO PLAY" ? 18 : 13
        label.fontColor = text == "TAP TO PLAY"
        ? .black : .white
        label.verticalAlignmentMode = .center
        label.position = CGPoint(
            x: size.width/2,
            y: y + height/2
        )
        addChild(label)

        // Idle pulse
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 0.7),
            SKAction.scale(to: 1.0, duration: 0.7),
        ])
        btn.run(SKAction.repeatForever(pulse))

        return btn
    }

    private func setupBestScore() {
        let best = UserDefaults.standard
            .integer(forKey: "highScore")

        bestLabel = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        bestLabel.text = "BEST: \(best)"
        bestLabel.fontSize = 13
        bestLabel.fontColor = SKColor(
            red: 1.0, green: 0.867, blue: 0.533, alpha: 1.0)
        bestLabel.position = CGPoint(
            x: size.width/2,
            y: size.height * 0.44 + 50
        )
        bestLabel.zPosition = 10
        addChild(bestLabel)
    }

    private func setupBubbles() {
        for _ in 0..<6 {
            let r = CGFloat.random(in: 5...14)
            let bubble = SKShapeNode(circleOfRadius: r)
            bubble.fillColor = UIColor.white.withAlphaComponent(0.12)
            bubble.lineWidth = 2
            bubble.strokeColor = .black
            bubble.position = CGPoint(
                x: CGFloat.random(in: 20...(size.width-20)),
                y: CGFloat.random(in: 0...size.height)
            )
            bubble.zPosition = -2
            addChild(bubble)

            let duration = Double.random(in: 4...8)
            let moveUp = SKAction.moveBy(
                x: 0, y: size.height + 40,
                duration: duration)
            let reset = SKAction.run { [weak bubble, weak self] in
                guard let self = self else { return }
                bubble?.position = CGPoint(
                    x: CGFloat.random(
                        in: 20...(self.size.width-20)),
                    y: -20
                )
            }
            bubble.run(SKAction.repeatForever(
                SKAction.sequence([moveUp, reset])
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
            if node.name == "TAP TO PLAY" ||
               node.parent?.name == "TAP TO PLAY" {
                startGame()
                return
            }
            if node.name == "SELECT SKIN" ||
               node.parent?.name == "SELECT SKIN" {
                openSkinSelect()
                return
            }
        }
    }

    private func startGame() {
        let transition = SKTransition.fade(
            withDuration: 0.3)
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: transition)
    }

    private func openSkinSelect() {
        let transition = SKTransition.moveIn(
            with: .up, duration: 0.3)
        let scene = SkinSelectScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: transition)
    }
}
