//
//  Constants.swift
//  pufferfishrun
//
//  Created by Daniël Hommersom on 08/05/2026.
//

import CoreGraphics
import SpriteKit
import UIKit

// MARK: - Screen
let SCREEN_WIDTH = UIScreen.main.bounds.width
let SCREEN_HEIGHT = UIScreen.main.bounds.height

// MARK: - Fish
let FISH_BASE_RADIUS: CGFloat = 18
let FISH_MAX_INFLATE: CGFloat = 14
let INFLATE_SPEED: CGFloat = 0.35
let DEFLATE_SPEED: CGFloat = 0.18
let GRAVITY: CGFloat = 0.22
let MAX_VEL_UP: CGFloat = -5.0
let MAX_VEL_DOWN: CGFloat = 5.0

// MARK: - Obstacles
let GAP_SIZE_INITIAL: CGFloat = 230
let GAP_SIZE_MIN: CGFloat = 120
let OBSTACLE_SPEED_INITIAL: CGFloat = 2.5
let OBSTACLE_SPEED_MAX: CGFloat = 4.0
let OBSTACLE_WIDTH: CGFloat = 64

// MARK: - Spawn intervals (seconds)
let SPAWN_INTERVAL_INITIAL: TimeInterval = 2.5
let SPAWN_INTERVAL_MIN: TimeInterval = 1.5

// MARK: - Difficulty ramp
let DIFFICULTY_RAMP_SPEED: Int = 25
let DIFFICULTY_RAMP_GAP: Int = 40
let DIFFICULTY_RAMP_SPAWN: Int = 35

// MARK: - Enemies
let ENEMY_JELLYFISH_MIN_SCORE: Int = 5
let ENEMY_SHARK_MIN_SCORE: Int = 15
let ENEMY_URCHIN_MIN_SCORE: Int = 25
let ENEMY_SPAWN_INTERVAL: TimeInterval = 3.2
let ENEMY_SPAWN_CHANCE: Double = 0.45

// MARK: - Colors
let COLOR_OCEAN_TOP = SKColor(
    red: 0.04, green: 0.16, blue: 0.29, alpha: 1.0)
let COLOR_OCEAN_MID = SKColor(
    red: 0.05, green: 0.23, blue: 0.42, alpha: 1.0)
let COLOR_OCEAN_BOTTOM = SKColor(
    red: 0.02, green: 0.10, blue: 0.20, alpha: 1.0)
let COLOR_FISH_SAFE = SKColor(
    red: 0.957, green: 0.659, blue: 0.196, alpha: 1.0)
let COLOR_FISH_WARNING = SKColor(
    red: 0.941, green: 0.471, blue: 0.125, alpha: 1.0)
let COLOR_FISH_DANGER = SKColor(
    red: 0.910, green: 0.220, blue: 0.125, alpha: 1.0)
let COLOR_CORAL_BASE = SKColor(
    red: 0.545, green: 0.125, blue: 0.125, alpha: 1.0)
let COLOR_CORAL_HIGHLIGHT = SKColor(
    red: 0.690, green: 0.188, blue: 0.188, alpha: 1.0)
