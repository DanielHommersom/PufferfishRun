class_name DailyRewardPanel
extends OverlayPanel
## Daily login reward: 7-day streak track, CLAIM or 2× with a rewarded video.

var _claim: PixelButton
var _double: PixelButton
var _track: Node2D
var _countdown: Label


func _init() -> void:
	title = "DAILY REWARD"
	panel_size = Vector2(340, 360)


func build() -> void:
	var cx := panel_rect.get_center().x
	var day := Daily.streak_day()
	UiUtil.label(self, tr("DAY %d") % day, 14, Color.WHITE, cx, content_top + 8, true)
	_track = Node2D.new()
	_track.position = Vector2(panel_rect.position.x, content_top + 26)
	_track.draw.connect(_draw_track)
	add_child(_track)

	if not Daily.reward_available():
		# Already claimed today: show the streak and when the next reward unlocks
		UiUtil.label(self, tr("CLAIMED TODAY"), 15, Constants.UI_GREEN, cx, panel_rect.end.y - 140, true)
		UiUtil.label(self, tr("NEXT REWARD IN"), 12, Constants.UI_MUTED_TEXT, cx, panel_rect.end.y - 104)
		_countdown = UiUtil.label(self, "", 24, Color.WHITE, cx, panel_rect.end.y - 70, true)
		_update_countdown()
		return
	var amount := Daily.reward_amount(day)
	_claim = PixelButton.create(tr("CLAIM %d") % amount, Constants.UI_GREEN, Color.WHITE, Vector2(260, 52), 15)
	_claim.pulse = true
	_claim.place_bottom_center(cx, panel_rect.end.y - 110)
	_claim.pressed.connect(func(): _do_claim(1))
	add_child(_claim)
	if AdManager.can_show_rewarded():
		_double = PixelButton.create(tr("CLAIM 2× (AD)"), Color(0.49, 0.30, 0.78), Color.WHITE, Vector2(260, 44), 13)
		_double.pulse = false
		_double.place_bottom_center(cx, panel_rect.end.y - 52)
		_double.pressed.connect(func():
			_double.interactive = false
			AdManager.show_rewarded(func(earned: bool):
				if earned:
					_do_claim(2)
				else:
					_double.interactive = true))
		add_child(_double)


func _process(_delta: float) -> void:
	if _countdown:
		_update_countdown()


func _update_countdown() -> void:
	var s := Daily.seconds_until_tomorrow()
	_countdown.text = "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]


func _do_claim(multiplier: int) -> void:
	var got := Daily.claim_reward(multiplier)
	if got <= 0:
		return
	SoundManager.play_buy()
	Haptics.medium()
	UiUtil.float_text(self, "+%d" % got, panel_rect.get_center(), Constants.UI_GOLD_TEXT, 30)
	await get_tree().create_timer(0.7).timeout
	close()


func _draw_track() -> void:
	var day := Daily.streak_day()
	var n := Constants.DAILY_REWARDS.size()
	var tile := Vector2(40, 64)
	var gap := 4.0
	var x0 := (panel_size.x - (n * tile.x + (n - 1) * gap)) / 2.0
	for i in n:
		var r := Rect2(x0 + i * (tile.x + gap), 0, tile.x, tile.y)
		var claimed_today := not Daily.reward_available()
		var is_today := i + 1 == day
		var done := i + 1 < day or (claimed_today and is_today)
		var fill := Constants.UI_BLUE if is_today else Color(0.02, 0.07, 0.12)
		DrawUtil.draw_rounded_rect_bordered(_track, r, 7, fill, Constants.UI_ORANGE if is_today else Color.BLACK, 2)
		DrawUtil.draw_text_centered(_track, str(i + 1), r.position + Vector2(tile.x / 2.0, 14), 10, Constants.UI_MUTED_TEXT)
		DrawUtil.draw_coin(_track, r.position + Vector2(tile.x / 2.0, 30), 7)
		DrawUtil.draw_text_centered(_track, str(Constants.DAILY_REWARDS[i]), r.position + Vector2(tile.x / 2.0, 56), 10, Constants.UI_GOLD_TEXT)
		if done:
			_track.draw_line(r.position + Vector2(10, 32), r.position + Vector2(17, 40), Constants.UI_GREEN, 4, true)
			_track.draw_line(r.position + Vector2(17, 40), r.position + Vector2(31, 22), Constants.UI_GREEN, 4, true)
