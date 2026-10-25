class_name Cosmetics
## Hats and bubble trails sold in the shop (coins only, purely visual).
## Add an entry here + a branch in draw_hat / the trail emitter to add an item.

const HATS := [
	{"id": "none", "name": "NO HAT", "price": 0},
	{"id": "cap", "name": "CAP", "price": 80},
	{"id": "party", "name": "PARTY HAT", "price": 100},
	{"id": "shades", "name": "SHADES", "price": 150},
	{"id": "tophat", "name": "TOP HAT", "price": 200},
	{"id": "pirate", "name": "PIRATE", "price": 250},
	{"id": "crown", "name": "CROWN", "price": 400},
	{"id": "halo", "name": "HALO", "price": 600},
]

const TRAILS := [
	{"id": "bubbles", "name": "BUBBLES", "price": 0},
	{"id": "rainbow", "name": "RAINBOW", "price": 120},
	{"id": "gold", "name": "GOLD DUST", "price": 200},
	{"id": "hearts", "name": "HEARTS", "price": 300},
	{"id": "stars", "name": "STARS", "price": 450},
]


static func list(kind: String) -> Array:
	return HATS if kind == "hat" else TRAILS


static func price_of(kind: String, id: String) -> int:
	for item in list(kind):
		if item.id == id:
			return item.price
	return 0


# ── Hats (drawn in fish-local space; r = fish radius, body top at y = −r) ──

static func draw_hat(canvas: CanvasItem, id: String, r: float) -> void:
	var o := 2.0 if r > 30.0 else 1.5 # outline width
	match id:
		"cap":
			var c := Vector2(r * 0.05, -r * 0.82)
			_poly(canvas, _arc_points(c, r * 0.5, PI, TAU, 14), Color(0.86, 0.18, 0.2), o)
			_poly(canvas, PackedVector2Array([c + Vector2(r * 0.3, 0), c + Vector2(r * 0.95, r * 0.02), c + Vector2(r * 0.9, r * 0.14), c + Vector2(r * 0.3, r * 0.12)]), Color(0.7, 0.12, 0.15), o)
			canvas.draw_circle(c + Vector2(0, -r * 0.5), r * 0.07, Color.WHITE, true, -1.0, true)
		"party":
			var base := Vector2(r * 0.1, -r * 0.85)
			var tip := base + Vector2(r * 0.15, -r * 0.95)
			var pts := PackedVector2Array([base + Vector2(-r * 0.38, 0), base + Vector2(r * 0.38, 0), tip])
			_poly(canvas, pts, Color(0.35, 0.7, 1.0), o)
			for k in 3:
				var f := 0.25 + k * 0.25
				var a := pts[0].lerp(tip, f)
				var b := pts[1].lerp(tip, f)
				canvas.draw_line(a, b, Color(1, 0.85, 0.2), r * 0.08, true)
			canvas.draw_circle(tip, r * 0.13 + o, Color.BLACK, true, -1.0, true)
			canvas.draw_circle(tip, r * 0.13, Color(1, 0.4, 0.6), true, -1.0, true)
		"shades":
			var e := Vector2(r * 0.55, -r * 0.22)
			var lens := r * 0.3
			canvas.draw_line(e + Vector2(-lens * 1.9, -lens * 0.1), e + Vector2(lens * 0.6, -lens * 0.1), Color.BLACK, maxf(2.0, r * 0.07), true)
			_poly(canvas, _round_rect_points(Rect2(e.x - lens * 1.05, e.y - lens * 0.75, lens * 2.1, lens * 1.4), lens * 0.45), Color(0.08, 0.08, 0.12), o)
			canvas.draw_line(e + Vector2(-lens * 0.6, -lens * 0.4), e + Vector2(-lens * 0.1, -lens * 0.4), Color(1, 1, 1, 0.5), maxf(1.5, r * 0.05), true)
		"tophat":
			var base := Vector2(r * 0.05, -r * 0.85)
			_poly(canvas, _rect_points(Rect2(base.x - r * 0.62, base.y - r * 0.1, r * 1.24, r * 0.14)), Color(0.1, 0.1, 0.12), o)
			_poly(canvas, _rect_points(Rect2(base.x - r * 0.38, base.y - r * 0.82, r * 0.76, r * 0.74)), Color(0.12, 0.12, 0.15), o)
			canvas.draw_rect(Rect2(base.x - r * 0.38, base.y - r * 0.28, r * 0.76, r * 0.14), Color(0.8, 0.15, 0.2))
		"pirate":
			var base := Vector2(r * 0.05, -r * 0.82)
			var pts := PackedVector2Array([base + Vector2(-r * 0.8, r * 0.05), base + Vector2(-r * 0.45, -r * 0.5), base + Vector2(0, -r * 0.62), base + Vector2(r * 0.45, -r * 0.5), base + Vector2(r * 0.8, r * 0.05)])
			_poly(canvas, pts, Color(0.12, 0.1, 0.12), o)
			canvas.draw_line(base + Vector2(-r * 0.62, -r * 0.08), base + Vector2(r * 0.62, -r * 0.08), Color(0.9, 0.75, 0.25), maxf(1.5, r * 0.06), true)
			canvas.draw_circle(base + Vector2(0, -r * 0.3), r * 0.12, Color.WHITE, true, -1.0, true)
			canvas.draw_circle(base + Vector2(-r * 0.04, -r * 0.31), r * 0.03, Color.BLACK, true, -1.0, true)
			canvas.draw_circle(base + Vector2(r * 0.04, -r * 0.31), r * 0.03, Color.BLACK, true, -1.0, true)
		"crown":
			var b := Vector2(r * 0.05, -r * 0.82)
			var w := r * 0.5
			var h := r * 0.45
			var pts := PackedVector2Array([b + Vector2(-w, 0), b + Vector2(-w, -h), b + Vector2(-w * 0.5, -h * 0.5), b + Vector2(0, -h * 1.1), b + Vector2(w * 0.5, -h * 0.5), b + Vector2(w, -h), b + Vector2(w, 0)])
			_poly(canvas, pts, Color(1.0, 0.8, 0.15), o)
			canvas.draw_circle(b + Vector2(0, -h * 0.3), r * 0.08, Color(0.85, 0.1, 0.25), true, -1.0, true)
			canvas.draw_circle(b + Vector2(-w * 0.6, -h * 0.25), r * 0.06, Color(0.2, 0.5, 1.0), true, -1.0, true)
			canvas.draw_circle(b + Vector2(w * 0.6, -h * 0.25), r * 0.06, Color(0.2, 0.8, 0.4), true, -1.0, true)
		"halo":
			var c := Vector2(r * 0.05, -r * 1.3)
			DrawUtil.draw_ellipse(canvas, c, r * 0.62, r * 0.2, Color(1.0, 0.9, 0.4, 0.35))
			var ring := DrawUtil.ellipse_points(c, r * 0.5, r * 0.15, 32)
			ring.append(ring[0])
			canvas.draw_polyline(ring, Color(1.0, 0.85, 0.2), maxf(2.5, r * 0.11), true)


