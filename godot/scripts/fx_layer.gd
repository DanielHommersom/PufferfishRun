class_name FxLayer
extends Node2D
## Lightweight particle layer for purely visual effects (bubbles, sparkles, debris).
## Everything is drawn in one _draw(); nothing here affects gameplay.

enum Kind { BUBBLE, DOT, SPARK, SHARD, HEART, STAR }

var _parts: Array[Dictionary] = []


func bubble(pos: Vector2, vel: Vector2, r: float, life: float) -> void:
	_parts.append({"kind": Kind.BUBBLE, "pos": pos, "vel": vel, "r": r, "life": life, "max": life, "color": Color.WHITE, "rot": 0.0, "spin": 0.0})


func dot(pos: Vector2, vel: Vector2, r: float, life: float, color: Color) -> void:
	_parts.append({"kind": Kind.DOT, "pos": pos, "vel": vel, "r": r, "life": life, "max": life, "color": color, "rot": 0.0, "spin": 0.0})


func heart(pos: Vector2, vel: Vector2, r: float, life: float, color: Color) -> void:
	_parts.append({"kind": Kind.HEART, "pos": pos, "vel": vel, "r": r, "life": life, "max": life, "color": color, "rot": 0.0, "spin": 0.0})


func star(pos: Vector2, vel: Vector2, r: float, life: float, color: Color) -> void:
	_parts.append({"kind": Kind.STAR, "pos": pos, "vel": vel, "r": r, "life": life, "max": life, "color": color, "rot": randf() * TAU, "spin": randf_range(-4, 4)})


static func draw_heart(canvas: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	canvas.draw_circle(c + Vector2(-r * 0.45, -r * 0.2), r * 0.55, color, true, -1.0, true)
	canvas.draw_circle(c + Vector2(r * 0.45, -r * 0.2), r * 0.55, color, true, -1.0, true)
	DrawUtil.draw_triangle(canvas, c + Vector2(-r * 0.98, 0.0), c + Vector2(r * 0.98, 0.0), c + Vector2(0, r * 1.05), color)


static func draw_star(canvas: CanvasItem, c: Vector2, r: float, color: Color, rot := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := rot - PI / 2.0 + TAU * i / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	canvas.draw_colored_polygon(pts, color)


func sparkle(pos: Vector2, count: int, color: Color) -> void:
	for i in count:
		var a := TAU * i / count + randf() * 0.4
		_parts.append({"kind": Kind.SPARK, "pos": pos, "vel": Vector2(cos(a), sin(a)) * randf_range(60, 120), "r": randf_range(2.5, 4.5), "life": 0.45, "max": 0.45, "color": color, "rot": a, "spin": 0.0})


func shards(pos: Vector2, count: int, colors: Array[Color]) -> void:
	for i in count:
		var a := randf() * TAU
		_parts.append({"kind": Kind.SHARD, "pos": pos, "vel": Vector2(cos(a), sin(a)) * randf_range(90, 220), "r": randf_range(3, 6), "life": 0.7, "max": 0.7, "color": colors[i % colors.size()], "rot": a, "spin": randf_range(-10, 10)})


func _process(delta: float) -> void:
	for i in range(_parts.size() - 1, -1, -1):
		var p := _parts[i]
		p.life -= delta
		if p.life <= 0.0:
			_parts.remove_at(i)
			continue
		p.pos += p.vel * delta
		p.rot += p.spin * delta
		match p.kind:
			Kind.BUBBLE:
				p.vel.y -= 60.0 * delta # buoyancy
				p.vel.x *= 0.96
			Kind.SHARD, Kind.SPARK, Kind.DOT, Kind.STAR:
				p.vel *= 0.95
			Kind.HEART:
				p.vel.y -= 25.0 * delta
				p.vel.x *= 0.95
	queue_redraw()


func _draw() -> void:
	for p in _parts:
		var t: float = p.life / p.max
		match p.kind:
			Kind.BUBBLE:
				draw_circle(p.pos, p.r, Color(0.7, 0.95, 1.0, 0.25 * t), true, -1.0, true)
				draw_arc(p.pos, p.r, 0, TAU, 12, Color(1, 1, 1, 0.7 * t), 1.2, true)
				draw_circle(p.pos + Vector2(-p.r, -p.r) * 0.35, p.r * 0.25, Color(1, 1, 1, 0.8 * t), true, -1.0, true)
			Kind.DOT:
				draw_circle(p.pos, p.r, Color(p.color, p.color.a * t), true, -1.0, true)
			Kind.SPARK:
				var d: Vector2 = Vector2(cos(p.rot), sin(p.rot)) * p.r * 2.0
				draw_line(p.pos - d, p.pos + d, Color(p.color, t), 2.0, true)
				draw_circle(p.pos, p.r * 0.6, Color(1, 1, 1, t), true, -1.0, true)
			Kind.HEART:
				draw_heart(self, p.pos, p.r, Color(p.color, t))
			Kind.STAR:
				draw_star(self, p.pos, p.r, Color(p.color, t), p.rot)
			Kind.SHARD:
				var f: Vector2 = Vector2(cos(p.rot), sin(p.rot)) * p.r
				var s: Vector2 = Vector2(-f.y, f.x) * 0.6
				var c: Color = Color(p.color, t)
				DrawUtil.draw_triangle(self, p.pos + f * 1.6, p.pos + s, p.pos - s, Color(0, 0, 0, t))
				DrawUtil.draw_triangle(self, p.pos + f * 1.2, p.pos + s * 0.6, p.pos - s * 0.6, c)
