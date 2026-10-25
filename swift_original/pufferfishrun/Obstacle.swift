//
//  Obstacle.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SpriteKit

class Obstacle: SKNode {

    // MARK: - Properties
    var passed: Bool = false
    let gapY: CGFloat
    let gapSize: CGFloat

    private var topNode: SKShapeNode!
    private var bottomNode: SKShapeNode!
    private var topCapNode: SKShapeNode!
    private var bottomCapNode: SKShapeNode!

    // Moving obstacle support
    let isMoving: Bool
    private var moveSpeed: CGFloat
    private var moveDirection: CGFloat = 1
    private var moveRange: CGFloat
    private var currentGapY: CGFloat

    // MARK: - Constants
    static let width: CGFloat = 80

    // MARK: - Init
    init(
        sceneSize: CGSize,
        gapY: CGFloat,
        gapSize: CGFloat,
        isMoving: Bool = false,
        moveSpeed: CGFloat = 0,
        moveRange: CGFloat = 0
    ) {
        self.gapY = gapY
        self.gapSize = gapSize
        self.currentGapY = gapY
        self.isMoving = isMoving
        self.moveSpeed = moveSpeed
        self.moveRange = moveRange
        super.init()
        drawColumns(gapY: currentGapY, sceneHeight: sceneSize.height)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Update
    func update(sceneHeight: CGFloat) {
        guard isMoving else { return }

        currentGapY += moveSpeed * moveDirection

        if currentGapY > gapY + moveRange { moveDirection = -1 }
        if currentGapY < gapY - moveRange { moveDirection = 1 }

        let minY = gapSize / 2 + 40
        let maxY = sceneHeight - gapSize / 2 - 40
        currentGapY = max(minY, min(maxY, currentGapY))

        // Update obstacle geometry efficiently without recreating nodes
        updateGeometry(sceneHeight: sceneHeight)
    }
    
    // MARK: - Efficient geometry update (no node recreation)
    private func updateGeometry(sceneHeight: CGFloat) {
        // Remove all children and redraw
        // (Moving obstacles are disabled anyway)
        removeAllChildren()
        drawColumns(gapY: currentGapY, sceneHeight: sceneHeight)
    }

    // MARK: - Collision rects (world space)
    func topRect() -> CGRect {
        let topHeight = currentGapY - gapSize / 2
        return CGRect(
            x: position.x,
            y: position.y,
            width: 80,
            height: topHeight
        )
    }

    func bottomRect() -> CGRect {
        let bottomY = currentGapY + gapSize / 2
        return CGRect(
            x: position.x,
            y: position.y + bottomY,
            width: 80,
            height: 9999
        )
    }

    // MARK: - Drawing
    private func drawColumns(gapY: CGFloat, sceneHeight: CGFloat) {
        let cw: CGFloat = 80
        let topHeight = gapY - gapSize / 2
        let bottomY = gapY + gapSize / 2
        let bottomHeight = sceneHeight - bottomY

        // ── TOP COLUMN ──────────────────────────────────

        // Main fill
        addRect(
            CGRect(x: 0, y: 0, width: cw, height: topHeight),
            color: SKColor(red: 0.545, green: 0.102, blue: 0.102, alpha: 1))

        // Left highlight
        addRect(
            CGRect(x: 0, y: 0, width: 8, height: topHeight),
            color: SKColor(red: 0.647, green: 0.125, blue: 0.125, alpha: 1))

        // Right shadow
        addRect(
            CGRect(x: cw - 10, y: 0, width: 10, height: topHeight),
            color: SKColor(red: 0.420, green: 0.063, blue: 0.063, alpha: 1))

        // Horizontal scan lines
        var lineY: CGFloat = 0
        while lineY < topHeight {
            addRect(
                CGRect(x: 0, y: lineY, width: cw, height: 1),
                color: SKColor(red: 0.420, green: 0.063, blue: 0.063, alpha: 1),
                alpha: 0.2)
            lineY += 12
        }

        // Jagged bottom edge
        drawJaggedEdge(
            atY: topHeight,
            columnWidth: cw,
            pointingDown: true
        )

        // Moss at bottom edge
        drawMoss(atY: topHeight - 16, columnWidth: cw)

        // Flowers
        drawFlowers(
            columnX: 0,
            columnY: 0,
            columnHeight: topHeight,
            columnWidth: cw
        )

        // ── BOTTOM COLUMN ────────────────────────────────

        // Main fill
        addRect(
            CGRect(x: 0, y: bottomY, width: cw, height: bottomHeight),
            color: SKColor(red: 0.545, green: 0.102, blue: 0.102, alpha: 1))

        // Left highlight
        addRect(
            CGRect(x: 0, y: bottomY, width: 8, height: bottomHeight),
            color: SKColor(red: 0.647, green: 0.125, blue: 0.125, alpha: 1))

        // Right shadow
        addRect(
            CGRect(x: cw - 10, y: bottomY, width: 10, height: bottomHeight),
            color: SKColor(red: 0.420, green: 0.063, blue: 0.063, alpha: 1))

        // Horizontal scan lines
        var lineY2 = bottomY
        while lineY2 < bottomY + bottomHeight {
            addRect(
                CGRect(x: 0, y: lineY2, width: cw, height: 1),
                color: SKColor(red: 0.420, green: 0.063, blue: 0.063, alpha: 1),
                alpha: 0.2)
            lineY2 += 12
        }

        // Jagged top edge
        drawJaggedEdge(
            atY: bottomY,
            columnWidth: cw,
            pointingDown: false
        )

        // Moss at top edge
        drawMoss(atY: bottomY + 2, columnWidth: cw)

        // Flowers
        drawFlowers(
            columnX: 0,
            columnY: bottomY,
            columnHeight: bottomHeight,
            columnWidth: cw
        )
    }

    // MARK: - Helper: add colored rect
    private func addRect(
        _ rect: CGRect,
        color: SKColor,
        alpha: CGFloat = 1.0
    ) {
        let node = SKShapeNode(rect: rect)
        node.fillColor = color
        node.lineWidth = 0
        node.alpha = alpha
        addChild(node)
    }

    // MARK: - Jagged pixel edge
    private func drawJaggedEdge(
        atY edgeY: CGFloat,
        columnWidth: CGFloat,
        pointingDown: Bool
    ) {
        // Height pattern for jagged blocks (in pixels)
        let pattern: [CGFloat] = [
            8, 4, 12, 4, 8, 12, 4, 8, 4, 12,
            8, 4, 12, 8, 4, 4, 12, 8, 4, 8
        ]
        let blockW: CGFloat = 4

        for i in 0..<Int(columnWidth / blockW) {
            let patternIndex = i % pattern.count
            let blockH = pattern[patternIndex]
            let bx = CGFloat(i) * blockW

            let rect: CGRect
            if pointingDown {
                rect = CGRect(
                    x: bx, y: edgeY,
                    width: blockW, height: blockH)
            } else {
                rect = CGRect(
                    x: bx, y: edgeY - blockH,
                    width: blockW, height: blockH)
            }

            addRect(rect, color: SKColor(
                red: 0.420, green: 0.063, blue: 0.063, alpha: 1))
        }

        // Second row — smaller 2x2 detail blocks
        for i in 0..<Int(columnWidth / 2) {
            let bx = CGFloat(i) * 2
            let color = i % 2 == 0
                ? SKColor(red: 0.545, green: 0.102, blue: 0.102, alpha: 1)
                : SKColor(red: 0.420, green: 0.063, blue: 0.063, alpha: 1)

            let detailY = pointingDown
                ? edgeY + pattern[i % pattern.count] + 1
                : edgeY - pattern[i % pattern.count] - 3

            addRect(
                CGRect(x: bx, y: detailY, width: 2, height: 2),
                color: color)
        }
    }

    // MARK: - Moss decoration
    private func drawMoss(
        atY y: CGFloat,
        columnWidth: CGFloat
    ) {
        let mossColors = [
            SKColor(red: 0.176, green: 0.541, blue: 0.243, alpha: 1),
            SKColor(red: 0.267, green: 0.667, blue: 0.333, alpha: 1),
        ]

        for i in 0..<8 {
            let mx = CGFloat(i) * 10 + CGFloat((i * 7) % 5)
            let my = y + CGFloat((i * 3) % 8) - 4
            let size: CGFloat = i % 3 == 0 ? 6 : 4

            addRect(
                CGRect(x: mx, y: my, width: size, height: size),
                color: mossColors[i % 2])
        }
    }

    // MARK: - Flower decoration
    private func drawFlowers(
        columnX: CGFloat,
        columnY: CGFloat,
        columnHeight: CGFloat,
        columnWidth: CGFloat
    ) {
        guard columnHeight > 60 else { return }

        let flowerCount: Int
        if columnHeight < 100 { flowerCount = 1 }
        else if columnHeight < 250 { flowerCount = 3 }
        else { flowerCount = 5 }

        let spacing = columnHeight / CGFloat(flowerCount + 1)

        for i in 0..<flowerCount {
            let fx = columnX + 20 + CGFloat((i * 23) % 40)
            let fy = columnY + spacing * CGFloat(i + 1)

            drawFlower(at: CGPoint(x: fx, y: fy))
        }
    }

    private func drawFlower(at center: CGPoint) {
        // 6 petals
        for i in 0..<6 {
            let angle = CGFloat(i) / 6 * .pi * 2
            let px = center.x + cos(angle) * 9
            let py = center.y + sin(angle) * 9

            let petalOutline = SKShapeNode(circleOfRadius: 6)
            petalOutline.position = CGPoint(x: px, y: py)
            petalOutline.fillColor = .black
            petalOutline.lineWidth = 0
            addChild(petalOutline)

            let petal = SKShapeNode(circleOfRadius: 5)
            petal.position = CGPoint(x: px, y: py)
            petal.fillColor = SKColor(
                red: 0.957, green: 0.627, blue: 0.125, alpha: 1)
            petal.lineWidth = 0
            addChild(petal)
        }

        // Center
        let centerOutline = SKShapeNode(circleOfRadius: 8)
        centerOutline.position = center
        centerOutline.fillColor = .black
        centerOutline.lineWidth = 0
        addChild(centerOutline)

        let centerFill = SKShapeNode(circleOfRadius: 7)
        centerFill.position = center
        centerFill.fillColor = SKColor(
            red: 0.910, green: 0.365, blue: 0.0, alpha: 1)
        centerFill.lineWidth = 0
        addChild(centerFill)
    }
}
