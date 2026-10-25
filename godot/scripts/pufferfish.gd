class_name PufferFish
extends Node2D
## The player (US-04 physics, US-05 visuals). `step()` is driven per physics tick by the game scene.

var vel_up: float = 0.0
var inflate_level: float = 0.0
var is_inflating: bool = false
var skin: SkinDefinition
var hat := "none"
var shield := false:
	set(v):
		shield = v
		queue_redraw()

var _blink_timer := 0
var _is_blinking := false
var _wag := 0.0
var _wag_dir := 1.0
var _time := 0.0 # visual-only clock (fin flap, look direction)


func _ready() -> void:
	if skin == null:
		skin = SaveManager.get_selected_skin()
	hat = SaveManager.selected_hat


func inflate() -> void:
	is_inflating = true


func deflate() -> void:
	is_inflating = false


func get_radius() -> float:
	return Constants.FISH_BASE_RADIUS + inflate_level * Constants.FISH_RADIUS_PER_INFLATE


## One 60 Hz tick: physics, animation timers, redraw. Same order as PufferFish.update() in Swift.
func step() -> void:
	if is_inflating:
		inflate_level = minf(Constants.FISH_MAX_INFLATE, inflate_level + Constants.INFLATE_SPEED)
		vel_up += Constants.INFLATE_LIFT
	else:
		inflate_level = maxf(0.0, inflate_level - Constants.DEFLATE_SPEED)
		vel_up -= Constants.GRAVITY
	vel_up = clampf(vel_up, -Constants.MAX_VEL, Constants.MAX_VEL)
	position.y -= vel_up # Godot y points down

	_blink_timer += 1
	if _blink_timer >= Constants.BLINK_INTERVAL:
		_is_blinking = true
		_blink_timer = 0
	if _is_blinking and _blink_timer >= Constants.BLINK_DURATION:
		_is_blinking = false

	_time += 1.0 / 60.0
	_wag += 0.15 * _wag_dir
	if absf(_wag) > 2.0:
		_wag_dir *= -1.0

	queue_redraw()


func _body_color() -> Color:
	var ratio := inflate_level / Constants.FISH_MAX_INFLATE
	if ratio >= 0.8:
		return DrawUtil.darken(skin.body, 0.2)
	if ratio >= 0.5:
		return DrawUtil.darken(skin.body, 0.1)
	return skin.body


