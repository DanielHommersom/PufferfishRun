extends Node2D
## Gameplay scene (US-04, 06, 07, 08, 09, 13, 14). Ported from GameScene.swift and extended with
## onboarding (GET READY), near misses, power-ups, six depth zones, missions and the daily challenge.
## Gameplay advances per physics tick (60 Hz), like the per-frame Swift update.

const TICK := 1.0 / 60.0
const MOUSE_TOUCH_ID := -100

var score := 0
var game_over := false
var is_challenge := false

var _size: Vector2
var _rng := RandomNumberGenerator.new()
var _modifier := ""
var _ocean: OceanBackground
var _fish: PufferFish
var _obstacles: Array[Obstacle] = []
var _enemies: Array[Enemy] = []
var _obstacle_layer: Node2D
var _enemy_layer: Node2D
var _score_label: Label
var _depth_label: Label
var _sound_button: SoundButton
var _spawn_timer := INF # INF: first pillar spawns on the very first tick (Swift lastSpawnTime = 0)
var _enemy_timer := INF
var _touches := {}
var _fx: FxLayer
var _shake := 0.0
var _trail_tick := 0
var _score_pop: Tween
var _coin_counter: CoinCounter
var _run_coins := 0
var _revive_used := false
var _watched_rewarded := false
var _invulnerable := 0.0
var _revive_panel: RevivePanel

# Onboarding
var _waiting := true
var _tutorial: TutorialOverlay
var _wait_time := 0.0
var _pillars_spawned := 0

# Power-ups
var _magnet_left := 0.0
var _slow_left := 0.0
var _hud: PowerUpHud
var _start_shield_bought := false

# Abyss
var _darkness: ColorRect
var _darkness_mat: ShaderMaterial
var _darkness_strength := 0.0


func _ready() -> void:
	# Gameplay runs at 60 ticks; on 120 Hz screens the world (fish, pillars, enemies, parallax)
	# is drawn interpolated between ticks. UI and effects animate per frame, so they opt out.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_size = get_viewport_rect().size
	is_challenge = bool(SceneRouter.params.get("challenge", false))
	if is_challenge:
		_rng.seed = Daily.challenge_seed()
		_modifier = Daily.challenge_modifier()
	else:
		_rng.randomize()

	_ocean = OceanBackground.new()
	_ocean.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child(_ocean)

	_obstacle_layer = Node2D.new()
	_obstacle_layer.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child(_obstacle_layer)
	_enemy_layer = Node2D.new()
	_enemy_layer.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child(_enemy_layer)

	_fx = FxLayer.new()
	_fx.z_index = 6
	add_child(_fx)

	_fish = PufferFish.new()
	_fish.position = _size * Constants.FISH_START
	_fish.z_index = 5
	_fish.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child(_fish)

	_setup_darkness()

	_score_label = Label.new()
	_score_label.text = "0"
	_score_label.add_theme_font_size_override("font_size", 36)
	_score_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_score_label.add_theme_constant_override("outline_size", 8)
	_score_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	_score_label.add_theme_constant_override("shadow_offset_y", 4)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_label.size = Vector2(_size.x, 50)
	var baseline := maxf(80.0, DrawUtil.safe_insets(get_viewport()).top + 40.0)
	_score_label.position = Vector2(0, baseline - DrawUtil.font().get_ascent(36))
	_score_label.z_index = 10
	_score_label.pivot_offset = Vector2(_size.x / 2.0, 25)
	add_child(_score_label)

	_depth_label = UiUtil.label(self, "0 m", 11, Color(1, 1, 1, 0.6), _size.x / 2.0, baseline + 22, true)
	_depth_label.z_index = 10

	_hud = PowerUpHud.new()
	_hud.position = Vector2(_size.x / 2.0, baseline + 48)
	_hud.z_index = 10
	add_child(_hud)

	_coin_counter = CoinCounter.new()
	_coin_counter.position = Vector2(18, baseline - 12)
	_coin_counter.z_index = 10
	add_child(_coin_counter)

	if is_challenge:
		var cl := UiUtil.label(self, tr("CHALLENGE: %s") % tr(_modifier), 11, Constants.UI_ORANGE, _size.x / 2.0, baseline - 46, true)
		cl.z_index = 10

	SoundManager.start_ambience()

	_sound_button = SoundButton.create()
	add_child(_sound_button)
	_sound_button.place_default(get_viewport())

	_tutorial = TutorialOverlay.new()
	_tutorial.shield_requested.connect(_on_start_shield)
	add_child(_tutorial)


