class_name BubbleField
extends Node2D
## Rising bubbles (US-13), reused by game, menu, splash and game over.
## Each bubble rises (screen height + 40) in 4–8 s, then restarts below the screen at a new x.

@export var count := 8
@export var radius_min := 6.0
@export var radius_max := 16.0
@export var fill_alpha := 0.15
@export var outline := true
@export var start_delay_max := 0.0 ## random 0..max delay before a bubble starts moving
@export var start_below := false ## start below the screen instead of at a random y
@export var duration_min := 4.0
@export var duration_max := 8.0

var _bubbles: Array[Dictionary] = []
var _size := Vector2.ZERO


func _ready() -> void:
	_size = get_viewport_rect().size
	for i in count:
		var b := {
			"r": randf_range(radius_min, radius_max),
			"pos": Vector2(randf_range(20, _size.x - 20), _size.y + 20 if start_below else randf_range(0, _size.y)),
			"duration": randf_range(duration_min, duration_max),
			"delay": randf_range(0, start_delay_max),
			"travelled": 0.0,
			"phase": randf() * TAU,
		}
		_bubbles.append(b)


func _process(delta: float) -> void:
	var dist := _size.y + 40.0
	for b in _bubbles:
		if b.delay > 0.0:
			b.delay -= delta
			continue
		var step: float = dist / b.duration * delta
		b.pos.y -= step
		b.travelled += step
		if b.travelled >= dist:
			b.travelled = 0.0
			b.pos = Vector2(randf_range(20, _size.x - 20), _size.y + 20)
	queue_redraw()


func _draw() -> void:
	var fill := Color(1, 1, 1, fill_alpha)
	var t := Time.get_ticks_msec() / 1000.0
	for b in _bubbles:
		# Gentle side-to-side wobble while rising (visual only)
		var p: Vector2 = b.pos + Vector2(sin(t * 2.0 + b.phase) * b.r * 0.25, 0)
		if outline:
			DrawUtil.draw_circle_stroked(self, p, b.r, fill, Color(0, 0, 0, 0.75), 2)
		else:
			draw_circle(p, b.r, fill, true, -1.0, true)
		# Specular glint + rim light
		draw_circle(p + Vector2(-b.r * 0.38, -b.r * 0.38), b.r * 0.22, Color(1, 1, 1, 0.55), true, -1.0, true)
		draw_arc(p, b.r * 0.72, 0.2, 1.3, 8, Color(1, 1, 1, 0.25), 1.5, true)
