extends SceneTree
## App Store preview: ~27 s of real gameplay, recorded with Godot's Movie Maker (PNG frames +
## WAV audio), then encoded to H.264 by tools/encode_preview.swift. The fish is steered by a
## simple autopilot; scenes are cut together: menu → reef → kelp + magnet → shipwreck + shield
## → abyss → shop. Runs on the fresh test save (tests/). The window size sets the video size,
## so pass it with an override.cfg (886×1920 for iPhone, 1200×1600 for iPad):
##   godot --path godot --fixed-fps 30 --write-movie <dir>/f.png -s res://tests/store_preview.gd

var _layout := Vector2.ZERO


func _initialize() -> void:
	await process_frame # let the autoloads finish _ready()
	var sm = root.get_node("SaveManager")
	sm.language = "en"
	sm.high_score = 48
	sm.coins = 1250
	sm.selected_hat = "crown"
	sm.selected_trail = "rainbow"
	sm.games_played = 40 # past onboarding: no tutorial overlays
	_layout = root.get_visible_rect().size
	var menu_script = load("res://scripts/menu.gd")
	menu_script._daily_shown_this_session = true # no daily popup in the video
	menu_script._splash_played = true

	await _menu(2.2)
	await _run(0, 0, "", 7.0)
	await _run(1, 10, "magnet", 5.0)
	await _run(3, 35, "shield", 4.5)
	await _run(5, 70, "", 4.5)
	await _shop(3.0)
	await _menu(1.6)
	quit()


func _clear() -> void:
	for c in root.get_children():
		if c is Node and not c.name in ["SaveManager", "SceneRouter", "SoundManager", "AdManager", "PurchaseManager"]:
			c.queue_free()
	await process_frame


func _menu(seconds: float) -> void:
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	for c in menu.get_children():
		if c.get_script() and c.get_script().get_global_name() in ["DailyRewardPanel", "ChallengePanel"]:
			c.queue_free()
	await create_timer(seconds).timeout
	await _clear()


func _shop(seconds: float) -> void:
	var shop: Node = load("res://scenes/skin_select.tscn").instantiate()
	root.add_child(shop)
	await create_timer(seconds * 0.34).timeout
	shop._switch_tab("hat")
	await create_timer(seconds * 0.33).timeout
	shop._switch_tab("trail")
	await create_timer(seconds * 0.33).timeout
	await _clear()


func _run(zone: int, score: int, power: String, seconds: float) -> void:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_run()
	game.score = score
	game._score_label.text = str(score)
	game._depth_label.text = "%d m" % (score * Constants.DEPTH_PER_POINT)
	if zone > 0:
		game._ocean._apply_zone(zone, false)
		game._ocean._zone = zone
	game._invulnerable = 999.0 # the autopilot never crashes
	var fish: Node2D = game.get("_fish")
	fish.position.y = _layout.y * 0.45
	if power == "shield":
		fish.shield = true
	elif power == "magnet":
		game._magnet_left = seconds
	await _autopilot(game, seconds)
	await _clear()


## Steers the fish towards the centre of the next gap, like a good player, and hides the
## invulnerability blink.
func _autopilot(game: Node, seconds: float) -> void:
	var fish: Node2D = game.get("_fish")
	var frames := int(seconds * 30.0)
	for i in frames:
		var target := _layout.y * 0.45
		for obs in game.get("_obstacles"):
			if obs.position.x + Constants.OBSTACLE_WIDTH > fish.position.x - 10.0:
				target = obs.current_gap_y if obs.current_gap_y != 0.0 else obs.gap_y
				break
		if fish.position.y > target + 6.0:
			fish.inflate()
		else:
			fish.deflate()
		await process_frame
		fish.modulate.a = 1.0
