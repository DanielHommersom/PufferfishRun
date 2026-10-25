extends Node
## Persistent progress (US-02) + one-time migration from the Swift build's NSUserDefaults (US-25).
## Key names match the Swift UserDefaults keys.

signal high_score_changed(value: int)
signal skin_changed(id: String)
signal mute_changed(muted: bool)
signal coins_changed(value: int)
signal owned_skins_changed
signal ads_removed_changed(removed: bool)
signal cosmetics_changed

const SAVE_PATH := "user://save.cfg"
const TEST_SAVE_PATH := "user://save_test.cfg" ## used by tests/*.gd so they never touch real progress

var high_score: int = 0:
	set(value):
		if value == high_score:
			return
		high_score = value
		_save()
		high_score_changed.emit(value)

var selected_skin: String = "default":
	set(value):
		if not SkinLibrary.has_id(value):
			value = "default"
		if value == selected_skin:
			return
		selected_skin = value
		_save()
		skin_changed.emit(value)

var is_muted: bool = false:
	set(value):
		if value == is_muted:
			return
		is_muted = value
		_save()
		mute_changed.emit(value)

var coins: int = 0:
	set(value):
		value = maxi(0, value)
		if value == coins:
			return
		coins = value
		_save()
		coins_changed.emit(value)

var owned_skins: PackedStringArray = PackedStringArray()
var owned_items: PackedStringArray = PackedStringArray() ## hats/trails as "hat:crown", "trail:gold"
var selected_hat := "none"
var selected_trail := "bubbles"
var free_coins_date := ""
var free_coins_used := 0

# Settings toggles
var vibration := true:
	set(v):
		vibration = v
		_save()
var screen_shake := true:
	set(v):
		screen_shake = v
		_save()
var language := "auto":
	set(v):
		language = v
		_apply_language()
		_save()

# Ads consent flow (UMP + ATT) — remembered so later launches start ads without prompts
var ads_consent_done := false
var ads_personalized := false

# Daily reward / missions / challenge
var daily_last_claim := ""
var daily_streak := 0
var missions_date := ""
var missions: Array = [] ## [{type, target, reward, progress, claimed}]
var challenge_date := ""
var challenge_best := 0
var challenge_claimed := false

## Non-consumable "Remove Ads" purchase: disables interstitials (rewarded stays optional).
var ads_removed := false:
	set(value):
		if value == ads_removed:
			return
		ads_removed = value
		_save()
		ads_removed_changed.emit(value)
var games_played: int = 0 ## lifetime count, used for the ad grace period

## Writes are batched: a change marks the save dirty and it is written at most once per
## SAVE_DELAY seconds (and immediately when the app goes to the background or quits), so a
## burst of coins never hits the flash storage on every pickup (that caused hitches on iOS).
const SAVE_DELAY := 1.5

var _cfg := ConfigFile.new()
var _dirty := false
var _save_timer: Timer
var _loading := false


var _path := SAVE_PATH


func _init() -> void:
	# Decided at construction, before any setter can write.
	for arg in OS.get_cmdline_args():
		if arg.begins_with("res://tests/"):
			_path = TEST_SAVE_PATH
			DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH)) # fresh every run


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DELAY
	_save_timer.timeout.connect(flush)
	add_child(_save_timer)
	_load()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_PREDELETE:
			flush()


## Writes pending changes to disk now.
func flush() -> void:
	if not _dirty:
		return
	_dirty = false
	if _save_timer and not _save_timer.is_stopped():
		_save_timer.stop()
	_write()


## Stores the score only when it beats the record. Returns true for a new record (B2 fix basis).
func submit_score(score: int) -> bool:
	if score > high_score:
		high_score = score
		return true
	return false


func add_coins(amount: int) -> void:
	coins += amount


func is_skin_unlocked(skin: SkinDefinition) -> bool:
	return skin.is_unlocked(high_score, owned_skins)


## Buys a skin with coins. Returns false when it can't be bought or is too expensive.
func buy_skin(skin: SkinDefinition) -> bool:
	if skin.price <= 0 or is_skin_unlocked(skin) or coins < skin.price:
		return false
	owned_skins.append(skin.id)
	coins -= skin.price # saves
	owned_skins_changed.emit()
	return true


func owns_item(kind: String, id: String) -> bool:
	return Cosmetics.price_of(kind, id) == 0 or owned_items.has("%s:%s" % [kind, id])


## Buys a hat or trail. Returns false when already owned or too expensive.
func buy_item(kind: String, id: String) -> bool:
	var price := Cosmetics.price_of(kind, id)
	if price <= 0 or owns_item(kind, id) or coins < price:
		return false
	owned_items.append("%s:%s" % [kind, id])
	coins -= price # saves
	cosmetics_changed.emit()
	return true


func equip_item(kind: String, id: String) -> void:
	if not owns_item(kind, id):
		return
	if kind == "hat":
		selected_hat = id
	else:
		selected_trail = id
	_save()
	cosmetics_changed.emit()


## Rewarded "free coins" in the shop: limited per calendar day.
func free_coins_left() -> int:
	var today := Time.get_date_string_from_system()
	if free_coins_date != today:
		return Constants.FREE_COINS_PER_DAY
	return maxi(0, Constants.FREE_COINS_PER_DAY - free_coins_used)


