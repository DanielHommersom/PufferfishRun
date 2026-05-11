//
//  Enemy.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SpriteKit

enum EnemyType {
    case jellyfish
    case shark
    case urchin
}

class Enemy: SKNode {

    // MARK: - Properties
    let enemyType: EnemyType
    var isDead: Bool = false

    private var velX: CGFloat = 0
    private var velY: CGFloat = 0
    private var time: CGFloat = 0
    private var baseY: CGFloat = 0
    private var enemyRadius: CGFloat = 0

    // Visual nodes
    private var bodyNode: SKShapeNode!
    private var eyeNode: SKShapeNode!
    private var detailNodes: [SKNode] = []

    // MARK: - Init
    init(type: EnemyType, sceneSize: CGSize) {
        self.enemyType = type
        super.init()
        zPosition = 4
        setupForType(sceneSize: sceneSize)
        draw()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Setup per type
    private func setupForType(sceneSize: CGSize) {
        switch enemyType {

        case .jellyfish:
            enemyRadius = 22
            velX = -1.4
            velY = 0
            position = CGPoint(
                x: sceneSize.width + 40,
                y: CGFloat.random(
                    in: 80...(sceneSize.height - 80))
            )

        case .shark:
            enemyRadius = 32
            velX = -4.0
            velY = 0
            position = CGPoint(
                x: sceneSize.width + 60,
                y: CGFloat.random(
                    in: 60...(sceneSize.height - 60))
            )

        case .urchin:
            enemyRadius = 18
            velX = -2.2
            velY = Bool.random() ? 1.6 : -1.6
            position = CGPoint(
                x: sceneSize.width + 30,
                y: CGFloat.random(
                    in: 60...(sceneSize.height - 60))
            )
        }
        baseY = position.y
    }

    func getRadius() -> CGFloat { return enemyRadius }

    // MARK: - Update
    func update(sceneHeight: CGFloat) {
        time += 0.04

        switch enemyType {

        case .jellyfish:
            position.x += velX
            position.y = baseY + sin(time * 1.8) * 55

        case .shark:
            position.x += velX
            position.y = baseY + sin(time * 0.6) * 20

        case .urchin:
            position.x += velX
            position.y += velY
            if position.y < 30 || position.y > sceneHeight - 30 {
                velY *= -1
            }
        }

        if position.x < -100 { isDead = true }

        // Redraw animated parts
        redrawAnimated()
    }

    // MARK: - Drawing
    private func draw() {
        removeAllChildren()
        detailNodes.removeAll()

        switch enemyType {
        case .jellyfish: drawJellyfish()
        case .shark: drawShark()
        case .urchin: drawUrchin()
        }
    }

    private func redrawAnimated() {
        switch enemyType {
        case .jellyfish: redrawTentacles()
        case .shark: break
        case .urchin: redrawSpines()
        }
    }

    // MARK: - Jellyfish
    private func drawJellyfish() {
        // Bell outline
        let outlinePath = CGMutablePath()
        outlinePath.addEllipse(in: CGRect(
            x: -24, y: 0, width: 48, height: 36))
        let outline = SKShapeNode(path: outlinePath)
        outline.fillColor = .black
        outline.lineWidth = 0
        addChild(outline)

        // Bell fill
        let bellPath = CGMutablePath()
        bellPath.addEllipse(in: CGRect(
            x: -20, y: 2, width: 40, height: 30))
        bodyNode = SKShapeNode(path: bellPath)
        bodyNode.fillColor = SKColor(
            red: 0.608, green: 0.349, blue: 0.714, alpha: 1.0)
        bodyNode.lineWidth = 0
        addChild(bodyNode)

        // Highlight
        let hlPath = CGMutablePath()
        hlPath.addEllipse(in: CGRect(
            x: -10, y: 18, width: 16, height: 9))
        let hl = SKShapeNode(path: hlPath)
        hl.fillColor = UIColor.white.withAlphaComponent(0.5)
        hl.lineWidth = 0
        addChild(hl)

        // Inner dots
        for pos in [CGPoint(x:-8,y:14),
                    CGPoint(x:0,y:16),
                    CGPoint(x:8,y:14)] {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.position = pos
            dot.fillColor = SKColor(
                red: 0.490, green: 0.235, blue: 0.596, alpha: 1.0)
            dot.lineWidth = 0
            addChild(dot)
        }

        // Eye
        let eyeOutline = SKShapeNode(circleOfRadius: 7)
        eyeOutline.position = CGPoint(x: 0, y: 10)
        eyeOutline.fillColor = .black
        eyeOutline.lineWidth = 0
        addChild(eyeOutline)

        let eyeWhite = SKShapeNode(circleOfRadius: 5)
        eyeWhite.position = CGPoint(x: 0, y: 10)
        eyeWhite.fillColor = .white
        eyeWhite.lineWidth = 0
        addChild(eyeWhite)

        let pupil = SKShapeNode(circleOfRadius: 3)
        pupil.position = CGPoint(x: 1, y: 9)
        pupil.fillColor = .black
        pupil.lineWidth = 0
        addChild(pupil)

        // Initial tentacles
        redrawTentacles()
    }

    private func redrawTentacles() {
        // Remove old tentacles
        detailNodes.forEach { $0.removeFromParent() }
        detailNodes.removeAll()

        for i in 0..<6 {
            let baseX = CGFloat(i) * 8 - 20
            for j in 0..<4 {
                let offset = sin(time * 2 +
                    CGFloat(i) * 0.8 +
                    CGFloat(j) * 0.4) * 4
                let seg = SKShapeNode(
                    rect: CGRect(
                        x: baseX + offset - 1.5,
                        y: -CGFloat(j) * 8,
                        width: 3,
                        height: 7
                    )
                )
                seg.fillColor = SKColor(
                    red: 0.490, green: 0.235,
                    blue: 0.596, alpha: 1.0)
                seg.lineWidth = 0
                addChild(seg)
                detailNodes.append(seg)
            }
        }
    }

    // MARK: - Shark
    private func drawShark() {
        // Body outline
        let outlinePath = CGMutablePath()
        outlinePath.addEllipse(in: CGRect(
            x: -36, y: -18, width: 72, height: 36))
        let outline = SKShapeNode(path: outlinePath)
        outline.fillColor = .black
        outline.lineWidth = 0
        addChild(outline)

        // Body fill
        let bodyPath = CGMutablePath()
        bodyPath.addEllipse(in: CGRect(
            x: -33, y: -16, width: 66, height: 32))
        bodyNode = SKShapeNode(path: bodyPath)
        bodyNode.fillColor = SKColor(
            red: 0.365, green: 0.541, blue: 0.659, alpha: 1.0)
        bodyNode.lineWidth = 0
        addChild(bodyNode)

        // Belly
        let bellyPath = CGMutablePath()
        bellyPath.addEllipse(in: CGRect(
            x: -16, y: -12, width: 38, height: 16))
        let belly = SKShapeNode(path: bellyPath)
        belly.fillColor = SKColor(
            red: 0.839, green: 0.918, blue: 0.973, alpha: 1.0)
        belly.lineWidth = 0
        addChild(belly)

        // Dorsal fin
        let dorsalOutline = CGMutablePath()
        dorsalOutline.move(to: CGPoint(x: -4, y: 16))
        dorsalOutline.addLine(to: CGPoint(x: 14, y: 16))
        dorsalOutline.addLine(to: CGPoint(x: 8, y: 0))
        dorsalOutline.closeSubpath()
        let dorsalO = SKShapeNode(path: dorsalOutline)
        dorsalO.fillColor = .black
        dorsalO.lineWidth = 0
        addChild(dorsalO)

        let dorsalPath = CGMutablePath()
        dorsalPath.move(to: CGPoint(x: -2, y: 14))
        dorsalPath.addLine(to: CGPoint(x: 12, y: 14))
        dorsalPath.addLine(to: CGPoint(x: 7, y: 0))
        dorsalPath.closeSubpath()
        let dorsal = SKShapeNode(path: dorsalPath)
        dorsal.fillColor = SKColor(
            red: 0.365, green: 0.541, blue: 0.659, alpha: 1.0)
        dorsal.lineWidth = 0
        addChild(dorsal)

        // Tail
        for (points, color) in [
            ([CGPoint(x:30,y:-18),CGPoint(x:42,y:-18),
              CGPoint(x:30,y:0)], UIColor.black),
            ([CGPoint(x:30,y:0),CGPoint(x:42,y:18),
              CGPoint(x:30,y:18)], UIColor.black),
            ([CGPoint(x:31,y:-16),CGPoint(x:40,y:-16),
              CGPoint(x:31,y:0)],
             SKColor(red:0.29,green:0.48,blue:0.59,alpha:1)),
            ([CGPoint(x:31,y:0),CGPoint(x:40,y:16),
              CGPoint(x:31,y:16)],
             SKColor(red:0.29,green:0.48,blue:0.59,alpha:1)),
        ] as [([ CGPoint], UIColor)] {
            let p = CGMutablePath()
            p.move(to: points[0])
            p.addLine(to: points[1])
            p.addLine(to: points[2])
            p.closeSubpath()
            let n = SKShapeNode(path: p)
            n.fillColor = color
            n.lineWidth = 0
            addChild(n)
        }

        // Eye
        let eyeOutline = SKShapeNode(circleOfRadius: 8)
        eyeOutline.position = CGPoint(x: -18, y: 4)
        eyeOutline.fillColor = .black
        eyeOutline.lineWidth = 0
        addChild(eyeOutline)

        let eyeWhite = SKShapeNode(circleOfRadius: 6)
        eyeWhite.position = CGPoint(x: -18, y: 4)
        eyeWhite.fillColor = .white
        eyeWhite.lineWidth = 0
        addChild(eyeWhite)

        let pupil = SKShapeNode(circleOfRadius: 3)
        pupil.position = CGPoint(x: -17, y: 3)
        pupil.fillColor = .black
        pupil.lineWidth = 0
        addChild(pupil)

        // Teeth
        for i in 0..<3 {
            let tx = CGFloat(i) * 7 - -30
            let toothPath = CGMutablePath()
            toothPath.move(to: CGPoint(x: tx, y: -4))
            toothPath.addLine(to: CGPoint(x: tx + 6, y: -4))
            toothPath.addLine(to: CGPoint(x: tx + 3, y: -10))
            toothPath.closeSubpath()
            let tooth = SKShapeNode(path: toothPath)
            tooth.fillColor = .white
            tooth.lineWidth = 1
            tooth.strokeColor = .black
            addChild(tooth)
        }
    }

    // MARK: - Urchin
    private func drawUrchin() {
        // Body outline
        let outlineBody = SKShapeNode(circleOfRadius: 21)
        outlineBody.fillColor = .black
        outlineBody.lineWidth = 0
        addChild(outlineBody)

        // Body fill
        bodyNode = SKShapeNode(circleOfRadius: 18)
        bodyNode.fillColor = SKColor(
            red: 0.173, green: 0.243, blue: 0.314, alpha: 1.0)
        bodyNode.lineWidth = 0
        addChild(bodyNode)

        // Highlight
        let hl = SKShapeNode(circleOfRadius: 6)
        hl.position = CGPoint(x: -5, y: 5)
        hl.fillColor = UIColor.white.withAlphaComponent(0.4)
        hl.lineWidth = 0
        addChild(hl)

        // Eye
        let eyeOutline = SKShapeNode(circleOfRadius: 7)
        eyeOutline.fillColor = .black
        eyeOutline.lineWidth = 0
        addChild(eyeOutline)

        eyeNode = SKShapeNode(circleOfRadius: 5)
        eyeNode.fillColor = SKColor(
            red: 0.910, green: 0.298, blue: 0.235, alpha: 1.0)
        eyeNode.lineWidth = 0
        addChild(eyeNode)

        let pupil = SKShapeNode(circleOfRadius: 2.5)
        pupil.position = CGPoint(x: 1, y: 1)
        pupil.fillColor = .black
        pupil.lineWidth = 0
        addChild(pupil)

        // Initial spines
        redrawSpines()
    }

    private func redrawSpines() {
        detailNodes.forEach { $0.removeFromParent() }
        detailNodes.removeAll()

        let spineCount = 12
        for i in 0..<spineCount {
            let angle = CGFloat(i) /
                CGFloat(spineCount) * .pi * 2
            let wobble = sin(time * 3 + CGFloat(i)) * 2
            let innerR: CGFloat = 18
            let outerR: CGFloat = 30

            let ix = cos(angle) * innerR
            let iy = sin(angle) * innerR
            let ox = cos(angle) * outerR + wobble
            let oy = sin(angle) * outerR + wobble

            let spineOutline = CGMutablePath()
            spineOutline.move(to: CGPoint(
                x: ix - 2, y: iy))
            spineOutline.addLine(to: CGPoint(x: ox, y: oy))
            spineOutline.addLine(to: CGPoint(
                x: ix + 2, y: iy))
            spineOutline.closeSubpath()

            let outlineNode = SKShapeNode(path: spineOutline)
            outlineNode.fillColor = .black
            outlineNode.lineWidth = 0
            addChild(outlineNode)
            detailNodes.append(outlineNode)

            let spineFill = CGMutablePath()
            spineFill.move(to: CGPoint(x: ix - 1, y: iy))
            spineFill.addLine(to: CGPoint(x: ox, y: oy))
            spineFill.addLine(to: CGPoint(x: ix + 1, y: iy))
            spineFill.closeSubpath()

            let fillNode = SKShapeNode(path: spineFill)
            fillNode.fillColor = SKColor(
                red: 0.933, green: 0.933,
                blue: 0.933, alpha: 1.0)
            fillNode.lineWidth = 0
            addChild(fillNode)
            detailNodes.append(fillNode)
        }
    }
}
