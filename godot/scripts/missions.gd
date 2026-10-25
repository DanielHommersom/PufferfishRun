extends Node2D
## Daily missions: three per day with progress bars and a CLAIM button each.

const PANEL_H := 560.0

var _rows: Array = []
var _coins: CoinCounter
var _leaving := false


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF # animated per frame
	Daily.ensure_missions()
	var s := get_viewport_rect().size
	var cx := s.x / 2.0
	var ocean := OceanBackground.new()
	ocean.parallax = false
	ocean.bubble_count = 6
	add_child(ocean)
	UiUtil.color_rect(self, Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.55))
	var top := s.y / 2.0 - PANEL_H / 2.0
	var bottom := top + PANEL_H
	var panel := ScorePanel.create(Rect2(20, top, s.x - 40, PANEL_H), Color(0.102, 0.416, 0.478))
	panel.divider = false
	add_child(panel)
	UiUtil.label(self, tr("DAILY MISSIONS"), 20, Color.WHITE, cx, top + 48, true)
	UiUtil.label(self, tr("NEW MISSIONS EVERY DAY"), 10, Constants.UI_MUTED_TEXT, cx, top + 70)
	_coins = CoinCounter.new()
	_coins.font_size = 14
	_coins.value = SaveManager.coins
	_coins.position = Vector2(s.x - 20 - 86, top + 24)
	add_child(_coins)

	for i in SaveManager.missions.size():
		var row := MissionRow.new()
		row.index = i
		row.position = Vector2(36, top + 96 + i * 118)
		row.size_px = Vector2(s.x - 72, 104)
		row.claimed.connect(_on_claimed)
		add_child(row)
		_rows.append(row)

	var challenge := PixelButton.create(tr("DAILY CHALLENGE"), Constants.UI_ORANGE, Color.BLACK, Vector2(260, 50), 14)
	challenge.pulse = false
	challenge.place_bottom_center(cx, bottom - 50)
	challenge.pressed.connect(func(): add_child(ChallengePanel.new()))
	add_child(challenge)

	var back := UiUtil.label(self, tr("< BACK"), 13, Constants.UI_MUTED_TEXT, cx, bottom - 16)
	back.z_index = 1
	var hit := Control.new()
	hit.size = Vector2(160, 36)
	hit.position = Vector2(cx - 80, bottom - 40)
	hit.gui_input.connect(_on_back_input)
	add_child(hit)


func _on_claimed(amount: int) -> void:
	_coins.value = SaveManager.coins
	_coins.pop()
	for r in _rows:
		r.refresh()


func _on_back_input(e: InputEvent) -> void:
	if _leaving or not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		return
	_leaving = true
	SoundManager.play_click()
	SceneRouter.go_to("menu", SceneRouter.Transition.FADE, 0.3)
