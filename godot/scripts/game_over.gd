extends Node2D
## Game-over screen with count-up score and medals (US-19). Triggers the interstitial logic (US-23).

const PANEL_SIZE := Vector2(300, 220)
const TITLE_RED := Color(1.0, 0.267, 0.267)
const GLOW := Color(0.102, 0.416, 0.478)

var final_score := 0
var _shown_score := 0
var _score_value: Label
var run_coins := 0
var _coins_counter: CoinCounter
var _leaving := false
var _total_label: Label
var _challenge := false


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF # animated per frame
	final_score = int(SceneRouter.params.get("score", 0))
	run_coins = int(SceneRouter.params.get("coins", 0))
	_challenge = bool(SceneRouter.params.get("challenge", false))
	# Challenge runs use modifiers, so they don't count for the normal best score.
	var is_new_best := false if _challenge else SaveManager.submit_score(final_score) # B2 fix: strictly greater, never at 0
	AdManager.on_player_died(is_new_best, bool(SceneRouter.params.get("watched_rewarded", false)))

	var s := get_viewport_rect().size
	var cx := s.x / 2.0

	var ocean := OceanBackground.new()
	ocean.parallax = false
	ocean.bubble_count = 0
	ocean.start_zone = Constants.DEEP_ZONE
	add_child(ocean)
	UiUtil.color_rect(self, Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.45))
	var bubbles := BubbleField.new()
	bubbles.count = 5
	bubbles.radius_min = 5.0
	bubbles.radius_max = 12.0
	bubbles.fill_alpha = 0.10
	bubbles.start_delay_max = 3.0
	bubbles.start_below = true
	bubbles.duration_max = 7.0
	add_child(bubbles)

	# Title
	var title := UiUtil.label(self, tr("CHALLENGE") if _challenge else tr("GAME OVER"), 36, Constants.UI_ORANGE if _challenge else TITLE_RED, cx, s.y * 0.20, true)
	if _challenge:
		var reward := int(SceneRouter.params.get("challenge_reward", 0))
		var line := tr("TARGET %d REACHED! +%d") % [Constants.CHALLENGE_TARGET, reward] if reward > 0 \
				else tr("TARGET %d  ·  BEST TODAY %d") % [Constants.CHALLENGE_TARGET, Daily.challenge_best()]
		UiUtil.label(self, line, 12, Constants.UI_GREEN if reward > 0 else Constants.UI_GOLD_TEXT, cx, s.y * 0.20 + 30, true)
		if reward > 0:
			get_tree().create_timer(0.9).timeout.connect(SoundManager.play_new_best)
	title.scale = Vector2(2, 2)
	title.modulate.a = 0.0
	var tt := create_tween().set_parallel()
	tt.tween_property(title, "modulate:a", 1.0, 0.3)
	tt.tween_property(title, "scale", Vector2.ONE, 0.4)

	# Score panel (bottom edge at 54 %)
	var bottom := s.y * 0.54
	var panel_rect := Rect2(cx - PANEL_SIZE.x / 2.0, bottom - PANEL_SIZE.y, PANEL_SIZE.x, PANEL_SIZE.y)
	add_child(ScorePanel.create(panel_rect, GLOW))

	UiUtil.label(self, tr("SCORE"), 13, Constants.UI_MUTED_TEXT, cx, bottom - PANEL_SIZE.y + 36)
	_score_value = UiUtil.label(self, "0", 52, Color.WHITE, cx, bottom - PANEL_SIZE.y * 0.55, true)
	UiUtil.label(self, tr("BEST TODAY") if _challenge else tr("BEST"), 13, Constants.UI_MUTED_TEXT, cx, bottom - PANEL_SIZE.y * 0.36)
	UiUtil.label(self, str(Daily.challenge_best() if _challenge else SaveManager.high_score), 42, Constants.UI_ORANGE if is_new_best else Color.WHITE, cx, bottom - PANEL_SIZE.y * 0.12, true)
	if is_new_best:
		var nb := UiUtil.label(self, tr("NEW BEST!"), 11, Constants.UI_ORANGE, cx, bottom - PANEL_SIZE.y * 0.06)
		get_tree().create_timer(0.9).timeout.connect(SoundManager.play_new_best)
		var nt := create_tween().set_loops()
		nt.tween_property(nb, "scale", Vector2(1.15, 1.15), 0.3)
		nt.tween_property(nb, "scale", Vector2.ONE, 0.3)

	var medal := Difficulty.medal(final_score)
	if not medal.is_empty():
		var center := Vector2(panel_rect.position.x + 44, bottom - PANEL_SIZE.y * 0.30)
		var m := Medal.new()
		m.position = center
		m.color = medal.color
		m.text = tr(medal.label)
		add_child(m)

	_start_count_up()

	# Coins earned this run (+ total)
	_coins_counter = CoinCounter.new()
	_coins_counter.prefix = "+"
	_coins_counter.value = run_coins
	_coins_counter.font_size = 20
	_coins_counter.position = Vector2(cx - 34, bottom + 26)
	add_child(_coins_counter)
	_total_label = UiUtil.label(self, tr("TOTAL %d") % SaveManager.coins, 11, Constants.UI_MUTED_TEXT, cx + 60, bottom + 31)
	SaveManager.coins_changed.connect(_on_coins_changed)

	# Buttons appear after a delay and are not tappable before that.
	# A pending interstitial is shown on the tap, before leaving the screen.
	_add_button(tr("PLAY AGAIN"), Constants.UI_GREEN, s.y * 0.66, 0.9, func():
		_leave("game"))
	_add_button(tr("MAIN MENU"), Constants.UI_BLUE, s.y * 0.76, 1.1, func():
		_leave("menu"))
	if run_coins > 0 and AdManager.can_show_rewarded():
		var double := _add_button(tr("2× COINS (AD)"), Color(0.49, 0.30, 0.78), s.y * 0.86, 1.3, Callable(), Vector2(240, 52), 14)
		double.pressed.connect(func():
			double.interactive = false
			AdManager.show_rewarded(func(earned: bool):
				if not earned:
					double.interactive = true
					return
				SaveManager.add_coins(run_coins)
				_coins_counter.value = run_coins * 2
				_coins_counter.pop()
				SoundManager.play_coin()
				var t := create_tween()
				t.tween_property(double, "modulate:a", 0.0, 0.3)
				t.tween_callback(double.queue_free)))

	var sound := SoundButton.create()
	add_child(sound)
	sound.place_default(get_viewport())


