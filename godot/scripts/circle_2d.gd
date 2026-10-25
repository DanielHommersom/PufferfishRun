class_name Circle2D
extends Node2D
## A single filled circle (used for the death bubbles).

var radius := 5.0
var color := Color.WHITE


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
