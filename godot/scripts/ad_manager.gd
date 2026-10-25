extends Node
## Consent → ATT → AdMob start (US-22), interstitials (US-23) and rewarded videos.
##
## Interstitial rules (player-friendly, replaces "every 3rd game over"):
##   • none during the first AD_GRACE_GAMES games a player ever plays
##   • at most one every AD_MIN_INTERVAL seconds (rewarded videos count too)
##   • still only every GAMES_BEFORE_AD-th game over
##   • never right after a new best, never in a run where the player watched a rewarded video
##   • shown when the player taps PLAY AGAIN / MAIN MENU, not when the game-over screen opens
##
## Order (same as PopPulse): nothing at launch; after the player's first finished game:
## UMP consent → our own short explainer → Apple's ATT prompt → Mobile Ads start.
##
## Talks to the native iOS singleton "PufferAds" (ios/plugins/PufferAds). Without it (editor,
## desktop, plugin not built) interstitials are skipped and — in debug builds only — rewarded
## videos are simulated so the revive / double-coins flows can be tested on a Mac.

signal rewarded_availability_changed(available: bool)

const NATIVE_SINGLETON := "PufferAds"

const PROD_INTERSTITIAL := "ca-app-pub-3366446717708247/8765817424"
const TEST_INTERSTITIAL := "ca-app-pub-3940256099942544/4411468910"
const PROD_REWARDED := "" ## TODO: create a rewarded ad unit in AdMob and paste its id here
const TEST_REWARDED := "ca-app-pub-3940256099942544/1712485313"
const TEST_DEVICE_IDS := ["SIMULATOR", "5538de831287f2fd84dfa736cfdea1d5"]

const SIMULATED_AD_TIME := 0.8

var games_since_ad := 0 # not persistent, resets on app restart
var is_ad_loaded := false
var is_rewarded_loaded := false

var _load_attempts := 0
var _rewarded_attempts := 0
var _started := false
var _flow_started := false
var _native: Object
var _last_ad_msec := -1
var _interstitial_pending := false
var _after_interstitial: Callable
var _rewarded_done: Callable
var _rewarded_earned := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton(NATIVE_SINGLETON):
		_native = Engine.get_singleton(NATIVE_SINGLETON)
		_native.connect("consent_finished", _on_consent_finished)
		_native.connect("tracking_finished", _on_tracking_finished)
		_native.connect("initialized", _on_initialized)
		_native.connect("interstitial_loaded", _on_loaded)
		_native.connect("interstitial_failed_to_load", _on_failed_to_load)
		_native.connect("interstitial_dismissed", _on_dismissed)
		_native.connect("interstitial_failed_to_show", _on_failed_to_show)
		_native.connect("rewarded_loaded", _on_rewarded_loaded)
		_native.connect("rewarded_failed_to_load", _on_rewarded_failed_to_load)
		_native.connect("rewarded_earned", func(): _rewarded_earned = true)
		_native.connect("rewarded_dismissed", _on_rewarded_closed)
		_native.connect("rewarded_failed_to_show", func(_m): _on_rewarded_closed())
	else:
		_log("no native ads plugin on this platform — interstitials off, rewarded %s" % ("simulated" if OS.is_debug_build() else "off"))


func interstitial_unit_id() -> String:
	return TEST_INTERSTITIAL if OS.is_debug_build() else PROD_INTERSTITIAL # B8


func rewarded_unit_id() -> String:
	return TEST_REWARDED if OS.is_debug_build() else PROD_REWARDED


# ── Interstitials ─────────────────────────────────────────────────

## Pure decision rule (unit-tested).
static func should_show_interstitial(lifetime_games: int, since_ad: int, seconds_since_last_ad: float, new_best: bool, watched_rewarded: bool) -> bool:
	if SaveManager.ads_removed:
		return false
	if lifetime_games <= Constants.AD_GRACE_GAMES:
		return false
	if new_best or watched_rewarded:
		return false
	if since_ad < Constants.GAMES_BEFORE_AD:
		return false
	return seconds_since_last_ad >= Constants.AD_MIN_INTERVAL


## Called when the GameOver screen opens. Decides whether the next button tap shows an ad.
func on_player_died(new_best := false, watched_rewarded := false) -> void:
	SaveManager.register_game_played()
	_start_flow() # consent → ATT → ads, once, after the first finished game
	games_since_ad += 1
	_interstitial_pending = should_show_interstitial(SaveManager.games_played, games_since_ad, _seconds_since_last_ad(), new_best, watched_rewarded)
	_log("game over #%d (since ad %d) → interstitial %s" % [SaveManager.games_played, games_since_ad, "pending" if _interstitial_pending else "skipped"])


## Called from the game-over buttons. Shows the pending interstitial (if any), then runs `then`.
func show_pending_interstitial(then: Callable) -> void:
	if not _interstitial_pending:
		then.call()
		return
	_interstitial_pending = false
	games_since_ad = 0 # reset even when nothing is loaded, to avoid spamming (parity)
	if is_ad_loaded and _native:
		_log("showing interstitial")
		_after_interstitial = then
		_mark_ad_shown()
		SoundManager.set_paused(true)
		is_ad_loaded = false
		_native.show_interstitial()
	else:
		_log("interstitial not ready, reloading")
		load_interstitial()
		then.call()


