class_name RevivePanel
extends Node2D
## "CONTINUE?" offer after dying: watch a rewarded video to keep the run going (once per run).
## Counts down REVIVE_COUNTDOWN seconds; expiring or tapping NO THANKS ends the run.

signal watch_pressed
signal declined

var paused := false
var _left := Constants.REVIVE_COUNTDOWN
var _done := false
var _center := Vector2.ZERO
var _watch: PixelButton
var _ring: Node2D


func _ready() -> void:
	z_index = 30
	var s := get_viewport_rect().size
	_center = Vector2(s.x / 2.0, s.y * 0.42)
	UiUtil.color_rect(self, Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.5))
	var panel := ScorePanel.create(Rect2(_center.x - 150, _center.y - 150, 300, 300), Color(0.102, 0.416, 0.478))
	panel.divider = false
	add_child(panel)
	_ring = Node2D.new()
	_ring.draw.connect(_draw_ring)
	add_child(_ring)
	UiUtil.label(self, tr("CONTINUE?"), 30, Constants.UI_ORANGE, _center.x, _center.y - 100, true)

	_watch = PixelButton.create(tr("WATCH AD"), Constants.UI_GREEN, Color.WHITE, Vector2(240, 58), 16)
	_watch.place_bottom_center(_center.x, _center.y + 108)
	_watch.pressed.connect(func():
		if _done:
			return
		paused = true
		watch_pressed.emit())
	add_child(_watch)

	var no := UiUtil.label(self, tr("NO THANKS"), 13, Constants.UI_MUTED_TEXT, _center.x, _center.y + 138)
	var hit := Control.new()
	hit.position = Vector2(_center.x - 90, _center.y + 118)
	hit.size = Vector2(180, 32)
	hit.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			SoundManager.play_click()
			_finish())
	add_child(hit)
	no.z_index = 1

	scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	position = _center * 0.15
	var t := create_tween().set_parallel()
	t.tween_property(self, "modulate:a", 1.0, 0.2)
	t.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if _done or paused:
		return
	_left -= delta
	_ring.queue_redraw()
	if _left <= 0.0:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	declined.emit()


## Countdown ring with the seconds left in the middle (drawn on its own child above the panel).
func _draw_ring() -> void:
	var c := _center + Vector2(0, -20)
	var frac := clampf(_left / Constants.REVIVE_COUNTDOWN, 0.0, 1.0)
	_ring.draw_circle(c, 46, Color(0, 0, 0, 0.35), true, -1.0, true)
	_ring.draw_arc(c, 42, 0, TAU, 48, Color(1, 1, 1, 0.12), 8, true)
	_ring.draw_arc(c, 42, -PI / 2.0, -PI / 2.0 + TAU * frac, 48, Constants.UI_ORANGE, 8, true)
	DrawUtil.draw_text_middle(_ring, str(ceili(_left)), c, 34, Color.WHITE)
