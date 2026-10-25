//
//  SkinSelectScene.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SpriteKit

class SkinSelectScene: SKScene {

    private var selectedIndex: Int = 0
    private var highScore: Int = 0
    private var cardNodes: [SKShapeNode] = []
    private var nameLabel: SKLabelNode!
    private var unlockLabel: SKLabelNode!
    private var bestLabel: SKLabelNode!
    private var selectBtn: SKShapeNode!
    private var selectBtnLabel: SKLabelNode!

    override func didMove(to view: SKView) {
        highScore = UserDefaults.standard
            .integer(forKey: "highScore")
        let savedId = UserDefaults.standard
            .string(forKey: "selectedSkin") ?? "default"
        selectedIndex = SKINS.firstIndex {
            $0.id == savedId
        } ?? 0

        backgroundColor = SKColor(
            red: 0.04, green: 0.16, blue: 0.29, alpha: 1.0)

        setupBackground()
        setupPanel()
        updateSelection()
    }

    private func setupBackground() {
        let overlay = SKSpriteNode(
            color: UIColor.black.withAlphaComponent(0.65),
            size: size)
        overlay.position = CGPoint(
            x: size.width/2, y: size.height/2)
        overlay.zPosition = -1
        addChild(overlay)
    }

    private func setupPanel() {
        let panelW = size.width - 40
        let panelH: CGFloat = 560
        let panelX: CGFloat = 20
        let panelY = size.height/2 - panelH/2

        // Panel
        let panelOutline = SKShapeNode(
            rect: CGRect(x: panelX-3, y: panelY-3,
                         width: panelW+6, height: panelH+6),
            cornerRadius: 22)
        panelOutline.fillColor = UIColor.black
        panelOutline.lineWidth = 0
        addChild(panelOutline)

        let panel = SKShapeNode(
            rect: CGRect(x: panelX, y: panelY,
                         width: panelW, height: panelH),
            cornerRadius: 20)
        panel.fillColor = SKColor(
            red: 0.039, green: 0.165, blue: 0.290, alpha: 1.0)
        panel.lineWidth = 0
        addChild(panel)

        // Title
        let title = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        title.text = "SELECT SKIN"
        title.fontSize = 18
        title.fontColor = .white
        title.position = CGPoint(
            x: size.width/2,
            y: panelY + panelH - 44
        )
        addChild(title)

        // Best score
        bestLabel = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        bestLabel.text = "BEST: \(highScore)"
        bestLabel.fontSize = 11
        bestLabel.fontColor = SKColor(
            red:1.0,green:0.867,blue:0.533,alpha:1)
        bestLabel.position = CGPoint(
            x: size.width/2,
            y: panelY + panelH - 68
        )
        addChild(bestLabel)

        // Skin cards — 2 rows of 3
        let cardW: CGFloat = 80
        let cardH: CGFloat = 110
        let cols = 3
        let spacing: CGFloat = 12
        let totalW = CGFloat(cols) * cardW +
            CGFloat(cols - 1) * spacing
        let startX = size.width/2 - totalW/2

        for i in 0..<SKINS.count {
            let col = i % cols
            let row = i / cols
            let cx = startX + CGFloat(col) * (cardW + spacing)
            let cy = panelY + panelH - 200 -
                CGFloat(row) * (cardH + spacing)

            let card = SKShapeNode(
                rect: CGRect(x: cx, y: cy,
                             width: cardW, height: cardH),
                cornerRadius: 10)
            card.lineWidth = 3
            card.name = "card_\(i)"
            addChild(card)
            cardNodes.append(card)

            // Fish preview
            let fishPreview = SKNode()
            fishPreview.position = CGPoint(
                x: cx + cardW/2, y: cy + cardH * 0.58)
            fishPreview.name = "card_\(i)"
            drawMinifish(
                on: fishPreview,
                skin: SKINS[i],
                locked: SKINS[i].unlockScore > highScore
            )
            addChild(fishPreview)

            // Score label
            let scoreText = SKINS[i].unlockScore == 0
                ? "FREE" : "\(SKINS[i].unlockScore)"
            let scoreLbl = SKLabelNode(
                fontNamed: "CourierNewPS-BoldMT")
            scoreLbl.text = scoreText
            scoreLbl.fontSize = 7
            scoreLbl.fontColor = SKINS[i].unlockScore <= highScore
                ? SKColor(red:0.267,green:0.800,blue:0.267,alpha:1)
                : SKColor(red:1.0,green:0.533,blue:0.0,alpha:1)
            scoreLbl.position = CGPoint(
                x: cx + cardW/2, y: cy + 8)
            scoreLbl.zPosition = 5
            addChild(scoreLbl)

            // Progress bar
            let barW = cardW - 6
            let barBg = SKShapeNode(
                rect: CGRect(
                    x: cx + 3, y: cy + 2,
                    width: barW, height: 3))
            barBg.fillColor = UIColor.black
            barBg.lineWidth = 0
            addChild(barBg)

            let progress = SKINS[i].unlockScore == 0
                ? 1.0
                : min(Double(highScore) /
                      Double(SKINS[i].unlockScore), 1.0)
            let fillW = barW * CGFloat(progress)

            if fillW > 0 {
                let barFill = SKShapeNode(
                    rect: CGRect(
                        x: cx + 3, y: cy + 2,
                        width: fillW, height: 3))
                barFill.fillColor = progress >= 1.0
                    ? SKColor(red:0.267,green:0.800,blue:0.267,alpha:1)
                    : SKColor(red:1.0,green:0.533,blue:0.0,alpha:1)
                barFill.lineWidth = 0
                barFill.zPosition = 4
                addChild(barFill)
            }
        }

        // Name label
        nameLabel = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        nameLabel.fontSize = 14
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(
            x: size.width/2,
            y: panelY + 140
        )
        addChild(nameLabel)

        // Unlock label
        unlockLabel = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        unlockLabel.fontSize = 10
        unlockLabel.position = CGPoint(
            x: size.width/2,
            y: panelY + 118
        )
        addChild(unlockLabel)

        // SELECT button
        let btnW: CGFloat = 240
        let btnH: CGFloat = 56
        let btnX = size.width/2 - btnW/2
        let btnY = panelY + 48

        let btnShadow = SKShapeNode(
            rect: CGRect(x: btnX+3, y: btnY-3,
                         width: btnW, height: btnH),
            cornerRadius: 12)
        btnShadow.fillColor = UIColor.black
        btnShadow.lineWidth = 0
        addChild(btnShadow)

        selectBtn = SKShapeNode(
            rect: CGRect(x: btnX, y: btnY,
                         width: btnW, height: btnH),
            cornerRadius: 10)
        selectBtn.lineWidth = 3
        selectBtn.strokeColor = UIColor.black
        selectBtn.name = "select"
        addChild(selectBtn)

        selectBtnLabel = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        selectBtnLabel.fontSize = 14
        selectBtnLabel.fontColor = .white
        selectBtnLabel.verticalAlignmentMode = .center
        selectBtnLabel.position = CGPoint(
            x: size.width/2, y: btnY + btnH/2)
        selectBtnLabel.name = "select"
        addChild(selectBtnLabel)

        // BACK button
        let backBtn = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        backBtn.text = "< BACK"
        backBtn.fontSize = 13
        backBtn.fontColor = SKColor(
            red:0.533,green:0.667,blue:0.733,alpha:1)
        backBtn.position = CGPoint(
            x: size.width/2,
            y: panelY + 14
        )
        backBtn.name = "back"
        addChild(backBtn)
    }