# ── Main loop ─────────────────────────────────────────

func _physics_process(_delta: float) -> void:
	if _waiting:
		_wait_time += TICK
		_fish.position.y = _size.y * Constants.FISH_START.y + sin(_wait_time * 3.0) * 8.0
		_fish.queue_redraw()
		return
	if game_over or SceneRouter.is_transitioning:
		return

	var f := _time_factor()
	_fish.step()
	var protected := _invulnerable > 0.0
	if protected:
		_invulnerable -= TICK
		_fish.modulate.a = 0.45 if int(_invulnerable * 10.0) % 2 == 0 else 1.0
		if _invulnerable <= 0.0:
			_fish.modulate.a = 1.0
	_tick_power_ups()

	# 1. Screen edges (while protected the fish is kept on screen instead)
	var r := _fish.get_radius()
	if _fish.position.y - r < 0.0 or _fish.position.y + r > _size.y:
		if not protected and not _fish.shield:
			trigger_game_over()
			return
		if _fish.shield and not protected:
			_break_shield()
		_fish.position.y = clampf(_fish.position.y, r, _size.y - r)
		_fish.vel_up = 0.0

	# 2. Pillars: spawn, move, score, collide, despawn
	_spawn_timer += TICK * f
	if _spawn_timer > Difficulty.spawn_interval(score):
		_spawn_obstacle()
		_spawn_timer = 0.0

	var speed := _speed() * f
	_ocean.scroll(speed)
	_emit_trail()
	for i in range(_obstacles.size() - 1, -1, -1):
		var obs := _obstacles[i]
		obs.position.x -= speed
		obs.step()
		_track_near_miss(obs, r)
		if not obs.passed and obs.position.x + Constants.OBSTACLE_WIDTH < _fish.position.x:
			obs.passed = true
			_add_point(obs)
		_update_pickups(obs, r)
		var hit := Difficulty.circle_hits_rect(_fish.position, r, obs.top_rect()) \
				or Difficulty.circle_hits_rect(_fish.position, r, obs.bottom_rect())
		if hit and _hit():
			return
		if obs.position.x < Constants.OBSTACLE_DESPAWN_X:
			obs.queue_free()
			_obstacles.remove_at(i)

	# 3. Enemies
	_enemy_timer += TICK * f
	if _enemy_timer > Constants.ENEMY_SPAWN_INTERVAL:
		_enemy_timer = 0.0
		_maybe_spawn_enemy()

	for i in range(_enemies.size() - 1, -1, -1):
		var enemy := _enemies[i]
		enemy.step(f)
		var min_dist := _fish.get_radius() + enemy.get_radius() - Constants.ENEMY_COLLISION_MARGIN
		if _fish.position.distance_to(enemy.position) < min_dist and _hit():
			return
		if enemy.is_dead:
			enemy.queue_free()
			_enemies.remove_at(i)


## Handles a lethal contact. Returns true when the run ends (no protection left).
func _hit() -> bool:
	if _invulnerable > 0.0:
		return false
	if _fish.shield:
		_break_shield()
		return false
	trigger_game_over()
	return true


func _process(delta: float) -> void:
	# Screen shake moves the whole canvas (not a node), so it doesn't fight interpolation.
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 30.0)
		get_viewport().canvas_transform = Transform2D(0.0, Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake)
	elif get_viewport().canvas_transform.origin != Vector2.ZERO:
		get_viewport().canvas_transform = Transform2D.IDENTITY
	_update_darkness(delta)


func _exit_tree() -> void:
	get_viewport().canvas_transform = Transform2D.IDENTITY


func _speed() -> float:
	var s := Difficulty.speed(score)
	if _modifier == "FAST CURRENT":
		s *= 1.25
	return s


func _time_factor() -> float:
	return Constants.SLOW_FACTOR if _slow_left > 0.0 else 1.0


# ── Input ─────────────────────────────────────────────
# Gameplay input arrives via _unhandled_input, so taps on buttons (Controls that accept the
# event) never inflate the fish. Raw ScreenTouch events bypass the GUI, hence the explicit rect
# checks too. Emulated mouse events from touches are ignored to avoid doubles.

