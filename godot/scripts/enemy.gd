class_name Enemy
extends Node2D
## Enemies (US-09 base, US-10 jellyfish, US-11 shark, US-12 urchin). One script, `match` per type.
## Shapes are Enemy.swift with every y mirrored for Godot.

enum Type { JELLYFISH, SHARK, URCHIN }

const JELLY_BODY := Color(0.608, 0.349, 0.714)
const JELLY_DARK := Color(0.490, 0.235, 0.596)
const SHARK_BODY := Color(0.365, 0.541, 0.659)
const SHARK_BELLY := Color(0.839, 0.918, 0.973)
const SHARK_TAIL := Color(0.29, 0.48, 0.59)
const URCHIN_BODY := Color(0.173, 0.243, 0.314)
const URCHIN_EYE := Color(0.910, 0.298, 0.235)
const URCHIN_SPINE := Color(0.933, 0.933, 0.933)

var enemy_type: Type = Type.JELLYFISH
var radius := 22.0
var time := 0.0
var base_y := 0.0
var is_dead := false
var vel_x := 0.0
var vel_y := 0.0
var screen_h := 852.0


static func create(type: Type, screen_size: Vector2) -> Enemy:
	var e := Enemy.new()
	e.enemy_type = type
	e.screen_h = screen_size.y
	e.z_index = Constants.ENEMY_Z
	match type:
		Type.JELLYFISH:
			e.radius = 22.0
			e.vel_x = -1.4
			e.position = Vector2(screen_size.x + 40, randf_range(80, screen_size.y - 80))
		Type.SHARK:
			e.radius = 32.0
			e.vel_x = -4.0
			e.position = Vector2(screen_size.x + 60, randf_range(60, screen_size.y - 60))
		Type.URCHIN:
			e.radius = 18.0
			e.vel_x = -2.2
			e.vel_y = 1.6 if randf() < 0.5 else -1.6
			e.position = Vector2(screen_size.x + 30, randf_range(60, screen_size.y - 60))
	e.base_y = e.position.y
	match type:
		Type.JELLYFISH:
			var glow := DrawUtil.make_glow(60.0, Color(0.75, 0.45, 1.0, 0.55))
			glow.position = Vector2(0, -10)
			e.add_child(glow)
		Type.URCHIN:
			e.add_child(DrawUtil.make_glow(26.0, Color(1.0, 0.35, 0.25, 0.35)))
	return e


func get_radius() -> float:
	return radius


## One 60 Hz tick.
## `factor` < 1 slows the enemy down (slow-motion power-up).
func step(factor := 1.0) -> void:
	time += Constants.ENEMY_TIME_STEP * factor
	position.x += vel_x * factor
	match enemy_type:
		Type.JELLYFISH:
			position.y = base_y + sin(time * 1.8) * 55.0
		Type.SHARK:
			position.y = base_y + sin(time * 0.6) * 20.0
		Type.URCHIN:
			position.y += vel_y * factor
			if position.y < 30.0 or position.y > screen_h - 30.0:
				vel_y *= -1.0
	if position.x < Constants.ENEMY_DESPAWN_X:
		is_dead = true
	if enemy_type != Type.SHARK or Debug.show_hitboxes:
		queue_redraw()


func _draw() -> void:
	match enemy_type:
		Type.JELLYFISH:
			_draw_jellyfish()
		Type.SHARK:
			_draw_shark()
		Type.URCHIN:
			_draw_urchin()
	if Debug.show_hitboxes:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1, 0.2, 0.2, 0.9), 1.5)


func _draw_jellyfish() -> void:
	var pulse := 1.0 + sin(time * 3.6) * 0.04
	# Tentacles: smooth wavy strands through the original segment positions
	for i in 6:
		var base_x := i * 8.0 - 20.0
		var pts := PackedVector2Array([Vector2(base_x, -4)])
		for j in 5:
			var off := sin(time * 2.0 + i * 0.8 + j * 0.4) * 4.0
			pts.append(Vector2(base_x + off, j * 8.0))
		draw_polyline(pts, Color(0, 0, 0, 0.6), 5.0, true)
		draw_polyline(pts, JELLY_DARK, 3.0, true)
		draw_polyline(pts, Color(JELLY_BODY.lightened(0.3), 0.6), 1.0, true)
	# Translucent bell
	DrawUtil.draw_ellipse(self, Vector2(0, -18), 24 * pulse, 18, Color.BLACK)
	DrawUtil.draw_ellipse(self, Vector2(0, -17), 20 * pulse, 15, JELLY_BODY)
	DrawUtil.draw_ellipse(self, Vector2(0, -12), 18 * pulse, 8, Color(JELLY_DARK, 0.45))
	DrawUtil.draw_ellipse(self, Vector2(0, -21), 15 * pulse, 9, Color(1, 0.85, 1, 0.18))
	DrawUtil.draw_ellipse(self, Vector2(-2, -22.5), 8, 4.5, Color(1, 1, 1, 0.5))
	for p in [Vector2(-8, -14), Vector2(0, -16), Vector2(8, -14)]:
		draw_circle(p, 3, JELLY_DARK, true, -1.0, true)
		draw_circle(p + Vector2(-0.8, -0.8), 1.0, Color(1, 0.8, 1, 0.6), true, -1.0, true)
	# Frilly rim
	for k in 7:
		draw_circle(Vector2((k - 3) * 6.0 * pulse, -3.5), 3.2, JELLY_BODY, true, -1.0, true)
	draw_circle(Vector2(0, -10), 7, Color.BLACK, true, -1.0, true)
	draw_circle(Vector2(0, -10), 5, Color.WHITE, true, -1.0, true)
	draw_circle(Vector2(1, -9), 3, Color.BLACK, true, -1.0, true)
	draw_circle(Vector2(-1, -11.5), 1.2, Color.WHITE, true, -1.0, true)


