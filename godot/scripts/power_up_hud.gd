class_name PowerUpHud
extends Node2D
## Active power-ups under the score: icon + shrinking ring showing the time left.

var items: Array = [] ## [{type: PowerUp.Type, frac: float}]


func set_items(list: Array) -> void:
	items = list
	queue_redraw()


func _draw() -> void:
	var x := -(items.size() - 1) * 18.0
	for it in items:
		var c := Vector2(x, 0)
		PowerUp.draw_icon(self, it.type, c, 11)
		if it.frac < 1.0:
			draw_arc(c, 15, -PI / 2.0, -PI / 2.0 + TAU * it.frac, 24, Color(1, 1, 1, 0.9), 2.5, true)
		x += 36.0