func _unhandled_input(event: InputEvent) -> void:
	if Debug.handle_key(event):
		_refresh_debug_draw()
		return
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.pressed, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and event.device != InputEvent.DEVICE_ID_EMULATION:
		_handle_touch(MOUSE_TOUCH_ID, event.pressed, event.position)


func _over_ui(pos: Vector2) -> bool:
	if _sound_button.get_global_rect().has_point(pos):
		return true
	if _tutorial and is_instance_valid(_tutorial):
		for c in _tutorial.get_children():
			if c is Control and c.mouse_filter == Control.MOUSE_FILTER_STOP and c.get_global_rect().has_point(pos):
				return true
	return false


func _handle_touch(id: int, pressed: bool, pos: Vector2) -> void:
	if game_over or SceneRouter.is_transitioning:
		return
	if pressed:
		if _touches.has(id) or _over_ui(pos):
			return
		if _waiting:
			_start_run()
		var was_idle := _touches.is_empty()
		_touches[id] = true
		if was_idle:
			_fish.inflate()
			_puff()
			Haptics.light()
			SoundManager.play_inflate() # once per press, not repeated while holding
	elif _touches.erase(id) and _touches.is_empty():
		_fish.deflate()
		SoundManager.play_release()


## First tap: leave the GET READY state.
func _start_run() -> void:
	_waiting = false
	_fish.vel_up = 0.0
	if _tutorial:
		_tutorial.dismiss()
		_tutorial = null


func _on_start_shield() -> void:
	if _start_shield_bought or not _waiting:
		return
	if SaveManager.coins >= Constants.START_SHIELD_PRICE:
		SaveManager.coins -= Constants.START_SHIELD_PRICE
		_grant_start_shield()
	else:
		AdManager.show_rewarded(func(earned: bool):
			if earned:
				_watched_rewarded = true
				_grant_start_shield())


func _grant_start_shield() -> void:
	_start_shield_bought = true
	_fish.shield = true
	SoundManager.play_revive()
	_fx.sparkle(_fish.position, 12, PowerUp.COLORS[PowerUp.Type.SHIELD])
	if _tutorial:
		_tutorial.hide_shield_button()


# ── Spawning ──────────────────────────────────────────

func _spawn_obstacle() -> void:
	var gap := Difficulty.gap_size(score)
	if _modifier == "NARROW GAPS":
		gap = maxf(110.0, gap - 25.0)
	if not is_challenge and SaveManager.games_played < Constants.TUTORIAL_GAMES and _pillars_spawned < Constants.TUTORIAL_GAP_BONUS.size():
		gap += Constants.TUTORIAL_GAP_BONUS[_pillars_spawned] # onboarding: easy first pillars
	_pillars_spawned += 1
	var margin := gap * Constants.GAP_MARGIN_FACTOR
	var lo := gap / 2.0 + margin
	var hi := _size.y - gap / 2.0 - margin
	var gap_y := _rng.randf_range(minf(lo, hi), maxf(lo, hi))
	var move_speed := 0.0
	var move_range := 0.0
	if _modifier == "MOVING CORAL" and _rng.randf() < 0.5:
		move_speed = 1.6
		move_range = Constants.MOVING_OBSTACLE_RANGE
	elif Constants.MOVING_OBSTACLES_ENABLED and _rng.randf() < Difficulty.moving_obstacle_chance(score):
		move_speed = Difficulty.moving_obstacle_speed(score)
		move_range = Constants.MOVING_OBSTACLE_RANGE
	var obs := Obstacle.new()
	obs.setup(gap_y, gap, _size.y, move_speed, move_range)
	obs.position = Vector2(_size.x + Constants.OBSTACLE_SPAWN_OFFSET, 0)
	if score >= Constants.POWERUP_MIN_SCORE and _rng.randf() < Constants.POWERUP_CHANCE:
		obs.add_power_up(_rng.randi_range(0, 2) as PowerUp.Type)
	elif _modifier == "COIN RUSH" or _rng.randf() < Constants.COIN_CHANCE:
		obs.add_coin()
	_obstacle_layer.add_child(obs)
	obs.reset_physics_interpolation()
	_obstacles.append(obs)


