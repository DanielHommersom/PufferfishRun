class_name OceanBackground
extends Node2D
## Animated ocean (US-13, US-27): shader gradient with god rays and caustics, parallax reef,
## drifting marine snow and bubbles. Darkens per depth zone with a 2 s tween.

const SHADER := preload("res://shaders/ocean.gdshader")

@export var parallax := true ## scrolling reef silhouettes (game only)
@export var bubble_count := 8
@export var start_zone := 0

var _rect: ColorRect
var _mat: ShaderMaterial
var _reefs: Array[ParallaxReef] = []
var _decor := {} ## kind -> ZoneDecor
var _zone := 0
var _tween: Tween
var _depth_label: Label
var _scroll := 0.0
var _w := 393.0


func _ready() -> void:
	z_index = -10
	var s := get_viewport_rect().size
	_w = s.x
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("aspect", s.x / s.y)
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.size = s
	_rect.material = _mat
	add_child(_rect)

	if parallax:
		for kind in ["wreck", "kelp", "abyss"]:
			var d := ZoneDecor.new()
			d.kind = kind
			add_child(d)
			_decor[kind] = d
		_add_reef(0.15, Color(0, 0.03, 0.07, 0.22), 120.0, 50.0, 0.0, 0)
		_add_reef(0.35, Color(0, 0.03, 0.06, 0.38), 60.0, 30.0, 0.37, 6)

	add_child(_make_snow(s))
	if bubble_count > 0:
		var bubbles := BubbleField.new()
		bubbles.count = bubble_count
		add_child(bubbles)

	if Constants.DEPTH_LABEL_ENABLED:
		_setup_depth_label(s)
	_zone = start_zone
	_apply_zone(start_zone, false)


func _add_reef(factor: float, color: Color, base: float, amp: float, seed: float, weeds: int) -> void:
	var r := ParallaxReef.new()
	r.factor = factor
	r.color = color
	r.base_height = base
	r.amplitude = amp
	r.seed_offset = seed
	r.seaweed = weeds
	add_child(r)
	_reefs.append(r)


## Floating particles ("marine snow") that drift slowly upward and sideways.
static func _make_snow(s: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 40
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = s / 2.0
	p.position = s / 2.0
	p.direction = Vector2(-0.4, -1)
	p.spread = 25.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 12.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.5
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.2, Color(1, 1, 1, 0.35))
	ramp.add_point(0.8, Color(1, 1, 1, 0.35))
	p.color_ramp = ramp
	return p


## Per tick from the game: scroll the parallax layers with the pillar speed.
func scroll(speed: float) -> void:
	for r in _reefs:
		r.scroll(speed)
	for d in _decor.values():
		d.scroll(speed)
	_scroll += speed * 0.1 / _w
	_mat.set_shader_parameter("scroll", _scroll)


func zone_for_score(score: int) -> int:
	var z := 0
	for i in Constants.ZONE_MIN_SCORES.size():
		if score >= Constants.ZONE_MIN_SCORES[i]:
			z = i
	return z


## Returns true when this score moved the ocean into a new depth zone.
func update_score(score: int) -> bool:
	var target := zone_for_score(score)
	if target == _zone:
		return false
	_zone = target
	_apply_zone(target, true)
	if _depth_label:
		_update_depth_label(target)
	return true


func current_zone() -> int:
	return _zone


func _apply_zone(index: int, animated: bool) -> void:
	var zone: Array = Constants.ZONE_COLORS[index]
	var active: String = Constants.ZONE_DECOR[index]
	for kind in _decor:
		var target := 1.0 if kind == active else 0.0
		if animated:
			create_tween().tween_property(_decor[kind], "modulate:a", target, Constants.ZONE_TWEEN_TIME)
		else:
			_decor[kind].modulate.a = target
	var params := {"top_color": zone[0], "mid_color": zone[1], "bottom_color": zone[2], "ray_alpha": zone[3]}
	if not animated:
		for k in params:
			_mat.set_shader_parameter(k, params[k])
		return
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel()
	for k in params:
		var from = _mat.get_shader_parameter(k)
		_tween.tween_method(func(v): _mat.set_shader_parameter(k, v), from, params[k], Constants.ZONE_TWEEN_TIME)


## US-27: placed bottom-left so it no longer overlaps the mute button at (w−50, h−50).
func _setup_depth_label(s: Vector2) -> void:
	_depth_label = Label.new()
	_depth_label.text = Constants.ZONE_NAMES[0]
	_depth_label.add_theme_font_size_override("font_size", 11)
	_depth_label.modulate = Color(1, 1, 1, 0.35)
	_depth_label.position = Vector2(12, s.y - 62 - DrawUtil.safe_insets(get_viewport()).bottom)
	_depth_label.z_index = 20
	_depth_label.z_as_relative = false
	add_child(_depth_label)


func _update_depth_label(zone: int) -> void:
	var t := create_tween()
	t.tween_property(_depth_label, "modulate:a", 0.0, 0.3)
	t.tween_callback(func(): _depth_label.text = Constants.ZONE_NAMES[zone])
	t.tween_property(_depth_label, "modulate:a", 0.35, 0.3)
