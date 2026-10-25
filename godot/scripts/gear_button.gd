class_name GearButton
extends Control
## Round settings button with a drawn gear icon (same style as SoundButton).

signal pressed

const HIT := 56.0


func _ready() -> void:
	size = Vector2(HIT, HIT)
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if SceneRouter.is_transitioning:
			return
		SoundManager.play_click()
		var t := create_tween()
		t.tween_property(self, "scale", Vector2(0.88, 0.88), 0.08)
		t.tween_property(self, "scale", Vector2.ONE, 0.08)
		pressed.emit()


func _draw() -> void:
	var c := size / 2.0
	draw_circle(c, 25, Color.BLACK, true, -1.0, true)
	DrawUtil.draw_circle_stroked(self, c, 22, Constants.UI_BLUE, Color.BLACK, 2)
	var pts := PackedVector2Array()
	var teeth := 8
	for i in teeth * 4:
		var a := TAU * i / (teeth * 4) + PI / 8.0
		var outer := (i % 4) < 2
		pts.append(c + Vector2(cos(a), sin(a)) * (11.0 if outer else 8.0))
	draw_colored_polygon(pts, Color.WHITE)
	draw_circle(c, 4.0, Constants.UI_BLUE, true, -1.0, true)
