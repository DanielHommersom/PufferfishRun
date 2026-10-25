class_name DrawUtil
## Shared vector-drawing helpers (replaces SKShapeNode paths) and the static "menu fish".

const ELLIPSE_SEGMENTS := 40

static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load(Constants.FONT_PATH)
	return _font


## SKColor.darken(by:) — subtract per RGB channel, clamped at 0.
static func darken(color: Color, amount: float) -> Color:
	return Color(maxf(0.0, color.r - amount), maxf(0.0, color.g - amount), maxf(0.0, color.b - amount), color.a)


static func ellipse_points(center: Vector2, rx: float, ry: float, segments: int = ELLIPSE_SEGMENTS) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.resize(segments)
	for i in segments:
		var a := TAU * i / segments
		pts[i] = center + Vector2(cos(a) * rx, sin(a) * ry)
	return pts


## Rotated ellipse with outline — used for fins.
static func draw_fin(canvas: CanvasItem, center: Vector2, rx: float, ry: float, angle: float, fill: Color, stroke_width: float) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry).rotated(angle))
	canvas.draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	canvas.draw_polyline(pts, Color.BLACK, stroke_width, true)
	# fin rays
	for k in 3:
		var d := Vector2(-rx * 0.8, (k - 1) * ry * 0.5).rotated(angle)
		canvas.draw_line(center + Vector2(rx * 0.6, 0).rotated(angle), center + d, Color(0, 0, 0, 0.25), 1.0, true)


static func draw_ellipse(canvas: CanvasItem, center: Vector2, rx: float, ry: float, color: Color) -> void:
	canvas.draw_colored_polygon(ellipse_points(center, rx, ry), color)


## Filled ellipse with a centred stroke of `width` px (SKShapeNode lineWidth).
static func draw_ellipse_stroked(canvas: CanvasItem, center: Vector2, rx: float, ry: float, fill: Color, stroke: Color, width: float) -> void:
	draw_ellipse(canvas, center, rx + width * 0.5, ry + width * 0.5, stroke)
	draw_ellipse(canvas, center, maxf(0.0, rx - width * 0.5), maxf(0.0, ry - width * 0.5), fill)


## Fill + ring outline; works with translucent fills (e.g. bubbles).
static func draw_circle_stroked(canvas: CanvasItem, center: Vector2, r: float, fill: Color, stroke: Color, width: float) -> void:
	canvas.draw_circle(center, r, fill, true, -1.0, true)
	canvas.draw_arc(center, r, 0.0, TAU, maxi(16, int(r * 2.0)), stroke, width, true)


