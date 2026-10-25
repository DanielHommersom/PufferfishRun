extends SceneTree
## Headless checks: `godot --headless --path godot -s res://tests/run_tests.gd`
## Covers the US-07 difficulty table, US-04 physics scenarios, US-02 save rules, US-08 collision
## math, US-19 medals, and that every scene instantiates without script errors.

var _failures := 0


func _initialize() -> void:
	await process_frame # let the autoloads finish _ready()
	_test_difficulty()
	_test_fish_physics()
	_test_collision()
	_test_medals_and_enemies()
	_test_skins()
	await _test_save_manager()
	await _test_scenes()
	await _test_flow()
	_test_ad_rules()
	await _test_shop()
	await _test_revive()
	await _test_new_features()
	print("\n%s — %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(1 if _failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_failures += 1
		printerr("  FAIL ", what)


func approx(a: float, b: float, eps := 0.01) -> bool:
	return absf(a - b) <= eps


func _test_difficulty() -> void:
	print("US-07 difficulty")
	check(approx(Difficulty.gap_size(0), 230) and approx(Difficulty.speed(0), 2.5) and approx(Difficulty.spawn_interval(0), 2.5), "score 0 → 230 / 2.5 / 2.5")
	check(approx(Difficulty.gap_size(20), 175) and approx(Difficulty.speed(20), 3.7) and approx(Difficulty.spawn_interval(20), 1.93, 0.01), "score 20 → 175 / 3.7 / 1.93")
	check(approx(Difficulty.gap_size(40), 120) and approx(Difficulty.speed(40), 4.0) and approx(Difficulty.spawn_interval(40), 1.5), "score 40 → 120 / 4.0 / 1.5")
	check(approx(Difficulty.gap_size(999), 120) and approx(Difficulty.spawn_interval(999), 1.5), "score ≥ 40 stays clamped")


func _test_fish_physics() -> void:
	print("US-04 fish physics")
	# Loaded at runtime: compiling it together with this script would happen before autoloads exist.
	var fish: Node2D = load("res://scripts/pufferfish.gd").new()
	fish.skin = SkinLibrary.get_all()[0]
	fish.position = Vector2(98, 426)
	var ticks := 0
	while fish.position.y + fish.get_radius() <= 852 and ticks < 1000:
		fish.step()
		ticks += 1
	check(ticks >= 85 and ticks <= 100, "falls to the bottom in ~93 ticks (got %d)" % ticks)
	fish.position = Vector2(98, 10000)
	fish.vel_up = 0
	fish.inflate()
	for i in 120:
		fish.step()
	check(approx(fish.vel_up, 5.0), "holding reaches max 5 px/tick upward")
	check(approx(fish.get_radius(), 29.9), "max radius 29.9")
	fish.free()


func _test_collision() -> void:
	print("US-08 collision")
	var r := Rect2(100, 0, 80, 300)
	check(Difficulty.circle_hits_rect(Vector2(90, 150), 18, r), "circle overlapping rect edge hits")
	check(not Difficulty.circle_hits_rect(Vector2(80, 150), 18, r), "circle 20 px away misses")
	check(not Difficulty.circle_hits_rect(Vector2(82, 150), 18, r), "exactly touching does not hit (strict <)")


func _test_medals_and_enemies() -> void:
	print("US-09 / US-19")
	check(Difficulty.medal(9).is_empty() and Difficulty.medal(10).label == "BRONZE" and Difficulty.medal(20).label == "SILVER" and Difficulty.medal(40).label == "GOLD", "medal thresholds 10/20/40")
	check(Difficulty.available_enemies(4).is_empty(), "no enemies below 5")
	check(Difficulty.available_enemies(15).size() == 2 and Difficulty.available_enemies(25).size() == 3, "shark from 15, urchin from 25")


func _test_skins() -> void:
	print("US-18 skins")
	var all := SkinLibrary.get_all()
	check(all.size() == 12, "12 skins loaded from data/skins.tres (6 earnable + 6 shop-only)")
	check(SkinLibrary.get_by_id("royal").is_shop_only() and not SkinLibrary.get_by_id("royal").is_unlocked(9999), "shop-only skins can't be earned by score")
	check(all[5].id == "shadow" and all[5].unlock_score == 75, "shadow unlocks at 75")
	check(SkinLibrary.get_by_id("nope").id == "default", "unknown id falls back to default")


func _test_save_manager() -> void:
	print("US-02 save manager")
	var sm = root.get_node("SaveManager")
	var prev_best: int = sm.high_score
	var prev_skin: String = sm.selected_skin
	sm.high_score = 10
	check(not sm.submit_score(10), "equal score is not a new record (B2)")
	check(sm.submit_score(11) and sm.high_score == 11, "higher score is a new record and is stored")
	sm.high_score = 0
	check(not sm.submit_score(0), "score 0 is never a new record (B2)")
	sm.selected_skin = "does-not-exist"
	check(sm.selected_skin == "default", "unknown skin falls back to default")
	sm.flush()
	var cfg := ConfigFile.new()
	cfg.load(sm.TEST_SAVE_PATH)
	check(cfg.has_section_key("progress", "highScore") and cfg.has_section_key("settings", "isMuted"), "written to user://save.cfg with Swift key names")
	sm.high_score = prev_best
	sm.selected_skin = prev_skin
	await process_frame


func _test_scenes() -> void:
	print("Scenes instantiate")
	for key in ["menu", "skin_select", "settings", "missions", "game", "game_over"]:
		var packed: PackedScene = load("res://scenes/%s.tscn" % key)
		var inst := packed.instantiate()
		root.add_child(inst)
		for i in 5:
			await physics_frame
		var ok := is_instance_valid(inst)
		if key == "game":
			ok = ok and inst.get("_fish") != null and inst.get("_waiting") and inst.get("_obstacles").is_empty()
		check(ok, key)
		inst.queue_free()
		await process_frame


func _test_flow() -> void:
	print("US-03 / US-14 scene flow")
	var router = root.get_node("SceneRouter")
	router.go_to("menu", 0)
	await create_timer(0.2).timeout
	check(current_scene and current_scene.name == "Menu", "menu loaded")
	router.go_to("skin_select", router.Transition.MOVE_IN_UP, 0.3)
	router.go_to("game", router.Transition.FADE, 0.3) # ignored: transition in progress
	await create_timer(0.5).timeout
	check(current_scene.name == "SkinSelect" and root.get_child_count() > 0 and not root.has_node("Menu"), "move-in replaced menu, double tap ignored")
	router.go_to("game", router.Transition.FADE, 0.3)
	await create_timer(0.5).timeout
	check(current_scene.name == "Game", "fade to game")
	await create_timer(0.5).timeout
	check(current_scene._waiting and current_scene._obstacles.is_empty(), "GET READY: nothing moves before the first tap")
	current_scene._start_run()
	# Do nothing: the fish falls and dies at the bottom, then GameOver opens with the score.
	await create_timer(3.0).timeout
	check(current_scene.name == "GameOver" and current_scene.get("final_score") == 0, "death → game over with score param")


func _test_ad_rules() -> void:
	print("Monetisation 3: interstitial rules")
	var ad = load("res://scripts/ad_manager.gd")
	var sm = root.get_node("SaveManager")
	var prev_removed: bool = sm.ads_removed
	sm.ads_removed = false
	check(not ad.should_show_interstitial(3, 3, INF, false, false), "no ads during grace period")
	check(ad.should_show_interstitial(10, 3, INF, false, false), "every 3rd game after grace")
	check(not ad.should_show_interstitial(10, 2, INF, false, false), "not before the 3rd game")
	check(not ad.should_show_interstitial(10, 3, 30.0, false, false), "min interval between ads")
	check(not ad.should_show_interstitial(10, 3, INF, true, false), "never after a new best")
	check(not ad.should_show_interstitial(10, 3, INF, false, true), "never after a rewarded video")
	sm.ads_removed = true
	check(not ad.should_show_interstitial(10, 3, INF, false, false), "Remove Ads disables interstitials")
	sm.ads_removed = prev_removed


func _test_shop() -> void:
	print("Monetisation 5: coins & shop")
	var sm = root.get_node("SaveManager")
	var prev_coins: int = sm.coins
	var prev_owned: PackedStringArray = sm.owned_skins.duplicate()
	var prev_best: int = sm.high_score
	sm.high_score = 0
	sm.owned_skins = PackedStringArray()
	var ghost: SkinDefinition = SkinLibrary.get_by_id("ghost")
	sm.coins = ghost.price - 1
	check(not sm.buy_skin(ghost), "can't buy with too few coins")
	sm.add_coins(1)
	check(sm.buy_skin(ghost) and sm.coins == 0 and sm.is_skin_unlocked(ghost), "buying spends coins and unlocks")
	check(not sm.buy_skin(ghost), "can't buy twice")
	check(not sm.buy_skin(SkinLibrary.get_by_id("default")), "free skin can't be bought")
	sm.coins = Cosmetics.price_of("hat", "crown")
	check(sm.buy_item("hat", "crown") and sm.owns_item("hat", "crown") and sm.coins == 0, "buying a hat")
	sm.equip_item("hat", "crown")
	check(sm.selected_hat == "crown", "equipping a hat")
	sm.equip_item("trail", "stars")
	check(sm.selected_trail != "stars", "can't equip an unowned trail")
	sm.free_coins_date = ""
	var claimed := 0
	while sm.claim_free_coins():
		claimed += 1
	check(claimed == Constants.FREE_COINS_PER_DAY and sm.coins == claimed * Constants.FREE_COINS_AMOUNT, "free coins limited per day")
	var prev_items: PackedStringArray = sm.owned_items.duplicate()
	sm.owned_items = PackedStringArray()
	sm.selected_hat = "none"
	sm.coins = prev_coins
	sm.owned_skins = prev_owned
	sm.owned_items = prev_items
	sm.high_score = prev_best
	await process_frame


func _test_revive() -> void:
	print("Monetisation 2: revive")
	var router = root.get_node("SceneRouter")
	router.go_to("game", 0)
	await create_timer(0.3).timeout
	var game = current_scene
	game._start_run()
	game.score = 5
	game.trigger_game_over()
	await create_timer(1.2).timeout
	var panel = game.get("_revive_panel")
	check(panel != null and is_instance_valid(panel), "continue offer appears at score ≥ 2 (debug: simulated ad)")
	panel.watch_pressed.emit()
	await create_timer(1.5).timeout
	check(current_scene == game and not game.game_over and game.score == 5, "watching the ad revives with score kept")
	check(game.get("_invulnerable") > 0.0, "fish protected right after revive")
	game.trigger_game_over()
	await create_timer(1.6).timeout
	check(current_scene.name == "GameOver", "second death goes straight to game over (one revive per run)")


func _test_new_features() -> void:
	print("Onboarding / near miss / power-ups / zones / daily / i18n / settings")
	var sm = root.get_node("SaveManager")
	var D = load("res://scripts/daily.gd") # loaded at runtime (needs the SaveManager autoload)
	# Zones
	var ocean = load("res://scripts/ocean_background.gd").new()
	root.add_child(ocean)
	await process_frame
	check(ocean.zone_for_score(9) == 0 and ocean.zone_for_score(10) == 1 and ocean.zone_for_score(70) == 5, "six zones at 0/10/20/35/50/70")
	ocean.queue_free()
	# Daily reward streak
	sm.daily_last_claim = ""
	sm.daily_streak = 0
	check(D.reward_available() and D.streak_day() == 1, "day 1 reward available")
	var c0: int = sm.coins
	check(D.claim_reward() == Constants.DAILY_REWARDS[0] and sm.coins == c0 + Constants.DAILY_REWARDS[0], "claim gives day-1 coins")
	check(not D.reward_available() and D.claim_reward() == 0, "only once per day")
	sm.daily_last_claim = str(D.day_index(-1))
	check(D.streak_day() == 2, "streak continues the next day")
	sm.daily_last_claim = str(D.day_index(-3))
	check(D.streak_day() == 1, "streak resets after a missed day")
	# Missions
	sm.missions_date = ""
	D.ensure_missions()
	check(sm.missions.size() == 3, "three missions per day")
	var m: Dictionary = sm.missions[0]
	var done: Array = D.report(m.type, m.target, m.type in ["score", "zone"])
	check(done.size() >= 1 and D.claimable_count() >= 1, "mission completes on progress")
	var before: int = sm.coins
	check(D.claim_mission(0) == m.reward and sm.coins == before + m.reward and D.claim_mission(0) == 0, "mission claim once")
	# Challenge
	sm.challenge_date = ""
	check(D.report_challenge(Constants.CHALLENGE_TARGET - 1) == 0, "challenge: below target no reward")
	check(D.report_challenge(Constants.CHALLENGE_TARGET) == Constants.CHALLENGE_REWARD, "challenge: reward on target")
	check(D.report_challenge(99) == 0 and D.challenge_best() == 99, "challenge: reward once, best tracked")
	# Game: near miss + power-ups
	var router = root.get_node("SceneRouter")
	router.go_to("game", 0)
	await create_timer(0.3).timeout
	var g = current_scene
	g._start_run()
	await physics_frame
	await physics_frame
	var obs = g._obstacles[0]
	obs.min_clearance = 3.0
	var coins_before: int = g._run_coins
	g._add_point(obs)
	check(g._run_coins == coins_before + Constants.NEAR_MISS_COINS, "near miss gives a coin")
	obs.add_power_up(0)
	g._collect_power_up(obs)
	check(g._fish.shield, "shield power-up")
	check(not g._hit() and not g._fish.shield and not g.game_over, "shield absorbs one hit")
	g._invulnerable = 0.0
	obs.add_power_up(2)
	g._collect_power_up(obs)
	check(g._time_factor() < 1.0, "slow-mo power-up")
	# Challenge determinism
	router.go_to("game", 0, 0.0, {"challenge": true})
	await create_timer(0.3).timeout
	current_scene._start_run()
	await physics_frame
	await physics_frame
	var y1: float = current_scene._obstacles[0].gap_y
	router.go_to("game", 0, 0.0, {"challenge": true})
	await create_timer(0.3).timeout
	current_scene._start_run()
	await physics_frame
	await physics_frame
	check(is_equal_approx(current_scene._obstacles[0].gap_y, y1), "challenge coral is the same every attempt")
	# i18n + settings
	sm.language = "nl"
	check(TranslationServer.translate("PLAY AGAIN") == "OPNIEUW", "Dutch translation active")
	sm.language = "ja"
	check(TranslationServer.translate("SETTINGS") == "設定", "Japanese translation active")
	sm.language = "auto"
	sm.vibration = false
	sm.screen_shake = false
	sm.flush()
	var cfg := ConfigFile.new()
	cfg.load(sm.TEST_SAVE_PATH)
	check(cfg.get_value("settings", "vibration") == false and cfg.get_value("settings", "screenShake") == false, "toggles are saved")