func _on_coins_changed(value: int) -> void:
	_total_label.text = tr("TOTAL %d") % value


func _leave(scene: String) -> void:
	if _leaving:
		return
	_leaving = true
	var params := {"challenge": true} if scene == "game" and _challenge else {}
	AdManager.show_pending_interstitial(func(): SceneRouter.go_to(scene, SceneRouter.Transition.FADE, 0.3, params))


## +max(1, score/20) every 0.04 s, ending exactly on the final score.
func _start_count_up() -> void:
	if final_score <= 0:
		return
	var timer := Timer.new()
	timer.wait_time = 0.04
	add_child(timer)
	var inc := maxi(1, final_score / 20)
	timer.timeout.connect(func():
		_shown_score = mini(final_score, _shown_score + inc)
		_score_value.text = str(_shown_score)
		SoundManager.play_tick()
		if _shown_score >= final_score:
			timer.stop())
	timer.start()


func _add_button(text: String, color: Color, bottom_y: float, delay: float, action: Callable, btn_size := Vector2(280, 62), font_size := 16) -> PixelButton:
	var b := PixelButton.create(text, color, Color.WHITE, btn_size, font_size)
	b.pulse = false
	b.interactive = false
	b.place_bottom_center(get_viewport_rect().size.x / 2.0, bottom_y)
	var final_y := b.position.y
	b.position.y += 30.0
	b.modulate.a = 0.0
	if action.is_valid():
		b.pressed.connect(action)
	add_child(b)
	var t := create_tween()
	t.tween_interval(delay)
	t.tween_property(b, "modulate:a", 1.0, 0.4)
	t.parallel().tween_property(b, "position:y", final_y, 0.4).set_ease(Tween.EASE_OUT)
	t.tween_callback(func():
		b.interactive = true
		b.start_pulse())
	return b
