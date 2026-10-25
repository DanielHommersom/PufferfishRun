class_name TutorialPanel
extends Node2D
## "▲ HOLD | ▼ RELEASE" hint panel on the menu. Origin = panel centre; pulses 1.0 ↔ 1.03.
## Arrows are drawn triangles (the ▲/▼ glyphs are not in every font).

var panel_size := Vector2(280, 72)


func _ready() -> void:
	var t := create_tween().set_loops()
	t.tween_property(self, "scale", Vector2(1.03, 1.03), 0.9)
	t.tween_property(self, "scale", Vector2.ONE, 0.9)


func _draw() -> void:
	var r := Rect2(-panel_size / 2.0, panel_size)
	DrawUtil.draw_rounded_rect(self, r.grow(3), 14, Color.BLACK)
	DrawUtil.draw_rounded_rect(self, r, 12, Constants.PANEL_BG)
	var bottom := r.end.y
	var left_x := r.position.x + panel_size.x * 0.25
	var right_x := r.position.x + panel_size.x * 0.75
	# Divider
	draw_rect(Rect2(-1, r.position.y + 8, 2, panel_size.y - 16), Color(0.2, 0.4, 0.6))
	# Arrows (centre ≈ 35 px above the bottom, like the 14 pt glyph at baseline +30)
	var ay := bottom - 36.0
	DrawUtil.draw_triangle(self, Vector2(left_x - 6, ay + 5), Vector2(left_x + 6, ay + 5), Vector2(left_x, ay - 6), Color.WHITE)
	DrawUtil.draw_triangle(self, Vector2(right_x - 6, ay - 5), Vector2(right_x + 6, ay - 5), Vector2(right_x, ay + 6), Color.WHITE)
	DrawUtil.draw_text_centered(self, "HOLD", Vector2(left_x, bottom - 10), 11, Color.WHITE)
	DrawUtil.draw_text_centered(self, "RELEASE", Vector2(right_x, bottom - 10), 11, Color.WHITE)
