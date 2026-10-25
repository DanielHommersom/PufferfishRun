class_name ParallaxReef
extends Node2D
## Tileable silhouette reef along the bottom edge that scrolls slower than the pillars.
## Heights come from a periodic sum of sines, so the strip repeats seamlessly every screen width.

var factor := 0.25 ## fraction of the pillar speed
var color := Color(0, 0.04, 0.08, 0.25)
var base_height := 70.0
var amplitude := 40.0
var seed_offset := 0.0
var seaweed := 0 ## number of swaying seaweed strands per screen width
var seaweed_color := Color(0.05, 0.25, 0.2, 0.55)

var _w := 393.0
var _h := 852.0
var _offset := 0.0
var _time := 0.0
var _profile := PackedVector2Array()
var _weeds: Array[Vector3] = [] # x, height, phase


func _ready() -> void:
	var s := get_viewport_rect().size
	_w = s.x
	_h = s.y
	var steps := 48
	for i in steps + 1:
		var u := float(i) / steps
		var y := base_height + amplitude * (0.5 * sin(TAU * (u * 2.0 + seed_offset)) + 0.3 * sin(TAU * (u * 5.0 + seed_offset * 1.7)) + 0.2 * sin(TAU * (u * 9.0 + seed_offset * 3.1)))
		_profile.append(Vector2(u * _w, _h - y))
	for i in seaweed:
		var u := (i + 0.5 + 0.3 * sin(i * 12.9898 + seed_offset * 7.0)) / seaweed
		_weeds.append(Vector3(u * _w, 40.0 + 30.0 * absf(sin(i * 4.1 + seed_offset)), i * 1.3))


## Called per tick with the current pillar speed (px/tick). Moves the layer itself (cheap and
## interpolated on 120 Hz screens) instead of redrawing it.
func scroll(speed: float) -> void:
	var before := _offset
	_offset = fposmod(_offset + speed * factor, _w)
	position.x = -_offset
	if _offset < before: # wrapped: jump without interpolating across the screen
		reset_physics_interpolation()


func _process(delta: float) -> void:
	if seaweed > 0: # only the swaying weeds need a redraw; the silhouette is static
		_time += delta
		queue_redraw()


func _draw() -> void:
	for tile in 2:
		var dx := tile * _w
		var poly := PackedVector2Array()
		for p in _profile:
			poly.append(p + Vector2(dx, 0))
		poly.append(Vector2(_w + dx, _h + 2))
		poly.append(Vector2(dx, _h + 2))
		draw_colored_polygon(poly, color)
		for wd in _weeds:
			var x: float = wd.x + dx
			if x < -30 or x > _w + 30:
				continue
			_draw_weed(x, wd.y, wd.z)


func _draw_weed(x: float, height: float, phase: float) -> void:
	var base_y := _h - base_height * 0.6
	var pts := PackedVector2Array()
	var segs := 8
	for j in segs + 1:
		var f := float(j) / segs
		var sway := sin(_time * 1.6 + phase + f * 2.5) * 6.0 * f
		pts.append(Vector2(x + sway, base_y - height * f))
	draw_polyline(pts, seaweed_color, 5.0, true)
	draw_polyline(pts, Color(seaweed_color.lightened(0.25), seaweed_color.a * 0.8), 2.0, true)
