class_name Obstacle
extends Node2D
## A coral pillar pair with a gap (US-06). Drawn once; only the position changes.
## Optional vertical movement of the gap (US-26) shifts the two halves, it never redraws.

var gap_y := 0.0
var gap_size := 0.0
var passed := false
var screen_h := 852.0

var is_moving := false
var move_speed := 0.0
var move_range := 0.0
var current_gap_y := 0.0
var _move_dir := 1.0

var coin: Coin
var power_up: PowerUp
var min_clearance := INF ## closest the fish came while overlapping horizontally (near-miss)
var _top: ObstacleColumn
var _bottom: ObstacleColumn


func setup(p_gap_y: float, p_gap_size: float, p_screen_h: float, p_move_speed := 0.0, p_move_range := 0.0) -> void:
	gap_y = p_gap_y
	gap_size = p_gap_size
	screen_h = p_screen_h
	current_gap_y = gap_y
	is_moving = p_move_speed > 0.0 and p_move_range > 0.0
	move_speed = p_move_speed
	move_range = p_move_range
	var extra := move_range + Constants.MOVING_OBSTACLE_EDGE if is_moving else 0.0

	_top = ObstacleColumn.new()
	_top.is_top = true
	_top.y_start = 0.0
	_top.y_end = gap_y - gap_size / 2.0
	_top.extra = extra
	_top.show_behind_parent = true
	add_child(_top)

	_bottom = ObstacleColumn.new()
	_bottom.is_top = false
	_bottom.y_start = gap_y + gap_size / 2.0
	_bottom.y_end = screen_h
	_bottom.extra = extra
	_bottom.show_behind_parent = true
	add_child(_bottom)


func add_coin() -> void:
	coin = Coin.new()
	coin.position = Vector2(Constants.OBSTACLE_WIDTH / 2.0, gap_y)
	add_child(coin)


func add_power_up(type: PowerUp.Type) -> void:
	power_up = PowerUp.new()
	power_up.type = type
	power_up.position = Vector2(Constants.OBSTACLE_WIDTH / 2.0, gap_y)
	add_child(power_up)


## Per tick: horizontal scroll is done by the game; this handles optional gap movement.
func step() -> void:
	if not is_moving:
		return
	current_gap_y += move_speed * _move_dir
	if current_gap_y > gap_y + move_range:
		_move_dir = -1.0
	if current_gap_y < gap_y - move_range:
		_move_dir = 1.0
	var min_y := gap_size / 2.0 + Constants.MOVING_OBSTACLE_EDGE
	var max_y := screen_h - gap_size / 2.0 - Constants.MOVING_OBSTACLE_EDGE
	current_gap_y = clampf(current_gap_y, min_y, max_y)
	var offset := current_gap_y - gap_y
	_top.position.y = offset
	_bottom.position.y = offset
	if coin:
		coin.position.y = gap_y + offset
	if power_up:
		power_up.position.y = gap_y + offset
	queue_redraw()


## Collision rects in world space: the flat pillar only (jagged edge/flowers don't count).
func top_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y - 10000.0, Constants.OBSTACLE_WIDTH, 10000.0 + current_gap_y - gap_size / 2.0)


func bottom_rect() -> Rect2:
	return Rect2(global_position.x, global_position.y + current_gap_y + gap_size / 2.0, Constants.OBSTACLE_WIDTH, 9999.0)


func _draw() -> void:
	if Debug.show_hitboxes:
		var t := top_rect()
		var b := bottom_rect()
		t.position -= global_position
		b.position -= global_position
		t = t.intersection(Rect2(0, -10, Constants.OBSTACLE_WIDTH, screen_h + 20))
		b = b.intersection(Rect2(0, -10, Constants.OBSTACLE_WIDTH, screen_h + 20))
		draw_rect(t, Color(0, 1, 0, 0.9), false, 1.5)
		draw_rect(b, Color(0, 1, 0, 0.9), false, 1.5)
