class_name Coin
extends Node2D
## Collectible coin in a pillar gap (US monetisation 5). Purely a reward; never kills the fish.

var collected := false
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(_time * 3.0) * 3.0
	draw_set_transform(Vector2(0, bob))
	DrawUtil.draw_coin(self, Vector2.ZERO, Constants.COIN_RADIUS, cos(_time * 4.0))
	draw_set_transform(Vector2.ZERO)