func load_interstitial() -> void:
	if _native == null or not _started:
		return
	_native.load_interstitial(interstitial_unit_id())


# ── Rewarded ──────────────────────────────────────────────────────

func can_show_rewarded() -> bool:
	if _native:
		return is_rewarded_loaded
	return OS.is_debug_build()


## Shows a rewarded video; `done(earned: bool)` runs after it closes.
func show_rewarded(done: Callable) -> void:
	if not can_show_rewarded():
		done.call(false)
		return
	_mark_ad_shown()
	if _native == null:
		_log("simulating rewarded video")
		await get_tree().create_timer(SIMULATED_AD_TIME).timeout
		done.call(true)
		return
	_rewarded_done = done
	_rewarded_earned = false
	is_rewarded_loaded = false
	rewarded_availability_changed.emit(false)
	SoundManager.set_paused(true)
	_native.show_rewarded()


func load_rewarded() -> void:
	if _native == null or not _started or rewarded_unit_id().is_empty():
		return
	_native.load_rewarded(rewarded_unit_id())


# ── Privacy options (UMP) ─────────────────────────────────────────

func is_privacy_options_required() -> bool:
	return _native != null and _native.is_privacy_options_required()


func show_privacy_options() -> void:
	if _native:
		_native.show_privacy_options()


# ── Startup flow: UMP consent (EEA/UK) → ATT → MobileAds.start ─────────

func _start_flow() -> void:
	if _native == null or _flow_started:
		return
	_flow_started = true
	_log("requesting UMP consent")
	_native.request_consent(OS.is_debug_build(), PackedStringArray(TEST_DEVICE_IDS))


func _on_consent_finished(_can_request_ads: bool) -> void:
	# Our explainer only when iOS will actually ask (status notDetermined = 0);
	# otherwise the native side reports the existing status straight away.
	if int(_native.tracking_status()) != 0:
		_native.request_tracking_authorization()
		return
	var panel := AttExplainerPanel.new()
	panel.continued.connect(func(): _native.request_tracking_authorization())
	get_tree().current_scene.add_child(panel)


func _on_tracking_finished(status: int) -> void:
	_log("ATT status %d, starting Mobile Ads" % status)
	_native.initialize(PackedStringArray(TEST_DEVICE_IDS) if OS.is_debug_build() else PackedStringArray())


func _on_initialized() -> void:
	_started = true
	_load_attempts = 0
	load_interstitial()
	load_rewarded()


# ── Callbacks ─────────────────────────────────────────────────────

func _on_loaded() -> void:
	is_ad_loaded = true
	_load_attempts = 0
	_log("interstitial loaded")


func _on_failed_to_load(message: String) -> void:
	is_ad_loaded = false
	_load_attempts += 1
	_log("interstitial failed to load (%d/%d): %s" % [_load_attempts, Constants.MAX_AD_LOAD_ATTEMPTS, message])
	if _load_attempts < Constants.MAX_AD_LOAD_ATTEMPTS:
		get_tree().create_timer(float(_load_attempts)).timeout.connect(load_interstitial)


func _on_dismissed() -> void:
	SoundManager.set_paused(false)
	_load_attempts = 0
	load_interstitial()
	_run_after_interstitial()


func _on_failed_to_show(message: String) -> void:
	_log("interstitial failed to show: %s" % message)
	SoundManager.set_paused(false)
	load_interstitial()
	_run_after_interstitial()


func _run_after_interstitial() -> void:
	if _after_interstitial.is_valid():
		var cb := _after_interstitial
		_after_interstitial = Callable()
		cb.call()


func _on_rewarded_loaded() -> void:
	is_rewarded_loaded = true
	_rewarded_attempts = 0
	rewarded_availability_changed.emit(true)


func _on_rewarded_failed_to_load(message: String) -> void:
	is_rewarded_loaded = false
	_rewarded_attempts += 1
	_log("rewarded failed to load (%d/%d): %s" % [_rewarded_attempts, Constants.MAX_AD_LOAD_ATTEMPTS, message])
	if _rewarded_attempts < Constants.MAX_AD_LOAD_ATTEMPTS:
		get_tree().create_timer(float(_rewarded_attempts)).timeout.connect(load_rewarded)


func _on_rewarded_closed() -> void:
	SoundManager.set_paused(false)
	_rewarded_attempts = 0
	load_rewarded()
	if _rewarded_done.is_valid():
		var cb := _rewarded_done
		_rewarded_done = Callable()
		cb.call(_rewarded_earned)


func _mark_ad_shown() -> void:
	_last_ad_msec = Time.get_ticks_msec()


func _seconds_since_last_ad() -> float:
	if _last_ad_msec < 0:
		return INF
	return (Time.get_ticks_msec() - _last_ad_msec) / 1000.0


func _log(msg: String) -> void:
	if OS.is_debug_build():
		print("[AdManager] ", msg)
