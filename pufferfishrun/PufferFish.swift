//
//  PufferFish.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SpriteKit

class PufferFish: SKNode {

    // MARK: - Properties
    var velY: CGFloat = 0
    var inflateLevel: CGFloat = 0
    var isInflating: Bool = false
    
    // Skin support
    private var currentSkin: SkinDefinition = SKINS[0]

    // Visual nodes
    private var bodyNode: SKShapeNode!
    private var tailNode: SKShapeNode!
    private var eyeWhiteNode: SKShapeNode!
    private var eyeIrisNode: SKShapeNode!
    private var eyePupilNode: SKShapeNode!
    private var eyeHighlightNode: SKShapeNode!
    private var bellyNode: SKShapeNode!
    private var highlightNode: SKShapeNode!
    private var spineNodes: [SKShapeNode] = []

    // Blink animation
    private var blinkTimer: Int = 0
    private var isBlinking: Bool = false

    // Tail wag animation
    private var wagOffset: CGFloat = 0
    private var wagDirection: CGFloat = 1
    
    // MARK: - Skin
    func setSkin(_ skin: SkinDefinition) {
        currentSkin = skin
    }

    // MARK: - Init
    override init() {
        super.init()
        setupNodes()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupNodes()
    }

    // MARK: - Setup
    private func setupNodes() {
        // Body
        bodyNode = SKShapeNode()
        bodyNode.lineWidth = 3
        bodyNode.strokeColor = .black
        addChild(bodyNode)

        // Belly
        bellyNode = SKShapeNode()
        bellyNode.lineWidth = 0
        bellyNode.alpha = 0.35
        addChild(bellyNode)

        // Highlight
        highlightNode = SKShapeNode()
        highlightNode.lineWidth = 0
        highlightNode.alpha = 0.45
        highlightNode.fillColor = .white
        addChild(highlightNode)

        // Tail
        tailNode = SKShapeNode()
        tailNode.lineWidth = 3
        tailNode.strokeColor = .black
        addChild(tailNode)

        // Eye white
        eyeWhiteNode = SKShapeNode()
        eyeWhiteNode.lineWidth = 3
        eyeWhiteNode.strokeColor = .black
        eyeWhiteNode.fillColor = .white
        addChild(eyeWhiteNode)

        // Eye iris
        eyeIrisNode = SKShapeNode()
        eyeIrisNode.lineWidth = 0
        eyeIrisNode.fillColor = SKColor(
            red: 0.29, green: 0.56, blue: 0.85, alpha: 1.0)
        addChild(eyeIrisNode)

        // Eye pupil
        eyePupilNode = SKShapeNode()
        eyePupilNode.lineWidth = 0
        eyePupilNode.fillColor = .black
        addChild(eyePupilNode)

        // Eye highlight
        eyeHighlightNode = SKShapeNode()
        eyeHighlightNode.lineWidth = 0
        eyeHighlightNode.fillColor = .white
        addChild(eyeHighlightNode)
    }

    // MARK: - Public methods
    func inflate() { isInflating = true }
    func deflate() { isInflating = false }

    func getRadius() -> CGFloat {
        return FISH_BASE_RADIUS + inflateLevel * 0.85
    }

    // MARK: - Update (call every frame from GameScene)
    func update() {
        updatePhysics()
        updateAnimations()
        redraw()
    }

    // MARK: - Physics
    private func updatePhysics() {
        if isInflating {
            inflateLevel = min(FISH_MAX_INFLATE, 
                              inflateLevel + INFLATE_SPEED)
            velY += INFLATE_SPEED * 1.2
        } else {
            inflateLevel = max(0, inflateLevel - DEFLATE_SPEED)
            velY -= GRAVITY
        }

        velY = max(MAX_VEL_UP, min(MAX_VEL_DOWN, velY))

        // In SpriteKit Y axis is flipped vs Phaser
        // positive velY = up, negative = down
        position.y += velY
    }

    // MARK: - Animations
    private func updateAnimations() {
        // Blink
        blinkTimer += 1
        if blinkTimer >= 180 {
            isBlinking = true
            blinkTimer = 0
        }
        if isBlinking && blinkTimer >= 6 {
            isBlinking = false
        }

        // Tail wag
        wagOffset += 0.15 * wagDirection
        if abs(wagOffset) > 2 { wagDirection *= -1 }
    }

