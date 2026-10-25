extends Node
## Sound effects + ambience (US-20) and mute (US-21).
## All sounds are synthesised in Godot by tools/generate_sfx.gd into assets/audio/*.wav.
## A small player pool lets sounds overlap (chime while inflating); the inflate sound still
## restarts itself, like the single player of the original. Ambience loops on its own bus.

const SFX_BUS := "SFX"
const AMBIENCE_BUS := "Ambience"
const POOL_SIZE := 6
const AMBIENCE_DB := -14.0

const SOUNDS := {
	"inflate": [preload("res://assets/audio/inflate.wav"), -3.0, 0.06],
	"release": [preload("res://assets/audio/release.wav"), -8.0, 0.08],
	"score": [preload("res://assets/audio/score.wav"), -4.0, 0.0],
	"game_over": [preload("res://assets/audio/game_over.wav"), -1.0, 0.0],
	"new_best": [preload("res://assets/audio/new_best.wav"), -3.0, 0.0],
	"zone": [preload("res://assets/audio/zone.wav"), -4.0, 0.0],
	"click": [preload("res://assets/audio/click.wav"), -5.0, 0.08],
	"confirm": [preload("res://assets/audio/confirm.wav"), -4.0, 0.0],
	"tick": [preload("res://assets/audio/tick.wav"), -10.0, 0.04],
	"splash": [preload("res://assets/audio/splash.wav"), -4.0, 0.0],
	"coin": [preload("res://assets/audio/coin.wav"), -5.0, 0.03],
	"revive": [preload("res://assets/audio/revive.wav"), -3.0, 0.0],
	"buy": [preload("res://assets/audio/buy.wav"), -3.0, 0.0],
} # name: [stream, volume dB, random pitch ±]
const AMBIENCE := preload("res://assets/audio/ambience.wav")

var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _inflate_player: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _ambience_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus(SFX_BUS)
	_ensure_bus(AMBIENCE_BUS)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_pool.append(p)
	_inflate_player = AudioStreamPlayer.new()
	_inflate_player.bus = SFX_BUS
	add_child(_inflate_player)

	var amb: AudioStreamWAV = AMBIENCE.duplicate()
	amb.loop_mode = AudioStreamWAV.LOOP_FORWARD
	amb.loop_begin = 0
	amb.loop_end = int(amb.get_length() * amb.mix_rate)
	_ambience = AudioStreamPlayer.new()
	_ambience.stream = amb
	_ambience.bus = AMBIENCE_BUS
	_ambience.volume_db = -80.0
	add_child(_ambience)

	_apply_mute(SaveManager.is_muted)
	SaveManager.mute_changed.connect(_apply_mute)


# ── Public API ────────────────────────────────────────────────────

func play_inflate() -> void:
	_play_on(_inflate_player, "inflate")


func play_release() -> void:
	play("release")


## Chime pitch climbs gently with the score (resets every 12 points).
func play_score(score: int) -> void:
	play("score", pow(2.0, float((score - 1) % 12) / 24.0))


func play_game_over() -> void:
	_inflate_player.stop()
	play("game_over")


func play_new_best() -> void:
	play("new_best")


func play_zone() -> void:
	play("zone")


func play_click() -> void:
	play("click")


func play_confirm() -> void:
	play("confirm")


func play_tick() -> void:
	play("tick")


func play_coin() -> void:
	play("coin")


func play_revive() -> void:
	play("revive")


func play_buy() -> void:
	play("buy")


func play_splash() -> void:
	play("splash")


func play(sound: String, pitch := 1.0) -> void:
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	_play_on(p, sound, pitch)


func start_ambience(fade := 1.5) -> void:
	if not _ambience.playing:
		_ambience.play()
	_fade_ambience(AMBIENCE_DB, fade)


func stop_ambience(fade := 1.0) -> void:
	_fade_ambience(-80.0, fade)


func set_muted(muted: bool) -> void:
	SaveManager.is_muted = muted


## Used by AdManager while a fullscreen ad is visible.
func set_paused(paused: bool) -> void:
	for bus in [SFX_BUS, AMBIENCE_BUS]:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), paused)
	_ambience.stream_paused = paused


# ── Internals ─────────────────────────────────────────────────────

func _play_on(p: AudioStreamPlayer, sound: String, pitch := 1.0) -> void:
	if SaveManager.is_muted:
		return
	var def: Array = SOUNDS[sound]
	var spread: float = def[2]
	p.stop()
	p.stream = def[0]
	p.volume_db = def[1]
	p.pitch_scale = pitch * (1.0 + randf_range(-spread, spread))
	p.play()


func _fade_ambience(target_db: float, time: float) -> void:
	if _ambience_tween:
		_ambience_tween.kill()
	_ambience_tween = create_tween()
	_ambience_tween.tween_property(_ambience, "volume_db", target_db, time)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _apply_mute(muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
