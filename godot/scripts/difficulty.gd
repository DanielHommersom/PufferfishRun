class_name Difficulty
## Linear difficulty ramps from GameScene.swift (US-07, US-26).


static func _t(score: int, ramp: int) -> float:
	return minf(float(score) / float(ramp), 1.0)


static func gap_size(score: int) -> float:
	return lerpf(Constants.GAP_SIZE_INITIAL, Constants.GAP_SIZE_MIN, _t(score, Constants.DIFFICULTY_RAMP_GAP))


static func speed(score: int) -> float:
	return lerpf(Constants.OBSTACLE_SPEED_INITIAL, Constants.OBSTACLE_SPEED_MAX, _t(score, Constants.DIFFICULTY_RAMP_SPEED))


static func spawn_interval(score: int) -> float:
	return lerpf(Constants.SPAWN_INTERVAL_INITIAL, Constants.SPAWN_INTERVAL_MIN, _t(score, Constants.DIFFICULTY_RAMP_SPAWN))


static func moving_obstacle_chance(score: int) -> float:
	if score < Constants.MOVING_OBSTACLE_MIN_SCORE:
		return 0.0
	return Constants.MOVING_OBSTACLE_MAX_CHANCE * _t(score - Constants.MOVING_OBSTACLE_MIN_SCORE, Constants.DIFFICULTY_RAMP_SPEED)


static func moving_obstacle_speed(score: int) -> float:
	return lerpf(Constants.MOVING_OBSTACLE_SPEED_MIN, Constants.MOVING_OBSTACLE_SPEED_MAX, _t(score, Constants.DIFFICULTY_RAMP_SPEED))


static func available_enemies(score: int) -> Array[int]:
	var out: Array[int] = []
	if score >= Constants.ENEMY_JELLYFISH_MIN_SCORE:
		out.append(Enemy.Type.JELLYFISH)
	if score >= Constants.ENEMY_SHARK_MIN_SCORE:
		out.append(Enemy.Type.SHARK)
	if score >= Constants.ENEMY_URCHIN_MIN_SCORE:
		out.append(Enemy.Type.URCHIN)
	return out


static func medal(score: int) -> Dictionary:
	if score >= Constants.MEDAL_GOLD:
		return {"label": "GOLD", "color": Color(0.969, 0.761, 0.204)}
	if score >= Constants.MEDAL_SILVER:
		return {"label": "SILVER", "color": Color(0.753, 0.753, 0.753)}
	if score >= Constants.MEDAL_BRONZE:
		return {"label": "BRONZE", "color": Color(0.804, 0.498, 0.196)}
	return {}


## Circle vs rect (GameScene.circleCollidesRect).
static func circle_hits_rect(center: Vector2, r: float, rect: Rect2) -> bool:
	var near := Vector2(clampf(center.x, rect.position.x, rect.end.x), clampf(center.y, rect.position.y, rect.end.y))
	return center.distance_squared_to(near) < r * r
