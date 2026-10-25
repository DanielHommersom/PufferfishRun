class_name Constants
## All gameplay values and shared colours, ported 1:1 from Constants.swift.
## Gameplay values are per physics tick (60 Hz), exactly like the per-frame Swift values.

# ── Fish ─────────────────────────────────────────────
const FISH_BASE_RADIUS := 18.0
const FISH_MAX_INFLATE := 14.0
const FISH_RADIUS_PER_INFLATE := 0.85
const INFLATE_SPEED := 0.35
const DEFLATE_SPEED := 0.18
const INFLATE_LIFT := INFLATE_SPEED * 1.2
const GRAVITY := 0.22
const MAX_VEL := 5.0
const FISH_START := Vector2(0.25, 0.5) # fraction of screen
const BLINK_INTERVAL := 180
const BLINK_DURATION := 6

# ── Obstacles ────────────────────────────────────────
const GAP_SIZE_INITIAL := 230.0
const GAP_SIZE_MIN := 120.0
const GAP_MARGIN_FACTOR := 0.55
const OBSTACLE_SPEED_INITIAL := 2.5
const OBSTACLE_SPEED_MAX := 4.0
const OBSTACLE_WIDTH := 80.0 # B1: Swift declared 64 but hardcoded 80 everywhere
const OBSTACLE_SPAWN_OFFSET := 10.0
const OBSTACLE_DESPAWN_X := -100.0

# ── Spawn intervals (seconds) ────────────────────────
const SPAWN_INTERVAL_INITIAL := 2.5
const SPAWN_INTERVAL_MIN := 1.5

# ── Difficulty ramp (score at which the max is reached) ──
const DIFFICULTY_RAMP_SPEED := 25
const DIFFICULTY_RAMP_GAP := 40
const DIFFICULTY_RAMP_SPAWN := 35

# ── Moving obstacles (US-26, off by default = parity with v1.0) ──
const MOVING_OBSTACLES_ENABLED := false
const MOVING_OBSTACLE_MIN_SCORE := 8
const MOVING_OBSTACLE_MAX_CHANCE := 0.55
const MOVING_OBSTACLE_SPEED_MIN := 1.2
const MOVING_OBSTACLE_SPEED_MAX := 2.4
const MOVING_OBSTACLE_RANGE := 60.0
const MOVING_OBSTACLE_EDGE := 40.0

# ── Enemies ──────────────────────────────────────────
const ENEMY_JELLYFISH_MIN_SCORE := 5
const ENEMY_SHARK_MIN_SCORE := 15
const ENEMY_URCHIN_MIN_SCORE := 25
const ENEMY_SPAWN_INTERVAL := 3.2
const ENEMY_SPAWN_CHANCE := 0.45
const ENEMY_COLLISION_MARGIN := 4.0
const ENEMY_DESPAWN_X := -100.0
const ENEMY_TIME_STEP := 0.04
const ENEMY_Z := 4

# ── Depth zones ──────────────────────────────────────
# Six zones (original three at 0/20/50, new: kelp forest, shipwreck, abyss).
const ZONE_MIN_SCORES := [0, 10, 20, 35, 50, 70]
const ZONE_NAMES := ["SHALLOW REEF", "KELP FOREST", "OPEN WATER", "SHIPWRECK", "DEEP OCEAN", "THE ABYSS"]
const ZONE_DECOR := ["", "kelp", "", "wreck", "", "abyss"]
const ZONE_TWEEN_TIME := 2.0
const DEPTH_LABEL_ENABLED := false # US-27, never visible in v1.0 (replaced by the zone banner)
const DEPTH_PER_POINT := 8 ## metres shown per point under the score
const ABYSS_DARKNESS := 0.62 ## darkness strength outside the fish's light in the abyss
const ABYSS_LIGHT_RADIUS := 150.0

# ── Onboarding ───────────────────────────────────────
const TUTORIAL_GAMES := 3 ## extra-wide first gaps during a player's first games
const TUTORIAL_GAP_BONUS := [90.0, 60.0, 30.0] ## added to the first three gaps

# ── Near miss ────────────────────────────────────────
const NEAR_MISS_DISTANCE := 7.0 ## px of clearance that counts as "CLOSE!"
const NEAR_MISS_COINS := 1

# ── Power-ups ────────────────────────────────────────
const POWERUP_MIN_SCORE := 3
const POWERUP_CHANCE := 0.14 ## per pillar (replaces the coin)
const POWERUP_RADIUS := 14.0
const MAGNET_TIME := 8.0
const MAGNET_RADIUS := 170.0
const SLOW_TIME := 5.0
const SLOW_FACTOR := 0.6
const SHIELD_SAVE_INVULNERABLE := 1.2
const START_SHIELD_PRICE := 30

