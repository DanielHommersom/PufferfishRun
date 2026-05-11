//
//  SplashScene.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SpriteKit

class SplashScene: SKScene {

    // MARK: - didMove
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(
            red: 0.04, green: 0.16, blue: 0.29, alpha: 1.0)

        setupOceanBackground()
        setupFish()
        setupTitle()
        setupSubtitle()
        setupBubbles()
        scheduleTransition()
    }

    // MARK: - Background
    private func setupOceanBackground() {
        // Ocean gradient layers
        let layers: [(SKColor, CGFloat, CGFloat)] = [
            (SKColor(red:0.306,green:0.753,blue:0.792,alpha:1),
             size.height * 0.55, size.height * 0.45),
            (SKColor(red:0.165,green:0.541,blue:0.604,alpha:1),
             size.height * 0.18, size.height * 0.37),
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

        // Light rays
        let rayPositions: [CGFloat] = [
            size.width * 0.2,
            size.width * 0.45,
            size.width * 0.65,
            size.width * 0.82,
        ]
        for xPos in rayPositions {
            let path = CGMutablePath()
            path.move(to: CGPoint(
                x: xPos - 6, y: size.height))
            path.addLine(to: CGPoint(
                x: xPos + 6, y: size.height))
            path.addLine(to: CGPoint(
                x: xPos + 40, y: size.height * 0.35))
            path.addLine(to: CGPoint(
                x: xPos - 40, y: size.height * 0.35))
            path.closeSubpath()

            let ray = SKShapeNode(path: path)
            ray.fillColor = SKColor(
                red:0.365,green:0.831,blue:0.867,alpha:1)
            ray.lineWidth = 0
            ray.alpha = 0.14
            ray.zPosition = -9
            addChild(ray)
        }

        // Coral stumps bottom
        for (x, h) in [
            (size.width * 0.12, 90),
            (size.width * 0.28, 65),
            (size.width * 0.72, 70),
            (size.width * 0.88, 95),
        ] as [(CGFloat, Int)] {
            let outline = SKShapeNode(rect: CGRect(
                x: x - 15, y: 0,
                width: 30, height: CGFloat(h)),
                                      cornerRadius: 4)
            outline.fillColor = .black
            outline.lineWidth = 0
            outline.zPosition = -5
            addChild(outline)

            let fill = SKShapeNode(rect: CGRect(
                x: x - 12, y: 0,
                width: 24, height: CGFloat(h) - 2),
                                   cornerRadius: 3)
            fill.fillColor = COLOR_CORAL_BASE
            fill.lineWidth = 0
            fill.zPosition = -4
            addChild(fill)
        }
    }

    // MARK: - Fish
    private func setupFish() {
        let fishNode = SKNode()
        fishNode.position = CGPoint(
            x: size.width / 2,
            y: size.height * 0.60
        )
        fishNode.alpha = 0
        fishNode.setScale(0.4)
        fishNode.name = "fishNode"
        addChild(fishNode)

        let r: CGFloat = 62
        let skin = SKINS[0]

        // Tail
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -r*1.1, y: r*0.55))
        tailPath.addLine(to: CGPoint(x: -r*1.1, y: -r*0.55))
        tailPath.addLine(to: CGPoint(x: -r*1.7, y: 0))
        tailPath.closeSubpath()
        let tailO = SKShapeNode(path: tailPath)
        tailO.fillColor = .black
        tailO.lineWidth = 0
        fishNode.addChild(tailO)

        let tailFPath = CGMutablePath()
        tailFPath.move(to: CGPoint(x: -r*1.0, y: r*0.48))
        tailFPath.addLine(to: CGPoint(x: -r*1.0, y: -r*0.48))
        tailFPath.addLine(to: CGPoint(x: -r*1.6, y: 0))
        tailFPath.closeSubpath()
        let tailF = SKShapeNode(path: tailFPath)
        tailF.fillColor = skin.tailColor
        tailF.lineWidth = 0
        fishNode.addChild(tailF)

        // Body outline
        let bodyO = SKShapeNode(ellipseOf: CGSize(
            width: r*2.3+6, height: r*2.0+6))
        bodyO.fillColor = .black
        bodyO.lineWidth = 0
        fishNode.addChild(bodyO)

        // Body fill
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

        // Spines (10 positions)
        for i in 0..<10 {
            let angle = CGFloat(i) / 10 * .pi * 2
            let sx = cos(angle) * r * 1.08
            let sy = sin(angle) * r * 0.92
            let so = SKShapeNode(circleOfRadius: 7)
            so.position = CGPoint(x: sx, y: sy)
            so.fillColor = .black
            so.lineWidth = 0
            fishNode.addChild(so)
            let sf = SKShapeNode(circleOfRadius: 5)
            sf.position = CGPoint(x: sx, y: sy)
            sf.fillColor = skin.spineColor
            sf.lineWidth = 0
            fishNode.addChild(sf)
        }

        // Eye
        let eyeO = SKShapeNode(circleOfRadius: r*0.32+4)
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

        // Entrance animation
        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.6)
        ])
        appear.timingMode = .easeOut
        fishNode.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            appear
        ]))

        // Bob animation after entrance
        let bob = SKAction.sequence([
            SKAction.wait(forDuration: 0.9),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x:0, y:16, duration:1.1),
                SKAction.moveBy(x:0, y:-16, duration:1.1),
            ]))
        ])
        fishNode.run(bob)
    }

    // MARK: - Title
    private func setupTitle() {
        // PUFFERFISH shadow
        let s1 = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        s1.text = "PUFFERFISH"
        s1.fontSize = 42
        s1.fontColor = UIColor.black.withAlphaComponent(0.4)
        s1.position = CGPoint(
            x: size.width/2 + 4,
            y: size.height * 0.32 - 4)
        s1.alpha = 0
        s1.zPosition = 8
        addChild(s1)

        // PUFFERFISH title
        let t1 = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        t1.text = "PUFFERFISH"
        t1.fontSize = 42
        t1.fontColor = .white
        t1.position = CGPoint(
            x: size.width/2,
            y: size.height * 0.32)
        t1.alpha = 0
        t1.zPosition = 9
        addChild(t1)

        // RUN shadow
        let s2 = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        s2.text = "RUN"
        s2.fontSize = 60
        s2.fontColor = UIColor.black.withAlphaComponent(0.4)
        s2.position = CGPoint(
            x: size.width/2 + 4,
            y: size.height * 0.23 - 4)
        s2.alpha = 0
        s2.zPosition = 8
        addChild(s2)

        // RUN title
        let t2 = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        t2.text = "RUN"
        t2.fontSize = 60
        t2.fontColor = SKColor(
            red:0.957,green:0.659,blue:0.196,alpha:1)
        t2.position = CGPoint(
            x: size.width/2,
            y: size.height * 0.23)
        t2.alpha = 0
        t2.setScale(0.6)
        t2.zPosition = 9
        addChild(t2)

        // Subtitle
        let sub = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        sub.text = "SURVIVE THE REEF"
        sub.fontSize = 16
        sub.fontColor = UIColor.white.withAlphaComponent(0.7)
        sub.position = CGPoint(
            x: size.width/2,
            y: size.height * 0.16)
        sub.alpha = 0
        sub.zPosition = 9
        addChild(sub)

        // Animations
        let fadeSlide = SKAction.group([
            SKAction.fadeIn(withDuration: 0.5),
            SKAction.moveBy(x:0, y:20, duration:0.5)
        ])
        fadeSlide.timingMode = .easeOut

        let delay1: TimeInterval = 0.7
        let delay2: TimeInterval = 0.9
        let delay3: TimeInterval = 1.1

        for (node, shadow, delay) in [
            (t1, s1, delay1),
            (t2, s2, delay2),
            (sub, sub, delay3)
        ] as [(SKLabelNode, SKLabelNode, TimeInterval)] {
            shadow.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeIn(withDuration: 0.5)
            ]))
            if node === t2 {
                node.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    SKAction.group([
                        SKAction.fadeIn(withDuration: 0.4),
                        SKAction.scale(to: 1.0, duration: 0.4)
                    ])
                ]))
            } else {
                node.run(SKAction.sequence([
                    SKAction.wait(forDuration: delay),
                    fadeSlide.copy() as! SKAction
                ]))
            }
        }
    }

    // MARK: - Subtitle
    private func setupSubtitle() {
        // Loading indicator
        let dots = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        dots.text = "..."
        dots.fontSize = 14
        dots.fontColor = UIColor.white.withAlphaComponent(0.4)
        dots.position = CGPoint(
            x: size.width/2,
            y: size.height * 0.08)
        dots.alpha = 0
        dots.zPosition = 9
        addChild(dots)

        dots.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.4),
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.2, duration: 0.5),
                SKAction.fadeAlpha(to: 0.6, duration: 0.5),
            ]))
        ]))
    }

    // MARK: - Bubbles
    private func setupBubbles() {
        for _ in 0..<7 {
            let r = CGFloat.random(in: 6...16)
            let bubble = SKShapeNode(circleOfRadius: r)
            bubble.fillColor = UIColor.white
                .withAlphaComponent(0.12)
            bubble.lineWidth = 2
            bubble.strokeColor = .black
            bubble.position = CGPoint(
                x: CGFloat.random(in: 20...(size.width-20)),
                y: CGFloat.random(in: 0...size.height)
            )
            bubble.zPosition = -2
            addChild(bubble)

            let duration = Double.random(in: 4...8)
            let delay = Double.random(in: 0...3)
            let moveUp = SKAction.moveBy(
                x: 0, y: size.height + 40,
                duration: duration)
            let reset = SKAction.run { [weak bubble,
                                         weak self] in
                guard let self = self else { return }
                bubble?.position = CGPoint(
                    x: CGFloat.random(
                        in: 20...(self.size.width - 20)),
                    y: -20)
            }
            bubble.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.repeatForever(
                    SKAction.sequence([moveUp, reset]))
            ]))
        }
    }

    // MARK: - Transition
    private func scheduleTransition() {
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.2),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                let scene = MenuScene(size: self.size)
                scene.scaleMode = self.scaleMode
                self.view?.presentScene(scene,
                                       transition: SKTransition.fade(
                                        withDuration: 0.6))
            }
        ]))
    }

    // MARK: - Touch to skip
    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        removeAllActions()
        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene,
                          transition: SKTransition.fade(
                            withDuration: 0.4))
    }
}