func _draw_shark() -> void:
	# Pectoral fin under the body
	DrawUtil.draw_triangle(self, Vector2(-8, 8), Vector2(6, 10), Vector2(-2, 24), Color.BLACK)
	DrawUtil.draw_triangle(self, Vector2(-6, 9), Vector2(4, 10), Vector2(-2, 21), SHARK_TAIL)
	DrawUtil.draw_ellipse(self, Vector2.ZERO, 36, 18, Color.BLACK)
	DrawUtil.draw_ellipse(self, Vector2.ZERO, 33, 16, SHARK_BODY)
	DrawUtil.draw_ellipse(self, Vector2(2, -7), 28, 7, Color(DrawUtil.darken(SHARK_BODY, 0.12), 0.8))
	DrawUtil.draw_ellipse(self, Vector2(3, 4), 19, 8, SHARK_BELLY)
	DrawUtil.draw_ellipse(self, Vector2(-8, -9), 12, 3, Color(1, 1, 1, 0.25))
	DrawUtil.draw_triangle(self, Vector2(-4, -16), Vector2(14, -16), Vector2(8, 0), Color.BLACK)
	DrawUtil.draw_triangle(self, Vector2(-2, -14), Vector2(12, -14), Vector2(7, 0), SHARK_BODY)
	DrawUtil.draw_triangle(self, Vector2(-1, -13), Vector2(4, -13), Vector2(5, -3), Color(1, 1, 1, 0.18))
	DrawUtil.draw_triangle(self, Vector2(30, 18), Vector2(42, 18), Vector2(30, 0), Color.BLACK)
	DrawUtil.draw_triangle(self, Vector2(30, 0), Vector2(42, -18), Vector2(30, -18), Color.BLACK)
	DrawUtil.draw_triangle(self, Vector2(31, 16), Vector2(40, 16), Vector2(31, 0), SHARK_TAIL)
	DrawUtil.draw_triangle(self, Vector2(31, 0), Vector2(40, -16), Vector2(31, -16), SHARK_TAIL)
	# Gills
	for g in 3:
		draw_arc(Vector2(-6 + g * 4.5, -1), 6, -0.9, 0.9, 6, Color(0, 0, 0, 0.5), 1.5, true)
	draw_circle(Vector2(-18, -4), 8, Color.BLACK, true, -1.0, true)
	draw_circle(Vector2(-18, -4), 6, Color.WHITE, true, -1.0, true)
	draw_circle(Vector2(-17, -3), 3, Color.BLACK, true, -1.0, true)
	draw_circle(Vector2(-19.5, -6), 1.3, Color.WHITE, true, -1.0, true)
	# Angry brow
	draw_line(Vector2(-25, -12), Vector2(-12, -8), Color.BLACK, 2.5, true)
	# Teeth — B12 fixed: at the mouth (x = -30 + i*7), not at the tail as in the Swift build.
	for i in 3:
		var tx := -30.0 + i * 7.0
		DrawUtil.draw_polygon_stroked(self, PackedVector2Array([
			Vector2(tx, 4), Vector2(tx + 6, 4), Vector2(tx + 3, 10),
		]), Color.WHITE, Color.BLACK, 1)


func _draw_urchin() -> void:
	draw_circle(Vector2.ZERO, 21, Color.BLACK, true, -1.0, true)
	draw_circle(Vector2.ZERO, 18, URCHIN_BODY, true, -1.0, true)
	draw_circle(Vector2(2, 3), 15, Color(DrawUtil.darken(URCHIN_BODY, 0.08), 0.8), true, -1.0, true)
	draw_circle(Vector2(-5, -5), 6, Color(1, 1, 1, 0.4), true, -1.0, true)
	draw_circle(Vector2.ZERO, 7, Color.BLACK, true, -1.0, true)
	draw_circle(Vector2.ZERO, 5, URCHIN_EYE, true, -1.0, true)
	draw_circle(Vector2(1, -1), 2.5, Color.BLACK, true, -1.0, true)
	draw_circle(Vector2(-1.5, -2), 1.0, Color.WHITE, true, -1.0, true)
	# 12 wobbling spines (base offset horizontally, as in the original)
	for i in 12:
		var a := TAU * i / 12.0
		var wobble := sin(time * 3.0 + i) * 2.0
		var inner := Vector2(cos(a), -sin(a)) * 18.0
		var tip := Vector2(cos(a), -sin(a)) * 30.0 + Vector2(wobble, wobble)
		DrawUtil.draw_triangle(self, inner + Vector2(-2, 0), tip, inner + Vector2(2, 0), Color.BLACK)
		DrawUtil.draw_triangle(self, inner + Vector2(-1, 0), tip, inner + Vector2(1, 0), URCHIN_SPINE)