# ── Daily ────────────────────────────────────────────
const DAILY_REWARDS := [20, 30, 40, 50, 60, 80, 150] ## day 1…7 of a streak
const MISSIONS_PER_DAY := 3
const CHALLENGE_TARGET := 15
const CHALLENGE_REWARD := 60

# ── Game flow ────────────────────────────────────────
const DEATH_DELAY := 0.8
const DEATH_ANIM_TIME := 0.4
const GAMES_BEFORE_AD := 3
const MAX_AD_LOAD_ATTEMPTS := 3

# ── Monetisation ─────────────────────────────────────
const AD_GRACE_GAMES := 5 ## no interstitials during a player's first games (lifetime)
const AD_MIN_INTERVAL := 75.0 ## seconds between two interstitials
const REVIVE_MIN_SCORE := 2 ## offer "continue?" only from this score
const REVIVE_COUNTDOWN := 5.0 ## seconds before the offer expires
const REVIVE_INVULNERABLE := 2.0 ## seconds of protection after reviving
const REVIVE_CLEAR_AHEAD := 220.0 ## remove pillars up to this far in front of the fish
const COIN_CHANCE := 0.6 ## chance a pillar carries a coin in its gap
const COIN_RADIUS := 11.0
const FREE_COINS_PER_DAY := 3 ## rewarded "free coins" in the shop
const FREE_COINS_AMOUNT := 25
const REMOVE_ADS_PRODUCT_ID := "digitaldiamonds.pufferfishrun.removeads" ## non-consumable in App Store Connect
const REMOVE_ADS_FALLBACK_PRICE := "€2,99" ## shown until StoreKit returns the localised price
const PRIVACY_POLICY_URL := "https://danielhommersom.github.io/PufferfishRun/"
const SUPPORT_EMAIL := "digitaldiamonds.ai@gmail.com"

# ── Medals ───────────────────────────────────────────
const MEDAL_GOLD := 40
const MEDAL_SILVER := 20
const MEDAL_BRONZE := 10

# ── Shared colours ───────────────────────────────────
const OCEAN_TOP := Color(0.04, 0.16, 0.29)
const CORAL_BASE := Color(0.545, 0.125, 0.125)
const CORAL_HIGHLIGHT := Color(0.690, 0.188, 0.188)
const UI_ORANGE := Color(0.957, 0.659, 0.196)
const UI_BLUE := Color(0.102, 0.290, 0.416)
const UI_GREEN := Color(0.267, 0.800, 0.267)
const UI_GOLD_TEXT := Color(1.0, 0.867, 0.533)
const UI_MUTED_TEXT := Color(0.533, 0.667, 0.733)
const UI_LOCK_ORANGE := Color(1.0, 0.533, 0.0)
const PANEL_BG := Color(0.039, 0.165, 0.290)

const ZONE_COLORS := [
	# [top, mid, bottom, ray alpha]
	[Color(0.306, 0.753, 0.792), Color(0.165, 0.541, 0.604), Color(0.051, 0.227, 0.361), 0.18], # shallow reef
	[Color(0.200, 0.600, 0.500), Color(0.090, 0.400, 0.340), Color(0.030, 0.200, 0.200), 0.14], # kelp forest
	[Color(0.102, 0.416, 0.541), Color(0.051, 0.290, 0.416), Color(0.024, 0.125, 0.251), 0.10], # open water
	[Color(0.070, 0.270, 0.320), Color(0.040, 0.170, 0.210), Color(0.020, 0.080, 0.110), 0.07], # shipwreck
	[Color(0.039, 0.165, 0.290), Color(0.024, 0.094, 0.157), Color(0.008, 0.039, 0.078), 0.04], # deep ocean
	[Color(0.015, 0.040, 0.100), Color(0.005, 0.020, 0.060), Color(0.000, 0.008, 0.025), 0.0], # the abyss
]
const DEEP_ZONE := 4 ## used as the game-over backdrop
## Launch colour: iOS launch screen, Godot boot screen and the start of the splash sequence share
## this one flat colour, so launch → boot → studio logo has no visible jump.
const LAUNCH_BG := Color(0.02, 0.05, 0.08)
const RAY_COLOR := Color(0.365, 0.831, 0.867)

const FONT_PATH := "res://assets/fonts/game_font.tres"
