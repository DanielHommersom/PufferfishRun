class_name ObstacleColumn
extends Node2D
## One half of a coral pillar, drawn once (US-06). The jagged edge, moss and flowers point
## into the gap. `extra` extends the far end so a moving pillar (US-26) never shows a seam.

const W := Constants.OBSTACLE_WIDTH
const BASE := Color(0.545, 0.102, 0.102)
const LIGHT := Color(0.647, 0.125, 0.125)
const DARK := Color(0.420, 0.063, 0.063)
const PATTERN := [8, 4, 12, 4, 8, 12, 4, 8, 4, 12, 8, 4, 12, 8, 4, 4, 12, 8, 4, 8]
const MOSS := [Color(0.176, 0.541, 0.243), Color(0.267, 0.667, 0.333)]
const PETAL := Color(0.957, 0.627, 0.125)
const HEART := Color(0.910, 0.365, 0.0)

var is_top := true
var y_start := 0.0 # visible column start (local)
var y_end := 0.0 # visible column end (local)
var extra := 0.0


func _draw() -> void:
	var y0 := y_start - (extra if is_top else 0.0)
	var y1 := y_end + (0.0 if is_top else extra)
	var h := y1 - y0
	# Soft drop shadow for depth (visual only, hitbox is the flat 80 px pillar)
	draw_rect(Rect2(6, y0, W, h), Color(0, 0, 0, 0.18))
	# Horizontal light → shadow gradient
	var pts := PackedVector2Array([Vector2(0, y0), Vector2(W, y0), Vector2(W, y1), Vector2(0, y1)])
	var mid := PackedVector2Array([Vector2(8, y0), Vector2(W * 0.45, y0), Vector2(W * 0.45, y1), Vector2(8, y1)])
	draw_polygon(pts, PackedColorArray([LIGHT, DARK, DARK, LIGHT]))
	draw_polygon(mid, PackedColorArray([Color(LIGHT, 0.0), Color(BASE.lightened(0.08), 0.9), Color(BASE.lightened(0.08), 0.9), Color(LIGHT, 0.0)]))
	draw_rect(Rect2(0, y0, 8, h), LIGHT)
	draw_rect(Rect2(3, y0, 3, h), Color(1, 0.75, 0.7, 0.22))
	draw_rect(Rect2(W - 10, y0, 10, h), DARK)
	var line_color := Color(DARK, 0.14)
	var ly := y_start - ceilf(extra / 12.0) * 12.0 if is_top else y_start
	while ly < y1:
		if ly >= y0:
			draw_rect(Rect2(0, ly, W, 1), line_color)
		ly += 12.0
	# Deterministic pores and polyps for an organic texture
	var k := 0
	var py := y0 + 14.0
	while py < y1 - 6.0:
		var px := 14.0 + float((k * 37) % 52)
		var pr := 2.0 + float((k * 13) % 3)
		draw_circle(Vector2(px, py), pr + 1.0, Color(DARK, 0.6), true, -1.0, true)
		draw_circle(Vector2(px - 0.6, py - 0.6), pr * 0.5, Color(1, 0.6, 0.55, 0.35), true, -1.0, true)
		py += 17.0 + float((k * 7) % 9)
		k += 1

	var edge := y_end if is_top else y_start
	_draw_jagged(edge, is_top)
	_draw_moss(edge - 16.0 if is_top else edge + 2.0)
	_draw_flowers(y_start, y_end - y_start)


func _draw_jagged(edge_y: float, pointing_down: bool) -> void:
	var block_w := 4.0
	for i in int(W / block_w):
		var bh: float = PATTERN[i % PATTERN.size()]
		var y := edge_y if pointing_down else edge_y - bh
		draw_rect(Rect2(i * block_w, y, block_w, bh), DARK)
	for i in int(W / 2.0):
		var p: float = PATTERN[i % PATTERN.size()]
		var dy := edge_y + p + 1.0 if pointing_down else edge_y - p - 3.0
		draw_rect(Rect2(i * 2.0, dy, 2, 2), BASE if i % 2 == 0 else DARK)


func _draw_moss(y: float) -> void:
	for i in 8:
		var mx := i * 10.0 + float((i * 7) % 5)
		var my := y + float((i * 3) % 8) - 4.0
		var s := 6.0 if i % 3 == 0 else 4.0
		draw_rect(Rect2(mx, my, s, s), MOSS[i % 2])


func _draw_flowers(column_y: float, column_h: float) -> void:
	if column_h <= 60.0:
		return
	var count := 1 if column_h < 100.0 else (3 if column_h < 250.0 else 5)
	var spacing := column_h / (count + 1)
	for i in count:
		var c := Vector2(20.0 + float((i * 23) % 40), column_y + spacing * (i + 1))
		for p in 6:
			var a := TAU * p / 6.0
			var pc := c + Vector2(cos(a), sin(a)) * 9.0
			draw_circle(pc, 6, Color.BLACK, true, -1.0, true)
			draw_circle(pc, 5, PETAL, true, -1.0, true)
			draw_circle(pc - Vector2(1.5, 1.5), 1.8, Color(1, 1, 0.8, 0.6), true, -1.0, true)
		draw_circle(c, 8, Color.BLACK, true, -1.0, true)
		draw_circle(c, 7, HEART, true, -1.0, true)
		draw_circle(c - Vector2(2, 2), 2.5, Color(1, 0.8, 0.4, 0.7), true, -1.0, true)
