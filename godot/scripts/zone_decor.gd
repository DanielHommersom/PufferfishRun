class_name ZoneDecor
extends Node2D
## Zone-specific scenery that fades in with its zone: tall swaying kelp, sunken shipwrecks,
## or bioluminescent specks in the abyss. Scrolls with the pillars at a parallax factor.

var kind := "kelp"
var factor := 0.45

var _w := 393.0
var _h := 852.0
var _offset := 0.0
var _time := 0.0
var _items: Array[Vector3] = []


func _ready() -> void:
	var s := get_viewport_rect().size
	_w = s.x
	_h = s.y
	modulate.a = 0.0
	match kind:
		"kelp":
			for i in 7:
				_items.append(Vector3((i + 0.3 * sin(i * 3.1)) * _w / 7.0, _h * (0.35 + 0.25 * absf(sin(i * 1.7))), i * 0.9))
		"wreck":
			factor = 0.2
			_items.append(Vector3(_w * 0.15, 0.0, 0.0))
			_items.append(Vector3(_w * 0.7, 1.0, 0.0))
		"abyss":
			factor = 0.3
			var rng := RandomNumberGenerator.new()
			rng.seed = 99
			for i in 26:
				_items.append(Vector3(rng.randf() * _w, rng.randf() * _h, rng.randf() * TAU))


func scroll(speed: float) -> void:
	var before := _offset
	_offset = fposmod(_offset + speed * factor, _w)
	position.x = -_offset
	if _offset < before:
		reset_physics_interpolation()


func _process(delta: float) -> void:
	if modulate.a <= 0.01 or kind == "wreck": # wrecks are static: drawn once, only moved
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	for tile in 2:
		var dx := tile * _w
		match kind:
			"kelp":
				for it in _items:
					_draw_kelp(it.x + dx, it.y, it.z)
			"wreck":
				for it in _items:
					_draw_wreck(it.x + dx, it.y)
			"abyss":
				for it in _items:
					var a := 0.35 + 0.35 * sin(_time * 1.5 + it.z)
					var p := Vector2(it.x + dx, it.y + sin(_time * 0.5 + it.z) * 6.0)
					draw_circle(p, 5.0, Color(0.3, 1.0, 0.85, a * 0.25), true, -1.0, true)
					draw_circle(p, 1.8, Color(0.6, 1.0, 0.95, a), true, -1.0, true)


func _draw_kelp(x: float, height: float, phase: float) -> void:
	var pts := PackedVector2Array()
	for j in 13:
		var f := j / 12.0
		var sway := sin(_time * 1.2 + phase + f * 3.0) * 14.0 * f
		pts.append(Vector2(x + sway, _h + 4 - height * f))
	draw_polyline(pts, Color(0.02, 0.12, 0.08, 0.55), 11.0, true)
	draw_polyline(pts, Color(0.12, 0.42, 0.22, 0.6), 7.0, true)
	for j in range(2, 12, 2):
		var p := pts[j]
		var side := 1.0 if j % 4 == 0 else -1.0
		DrawUtil.draw_fin(self, p + Vector2(side * 8, 0), 9.0, 4.0, side * 0.6, Color(0.15, 0.5, 0.25, 0.55), 1.0)


func _draw_wreck(x: float, variant: float) -> void:
	var col := Color(0.0, 0.05, 0.07, 0.5)
	var base := _h - 30.0
	if variant < 0.5:
		# Tilted hull with a broken mast
		var hull := PackedVector2Array([Vector2(x - 90, base - 10), Vector2(x + 80, base - 60), Vector2(x + 95, base - 20), Vector2(x + 60, base + 30), Vector2(x - 70, base + 30)])
		draw_colored_polygon(hull, col)
		draw_line(Vector2(x + 10, base - 35), Vector2(x - 20, base - 210), col, 7.0, true)
		draw_line(Vector2(x - 12, base - 150), Vector2(x + 40, base - 160), col, 5.0, true)
		for k in 3:
			draw_circle(Vector2(x - 40 + k * 35, base - 5 - k * 10), 6.0, Color(0, 0, 0, 0.35), true, -1.0, true)
	else:
		# Anchor and barrels
		draw_line(Vector2(x, base - 90), Vector2(x, base + 10), col, 6.0, true)
		draw_arc(Vector2(x, base - 5), 28, 0.2, PI - 0.2, 12, col, 6.0, true)
		draw_line(Vector2(x - 18, base - 75), Vector2(x + 18, base - 75), col, 6.0, true)
		draw_rect(Rect2(x + 50, base - 10, 34, 40), col)
		draw_rect(Rect2(x + 70, base - 40, 30, 34), col)
