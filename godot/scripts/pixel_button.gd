class_name PixelButton
extends Control
## Chunky pixel-style button (US-17, reused by GameOver and SkinSelect).
## Pulses from its centre; the label pulses with it.

signal pressed

var text := "BUTTON":
	set(v):
		text = v
		queue_redraw()
var color := Constants.UI_ORANGE:
	set(v):
		color = v
		queue_redraw()
var text_color := Color.BLACK:
	set(v):
		text_color = v
		queue_redraw()
var font_size := 16
var badge := 0: ## red notification bubble with a count (0 = hidden)
	set(v):
		badge = v
		queue_redraw()
var shadow_offset := 4.0
var pulse := true
var interactive := true:
	set(v):
		interactive = v
		mouse_filter = Control.MOUSE_FILTER_STOP if v else Control.MOUSE_FILTER_IGNORE

var _pulse_tween: Tween


static func create(p_text: String, p_color: Color, p_text_color: Color, p_size: Vector2, p_font_size: int) -> PixelButton:
	var b := PixelButton.new()
	b.text = p_text
	b.color = p_color
	b.text_color = p_text_color
	b.size = p_size
	b.font_size = p_font_size
	return b


func _ready() -> void:
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	if pulse:
		start_pulse()


func start_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	scale = Vector2.ONE
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.7)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.7)


## Quick press bounce (0.94 → 1.0, 2× 0.08 s). Returns the tween so callers can await it.
func press_bounce() -> Tween:
	if _pulse_tween:
		_pulse_tween.kill()
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.94, 0.94), 0.08)
	t.tween_property(self, "scale", Vector2.ONE, 0.08)
	return t


## Positions the button so its bottom edge sits at `bottom_y`, horizontally centred on `center_x`.
func place_bottom_center(center_x: float, bottom_y: float) -> void:
	position = Vector2(center_x - size.x / 2.0, bottom_y - size.y)


func _gui_input(event: InputEvent) -> void:
	if not interactive or SceneRouter.is_transitioning:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		SoundManager.play_click()
		pressed.emit()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	DrawUtil.draw_rounded_rect(self, Rect2(r.position + Vector2(shadow_offset, shadow_offset), r.size), 14, Color.BLACK)
	DrawUtil.draw_rounded_rect_bordered(self, r, 12, color, Color.BLACK, 3)
	# Bevel: darker lower band, light top band and a small glint
	DrawUtil.draw_rounded_rect(self, Rect2(3, size.y * 0.62, size.x - 6, size.y * 0.38 - 3), 9, Color(0, 0, 0, 0.16))
	DrawUtil.draw_rounded_rect(self, Rect2(4, 4, size.x - 8, size.y * 0.36), 9, Color(1, 1, 1, 0.22))
	DrawUtil.draw_rounded_rect(self, Rect2(12, 7, minf(28.0, size.x * 0.12), 5), 3, Color(1, 1, 1, 0.45))
	var center := size / 2.0 + Vector2(0, 1)
	var label := tr(text)
	var fs := DrawUtil.fit_font_size(label, font_size, size.x - 14.0)
	DrawUtil.draw_text_middle(self, label, center + Vector2(0, 2), fs, Color(0, 0, 0, 0.25))
	DrawUtil.draw_text_middle(self, label, center, fs, text_color)
	if badge > 0:
		var bc := Vector2(size.x - 4, 4)
		draw_circle(bc, 11, Color.BLACK, true, -1.0, true)
		draw_circle(bc, 9, Color(0.9, 0.15, 0.2), true, -1.0, true)
		DrawUtil.draw_text_middle(self, str(badge), bc, 11, Color.WHITE)