    private func drawMinifish(
        on node: SKNode,
        skin: SkinDefinition,
        locked: Bool
    ) {
        let r: CGFloat = 22

        if locked {
            // Dark fish silhouette
            let silhouette = SKShapeNode(
                ellipseOf: CGSize(
                    width: r*2.3, height: r*2.0))
            silhouette.fillColor = SKColor(
                red:0.1,green:0.1,blue:0.15,alpha:1)
            silhouette.lineWidth = 0
            node.addChild(silhouette)

            let lockLabel = SKLabelNode(text: "?")
            lockLabel.fontSize = 20
            lockLabel.fontColor = SKColor(
                red:0.2,green:0.3,blue:0.4,alpha:1)
            lockLabel.verticalAlignmentMode = .center
            node.addChild(lockLabel)
            return
        }

        // Tail
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -r*1.0, y: r*0.48))
        tailPath.addLine(to: CGPoint(x: -r*1.0, y: -r*0.48))
        tailPath.addLine(to: CGPoint(x: -r*1.6, y: 0))
        tailPath.closeSubpath()
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = skin.tailColor
        tail.lineWidth = 2
        tail.strokeColor = UIColor.black
        node.addChild(tail)

        // Body
        let body = SKShapeNode(
            ellipseOf: CGSize(
                width: r*2.3, height: r*2.0))
        body.fillColor = skin.bodyColor
        body.lineWidth = 2
        body.strokeColor = UIColor.black
        node.addChild(body)

        // Spines
        for i in 0..<6 {
            let angle = CGFloat(i) / 6 * .pi * 2
            let spine = SKShapeNode(circleOfRadius: 3)
            spine.position = CGPoint(
                x: cos(angle) * r * 1.05,
                y: sin(angle) * r * 0.92
            )
            spine.fillColor = skin.spineColor
            spine.lineWidth = 1
            spine.strokeColor = UIColor.black
            node.addChild(spine)
        }

        // Eye
        let eyeW = SKShapeNode(circleOfRadius: r*0.28)
        eyeW.position = CGPoint(x: r*0.55, y: r*0.22)
        eyeW.fillColor = .white
        eyeW.lineWidth = 2
        eyeW.strokeColor = UIColor.black
        node.addChild(eyeW)

        let pupil = SKShapeNode(circleOfRadius: r*0.12)
        pupil.position = CGPoint(x: r*0.60, y: r*0.20)
        pupil.fillColor = skin.eyeColor
        pupil.lineWidth = 0
        node.addChild(pupil)
    }

    private func updateSelection() {
        for (i, card) in cardNodes.enumerated() {
            let isSelected = i == selectedIndex
            let isUnlocked = SKINS[i].unlockScore <= highScore

            if isSelected {
                card.strokeColor = SKColor(
                    red:0.957,green:0.659,blue:0.196,alpha:1)
                card.fillColor = SKColor(
                    red:0.102,green:0.290,blue:0.416,alpha:1)
            } else {
                card.strokeColor = UIColor.black
                card.fillColor = SKColor(
                    red:0.024,green:0.078,blue:0.125,alpha:1)
            }

            // Locked card overlay handled in drawMinifish
            _ = isUnlocked
        }

        let skin = SKINS[selectedIndex]
        let unlocked = skin.unlockScore <= highScore

        nameLabel.text = skin.name
        nameLabel.fontColor = unlocked ? .white : SKColor(
            red:0.533,green:0.667,blue:0.733,alpha:1)

        if unlocked {
            unlockLabel.text = "UNLOCKED"
            unlockLabel.fontColor = SKColor(
                red:0.267,green:0.800,blue:0.267,alpha:1)
        } else {
            unlockLabel.text =
                "REACH SCORE \(skin.unlockScore)"
            unlockLabel.fontColor = SKColor(
                red:1.0,green:0.533,blue:0.0,alpha:1)
        }

        selectBtn.fillColor = unlocked
            ? SKColor(red:0.267,green:0.800,blue:0.267,alpha:1)
            : SKColor(red:0.2,green:0.2,blue:0.2,alpha:1)
        selectBtnLabel.text = unlocked
            ? "SELECT" : "LOCKED"
    }

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        for node in tapped {
            // Card tap
            if let name = node.name,
               name.hasPrefix("card_"),
               let indexStr = name.split(
                separator: "_").last,
               let index = Int(indexStr) {
                selectedIndex = index
                updateSelection()
                return
            }

            // Select button
            if node.name == "select" {
                let skin = SKINS[selectedIndex]
                guard skin.unlockScore <= highScore else { return }

                UserDefaults.standard.set(
                    skin.id, forKey: "selectedSkin")

                // Press animation then go back
                selectBtn.run(SKAction.sequence([
                    SKAction.scale(to: 0.94, duration: 0.08),
                    SKAction.scale(to: 1.0, duration: 0.08),
                    SKAction.run { [weak self] in
                        guard let self = self else { return }
                        let scene = MenuScene(size: self.size)
                        scene.scaleMode = self.scaleMode
                        self.view?.presentScene(scene,
                                               transition: SKTransition.moveIn(
                                                with: .down, duration: 0.3))
                    }
                ]))
                return
            }

            // Back button
            if node.name == "back" {
                let scene = MenuScene(size: size)
                scene.scaleMode = scaleMode
                view?.presentScene(scene,
                                  transition: SKTransition.moveIn(
                                    with: .down, duration: 0.3))
                return
            }
        }
    }
}
