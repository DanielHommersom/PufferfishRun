class_name Medal
extends Node2D
## Medal disc (r 24, black 3 px stroke) with a 9 pt label.

var color := Color.WHITE
var text := ""


func _draw() -> void:
	DrawUtil.draw_circle_stroked(self, Vector2.ZERO, 24, color, Color.BLACK, 3)
	draw_arc(Vector2.ZERO, 18, 0, TAU, 32, DrawUtil.darken(color, 0.15), 2.0, true)
	draw_arc(Vector2.ZERO, 21, PI * 1.05, PI * 1.55, 10, Color(1, 1, 1, 0.7), 2.5, true)
	draw_circle(Vector2(-9, -11), 3, Color(1, 1, 1, 0.6), true, -1.0, true)
	DrawUtil.draw_text_middle(self, text, Vector2.ZERO, 9, Color.BLACK)
