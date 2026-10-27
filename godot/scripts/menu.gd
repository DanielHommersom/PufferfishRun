extends Node2D
## Main menu (US-17). Only taps on the buttons do something (like the original).

const PANEL_SIZE := Vector2(280, 72)

static var _daily_shown_this_session := false
static var _splash_played := false

var _daily_btn: PixelButton


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF # animated per frame
	var s := get_viewport_rect().size
	var cx := s.x / 2.0

	# Background
	var ocean := OceanBackground.new()
	ocean.parallax = false
	ocean.bubble_count = 0
	add_child(ocean)
	for c in [[60.0, 80.0], [cx, 60.0], [s.x - 60.0, 80.0]]:
		add_child(CoralStump.create(Vector2(c[0], s.y), c[1]))
	var bubbles := BubbleField.new()
	bubbles.count = 6
	bubbles.radius_min = 5.0
	bubbles.radius_max = 14.0
	bubbles.fill_alpha = 0.12
	add_child(bubbles)

	# Fish with the selected skin, bobbing 14 px
	var fish := StaticFish.create(SaveManager.get_selected_skin(), 52.0, 8)
	fish.hat = SaveManager.selected_hat
	fish.position = Vector2(cx, s.y * 0.38)
	add_child(fish)
	var bob := create_tween().set_loops()
	bob.tween_property(fish, "position:y", fish.position.y - 14.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(fish, "position:y", fish.position.y, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Best score + title
	UiUtil.label(self, tr("BEST: %d") % SaveManager.high_score, 13, Constants.UI_GOLD_TEXT, cx, s.y * 0.56 - 50.0)
	var puffer := UiUtil.label(self, "PUFFERFISH", 38, Color.WHITE, cx, s.y * 0.56, true)
	puffer.modulate.a = 0.0
	var pt := create_tween().set_parallel()
	pt.tween_property(puffer, "modulate:a", 1.0, 0.5)
	pt.tween_property(puffer, "position:y", puffer.position.y - 20.0, 0.5).set_ease(Tween.EASE_OUT)
	var run := UiUtil.label(self, "RUN", 52, Constants.UI_ORANGE, cx, s.y * 0.63, true)
	run.modulate.a = 0.0
	run.scale = Vector2(1.0, 0.7)
	var rt := create_tween()
	rt.tween_interval(0.2)
	rt.tween_property(run, "modulate:a", 1.0, 0.5)
	rt.parallel().tween_property(run, "scale:y", 1.0, 0.4)

	# Daily row: reward / missions / challenge (the GET READY screen now teaches the controls)
	var row_w := (300.0 - 2 * 8.0) / 3.0
	var row_bottom := s.y * 0.73
	_daily_btn = _row_button(tr("DAILY"), Color(0.49, 0.30, 0.78), cx - 150.0, row_bottom, row_w, _open_daily)
	_daily_btn.badge = 1 if Daily.reward_available() else 0
	var missions_btn := _row_button(tr("MISSIONS"), Constants.UI_BLUE, cx - 150.0 + row_w + 8.0, row_bottom, row_w, func():
		SceneRouter.go_to("missions", SceneRouter.Transition.FADE, 0.3))
	missions_btn.badge = Daily.claimable_count()
	var ch := _row_button(tr("CHALLENGE"), Color(0.85, 0.35, 0.2), cx - 150.0 + 2 * (row_w + 8.0), row_bottom, row_w, func():
		add_child(ChallengePanel.new()))
	ch.badge = 0 if Daily.challenge_claimed() else 1

	# Buttons
	var play := PixelButton.create(tr("TAP TO PLAY"), Constants.UI_ORANGE, Color.BLACK, Vector2(300, 68), 18)
	play.place_bottom_center(cx, s.y * 0.82)
	add_child(play)
	play.pressed.connect(func(): SceneRouter.go_to("game", SceneRouter.Transition.FADE, 0.3))

	var skin := PixelButton.create(tr("SKINS & SHOP"), Constants.UI_BLUE, Color.WHITE, Vector2(220, 52), 13)
	skin.place_bottom_center(cx, s.y * 0.90)
	add_child(skin)
	skin.pressed.connect(func(): SceneRouter.go_to("skin_select", SceneRouter.Transition.MOVE_IN_UP, 0.3))

	SoundManager.start_ambience()

	# Coins + settings along the top
	var top := maxf(0.0, DrawUtil.safe_insets(get_viewport()).top)
	var coins := CoinCounter.new()
	coins.value = SaveManager.coins
	coins.position = Vector2(18, top + 34)
	add_child(coins)
	var gear := GearButton.new()
	gear.position = Vector2(s.x - 18 - GearButton.HIT, top + 6)
	gear.pressed.connect(func(): SceneRouter.go_to("settings", SceneRouter.Transition.FADE, 0.3))
	add_child(gear)
	if not SaveManager.ads_removed:
		var no_ads := PixelButton.create(tr("NO ADS"), Constants.UI_ORANGE, Color.BLACK, Vector2(84, 34), 12)
		no_ads.pulse = false
		no_ads.shadow_offset = 3.0
		no_ads.position = Vector2(gear.position.x - 96, top + 17)
		no_ads.pressed.connect(func(): SceneRouter.go_to("settings", SceneRouter.Transition.FADE, 0.3))
		add_child(no_ads)

	var sound := SoundButton.create()
	add_child(sound)
	sound.place_default(get_viewport())

	# Launch: studio + game splash over this menu (PopPulse order), then the daily reward.
	# Tests skip it.
	if not _splash_played and not SaveManager.is_test_run():
		_splash_played = true
		var splash := SplashSequence.new()
		splash.finished.connect(_after_splash)
		add_child(splash)
	else:
		_after_splash()


func _after_splash() -> void:
	# First launch: consent + App Tracking Transparency before anything else (App Review
	# expects the tracking prompt right away, not only after the first game over).
	await AdManager.start_flow()
	if not is_inside_tree():
		return
	# Daily reward pops up once per session when it's available
	if Daily.reward_available() and not _daily_shown_this_session:
		_daily_shown_this_session = true
		get_tree().create_timer(0.4).timeout.connect(_open_daily)


func _row_button(text: String, color: Color, x: float, bottom: float, w: float, action: Callable) -> PixelButton:
	var b := PixelButton.create(text, color, Color.WHITE, Vector2(w, 56), 13)
	b.pulse = false
	b.shadow_offset = 3.0
	b.position = Vector2(x, bottom - 56)
	b.pressed.connect(action)
	add_child(b)
	return b


func _open_daily() -> void:
	var p := DailyRewardPanel.new()
	p.closed.connect(func(): _daily_btn.badge = 1 if Daily.reward_available() else 0)
	add_child(p)
