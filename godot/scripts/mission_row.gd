class_name MissionRow
extends Node2D
## One mission card: description, progress bar, reward and CLAIM.

signal claimed(amount: int)

var index := 0
var size_px := Vector2(320, 104)
var _btn: PixelButton
var _desc: Label


func _ready() -> void:
	_desc = UiUtil.label(self, "", 12, Color.WHITE, size_px.x / 2.0, 26)
	_btn = PixelButton.create("", Constants.UI_GREEN, Color.WHITE, Vector2(130, 34), 12)
	_btn.pulse = false
	_btn.shadow_offset = 2.0
	_btn.position = Vector2(size_px.x - 142, size_px.y - 44)
	_btn.pressed.connect(_claim)
	add_child(_btn)
	refresh()


func refresh() -> void:
	var m: Dictionary = SaveManager.missions[index]
	_desc.text = Daily.mission_text(m)
	var done: bool = m.progress >= m.target
	if m.claimed:
		_btn.text = tr("DONE")
		_btn.color = Color(0.25, 0.35, 0.3)
		_btn.interactive = false
	elif done:
		_btn.text = tr("CLAIM %d") % m.reward
		_btn.color = Constants.UI_GREEN
		_btn.interactive = true
	else:
		_btn.text = "%d / %d" % [m.progress, m.target]
		_btn.color = Color(0.25, 0.25, 0.3)
		_btn.interactive = false
	queue_redraw()


func _claim() -> void:
	var got := Daily.claim_mission(index)
	if got > 0:
		SoundManager.play_buy()
		Haptics.medium()
		UiUtil.float_text(self, "+%d" % got, Vector2(size_px.x - 77, size_px.y - 50), Constants.UI_GOLD_TEXT, 20)
		claimed.emit(got)


func _draw() -> void:
	var m: Dictionary = SaveManager.missions[index]
	DrawUtil.draw_rounded_rect_bordered(self, Rect2(Vector2.ZERO, size_px), 12, Color(0.02, 0.07, 0.12), Constants.UI_ORANGE if (m.progress >= m.target and not m.claimed) else Color.BLACK, 2)
	# Progress bar
	var bar := Rect2(14, size_px.y - 36, size_px.x - 172, 14)
	DrawUtil.draw_rounded_rect(self, bar, 7, Color.BLACK)
	var frac := clampf(float(m.progress) / m.target, 0.0, 1.0)
	if frac > 0.0:
		DrawUtil.draw_rounded_rect(self, Rect2(bar.position + Vector2(2, 2), Vector2(maxf(10.0, (bar.size.x - 4) * frac), bar.size.y - 4)), 5, Constants.UI_GREEN if frac >= 1.0 else Constants.UI_ORANGE)
	# Reward
	DrawUtil.draw_coin(self, Vector2(22, 52), 7)
	draw_string(DrawUtil.font(), Vector2(34, 57), str(m.reward), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Constants.UI_GOLD_TEXT)
