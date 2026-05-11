//
//  OceanBackground.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SpriteKit

class OceanBackground: SKNode {

    // MARK: - Zone definitions
    struct OceanZone {
        let topColor: SKColor
        let midColor: SKColor
        let bottomColor: SKColor
        let rayAlpha: CGFloat
    }

    private let zones: [OceanZone] = [
        // Zone 0 — Shallow reef (score 0-9)
        OceanZone(
            topColor: SKColor(red:0.306,green:0.753,blue:0.792,alpha:1),
            midColor: SKColor(red:0.165,green:0.541,blue:0.604,alpha:1),
            bottomColor: SKColor(red:0.051,green:0.227,blue:0.361,alpha:1),
            rayAlpha: 0.18
        ),
        // Zone 1 — Open water (score 10-24)
        OceanZone(
            topColor: SKColor(red:0.102,green:0.416,blue:0.541,alpha:1),
            midColor: SKColor(red:0.051,green:0.290,blue:0.416,alpha:1),
            bottomColor: SKColor(red:0.024,green:0.125,blue:0.251,alpha:1),
            rayAlpha: 0.10
        ),
        // Zone 2 — Deep ocean (score 25+)
        OceanZone(
            topColor: SKColor(red:0.039,green:0.165,blue:0.290,alpha:1),
            midColor: SKColor(red:0.024,green:0.094,blue:0.157,alpha:1),
            bottomColor: SKColor(red:0.008,green:0.039,blue:0.078,alpha:1),
            rayAlpha: 0.04
        ),
    ]

    // MARK: - Properties
    private var topLayer: SKSpriteNode!
    private var midLayer: SKSpriteNode!
    private var bottomLayer: SKSpriteNode!
    private var rayNodes: [SKShapeNode] = []
    private var bubbleNodes: [SKShapeNode] = []
    private var depthLabel: SKLabelNode!

    private var currentZoneIndex: Int = 0
    private var sceneSize: CGSize

    // MARK: - Init
    init(sceneSize: CGSize) {
        self.sceneSize = sceneSize
        super.init()
        zPosition = -10
        setupLayers()
        setupRays()
        setupBubbles()
        // setupDepthLabel() // Removed - clean UI
        applyZone(index: 0, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Setup
    private func setupLayers() {
        let w = sceneSize.width
        let h = sceneSize.height

        // Top layer
        topLayer = SKSpriteNode(color: .clear,
            size: CGSize(width: w, height: h * 0.55))
        topLayer.anchorPoint = CGPoint(x: 0, y: 0)
        topLayer.position = CGPoint(x: 0, y: h * 0.45)
        addChild(topLayer)

        // Mid layer
        midLayer = SKSpriteNode(color: .clear,
            size: CGSize(width: w, height: h * 0.27))
        midLayer.anchorPoint = CGPoint(x: 0, y: 0)
        midLayer.position = CGPoint(x: 0, y: h * 0.18)
        addChild(midLayer)

        // Bottom layer
        bottomLayer = SKSpriteNode(color: .clear,
            size: CGSize(width: w, height: h * 0.18))
        bottomLayer.anchorPoint = CGPoint(x: 0, y: 0)
        bottomLayer.position = CGPoint(x: 0, y: 0)
        addChild(bottomLayer)
    }

    private func setupRays() {
        let rayPositions: [CGFloat] = [
            sceneSize.width * 0.15,
            sceneSize.width * 0.38,
            sceneSize.width * 0.62,
            sceneSize.width * 0.82,
        ]

        for xPos in rayPositions {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: xPos - 5, y: sceneSize.height))
            path.addLine(to: CGPoint(x: xPos + 5, y: sceneSize.height))
            path.addLine(to: CGPoint(
                x: xPos + 25, y: sceneSize.height * 0.4))
            path.addLine(to: CGPoint(
                x: xPos - 25, y: sceneSize.height * 0.4))
            path.closeSubpath()

            let ray = SKShapeNode(path: path)
            ray.fillColor = SKColor(
                red: 0.365, green: 0.831, blue: 0.867, alpha: 1.0)
            ray.lineWidth = 0
            ray.alpha = 0.18
            addChild(ray)
            rayNodes.append(ray)
        }
    }

    private func setupBubbles() {
        for _ in 0..<8 {
            let r = CGFloat.random(in: 6...16)
            let bubble = SKShapeNode(circleOfRadius: r)
            bubble.fillColor = UIColor.white.withAlphaComponent(0.15)
            bubble.lineWidth = 2
            bubble.strokeColor = .black
            bubble.position = CGPoint(
                x: CGFloat.random(in: 20...(sceneSize.width - 20)),
                y: CGFloat.random(in: 0...sceneSize.height)
            )
            addChild(bubble)
            bubbleNodes.append(bubble)

            // Float upward animation
            let duration = Double.random(in: 4...8)
            let moveUp = SKAction.moveBy(
                x: 0, y: sceneSize.height + 40,
                duration: duration)
            let reset = SKAction.run { [weak bubble] in
                bubble?.position = CGPoint(
                    x: CGFloat.random(
                        in: 20...(self.sceneSize.width - 20)),
                    y: -20
                )
            }
            bubble.run(SKAction.repeatForever(
                SKAction.sequence([moveUp, reset])
            ))
        }
    }

    private func setupDepthLabel() {
        depthLabel = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        depthLabel.fontSize = 11
        depthLabel.fontColor = UIColor.white.withAlphaComponent(0.35)
        depthLabel.horizontalAlignmentMode = .right
        depthLabel.position = CGPoint(
            x: sceneSize.width - 12,
            y: 50
        )
        depthLabel.zPosition = 10
        depthLabel.text = "~ SHALLOW REEF ~"
        addChild(depthLabel)
    }

    // MARK: - Public update
    func update(score: Int) {
        let targetZone: Int
        if score >= 25 { targetZone = 2 }
        else if score >= 10 { targetZone = 1 }
        else { targetZone = 0 }

        if targetZone != currentZoneIndex {
            currentZoneIndex = targetZone
            applyZone(index: targetZone, animated: true)
            // updateDepthLabel(zone: targetZone) // Removed - clean UI
        }
    }

    // MARK: - Zone transition
    private func applyZone(index: Int, animated: Bool) {
        let zone = zones[index]
        let duration: TimeInterval = animated ? 2.0 : 0.0

        topLayer.run(SKAction.colorize(
            with: zone.topColor,
            colorBlendFactor: 1.0,
            duration: duration))
        midLayer.run(SKAction.colorize(
            with: zone.midColor,
            colorBlendFactor: 1.0,
            duration: duration))
        bottomLayer.run(SKAction.colorize(
            with: zone.bottomColor,
            colorBlendFactor: 1.0,
            duration: duration))

        for ray in rayNodes {
            ray.run(SKAction.fadeAlpha(
                to: zone.rayAlpha,
                duration: duration))
        }
    }

    private func updateDepthLabel(zone: Int) {
        let texts = [
            "~ SHALLOW REEF ~",
            "~ OPEN WATER ~",
            "~ DEEP OCEAN ~",
        ]
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 0.3)
        let change = SKAction.run { [weak self] in
            self?.depthLabel.text = texts[zone]
        }
        let fadeIn = SKAction.fadeAlpha(to: 0.35, duration: 0.3)
        depthLabel.run(SKAction.sequence([fadeOut, change, fadeIn]))
    }
}
