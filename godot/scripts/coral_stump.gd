class_name CoralStump
extends Node2D
## Decorative coral stump rising from the bottom edge (splash US-16, menu US-17).
## `position` is the bottom-centre of the stump.

var height := 80.0
var outline_width := 28.0
var outline_radius := 4.0
var fill_radius := 3.0


static func create(pos: Vector2, p_height: float, p_outline_width := 28.0) -> CoralStump:
	var c := CoralStump.new()
	c.position = pos
	c.height = p_height
	c.outline_width = p_outline_width
	return c


func _draw() -> void:
	DrawUtil.draw_rounded_rect(self, Rect2(-outline_width / 2.0, -height, outline_width, height), outline_radius, Color.BLACK)
	DrawUtil.draw_rounded_rect(self, Rect2(-12, -height + 2, 24, height - 2), fill_radius, Constants.CORAL_BASE)
	draw_rect(Rect2(-10, -height + 5, 5, height - 5), Color(Constants.CORAL_HIGHLIGHT, 0.8))
	draw_rect(Rect2(5, -height + 5, 6, height - 5), Color(0.42, 0.06, 0.06, 0.7))
	var y := -height + 14.0
	var k := 0
	while y < -6.0:
		draw_circle(Vector2(-3.0 + float((k * 5) % 8), y), 2.2, Color(0.42, 0.06, 0.06, 0.8), true, -1.0, true)
		y += 15.0
		k += 1
	# Polyp tufts on top
	for i in 3:
		var p := Vector2(-7 + i * 7, -height + 1)
		draw_circle(p, 4.5, Color.BLACK, true, -1.0, true)
		draw_circle(p, 3.2, Color(1.0, 0.55, 0.6), true, -1.0, true)
		draw_circle(p + Vector2(-1, -1), 1.1, Color(1, 0.9, 0.9), true, -1.0, true)