static func _poly(canvas: CanvasItem, pts: PackedVector2Array, fill: Color, outline: float) -> void:
	canvas.draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	canvas.draw_polyline(closed, Color.BLACK, outline, true)


static func _arc_points(c: Vector2, r: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func _rect_points(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


static func _round_rect_points(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [[r.end.x - rad, r.position.y + rad, -PI / 2.0], [r.end.x - rad, r.end.y - rad, 0.0], [r.position.x + rad, r.end.y - rad, PI / 2.0], [r.position.x + rad, r.position.y + rad, PI]]
	for c in corners:
		for k in 5:
			var a: float = c[2] + PI / 2.0 * k / 4.0
			pts.append(Vector2(c[0], c[1]) + Vector2(cos(a), sin(a)) * rad)
	return pts


# ── Trails ────────────────────────────────────────────────────────

## Emits one trail particle for `id` behind a fish of radius r at `pos`.
static func emit_trail(fx: FxLayer, id: String, pos: Vector2, r: float, t: float) -> void:
	var at := pos + Vector2(-r * 1.4, randf_range(-r, r) * 0.4)
	var vel := Vector2(randf_range(-70, -40), randf_range(-20, 10))
	match id:
		"rainbow":
			fx.dot(at, vel, randf_range(3.0, 5.0), 0.9, Color.from_hsv(fmod(t * 0.5, 1.0), 0.75, 1.0, 0.85))
		"gold":
			fx.dot(at, vel, randf_range(1.5, 3.0), 0.8, Color(1.0, 0.85, 0.3, 0.95))
			if randf() < 0.4:
				fx.sparkle(at, 3, Color(1.0, 0.85, 0.3))
		"hearts":
			fx.heart(at, vel + Vector2(0, -20), randf_range(4.0, 6.0), 1.0, Color(1.0, 0.35, 0.55))
		"stars":
			fx.star(at, vel, randf_range(4.0, 6.5), 1.0, Color.from_hsv(randf_range(0.1, 0.18), 0.6, 1.0))
		_:
			fx.bubble(at + Vector2(r * 2.4, 0), Vector2(randf_range(-40, -10), randf_range(-30, 0)), randf_range(2, 4), 1.2)


## Small static preview for shop cards.
static func draw_trail_preview(canvas: CanvasItem, id: String, center: Vector2) -> void:
	for k in 5:
		var p := center + Vector2(-k * 9.0, sin(k * 1.3) * 5.0)
		var s := 4.5 - k * 0.5
		match id:
			"rainbow":
				canvas.draw_circle(p, s, Color.from_hsv(k * 0.18, 0.75, 1.0), true, -1.0, true)
			"gold":
				canvas.draw_circle(p, s * 0.7, Color(1.0, 0.85, 0.3), true, -1.0, true)
			"hearts":
				FxLayer.draw_heart(canvas, p, s + 1.0, Color(1.0, 0.35, 0.55))
			"stars":
				FxLayer.draw_star(canvas, p, s + 1.5, Color(1.0, 0.9, 0.4))
			_:
				canvas.draw_arc(p, s, 0, TAU, 12, Color(1, 1, 1, 0.8), 1.2, true)