func claim_free_coins() -> bool:
	if free_coins_left() <= 0:
		return false
	var today := Time.get_date_string_from_system()
	if free_coins_date != today:
		free_coins_date = today
		free_coins_used = 0
	free_coins_used += 1
	coins += Constants.FREE_COINS_AMOUNT # saves
	return true


## Public save for helpers (Daily) that mutate the arrays above.
func is_test_run() -> bool:
	return _path == TEST_SAVE_PATH


func save() -> void:
	_save()


func _apply_language() -> void:
	var loc := OS.get_locale() if language == "auto" else language
	TranslationServer.set_locale(loc)


func register_game_played() -> void:
	games_played += 1
	_save()


func get_selected_skin() -> SkinDefinition:
	return SkinLibrary.get_by_id(selected_skin)


func _load() -> void:
	_loading = true
	var err := _cfg.load(_path)
	if err == OK:
		high_score = int(_cfg.get_value("progress", "highScore", 0))
		selected_skin = str(_cfg.get_value("progress", "selectedSkin", "default"))
		is_muted = bool(_cfg.get_value("settings", "isMuted", false))
		coins = int(_cfg.get_value("progress", "coins", 0))
		owned_skins = PackedStringArray(_cfg.get_value("progress", "ownedSkins", PackedStringArray()))
		games_played = int(_cfg.get_value("progress", "gamesPlayed", 0))
		owned_items = PackedStringArray(_cfg.get_value("progress", "ownedItems", PackedStringArray()))
		selected_hat = str(_cfg.get_value("progress", "selectedHat", "none"))
		selected_trail = str(_cfg.get_value("progress", "selectedTrail", "bubbles"))
		free_coins_date = str(_cfg.get_value("progress", "freeCoinsDate", ""))
		free_coins_used = int(_cfg.get_value("progress", "freeCoinsUsed", 0))
		ads_removed = bool(_cfg.get_value("purchases", "adsRemoved", false))
		vibration = bool(_cfg.get_value("settings", "vibration", true))
		ads_consent_done = bool(_cfg.get_value("ads", "consentDone", false))
		ads_personalized = bool(_cfg.get_value("ads", "personalized", false))
		screen_shake = bool(_cfg.get_value("settings", "screenShake", true))
		language = str(_cfg.get_value("settings", "language", "auto"))
		daily_last_claim = str(_cfg.get_value("daily", "lastClaim", ""))
		daily_streak = int(_cfg.get_value("daily", "streak", 0))
		missions_date = str(_cfg.get_value("daily", "missionsDate", ""))
		missions = _cfg.get_value("daily", "missions", [])
		challenge_date = str(_cfg.get_value("daily", "challengeDate", ""))
		challenge_best = int(_cfg.get_value("daily", "challengeBest", 0))
		challenge_claimed = bool(_cfg.get_value("daily", "challengeClaimed", false))
	elif not _cfg.get_value("meta", "migrated", false):
		_migrate_legacy()
	_loading = false
	_apply_language()
	_save()
	flush()


## US-25: take over the three keys the Swift build left in NSUserDefaults, exactly once (on the
## first launch of the Godot build, when there is no save.cfg yet). iOS only; tests never read it.
func _migrate_legacy() -> void:
	if OS.has_feature("ios") and not is_test_run():
		var legacy := LegacyDefaults.read()
		if not legacy.is_empty():
			high_score = int(legacy.get("highScore", 0))
			selected_skin = str(legacy.get("selectedSkin", "default"))
			is_muted = bool(legacy.get("isMuted", false))
			if OS.is_debug_build():
				print("[SaveManager] migrated legacy defaults: ", legacy)
	_cfg.set_value("meta", "migrated", true)


func _save() -> void:
	if _loading:
		return
	_dirty = true
	if _save_timer == null or not _save_timer.is_inside_tree():
		flush()
	elif _save_timer.is_stopped():
		_save_timer.start()


func _write() -> void:
	_cfg.set_value("progress", "highScore", high_score)
	_cfg.set_value("progress", "selectedSkin", selected_skin)
	_cfg.set_value("settings", "isMuted", is_muted)
	_cfg.set_value("progress", "coins", coins)
	_cfg.set_value("progress", "ownedSkins", owned_skins)
	_cfg.set_value("progress", "gamesPlayed", games_played)
	_cfg.set_value("progress", "ownedItems", owned_items)
	_cfg.set_value("progress", "selectedHat", selected_hat)
	_cfg.set_value("progress", "selectedTrail", selected_trail)
	_cfg.set_value("progress", "freeCoinsDate", free_coins_date)
	_cfg.set_value("progress", "freeCoinsUsed", free_coins_used)
	_cfg.set_value("purchases", "adsRemoved", ads_removed)
	_cfg.set_value("settings", "vibration", vibration)
	_cfg.set_value("ads", "consentDone", ads_consent_done)
	_cfg.set_value("ads", "personalized", ads_personalized)
	_cfg.set_value("settings", "screenShake", screen_shake)
	_cfg.set_value("settings", "language", language)
	_cfg.set_value("daily", "lastClaim", daily_last_claim)
	_cfg.set_value("daily", "streak", daily_streak)
	_cfg.set_value("daily", "missionsDate", missions_date)
	_cfg.set_value("daily", "missions", missions)
	_cfg.set_value("daily", "challengeDate", challenge_date)
	_cfg.set_value("daily", "challengeBest", challenge_best)
	_cfg.set_value("daily", "challengeClaimed", challenge_claimed)
	_cfg.set_value("meta", "migrated", true)
	_cfg.save(_path)
