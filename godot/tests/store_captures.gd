extends SceneTree
## Raw in-game captures for App Store screenshots (no captions; those are added afterwards).
## Renders off-screen in a SubViewport at the exact store resolution, with the game's own
## layout size, so the Mac screen size doesn't matter. Runs on the fresh test save (tests/).
##   godot --path godot -s res://tests/store_captures.gd -- <out_dir> <iphone|ipad>

const DEVICES := {
	"iphone": {"size": Vector2i(1179, 2556), "layout": Vector2i(393, 852)},
	"ipad": {"size": Vector2i(2048, 2732), "layout": Vector2i(639, 852)}, # 3:4, game layout expands sideways
}

var out_dir := "user://store"
var vp: SubViewport
var layout := Vector2.ZERO


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	var device: String = args[1] if args.size() > 1 else "iphone"
	DirAccess.make_dir_recursive_absolute(out_dir)
	await process_frame # let the autoloads finish _ready()

	var sm = root.get_node("SaveManager")
	sm.language = "en"
	sm.high_score = 48
	sm.coins = 1250
	sm.selected_hat = "crown"
	sm.selected_trail = "rainbow"
	sm.games_played = 40 # past onboarding: no tutorial overlays in the shots

	var spec: Dictionary = DEVICES[device]
	layout = Vector2(spec.layout)
	vp = SubViewport.new()
	vp.size = spec.size
	vp.size_2d_override = spec.layout
	vp.size_2d_override_stretch = true
	vp.msaa_2d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	await _shot_menu("01_menu")
	await _shot_game("02_gameplay")
	await _shot_zone(1, "03_kelp_magnet", "magnet")
	await _shot_zone(3, "04_shipwreck_shield", "shield")
	await _shot_zone(5, "05_abyss", "")
	await _shot_shop("hat", "06_shop_hats")
	await _shot_daily("07_daily")
	quit()


func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png("%s/%s.png" % [out_dir, name])
	print("saved ", name, " ", img.get_size())


func _clear() -> void:
	for c in vp.get_children():
		c.queue_free()
	await process_frame


func _shot_menu(name: String) -> void:
	vp.add_child(load("res://scenes/menu.tscn").instantiate())
	await create_timer(1.4).timeout
	for c in vp.get_child(0).get_children(): # drop the daily popup if it opened
		if c.get_script() and c.get_script().get_global_name() in ["DailyRewardPanel", "ChallengePanel"]:
			c.queue_free()
	await create_timer(0.3).timeout
	await _save(name)
	await _clear()


func _shot_game(name: String) -> void:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	vp.add_child(game)
	await process_frame
	game._start_run()
	game.score = 8 # stays in the first zone, no zone banner
	game._invulnerable = 99.0 # never crash during the capture
	await _hover(game, 4.0)
	for t in 2:
		var e = load("res://scripts/enemy.gd").create(t, layout)
		e.position = Vector2(layout.x * 0.62 + t * layout.x * 0.18, layout.y * 0.22 + t * layout.y * 0.5)
		e.base_y = e.position.y
		e.vel_x = 0.0
		game.get("_enemy_layer").add_child(e)
	await _hover(game, 0.35)
	await _freeze_and_save(game, name)


## Steers the fish towards the centre of the next gap, like a good player.
func _hover(game: Node, seconds: float) -> void:
	var fish: Node2D = game.get("_fish")
	var frames := int(seconds * 60.0)
	for i in frames:
		var target := layout.y * 0.45
		for obs in game.get("_obstacles"):
			if obs.position.x + Constants.OBSTACLE_WIDTH > fish.position.x - 10.0:
				target = obs.current_gap_y if obs.current_gap_y != 0.0 else obs.gap_y
				break
		if fish.position.y > target + 6.0:
			fish.inflate()
		else:
			fish.deflate()
		await physics_frame


func _freeze_and_save(game: Node, name: String) -> void:
	game.set_physics_process(false)
	game.get("_fish").modulate.a = 1.0 # hide the invulnerability blink
	_remove_popups(game)
	var fish: Node2D = game.get("_fish")
	fish.inflate_level = minf(fish.inflate_level, 3.0) # a bit puffed, not the dark warning colour
	fish.is_inflating = false
	fish.queue_redraw()
	await _save(name)
	await _clear()


func _shot_zone(zone: int, name: String, power: String) -> void:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	vp.add_child(game)
	await process_frame
	game._start_run()
	var score: int = Constants.ZONE_MIN_SCORES[zone]
	game.score = score - 1
	game._ocean._apply_zone(zone, false)
	game._ocean._zone = zone
	game._invulnerable = 99.0
	await _hover(game, 0.8)
	game._fish.shield = power == "shield"
	game._magnet_left = 5.0 if power == "magnet" else 0.0
	await _hover(game, 1.2)
	game.score = score
	game._add_point(game._obstacles[0])
	await _hover(game, 2.2)
	await _freeze_and_save(game, name)


func _shot_shop(kind: String, name: String) -> void:
	var inst: Node = load("res://scenes/skin_select.tscn").instantiate()
	vp.add_child(inst)
	await process_frame
	inst._switch_tab(kind)
	await create_timer(0.5).timeout
	await _save(name)
	await _clear()


func _shot_daily(name: String) -> void:
	var inst: Node = load("res://scenes/menu.tscn").instantiate()
	vp.add_child(inst)
	await process_frame
	for c in inst.get_children():
		if c.get_script() and c.get_script().get_global_name() in ["DailyRewardPanel", "ChallengePanel"]:
			c.queue_free()
	inst.add_child(load("res://scripts/daily_reward_panel.gd").new())
	await create_timer(0.9).timeout
	await _save(name)
	await _clear()


## Drops floating texts like "MISSION COMPLETE!" and "CLOSE! +1" so they don't cover the fish.
func _remove_popups(node: Node) -> void:
	for c in node.get_children():
		if c is Label and (c.text.contains("MISSION") or c.text.contains("CLOSE") or c.text.contains("+")):
			c.visible = false
		_remove_popups(c)