    // MARK: - Drawing
    private func redraw() {
        let r = getRadius()
        let color = bodyColor()

        // Body
        let bodyPath = CGMutablePath()
        bodyPath.addEllipse(in: CGRect(
            x: -r * 1.15, y: -r,
            width: r * 2.3, height: r * 2.0
        ))
        bodyNode.path = bodyPath
        bodyNode.fillColor = color

        // Belly
        let bellyPath = CGMutablePath()
        bellyPath.addEllipse(in: CGRect(
            x: -r * 0.6, y: -r * 0.85,
            width: r * 1.4, height: r * 0.85
        ))
        bellyNode.path = bellyPath
        bellyNode.fillColor = color.darken(by: 0.15)

        // Highlight
        let highlightPath = CGMutablePath()
        highlightPath.addEllipse(in: CGRect(
            x: -r * 0.55, y: r * 0.1,
            width: r * 0.75, height: r * 0.42
        ))
        highlightNode.path = highlightPath

        // Tail with wag
        let wagSnap = round(wagOffset) * 2
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(
            x: -r * 1.1, y: r * 0.55 + wagSnap))
        tailPath.addLine(to: CGPoint(
            x: -r * 1.1, y: -r * 0.55 + wagSnap))
        tailPath.addLine(to: CGPoint(
            x: -r * 1.7, y: wagSnap))
        tailPath.closeSubpath()
        tailNode.path = tailPath
        tailNode.fillColor = currentSkin.tailColor

        // Eye
        let eyeX = r * 0.55
        let eyeY = r * 0.22
        let eyeR = r * 0.30

        if isBlinking {
            // Closed eye — thin horizontal rect
            let blinkPath = CGMutablePath()
            blinkPath.addRect(CGRect(
                x: eyeX - eyeR, y: eyeY - 2,
                width: eyeR * 2, height: 4
            ))
            eyeWhiteNode.path = blinkPath
            eyeWhiteNode.fillColor = .black
            eyeIrisNode.isHidden = true
            eyePupilNode.isHidden = true
            eyeHighlightNode.isHidden = true
        } else {
            eyeIrisNode.isHidden = false
            eyePupilNode.isHidden = false
            eyeHighlightNode.isHidden = false

            let eyeWhitePath = CGMutablePath()
            eyeWhitePath.addEllipse(in: CGRect(
                x: eyeX - eyeR, y: eyeY - eyeR,
                width: eyeR * 2, height: eyeR * 2
            ))
            eyeWhiteNode.path = eyeWhitePath
            eyeWhiteNode.fillColor = .white

            let irisPath = CGMutablePath()
            irisPath.addEllipse(in: CGRect(
                x: eyeX - eyeR * 0.6,
                y: eyeY - eyeR * 0.6,
                width: eyeR * 1.2, height: eyeR * 1.2
            ))
            eyeIrisNode.path = irisPath
            eyeIrisNode.fillColor = currentSkin.eyeColor

            let pupilPath = CGMutablePath()
            pupilPath.addEllipse(in: CGRect(
                x: eyeX - eyeR * 0.35,
                y: eyeY - eyeR * 0.35,
                width: eyeR * 0.7, height: eyeR * 0.7
            ))
            eyePupilNode.path = pupilPath

            let hlPath = CGMutablePath()
            hlPath.addEllipse(in: CGRect(
                x: eyeX - eyeR * 0.55,
                y: eyeY + eyeR * 0.25,
                width: eyeR * 0.3, height: eyeR * 0.3
            ))
            eyeHighlightNode.path = hlPath
        }

        // Spines
        spineNodes.forEach { $0.removeFromParent() }
        spineNodes.removeAll()

        if inflateLevel > 3 {
            let spineCount = min(10, Int(inflateLevel * 1.1))
            let angleStep = (CGFloat.pi * 2) / CGFloat(spineCount)
            let spineR = max(1.2, min(3.5, inflateLevel * 0.22))

            for i in 0..<spineCount {
                let angle = CGFloat(i) * angleStep
                let sx = cos(angle) * r * 1.08
                let sy = sin(angle) * r * 0.92

                let outline = SKShapeNode(
                    circleOfRadius: spineR + 2)
                outline.position = CGPoint(x: sx, y: sy)
                outline.fillColor = .black
                outline.lineWidth = 0
                addChild(outline)
                spineNodes.append(outline)

                let spine = SKShapeNode(
                    circleOfRadius: spineR)
                spine.position = CGPoint(x: sx, y: sy)
                spine.fillColor = currentSkin.spineColor
                spine.lineWidth = 0
                addChild(spine)
                spineNodes.append(spine)
            }
        }
    }

    // MARK: - Color helpers
    private func bodyColor() -> SKColor {
        let ratio = inflateLevel / FISH_MAX_INFLATE
        if ratio >= 0.8 {
            return currentSkin.bodyColor.darken(by: 0.2)
        }
        if ratio >= 0.5 {
            return currentSkin.bodyColor.darken(by: 0.1)
        }
        return currentSkin.bodyColor
    }
}

// MARK: - SKColor extension
extension SKColor {
    func darken(by amount: CGFloat) -> SKColor {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(
            red: max(0, r - amount),
            green: max(0, g - amount),
            blue: max(0, b - amount),
            alpha: a
        )
    }
}
