class_name Daily
## Daily reward streak, three daily missions and the daily challenge.
## Days are local calendar days (device time zone). State lives in SaveManager.

const MISSION_POOL := [
	# type, targets (pick one), reward per target
	{"type": "coins", "targets": [10, 15, 20], "rewards": [30, 45, 60]},
	{"type": "score", "targets": [8, 12, 18], "rewards": [30, 50, 80]},
	{"type": "pillars", "targets": [25, 40, 60], "rewards": [30, 45, 60]},
	{"type": "games", "targets": [3, 5, 8], "rewards": [25, 35, 50]},
	{"type": "near", "targets": [3, 5, 8], "rewards": [35, 50, 70]},
	{"type": "powerups", "targets": [2, 3, 5], "rewards": [35, 50, 70]},
	{"type": "zone", "targets": [1, 2, 3], "rewards": [35, 55, 80]},
]

## Challenge modifiers, one per day (rotates).
const MODIFIERS := ["FAST CURRENT", "NARROW GAPS", "JELLY SWARM", "COIN RUSH", "MOVING CORAL", "SHARK ALLEY"]


static func day_index(offset_days := 0) -> int:
	var bias_min: int = Time.get_time_zone_from_system().get("bias", 0)
	return int(floor((Time.get_unix_time_from_system() + bias_min * 60.0) / 86400.0)) + offset_days


static func _today() -> String:
	return str(day_index())


# ── Daily reward ──────────────────────────────────────────────────

static func reward_available() -> bool:
	return SaveManager.daily_last_claim != _today()


## Day 1…7 of the streak that today's claim would be.
static func streak_day() -> int:
	if SaveManager.daily_last_claim == str(day_index(-1)):
		return (SaveManager.daily_streak % Constants.DAILY_REWARDS.size()) + 1
	if SaveManager.daily_last_claim == _today():
		return ((SaveManager.daily_streak - 1) % Constants.DAILY_REWARDS.size()) + 1
	return 1


## Seconds until the next local midnight (when the next reward unlocks).
static func seconds_until_tomorrow() -> int:
	var bias_min: int = Time.get_time_zone_from_system().get("bias", 0)
	var local := Time.get_unix_time_from_system() + bias_min * 60.0
	return int(86400.0 - fposmod(local, 86400.0))


static func reward_amount(day: int) -> int:
	return Constants.DAILY_REWARDS[clampi(day, 1, Constants.DAILY_REWARDS.size()) - 1]


## Claims today's reward (× multiplier, e.g. 2 after a rewarded video). Returns coins given.
static func claim_reward(multiplier := 1) -> int:
	if not reward_available():
		return 0
	var day := streak_day()
	var amount := reward_amount(day) * multiplier
	SaveManager.daily_streak = day
	SaveManager.daily_last_claim = _today()
	SaveManager.add_coins(amount) # saves
	return amount


# ── Missions ──────────────────────────────────────────────────────

## Generates today's three missions once per day (deterministic per day).
static func ensure_missions() -> void:
	if SaveManager.missions_date == _today() and SaveManager.missions.size() == Constants.MISSIONS_PER_DAY:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = day_index() * 2654435761
	var pool := MISSION_POOL.duplicate()
	var list: Array = []
	for i in Constants.MISSIONS_PER_DAY:
		var k := rng.randi_range(0, pool.size() - 1)
		var def: Dictionary = pool[k]
		pool.remove_at(k)
		var level := rng.randi_range(0, 2)
		list.append({"type": def.type, "target": def.targets[level], "reward": def.rewards[level], "progress": 0, "claimed": false})
	SaveManager.missions = list
	SaveManager.missions_date = _today()
	SaveManager.save()


## Adds progress. `as_max` means the value is a best-of (score, zone) instead of a sum.
## Returns the missions that became complete because of this report.
static func report(type: String, value: int, as_max := false) -> Array:
	ensure_missions()
	var completed: Array = []
	for m in SaveManager.missions:
		if m.type != type or m.claimed or m.progress >= m.target:
			continue
		m.progress = maxi(m.progress, value) if as_max else m.progress + value
		m.progress = mini(m.progress, m.target)
		if m.progress >= m.target:
			completed.append(m)
	SaveManager.save()
	return completed


static func claimable_count() -> int:
	ensure_missions()
	var n := 0
	for m in SaveManager.missions:
		if not m.claimed and m.progress >= m.target:
			n += 1
	return n


static func claim_mission(index: int) -> int:
	var m: Dictionary = SaveManager.missions[index]
	if m.claimed or m.progress < m.target:
		return 0
	m.claimed = true
	SaveManager.add_coins(m.reward) # saves
	return m.reward


static func mission_text(m: Dictionary) -> String:
	match m.type:
		"coins":
			return TranslationServer.translate("COLLECT %d COINS") % m.target
		"score":
			return TranslationServer.translate("SCORE %d IN ONE RUN") % m.target
		"pillars":
			return TranslationServer.translate("PASS %d PILLARS") % m.target
		"games":
			return TranslationServer.translate("PLAY %d GAMES") % m.target
		"near":
			return TranslationServer.translate("GET %d NEAR MISSES") % m.target
		"powerups":
			return TranslationServer.translate("GRAB %d POWER-UPS") % m.target
		"zone":
			return TranslationServer.translate("REACH THE %s") % TranslationServer.translate(Constants.ZONE_NAMES[m.target])
	return ""


# ── Daily challenge ───────────────────────────────────────────────

static func challenge_modifier() -> String:
	return MODIFIERS[posmod(day_index(), MODIFIERS.size())]


static func challenge_seed() -> int:
	return day_index() * 7919 + 17


static func _ensure_challenge_day() -> void:
	if SaveManager.challenge_date != _today():
		SaveManager.challenge_date = _today()
		SaveManager.challenge_best = 0
		SaveManager.challenge_claimed = false
		SaveManager.save()


static func challenge_best() -> int:
	_ensure_challenge_day()
	return SaveManager.challenge_best


static func challenge_claimed() -> bool:
	_ensure_challenge_day()
	return SaveManager.challenge_claimed


## Records a challenge run. Returns the coins awarded (only the first time the target is hit).
static func report_challenge(score: int) -> int:
	_ensure_challenge_day()
	SaveManager.challenge_best = maxi(SaveManager.challenge_best, score)
	var reward := 0
	if score >= Constants.CHALLENGE_TARGET and not SaveManager.challenge_claimed:
		SaveManager.challenge_claimed = true
		reward = Constants.CHALLENGE_REWARD
		SaveManager.add_coins(reward)
	SaveManager.save()
	return reward
