//
//  GameScene.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene {
    
    // MARK: - Properties
    private var oceanBackground: OceanBackground!
    private var fish: PufferFish!
    private var obstacles: [Obstacle] = []
    private var enemies: [Enemy] = []
    private var score: Int = 0
    private var scoreLabel: SKLabelNode!
    private var lastSpawnTime: TimeInterval = 0
    private var lastEnemySpawnTime: TimeInterval = 0
    private var gameOver: Bool = false
    private var isPlayingInflate = false
    private var soundButton: SoundButton!
    
    // MARK: - Scene Setup
    override func didMove(to view: SKView) {
        // Ocean background
        oceanBackground = OceanBackground(sceneSize: size)
        addChild(oceanBackground)
        
        backgroundColor = COLOR_OCEAN_TOP
        
        fish = PufferFish()
        fish.position = CGPoint(
            x: size.width * 0.25,
            y: size.height * 0.5
        )
        addChild(fish)
        
        // Apply selected skin
        let savedId = UserDefaults.standard
            .string(forKey: "selectedSkin") ?? "default"
        if let skin = SKINS.first(
            where: { $0.id == savedId }) {
            fish.setSkin(skin)
        }
        
        // Score label
        scoreLabel = SKLabelNode(
            fontNamed: "CourierNewPS-BoldMT")
        scoreLabel.fontSize = 36
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height - 80
        )
        scoreLabel.zPosition = 10
        addChild(scoreLabel)
        scoreLabel.text = "0"
        
        soundButton = SoundButton(
            position: CGPoint(
                x: size.width - 50,
                y: 50
            )
        )
        soundButton.zPosition = 20
        addChild(soundButton)
    }
    
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        guard !gameOver else { return }

        fish.update()

        // Boundary check
        let r = fish.getRadius()
        if fish.position.y - r < 0 ||
           fish.position.y + r > size.height {
            triggerGameOver()
            return
        }

        // Spawn obstacles
        let spawnInterval = currentSpawnInterval()
        if currentTime - lastSpawnTime > spawnInterval {
            spawnObstacle()
            lastSpawnTime = currentTime
        }

        // Move and check obstacles
        let speed = currentSpeed()
        for i in stride(
            from: obstacles.count - 1,
            through: 0, by: -1
        ) {
            let obs = obstacles[i]
            obs.position.x -= speed
            obs.update(sceneHeight: size.height)

            // Score
            if !obs.passed &&
               obs.position.x + Obstacle.width < fish.position.x {
                obs.passed = true
                score += 1
                scoreLabel.text = "\(score)"
                oceanBackground.update(score: score)
            }

            // Collision
            let fishCenter = fish.position
            let fishR = fish.getRadius()

            if circleCollidesRect(
                center: fishCenter, radius: fishR,
                rect: obs.topRect()
            ) || circleCollidesRect(
                center: fishCenter, radius: fishR,
                rect: obs.bottomRect()
            ) {
                triggerGameOver()
                return
            }

            // Remove off screen
            if obs.position.x < -100 {
                obs.removeFromParent()
                obstacles.remove(at: i)
            }
        }
        
        // Enemy spawning
        if currentTime - lastEnemySpawnTime > ENEMY_SPAWN_INTERVAL {
            lastEnemySpawnTime = currentTime
            maybeSpawnEnemy()
        }

        // Enemy update loop
        for i in stride(
            from: enemies.count - 1,
            through: 0, by: -1
        ) {
            let enemy = enemies[i]
            enemy.update(sceneHeight: size.height)

            // Circle vs circle collision
            let dx = fish.position.x - enemy.position.x
            let dy = fish.position.y - enemy.position.y
            let dist = sqrt(dx*dx + dy*dy)
            let minDist = fish.getRadius() +
                enemy.getRadius() - 4

            if dist < minDist {
                triggerGameOver()
                return
            }

            if enemy.isDead {
                enemy.removeFromParent()
                enemies.remove(at: i)
            }
        }
    }
    
    // MARK: - Touch Input
    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        guard !gameOver else { return }
        fish.inflate()
        
        if !isPlayingInflate {
            isPlayingInflate = true
            SoundManager.shared.playInflate()
        }
    }
    
    override func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent?
    ) {
        guard !gameOver else { return }
        fish.deflate()
        isPlayingInflate = false
    }
    
    // MARK: - Obstacle Spawning
    private func spawnObstacle() {
        let gap = currentGapSize()
        let margin = gap * 0.55
        let minY = gap / 2 + margin
        let maxY = size.height - gap / 2 - margin
        let gapY = CGFloat.random(in: minY...maxY)

        // Disable moving obstacles (always false for stability)
        let shouldMove = false
        let moveSpeed: CGFloat = 0
        let moveRange: CGFloat = 0

        let obs = Obstacle(
            sceneSize: size,
            gapY: gapY,
            gapSize: gap,
            isMoving: shouldMove,
            moveSpeed: moveSpeed,
            moveRange: moveRange
        )
        obs.position = CGPoint(x: size.width + 10, y: 0)
        addChild(obs)
        obstacles.append(obs)
    }
    
    private func maybeSpawnEnemy() {
        guard !gameOver else { return }
        guard Double.random(in: 0...1) < ENEMY_SPAWN_CHANCE
        else { return }

        var available: [EnemyType] = []
        if score >= ENEMY_JELLYFISH_MIN_SCORE {
            available.append(.jellyfish)
        }
        if score >= ENEMY_SHARK_MIN_SCORE {
            available.append(.shark)
        }
        if score >= ENEMY_URCHIN_MIN_SCORE {
            available.append(.urchin)
        }

        guard !available.isEmpty else { return }

        let type = available.randomElement()!
        let enemy = Enemy(type: type, sceneSize: size)
        addChild(enemy)
        enemies.append(enemy)
    }
    
    // MARK: - Collision Detection
    private func circleCollidesRect(
        center: CGPoint,
        radius: CGFloat,
        rect: CGRect
    ) -> Bool {
        let nearX = max(rect.minX, min(center.x, rect.maxX))
        let nearY = max(rect.minY, min(center.y, rect.maxY))
        let dx = center.x - nearX
        let dy = center.y - nearY
        return dx * dx + dy * dy < radius * radius
    }
    
    // MARK: - Difficulty Scaling
    private func currentGapSize() -> CGFloat {
        let t = min(CGFloat(score) / CGFloat(DIFFICULTY_RAMP_GAP), 1)
        return GAP_SIZE_INITIAL + (GAP_SIZE_MIN - GAP_SIZE_INITIAL) * t
    }

    private func currentSpeed() -> CGFloat {
        let t = min(CGFloat(score) / CGFloat(DIFFICULTY_RAMP_SPEED), 1)
        return OBSTACLE_SPEED_INITIAL +
            (OBSTACLE_SPEED_MAX - OBSTACLE_SPEED_INITIAL) * t
    }

    private func currentSpawnInterval() -> TimeInterval {
        let t = min(Double(score) / Double(DIFFICULTY_RAMP_SPAWN), 1)
        return SPAWN_INTERVAL_INITIAL +
            (SPAWN_INTERVAL_MIN - SPAWN_INTERVAL_INITIAL) * t
    }

    private func movingObstacleChance() -> Double {
        guard score >= 8 else { return 0 }
        let t = min(Double(score - 8) /
            Double(DIFFICULTY_RAMP_SPEED), 1)
        return 0.55 * t
    }

    private func currentMoveSpeed() -> CGFloat {
        let t = min(CGFloat(score) / CGFloat(DIFFICULTY_RAMP_SPEED), 1)
        return 1.2 + (2.4 - 1.2) * t
    }
    
    // MARK: - Game Over
    private func triggerGameOver() {
        guard !gameOver else { return }
        gameOver = true
        
        SoundManager.shared.playGameOver()

        fish.deflate()
        enemies.forEach { $0.removeFromParent() }
        enemies.removeAll()

        // Death animation
        let shrink = SKAction.scale(to: 0, duration: 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        fish.run(SKAction.group([shrink, fadeOut]))

        // Spawn bubbles at fish position
        for _ in 0..<8 {
            let bubble = SKShapeNode(
                circleOfRadius: CGFloat.random(in: 4...10))
            bubble.fillColor = UIColor(
                red: 0.533, green: 0.867,
                blue: 1.0, alpha: 0.7)
            bubble.lineWidth = 0
            bubble.position = fish.position
            addChild(bubble)

            let dx = CGFloat.random(in: -50...50)
            let dy = CGFloat.random(in: 20...80)
            bubble.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(
                        x: dx, y: dy, duration: 0.6),
                    SKAction.fadeOut(withDuration: 0.6)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        // Navigate to GameOverScene
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                let scene = GameOverScene(
                    size: self.size,
                    score: self.score
                )
                scene.scaleMode = self.scaleMode
                self.view?.presentScene(scene,
                                       transition: SKTransition.fade(
                                        withDuration: 0.3))
            }
        ]))
    }
}
