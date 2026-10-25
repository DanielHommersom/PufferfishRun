class_name PowerUp
extends Node2D
## Collectible power-up bubble in a pillar gap: shield, magnet or slow-motion.

enum Type { SHIELD, MAGNET, SLOW }

const COLORS := {Type.SHIELD: Color(0.35, 0.75, 1.0), Type.MAGNET: Color(1.0, 0.35, 0.35), Type.SLOW: Color(0.65, 0.5, 1.0)}

var type: Type = Type.SHIELD
var collected := false
var _time := 0.0


static func type_name(t: Type) -> String:
	return ["SHIELD", "MAGNET", "SLOW-MO"][t]


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(_time * 3.0) * 3.0
	var pulse := 1.0 + sin(_time * 5.0) * 0.06
	draw_set_transform(Vector2(0, bob), 0.0, Vector2(pulse, pulse))
	PowerUp.draw_icon(self, type, Vector2.ZERO, Constants.POWERUP_RADIUS)
	draw_set_transform(Vector2.ZERO)


## Bubble with an icon; also used by the HUD.
static func draw_icon(canvas: CanvasItem, t: Type, c: Vector2, r: float) -> void:
	var col: Color = COLORS[t]
	canvas.draw_circle(c, r + 4, Color(col, 0.25), true, -1.0, true)
	DrawUtil.draw_circle_stroked(canvas, c, r, Color(col, 0.55), Color.BLACK, 2)
	canvas.draw_circle(c + Vector2(-r * 0.4, -r * 0.4), r * 0.2, Color(1, 1, 1, 0.7), true, -1.0, true)
	var s := r * 0.55
	match t:
		Type.SHIELD:
			var pts := PackedVector2Array([c + Vector2(-s, -s * 0.8), c + Vector2(s, -s * 0.8), c + Vector2(s * 0.85, s * 0.2), c + Vector2(0, s), c + Vector2(-s * 0.85, s * 0.2)])
			canvas.draw_colored_polygon(pts, Color.WHITE)
			pts.append(pts[0])
			canvas.draw_polyline(pts, Color.BLACK, 1.5, true)
		Type.MAGNET:
			canvas.draw_arc(c + Vector2(0, -s * 0.1), s * 0.75, 0.0, PI, 12, Color.BLACK, s * 0.62, true)
			canvas.draw_arc(c + Vector2(0, -s * 0.1), s * 0.75, 0.0, PI, 12, Color(0.95, 0.2, 0.2), s * 0.42, true)
			canvas.draw_rect(Rect2(c.x - s * 0.96, c.y - s * 0.75, s * 0.42, s * 0.5), Color(0.9, 0.9, 0.95))
			canvas.draw_rect(Rect2(c.x + s * 0.54, c.y - s * 0.75, s * 0.42, s * 0.5), Color(0.9, 0.9, 0.95))
		Type.SLOW:
			canvas.draw_circle(c, s, Color.WHITE, true, -1.0, true)
			canvas.draw_arc(c, s, 0, TAU, 16, Color.BLACK, 1.5, true)
			canvas.draw_line(c, c + Vector2(0, -s * 0.7), Color.BLACK, 1.8, true)
			canvas.draw_line(c, c + Vector2(s * 0.5, 0), Color.BLACK, 1.8, true)
