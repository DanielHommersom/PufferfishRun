extends Node
## Ads via the Poing Studios AdMob plugin (addons/admob, v5.1 — same setup as PopPulse) plus
## Godotx ATT for Apple's tracking prompt. Rewarded videos (revive, 2× coins, free coins, start
## shield) and interstitials.
##
## Order (same as PopPulse): nothing at launch; after the player's first finished game:
## UMP consent (Google's GDPR form where required) → our own explainer → Apple ATT → Mobile Ads.
## Later launches remember the outcome and start ads straight away, without prompts.
##
## Interstitial rules (player-friendly):
##   • none during the first AD_GRACE_GAMES games a player ever plays
##   • at most one every AD_MIN_INTERVAL seconds (rewarded videos count too)
##   • only every GAMES_BEFORE_AD-th game over
##   • never right after a new best, never in a run where the player watched a rewarded video
##   • never after "Remove Ads"
##   • shown when the player taps PLAY AGAIN / MAIN MENU, not when the game-over screen opens
##
## Without the native plugins (editor, desktop) interstitials are skipped and — in debug builds
## only — rewarded videos are simulated so the flows can be tested on a Mac.

signal rewarded_availability_changed(available: bool)

const ADMOB_SINGLETON := "PoingGodotAdMob"
const ATT_SINGLETON := "GodotxATT"

## Release ad units (AdMob app ca-app-pub-3366446717708247~2391980768).
const PROD_REWARDED := "ca-app-pub-3366446717708247/9385094409"
const PROD_INTERSTITIAL := "ca-app-pub-3366446717708247/8765817424"
## Google's official test units (debug builds).
const TEST_REWARDED := "ca-app-pub-3940256099942544/1712485313"
const TEST_INTERSTITIAL := "ca-app-pub-3940256099942544/4411468910"

const SIMULATED_AD_TIME := 0.8
const LOAD_RETRY := 30.0

var games_since_ad := 0 # not persistent, resets on app restart
var ads_started := false

var _admob := false
var _initialized := false
var _personalized := false
var _rewarded: RewardedAd
var _interstitial: InterstitialAd
var _loaders: Array = [] ## loader objects must stay referenced while they load
var _last_ad_msec := -1
var _interstitial_pending := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_admob = Engine.has_singleton(ADMOB_SINGLETON)
	if not _admob:
		_log("no AdMob plugin on this platform — interstitials off, rewarded %s" % ("simulated" if OS.is_debug_build() else "off"))
	elif SaveManager.ads_consent_done:
		# Consent was handled in an earlier session: start right away, no prompts.
		call_deferred("start_flow")


func rewarded_unit_id() -> String:
	return TEST_REWARDED if OS.is_debug_build() else PROD_REWARDED


func interstitial_unit_id() -> String:
	return TEST_INTERSTITIAL if OS.is_debug_build() else PROD_INTERSTITIAL


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


## Called when the GameOver screen opens. Decides whether the next button tap shows an
## interstitial. (The consent flow normally ran at launch already; this is a fallback.)
func on_player_died(new_best := false, watched_rewarded := false) -> void:
	SaveManager.register_game_played()
	start_flow()
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
	var ad := _interstitial
	if ad == null:
		_log("interstitial not ready")
		then.call()
		return
	_interstitial = null
	_mark_ad_shown()
	SoundManager.set_paused(true)
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		SoundManager.set_paused(false)
		ad.destroy()
		_load_interstitial()
		then.call()
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_e: AdError) -> void:
		SoundManager.set_paused(false)
		ad.destroy()
		_load_interstitial()
		then.call()
	ad.show()


# ── Rewarded ──────────────────────────────────────────────────────

func can_show_rewarded() -> bool:
	if _admob:
		return _rewarded != null
	return OS.is_debug_build()


## Shows a rewarded video; `done(earned: bool)` runs after it closes.
func show_rewarded(done: Callable) -> void:
	if not can_show_rewarded():
		done.call(false)
		return
	_mark_ad_shown()
	if not _admob:
		_log("simulating rewarded video")
		await get_tree().create_timer(SIMULATED_AD_TIME).timeout
		done.call(true)
		return
	var ad := _rewarded
	_rewarded = null
	rewarded_availability_changed.emit(false)
	SoundManager.set_paused(true)
	var earned := [false]
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		# Reward and dismiss both arrive deferred from the native side; give a reward that
		# lands just after the dismiss a moment so it isn't lost (PopPulse).
		var until := Time.get_ticks_msec() + 500
		while not earned[0] and Time.get_ticks_msec() < until:
			await get_tree().process_frame
		SoundManager.set_paused(false)
		ad.destroy()
		_load_rewarded()
		done.call(earned[0])
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_e: AdError) -> void:
		SoundManager.set_paused(false)
		ad.destroy()
		_load_rewarded()
		done.call(false)
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void: earned[0] = true
	ad.show(listener)


# ── Startup flow: UMP consent → explainer → ATT → MobileAds.initialize ─────