func _maybe_spawn_enemy() -> void:
	if game_over:
		return
	var available := Difficulty.available_enemies(score)
	var chance := Constants.ENEMY_SPAWN_CHANCE
	match _modifier:
		"JELLY SWARM":
			if not available.has(Enemy.Type.JELLYFISH):
				available.append(Enemy.Type.JELLYFISH)
			chance = 0.8
		"SHARK ALLEY":
			if score >= 5 and not available.has(Enemy.Type.SHARK):
				available.append(Enemy.Type.SHARK)
	if OS.is_debug_build() and Debug.forced_enemy >= 0:
		available.clear()
		available.append(Debug.forced_enemy)
	elif _rng.randf() >= chance:
		return
	if available.is_empty():
		return
	var enemy := Enemy.create(available[_rng.randi_range(0, available.size() - 1)], _size)
	_enemy_layer.add_child(enemy)
	enemy.reset_physics_interpolation()
	_enemies.append(enemy)


# ── Scoring, near misses, pickups ─────────────────────

func _add_point(obs: Obstacle) -> void:
	score += 1
	_score_label.text = str(score)
	_depth_label.text = "%d m" % (score * Constants.DEPTH_PER_POINT)
	SoundManager.play_score(score)
	Haptics.light()
	_report("pillars", 1)
	if _ocean.update_score(score):
		var zone := _ocean.current_zone()
		SoundManager.play_zone()
		UiUtil.banner(self, "~ %s ~" % tr(Constants.ZONE_NAMES[zone]), _size.y * 0.3)
		_report("zone", zone, true)
	if _score_pop:
		_score_pop.kill()
	_score_label.scale = Vector2(1.35, 1.35)
	_score_pop = create_tween()
	_score_pop.tween_property(_score_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fx.sparkle(_fish.position + Vector2(0, -_fish.get_radius() - 6), 8, Constants.UI_GOLD_TEXT)
	if obs.min_clearance < Constants.NEAR_MISS_DISTANCE:
		_near_miss()


## Closest distance between the fish's edge and the pillar while they overlap horizontally.
func _track_near_miss(obs: Obstacle, r: float) -> void:
	if obs.passed:
		return
	var fx := _fish.position.x
	if fx + r < obs.position.x or fx - r > obs.position.x + Constants.OBSTACLE_WIDTH:
		return
	var d := minf(_rect_distance(_fish.position, obs.top_rect()), _rect_distance(_fish.position, obs.bottom_rect())) - r
	obs.min_clearance = minf(obs.min_clearance, d)


static func _rect_distance(p: Vector2, rect: Rect2) -> float:
	var near := Vector2(clampf(p.x, rect.position.x, rect.end.x), clampf(p.y, rect.position.y, rect.end.y))
	return p.distance_to(near)


func _near_miss() -> void:
	_run_coins += Constants.NEAR_MISS_COINS
	SaveManager.add_coins(Constants.NEAR_MISS_COINS)
	_coin_counter.value = _run_coins
	_coin_counter.pop()
	SoundManager.play_coin()
	Haptics.medium()
	UiUtil.float_text(self, tr("CLOSE!") + " +%d" % Constants.NEAR_MISS_COINS, _fish.position + Vector2(0, -_fish.get_radius() - 24), Constants.UI_ORANGE, 18)
	_report("near", 1)


func _update_pickups(obs: Obstacle, r: float) -> void:
	if obs.coin and not obs.coin.collected:
		var world := obs.position + obs.coin.position
		if _magnet_left > 0.0 and world.distance_to(_fish.position) < Constants.MAGNET_RADIUS:
			obs.coin.position += (_fish.position - world).normalized() * 9.0
			world = obs.position + obs.coin.position
		if _fish.position.distance_to(world) < r + Constants.COIN_RADIUS:
			_collect_coin(obs)
	if obs.power_up and not obs.power_up.collected:
		if _fish.position.distance_to(obs.position + obs.power_up.position) < r + Constants.POWERUP_RADIUS:
			_collect_power_up(obs)


func _collect_coin(obs: Obstacle) -> void:
	obs.coin.collected = true
	var world := obs.position + obs.coin.position
	obs.coin.queue_free()
	obs.coin = null
	_run_coins += 1
	SaveManager.add_coins(1) # saved immediately, never lost if the app is killed
	_coin_counter.value = _run_coins
	_coin_counter.pop()
	SoundManager.play_coin()
	Haptics.light()
	_fx.sparkle(world, 10, Color(1.0, 0.8, 0.2))
	_report("coins", 1)


func _collect_power_up(obs: Obstacle) -> void:
	var p := obs.power_up
	p.collected = true
	var world := obs.position + p.position
	match p.type:
		PowerUp.Type.SHIELD:
			_fish.shield = true
		PowerUp.Type.MAGNET:
			_magnet_left = Constants.MAGNET_TIME
		PowerUp.Type.SLOW:
			_slow_left = Constants.SLOW_TIME
	p.queue_free()
	obs.power_up = null
	SoundManager.play_revive()
	Haptics.medium()
	_fx.sparkle(world, 14, PowerUp.COLORS[p.type])
	UiUtil.float_text(self, tr(PowerUp.type_name(p.type)) + "!", world + Vector2(0, -24), PowerUp.COLORS[p.type], 16)
	_report("powerups", 1)


func _tick_power_ups() -> void:
	_magnet_left = maxf(0.0, _magnet_left - TICK)
	_slow_left = maxf(0.0, _slow_left - TICK)
	var items: Array = []
	if _fish.shield:
		items.append({"type": PowerUp.Type.SHIELD, "frac": 1.0})
	if _magnet_left > 0.0:
		items.append({"type": PowerUp.Type.MAGNET, "frac": _magnet_left / Constants.MAGNET_TIME})
	if _slow_left > 0.0:
		items.append({"type": PowerUp.Type.SLOW, "frac": _slow_left / Constants.SLOW_TIME})
	_hud.set_items(items)


func _break_shield() -> void:
	_fish.shield = false
	_invulnerable = Constants.SHIELD_SAVE_INVULNERABLE
	var colors: Array[Color] = [Color(0.55, 0.9, 1.0), Color.WHITE]
	_fx.shards(_fish.position, 10, colors)
	SoundManager.play_release()
	Haptics.heavy()
	_add_shake(5.0)


func _add_shake(amount: float) -> void:
	if SaveManager.screen_shake:
		_shake = maxf(_shake, amount)


# ── Missions ──────────────────────────────────────────

func _report(type: String, value: int, as_max := false) -> void:
	for m in Daily.report(type, value, as_max):
		UiUtil.banner(self, tr("MISSION COMPLETE!"), _size.y * 0.22, Constants.UI_GREEN)
		SoundManager.play_confirm()


# ── Visual helpers ────────────────────────────────────

## Trail behind the fish (visual only). Default: small bubbles from the mouth while puffed up;
## bought trails (rainbow, gold, hearts, stars) stream continuously.
func _emit_trail() -> void:
	_trail_tick += 1
	var trail := SaveManager.selected_trail
	var r := _fish.get_radius()
	if trail == "bubbles":
		if _fish.is_inflating and _trail_tick % 7 == 0:
			_fx.bubble(_fish.position + Vector2(r * 1.05, r * 0.15), Vector2(randf_range(-40, -10), randf_range(-30, 0)), randf_range(2, 4), 1.2)
	elif _trail_tick % 5 == 0:
		Cosmetics.emit_trail(_fx, trail, _fish.position, r, _trail_tick / 60.0)


## Burst of bubbles when a press starts.
func _puff() -> void:
	var r := _fish.get_radius()
	for i in 4:
		_fx.bubble(_fish.position + Vector2(-r * 1.2, randf_range(-r, r) * 0.5), Vector2(randf_range(-90, -40), randf_range(-40, 40)), randf_range(2, 5), 0.9)


func _setup_darkness() -> void:
	_darkness_mat = ShaderMaterial.new()
	_darkness_mat.shader = preload("res://shaders/darkness.gdshader")
	_darkness_mat.set_shader_parameter("rect_size", _size)
	_darkness_mat.set_shader_parameter("light_radius", Constants.ABYSS_LIGHT_RADIUS)
	_darkness = ColorRect.new()
	_darkness.size = _size
	_darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_darkness.material = _darkness_mat
	_darkness.z_index = 7
	_darkness.visible = false
	add_child(_darkness)


func _update_darkness(delta: float) -> void:
	var target := Constants.ABYSS_DARKNESS if Constants.ZONE_DECOR[_ocean.current_zone()] == "abyss" else 0.0
	_darkness_strength = move_toward(_darkness_strength, target, delta / Constants.ZONE_TWEEN_TIME)
	_darkness.visible = _darkness_strength > 0.001
	if _darkness.visible:
		_darkness_mat.set_shader_parameter("strength", _darkness_strength)
		_darkness_mat.set_shader_parameter("light_pos", _fish.position)


func _refresh_debug_draw() -> void:
	_fish.queue_redraw()
	for o in _obstacles:
		o.queue_redraw()
	for e in _enemies:
		e.queue_redraw()


# ── Game over (US-14) ─────────────────────────────────

func trigger_game_over() -> void:
	if game_over:
		return
	game_over = true
	SoundManager.play_game_over()
	Haptics.heavy()

	_fish.deflate()
	_fish.shield = false
	_touches.clear()
	for e in _enemies:
		e.queue_free()
	_enemies.clear()
	_magnet_left = 0.0
	_slow_left = 0.0
	_hud.set_items([])

	_add_shake(10.0)
	var skin := _fish.skin
	var colors: Array[Color] = [skin.body, skin.spine, skin.tail]
	_fx.shards(_fish.position, 14, colors)

	var t := create_tween().set_parallel().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	t.tween_property(_fish, "scale", Vector2.ZERO, Constants.DEATH_ANIM_TIME)
	t.tween_property(_fish, "modulate:a", 0.0, Constants.DEATH_ANIM_TIME)

	for i in 8:
		var b := Circle2D.new()
		b.radius = randf_range(4, 10)
		b.color = Color(0.533, 0.867, 1.0, 0.7)
		b.position = _fish.position
		b.z_index = 6
		add_child(b)
		var target := b.position + Vector2(randf_range(-50, 50), -randf_range(20, 80))
		var bt := create_tween().set_parallel()
		bt.tween_property(b, "position", target, 0.6)
		bt.tween_property(b, "modulate:a", 0.0, 0.6)
		bt.chain().tween_callback(b.queue_free)

	await get_tree().create_timer(Constants.DEATH_DELAY).timeout
	if _can_offer_revive():
		_offer_revive()
	else:
		_finish_run()


func _finish_run() -> void:
	_report("games", 1)
	_report("score", score, true)
	var challenge_reward := 0
	if is_challenge:
		challenge_reward = Daily.report_challenge(score)
	SceneRouter.go_to("game_over", SceneRouter.Transition.FADE, 0.3, {
		"score": score, "coins": _run_coins, "watched_rewarded": _watched_rewarded,
		"challenge": is_challenge, "challenge_reward": challenge_reward,
	})


# ── Revive (monetisation) ─────────────────────────────

func _can_offer_revive() -> bool:
	return not is_challenge and not _revive_used and score >= Constants.REVIVE_MIN_SCORE and AdManager.can_show_rewarded()


func _offer_revive() -> void:
	_revive_panel = RevivePanel.new()
	add_child(_revive_panel)
	_revive_panel.declined.connect(func():
		_revive_panel.queue_free()
		_finish_run())
	_revive_panel.watch_pressed.connect(func():
		AdManager.show_rewarded(func(earned: bool):
			if earned:
				_revive_panel.queue_free()
				_revive()
			else:
				_revive_panel.queue_free()
				_finish_run()))


## Back into the run: clear the danger zone, reset the fish, brief invulnerability.
func _revive() -> void:
	_revive_used = true
	_watched_rewarded = true
	for i in range(_obstacles.size() - 1, -1, -1):
		var obs := _obstacles[i]
		if obs.position.x < _fish.position.x + Constants.REVIVE_CLEAR_AHEAD:
			obs.queue_free()
			_obstacles.remove_at(i)
	_spawn_timer = 0.0
	_enemy_timer = 0.0
	_fish.position = Vector2(_size.x * Constants.FISH_START.x, _size.y * 0.5)
	_fish.reset_physics_interpolation()
	_fish.vel_up = 0.0
	_fish.inflate_level = 0.0
	_fish.scale = Vector2.ONE
	_fish.modulate.a = 1.0
	_invulnerable = Constants.REVIVE_INVULNERABLE
	_touches.clear()
	SoundManager.play_revive()
	_fx.sparkle(_fish.position, 16, Constants.UI_GREEN)
	game_over = false
