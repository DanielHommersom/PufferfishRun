extends SceneTree
## Renders each screen to PNG for visual review:
## godot --path godot -s res://tests/screenshots.gd -- <out_dir>

var out_dir := "user://screenshots"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	await process_frame # let the autoloads finish _ready()
	await _shot_splash(1.6, "splash_studio")
	await _shot_splash(4.6, "splash_game")
	root.get_node("SaveManager").high_score = 23
	var sm = root.get_node("SaveManager")
	var prev_hat: String = sm.selected_hat
	var prev_trail: String = sm.selected_trail
	sm.selected_hat = "crown"
	sm.selected_trail = "rainbow"
	await _shot("menu", 1.2)
	root.get_node("SaveManager").coins = 140
	await _shot("skin_select", 0.5)
	await _shot_shop_tab("hat")
	await _shot_shop_tab("trail")
	await _shot("settings", 0.5)
	await _shot("game", 0.8, "get_ready")
	await _shot_zone(1, "zone_kelp")
	await _shot_zone(3, "zone_wreck")
	await _shot_zone(5, "zone_abyss")
	await _shot_overlay("menu", "DailyRewardPanel", "daily_panel")
	await _shot_overlay("menu", "ChallengePanel", "challenge_panel")
	await _shot("missions", 0.6)
	sm.language = "de"
	await _shot("menu", 1.0, "menu_de")
	sm.language = "ja"
	await _shot("skin_select", 0.5, "shop_ja")
	sm.language = "auto"
	await _shot_game()
	await _shot_revive()
	sm.selected_hat = prev_hat
	sm.selected_trail = prev_trail
	root.get_node("SceneRouter").params = {"score": 42, "coins": 7}
	root.get_node("SaveManager").high_score = 23
	await _shot("game_over", 2.0)
	quit()


func _shot(key: String, wait: float, out_name := "") -> void:
	var inst: Node = load("res://scenes/%s.tscn" % key).instantiate()
	root.add_child(inst)
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var name := out_name if out_name != "" else key
	root.get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("saved ", name)
	inst.queue_free()
	await process_frame


func _shot_game() -> void:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	var fish: Node2D = game.get("_fish")
	game._start_run()
	fish.inflate()
	for i in 40:
		await physics_frame
	fish.deflate()
	await create_timer(1.3).timeout
	for t in 3:
		var e = load("res://scripts/enemy.gd").create(t, root.get_visible_rect().size)
		e.position = Vector2(170 + t * 80, 300 + t * 140)
		e.base_y = e.position.y
		e.vel_x = 0.0
		game.get("_enemy_layer").add_child(e)
	fish.inflate()
	await create_timer(0.35).timeout
	game.set_physics_process(false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/game.png" % out_dir)
	print("saved game")
	game.queue_free()
	await process_frame


func _shot_revive() -> void:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await create_timer(1.5).timeout
	game._start_run()
	game.score = 6
	game.trigger_game_over()
	await create_timer(1.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/revive.png" % out_dir)
	print("saved revive")
	game.queue_free()
	await process_frame


func _shot_shop_tab(kind: String) -> void:
	var inst: Node = load("res://scenes/skin_select.tscn").instantiate()
	root.add_child(inst)
	await process_frame
	inst._switch_tab(kind)
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/shop_%s.png" % [out_dir, kind])
	print("saved shop_", kind)
	inst.queue_free()
	await process_frame


func _shot_zone(zone: int, name: String) -> void:
	var game: Node = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_run()
	var score: int = Constants.ZONE_MIN_SCORES[zone]
	game.score = score - 1
	game._ocean._apply_zone(zone, false)
	game._ocean._zone = zone
	game._invulnerable = 99.0
	game._fish.inflate()
	for i in 50:
		await physics_frame
	game._fish.deflate()
	game._fish.shield = zone == 3
	game._magnet_left = 5.0 if zone == 3 else 0.0
	await create_timer(1.2).timeout
	game.score = score
	game._add_point(game._obstacles[0])
	await create_timer(2.2).timeout
	game.set_physics_process(false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("saved ", name)
	game.queue_free()
	await process_frame


func _shot_overlay(scene: String, panel_class: String, name: String) -> void:
	var inst: Node = load("res://scenes/%s.tscn" % scene).instantiate()
	root.add_child(inst)
	await process_frame
	for c in inst.get_children():
		if c.get_script() and c.get_script().get_global_name() in ["DailyRewardPanel", "ChallengePanel"]:
			c.queue_free()
	var p = load("res://scripts/%s.gd" % ("daily_reward_panel" if panel_class == "DailyRewardPanel" else "challenge_panel")).new()
	inst.add_child(p)
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("saved ", name)
	inst.queue_free()
	await process_frame


func _shot_splash(at: float, name: String) -> void:
	var menu: Node = load("res://scenes/menu.tscn").instantiate()
	root.add_child(menu)
	var seq = load("res://scripts/splash_sequence.gd").new()
	menu.add_child(seq)
	await create_timer(at).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("saved ", name)
	menu.queue_free()
	await process_frame