## Runs once per launch, from the menu right after the splash: on a fresh install it shows the
## consent form (where required), our explainer and Apple's tracking prompt before any ad data
## is collected; later launches start the ads straight away without prompts.
func start_flow() -> void:
	if not _admob or ads_started:
		return
	ads_started = true
	var consent := "obtained"
	var tracking := "authorized"
	if SaveManager.ads_consent_done:
		_personalized = SaveManager.ads_personalized
	else:
		consent = await _request_consent()
		tracking = await _request_tracking()
		_personalized = consent in ["obtained", "not_required"] and tracking == "authorized"
		SaveManager.ads_consent_done = true
		SaveManager.ads_personalized = _personalized
		SaveManager.save()
	_log("consent %s, tracking %s → %s ads" % [consent, tracking, "personalised" if _personalized else "non-personalised"])
	_initialize_ads()


## Google's User Messaging Platform; shows the GDPR form where required.
## Resolves to "obtained" | "not_required" | "denied" | "error".
func _request_consent() -> String:
	var info := UserMessagingPlatform.consent_information
	var done := [""]
	info.update(ConsentRequestParameters.new(),
		func() -> void: done[0] = "updated",
		func(_e: FormError) -> void: done[0] = "error")
	while done[0] == "":
		await get_tree().process_frame
	if done[0] == "error":
		return "error"
	if info.get_is_consent_form_available() and info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		done[0] = ""
		UserMessagingPlatform.load_consent_form(
			func(form: ConsentForm) -> void:
				form.show(func(_e: FormError) -> void: done[0] = "shown"),
			func(_e: FormError) -> void: done[0] = "shown")
		while done[0] == "":
			await get_tree().process_frame
	return _consent_string()


func _consent_string() -> String:
	match UserMessagingPlatform.consent_information.get_consent_status():
		ConsentInformation.ConsentStatus.OBTAINED:
			return "obtained"
		ConsentInformation.ConsentStatus.NOT_REQUIRED:
			return "not_required"
	return "denied"


## Apple ATT after consent: our explainer first (only when iOS will actually ask), then the
## system dialog. Denied / restricted → non-personalised ads.
func _request_tracking() -> String:
	if not Engine.has_singleton(ATT_SINGLETON):
		return "unavailable"
	var att: Object = Engine.get_singleton(ATT_SINGLETON)
	if int(att.get_status()) == 0: # not determined yet
		var panel := AttExplainerPanel.new()
		var closed := [false]
		panel.continued.connect(func(): closed[0] = true)
		get_tree().current_scene.add_child(panel)
		while not closed[0] and is_instance_valid(panel):
			await get_tree().process_frame
		att.request_permission()
		var until := Time.get_ticks_msec() + 120000
		while int(att.get_status()) == 0 and Time.get_ticks_msec() < until:
			await get_tree().create_timer(0.25).timeout
	return ["not_determined", "restricted", "denied", "authorized"][clampi(int(att.get_status()), 0, 3)]


func _initialize_ads() -> void:
	if _initialized:
		return
	_initialized = true
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_load_rewarded()
		_load_interstitial()
	MobileAds.initialize(listener)


func _request() -> AdRequest:
	var req := AdRequest.new()
	if not _personalized:
		req.extras = {"npa": "1"} # non-personalised ads when consent/tracking was refused
	return req


func _load_rewarded() -> void:
	if rewarded_unit_id().is_empty():
		return
	var loader := RewardedAdLoader.new()
	_loaders.append(loader)
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded = ad
		_loaders.erase(loader)
		rewarded_availability_changed.emit(true)
	cb.on_ad_failed_to_load = func(e: LoadAdError) -> void:
		_loaders.erase(loader)
		_log("rewarded failed to load: %s" % e.message)
		_retry(_load_rewarded)
	loader.load(rewarded_unit_id(), _request(), cb)


func _load_interstitial() -> void:
	if interstitial_unit_id().is_empty() or SaveManager.ads_removed:
		return
	var loader := InterstitialAdLoader.new()
	_loaders.append(loader)
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial = ad
		_loaders.erase(loader)
	cb.on_ad_failed_to_load = func(e: LoadAdError) -> void:
		_loaders.erase(loader)
		_log("interstitial failed to load: %s" % e.message)
		_retry(_load_interstitial)
	loader.load(interstitial_unit_id(), _request(), cb)


func _retry(fn: Callable) -> void:
	await get_tree().create_timer(LOAD_RETRY).timeout
	fn.call()


# ── Privacy options (Settings) ────────────────────────────────────

## True when Google says the player must be able to revisit consent (EEA, UK, CH, some US
## states). Known once the consent flow has run.
func is_privacy_options_required() -> bool:
	if not _admob or not ads_started:
		return false
	return UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED


func show_privacy_options() -> void:
	if not _admob:
		return
	var done := [false]
	UserMessagingPlatform.show_privacy_options_form(func(_e: FormError) -> void: done[0] = true)
	while not done[0]:
		await get_tree().process_frame
	var consent := _consent_string()
	var tracking_ok := Engine.has_singleton(ATT_SINGLETON) and int(Engine.get_singleton(ATT_SINGLETON).get_status()) == 3
	_personalized = consent in ["obtained", "not_required"] and tracking_ok
	SaveManager.ads_personalized = _personalized
	SaveManager.save()


func _mark_ad_shown() -> void:
	_last_ad_msec = Time.get_ticks_msec()


func _seconds_since_last_ad() -> float:
	if _last_ad_msec < 0:
		return INF
	return (Time.get_ticks_msec() - _last_ad_msec) / 1000.0


func _log(msg: String) -> void:
	if OS.is_debug_build():
		print("[AdManager] ", msg)