## draw_primitive: no triangulation, so (near-)degenerate triangles never error.
static func draw_triangle(canvas: CanvasItem, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	canvas.draw_primitive(PackedVector2Array([a, b, c]), PackedColorArray([color, color, color]), PackedVector2Array())


static func draw_polygon_stroked(canvas: CanvasItem, pts: PackedVector2Array, fill: Color, stroke: Color, width: float) -> void:
	canvas.draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	canvas.draw_polyline(closed, stroke, width, true)


static func draw_rounded_rect(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(round(radius)))
	sb.anti_aliasing = true
	sb.draw(canvas.get_canvas_item(), rect)


static func draw_rounded_rect_bordered(canvas: CanvasItem, rect: Rect2, radius: float, fill: Color, border: Color, border_width: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(int(round(border_width)))
	sb.set_corner_radius_all(int(round(radius)))
	sb.anti_aliasing = true
	sb.draw(canvas.get_canvas_item(), rect)


## Largest font size ≤ `size` at which `text` fits in `max_width` (min 7) — for long translations.
static func fit_font_size(text: String, size: int, max_width: float) -> int:
	var f := font()
	var s := size
	while s > 7 and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x > max_width:
		s -= 1
	return s


## Draws centred text with its baseline at `baseline`.
static func draw_text_centered(canvas: CanvasItem, text: String, baseline: Vector2, size: int, color: Color) -> void:
	var f := font()
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	canvas.draw_string(f, Vector2(baseline.x - w * 0.5, baseline.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## Draws centred text vertically centred on `center` (SKLabelNode verticalAlignmentMode = .center).
static func draw_text_middle(canvas: CanvasItem, text: String, center: Vector2, size: int, color: Color) -> void:
	var f := font()
	var baseline_y := center.y + (f.get_ascent(size) - f.get_descent(size)) * 0.5
	draw_text_centered(canvas, text, Vector2(center.x, baseline_y), size, color)


## Static fish used by menu (r 52, 8 spines), splash (r 62, 10 spines). Black +3 px outline
## around the body instead of a stroke, exactly like MenuScene.drawMenuFish. y is mirrored for Godot.
static func draw_menu_fish(canvas: CanvasItem, skin: SkinDefinition, r: float, spine_count: int, time := 0.0) -> void:
	# Spikes behind the body
	for i in spine_count:
		var a := TAU * i / spine_count
		var n := Vector2(cos(a), -sin(a))
		var base := Vector2(cos(a) * r * 1.1, -sin(a) * r * 0.95) - n * 2.0
		var t := Vector2(-n.y, n.x)
		var len := r * 0.36
		draw_triangle(canvas, base - t * (r * 0.13 + 3), base + t * (r * 0.13 + 3), base + n * (len + 5), Color.BLACK)
		draw_triangle(canvas, base - t * r * 0.13, base + t * r * 0.13, base + n * len, skin.spine)
	# Tail
	var wag := sin(time * 3.0) * r * 0.06
	draw_triangle(canvas, Vector2(-r * 1.1, -r * 0.55 + wag), Vector2(-r * 1.1, r * 0.55 + wag), Vector2(-r * 1.7, wag), Color.BLACK)
	draw_triangle(canvas, Vector2(-r * 1.0, -r * 0.48 + wag), Vector2(-r * 1.0, r * 0.48 + wag), Vector2(-r * 1.6, wag), skin.tail)
	draw_triangle(canvas, Vector2(-r * 1.08, -r * 0.26 + wag), Vector2(-r * 1.08, r * 0.26 + wag), Vector2(-r * 1.42, wag), darken(skin.tail, 0.08))
	# Body + shading
	draw_ellipse(canvas, Vector2.ZERO, r * 1.15 + 3, r + 3, Color.BLACK)
	draw_ellipse(canvas, Vector2.ZERO, r * 1.15, r, skin.body)
	draw_ellipse(canvas, Vector2(0, r * 0.35), r * 0.95, r * 0.6, Color(darken(skin.body, 0.25), 0.28))
	draw_ellipse(canvas, Vector2(r * 0.1, r * 0.425), r * 0.7, r * 0.425, Color(darken(skin.body, 0.15), 0.35))
	for sp in [Vector2(-0.55, -0.45), Vector2(-0.2, -0.62), Vector2(0.12, -0.7), Vector2(-0.7, -0.05), Vector2(-0.35, -0.22)]:
		canvas.draw_circle(Vector2(sp.x * r, sp.y * r), r * 0.07, Color(darken(skin.body, 0.22), 0.55), true, -1.0, true)
	draw_ellipse(canvas, Vector2(-r * 0.1, -r * 0.45), r * 0.7, r * 0.35, Color(1, 1, 1, 0.12))
	draw_ellipse(canvas, Vector2(-r * 0.2, -r * 0.35), r * 0.375, r * 0.21, Color(1, 1, 1, 0.45))
	canvas.draw_circle(Vector2(-r * 0.34, -r * 0.42), r * 0.07, Color(1, 1, 1, 0.8), true, -1.0, true)
	# Fin, cheek, mouth
	draw_fin(canvas, Vector2(-r * 0.12, r * 0.28), r * 0.28, r * 0.14, 0.45 + sin(time * 6.0) * 0.25, Color(skin.tail.lightened(0.15), 0.95), 2.5)
	canvas.draw_circle(Vector2(r * 0.8, r * 0.16), r * 0.12, Color(1.0, 0.45, 0.45, 0.3), true, -1.0, true)
	canvas.draw_arc(Vector2(r * 1.02, r * 0.16), r * 0.09, PI * 0.55, PI * 1.35, 12, Color.BLACK, 3.0, true)
	# Eye
	canvas.draw_circle(Vector2(r * 0.55, -r * 0.22), r * 0.32 + 3, Color.BLACK, true, -1.0, true)
	canvas.draw_circle(Vector2(r * 0.55, -r * 0.22), r * 0.30, Color.WHITE, true, -1.0, true)
	canvas.draw_circle(Vector2(r * 0.58, -r * 0.20), r * 0.18, skin.eye, true, -1.0, true)
	canvas.draw_circle(Vector2(r * 0.61, -r * 0.18), r * 0.10, Color.BLACK, true, -1.0, true)
	canvas.draw_circle(Vector2(r * 0.52, -r * 0.27), r * 0.07, Color.WHITE, true, -1.0, true)


## Mini fish on a skin card (r 22, 6 spines, 2 px outlines) — SkinSelectScene.drawMinifish.
static func draw_card_fish(canvas: CanvasItem, skin: SkinDefinition, locked: bool) -> void:
	var r := 22.0
	if locked:
		draw_ellipse(canvas, Vector2.ZERO, r * 1.15, r, Color(0.1, 0.1, 0.15))
		draw_text_middle(canvas, "?", Vector2.ZERO, 20, Color(0.2, 0.3, 0.4))
		return
	draw_polygon_stroked(canvas, PackedVector2Array([Vector2(-r, -r * 0.48), Vector2(-r, r * 0.48), Vector2(-r * 1.6, 0)]), skin.tail, Color.BLACK, 2)
	draw_ellipse_stroked(canvas, Vector2.ZERO, r * 1.15, r, skin.body, Color.BLACK, 2)
	for i in 6:
		var a := TAU * i / 6
		draw_circle_stroked(canvas, Vector2(cos(a) * r * 1.05, -sin(a) * r * 0.92), 3, skin.spine, Color.BLACK, 1)
	draw_circle_stroked(canvas, Vector2(r * 0.55, -r * 0.22), r * 0.28, Color.WHITE, Color.BLACK, 2)
	canvas.draw_circle(Vector2(r * 0.60, -r * 0.20), r * 0.12, skin.eye)


## Safe-area insets in viewport units (notch / Dynamic Island / home indicator).
static func safe_insets(viewport: Viewport) -> Dictionary:
	var vp_size := viewport.get_visible_rect().size
	var win_size := Vector2(DisplayServer.window_get_size())
	var safe := DisplayServer.get_display_safe_area()
	if not OS.has_feature("mobile") or win_size.x <= 0 or safe.size.x <= 0:
		return {"top": 0.0, "bottom": 0.0}
	var scale := vp_size.y / win_size.y
	var top := maxf(0.0, safe.position.y) * scale
	var bottom := maxf(0.0, win_size.y - safe.end.y) * scale
	return {"top": top, "bottom": bottom}


static var _glow_tex: Texture2D


## Soft additive glow sprite (radial white → transparent), tinted by `color`.
static func make_glow(radius: float, color: Color) -> Sprite2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.35, Color(1, 1, 1, 0.45))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 128
		tex.height = 128
		_glow_tex = tex
	var s := Sprite2D.new()
	s.texture = _glow_tex
	s.scale = Vector2.ONE * (radius * 2.0 / 128.0)
	s.modulate = color
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	s.material = m
	s.show_behind_parent = true
	return s


## Gold coin; `spin` (−1…1) squashes it horizontally to fake a 3D spin.
static func draw_coin(canvas: CanvasItem, center: Vector2, r: float, spin := 1.0) -> void:
	var sx := maxf(0.15, absf(spin))
	draw_ellipse(canvas, center, r * sx + 2.0, r + 2.0, Color.BLACK)
	draw_ellipse(canvas, center, r * sx, r, Color(0.851, 0.584, 0.051))
	draw_ellipse(canvas, center + Vector2(0, -r * 0.08), r * sx * 0.78, r * 0.78, Color(1.0, 0.8, 0.2))
	if sx > 0.5:
		canvas.draw_rect(Rect2(center.x - r * 0.12 * sx, center.y - r * 0.4, r * 0.24 * sx, r * 0.8), Color(0.851, 0.584, 0.051))
	draw_ellipse(canvas, center + Vector2(-r * 0.3 * sx, -r * 0.35), r * 0.22 * sx, r * 0.16, Color(1, 1, 1, 0.75))
