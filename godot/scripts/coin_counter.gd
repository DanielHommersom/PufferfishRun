class_name CoinCounter
extends Node2D
## Coin icon + number. Origin = left-centre of the icon.

var value := 0:
	set(v):
		value = v
		queue_redraw()
var font_size := 18
var prefix := ""


func pop() -> void:
	scale = Vector2(1.3, 1.3)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var r := font_size * 0.5
	DrawUtil.draw_coin(self, Vector2(r, 0), r)
	var text := prefix + str(value)
	var f := DrawUtil.font()
	var base := Vector2(r * 2.0 + 6.0, (f.get_ascent(font_size) - f.get_descent(font_size)) * 0.5)
	draw_string_outline(f, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color.BLACK)
	draw_string(f, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Constants.UI_GOLD_TEXT)