func _draw() -> void:
	var r := get_radius()
	var body := _body_color()
	var inflate_t := inflate_level / Constants.FISH_MAX_INFLATE

	# Visual-only squash/stretch and tilt from vertical speed (hitbox stays a circle of r)
	var stretch := clampf(vel_up * 0.012, -0.06, 0.06)
	draw_set_transform(Vector2.ZERO, -vel_up * 0.035, Vector2(1.0 - stretch * 0.5, 1.0 + stretch))

	# Spikes grow out from behind the body
	if inflate_level > 3.0:
		var count := mini(10, int(inflate_level * 1.1))
		var spine_r := clampf(inflate_level * 0.22, 1.2, 3.5)
		for i in count:
			var a := TAU * i / count
			_draw_spike(a, r, spine_r)

	# Tail with pixel-stepped wag
	var w := roundf(_wag) * 2.0
	DrawUtil.draw_polygon_stroked(self, PackedVector2Array([
		Vector2(-r * 1.05, -r * 0.55 + w), Vector2(-r * 1.05, r * 0.55 + w), Vector2(-r * 1.7, w),
	]), skin.tail, Color.BLACK, 3)
	DrawUtil.draw_triangle(self, Vector2(-r * 1.12, -r * 0.3 + w), Vector2(-r * 1.12, r * 0.3 + w), Vector2(-r * 1.5, w), DrawUtil.darken(skin.tail, 0.08))

	# Body with shading, belly, spots and highlights
	DrawUtil.draw_ellipse_stroked(self, Vector2.ZERO, r * 1.15, r, body, Color.BLACK, 3)
	DrawUtil.draw_ellipse(self, Vector2(0, r * 0.35), r * 0.95, r * 0.6, Color(DrawUtil.darken(body, 0.25), 0.28))
	var belly := DrawUtil.darken(body, 0.15)
	belly.a = 0.35
	DrawUtil.draw_ellipse(self, Vector2(r * 0.1, r * 0.425), r * 0.7, r * 0.425, belly)
	var spot := Color(DrawUtil.darken(body, 0.22), 0.55)
	for sp in [Vector2(-0.55, -0.45), Vector2(-0.2, -0.62), Vector2(0.12, -0.7), Vector2(-0.7, -0.05), Vector2(-0.35, -0.22)]:
		draw_circle(Vector2(sp.x * r, sp.y * r), r * 0.07, spot, true, -1.0, true)
	DrawUtil.draw_ellipse(self, Vector2(-r * 0.1, -r * 0.45), r * 0.7, r * 0.35, Color(1, 1, 1, 0.12))
	DrawUtil.draw_ellipse(self, Vector2(-r * 0.175, -r * 0.31), r * 0.375, r * 0.21, Color(1, 1, 1, 0.45))
	draw_circle(Vector2(-r * 0.32, -r * 0.4), r * 0.07, Color(1, 1, 1, 0.8), true, -1.0, true)

	# Pectoral fin (flaps faster while inflating)
	var flap := sin(_time * (16.0 if is_inflating else 7.0)) * 0.3
	DrawUtil.draw_fin(self, Vector2(-r * 0.12, r * 0.28), r * 0.28, r * 0.14, 0.45 + flap, Color(skin.tail.lightened(0.15), 0.95), 2.0)

	# Cheek + mouth
	draw_circle(Vector2(r * 0.78, r * 0.16), r * 0.12, Color(1.0, 0.45, 0.45, 0.3), true, -1.0, true)
	var mouth_open := inflate_t * r * 0.06
	draw_arc(Vector2(r * 1.02, r * 0.16), r * 0.09 + mouth_open, PI * 0.55, PI * 1.35, 10, Color.BLACK, 2.0, true)

	# Eye (pupil looks where the fish is heading)
	var eye := Vector2(r * 0.55, -r * 0.22)
	var eye_r := r * 0.30
	if _is_blinking:
		draw_line(eye + Vector2(-eye_r, 0), eye + Vector2(eye_r, 0), Color.BLACK, 4.0, true)
	else:
		DrawUtil.draw_circle_stroked(self, eye, eye_r, Color.WHITE, Color.BLACK, 3)
		var look := Vector2(eye_r * 0.18, clampf(-vel_up * 0.05, -0.22, 0.22) * eye_r)
		draw_circle(eye + look, eye_r * 0.6, skin.eye, true, -1.0, true)
		draw_circle(eye + look, eye_r * 0.35, Color.BLACK, true, -1.0, true)
		draw_circle(Vector2(r * 0.43, -r * 0.34) + look * 0.5, r * 0.045 + 0.8, Color.WHITE, true, -1.0, true)
	# Worried brow when fully puffed up
	if inflate_t > 0.7:
		var bt := (inflate_t - 0.7) / 0.3
		draw_line(eye + Vector2(-eye_r * 0.9, -eye_r * 1.35), eye + Vector2(eye_r * 0.7, -eye_r * (1.35 + 0.35 * bt)), Color.BLACK, 2.5, true)

	Cosmetics.draw_hat(self, hat, r)

	draw_set_transform(Vector2.ZERO)
	if shield:
		var sr := r * 1.75 + sin(_time * 4.0) * 1.5
		draw_circle(Vector2.ZERO, sr, Color(0.4, 0.8, 1.0, 0.16), true, -1.0, true)
		draw_arc(Vector2.ZERO, sr, 0, TAU, 40, Color(0.55, 0.9, 1.0, 0.85), 2.5, true)
		draw_arc(Vector2.ZERO, sr - 4, -2.4, -1.4, 10, Color(1, 1, 1, 0.7), 2.0, true)
	if Debug.show_hitboxes:
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(0, 1, 0, 0.9), 1.5)


## Spike from the body edge outwards at angle `a`; drawn before the body so its base is hidden.
func _draw_spike(a: float, r: float, spine_r: float) -> void:
	var n := Vector2(cos(a), sin(a))
	var base := Vector2(cos(a) * r * 1.08, sin(a) * r * 0.92) - n * spine_r
	var tangent := Vector2(-n.y, n.x)
	var length := spine_r * 3.2 + 2.0
	var half := spine_r * 1.1
	DrawUtil.draw_triangle(self, base - tangent * (half + 1.8), base + tangent * (half + 1.8), base + n * (length + 2.5), Color.BLACK)
	DrawUtil.draw_triangle(self, base - tangent * half, base + tangent * half, base + n * length, skin.spine)
