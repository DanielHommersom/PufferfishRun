class_name SplashSequence
extends CanvasLayer
## Launch splashes over the already-built menu, matching PopPulse:
## 1. Digital Diamonds — blue glow, logo springs in, two shimmer pulses with a shine sweep, fade out.
## 2. Pufferfish Run — the fish pops in, bubbles rise, the title pulses in on the beat.
## Starts on Constants.LAUNCH_BG — the colour of the iOS launch screen and Godot's boot screen —
## so the hand-over is invisible; the ocean is revealed for the game splash.
## A tap skips the current splash.

signal finished

const OCEAN_SHADER := preload("res://shaders/ocean.gdshader")

var _root: Control
var _bg: ColorRect ## the ocean backdrop = the iOS launch image
var _shade: ColorRect ## darkens it for the studio logo
var _skip := false


func _ready() -> void:
	layer = 90
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_input)
	add_child(_root)
	var vs := get_viewport().get_visible_rect().size
	_root.size = vs
	_bg = ColorRect.new()
	var mat := ShaderMaterial.new()
	mat.shader = OCEAN_SHADER
	var zone: Array = Constants.ZONE_COLORS[0]
	mat.set_shader_parameter("top_color", zone[0])
	mat.set_shader_parameter("mid_color", zone[1])
	mat.set_shader_parameter("bottom_color", zone[2])
	mat.set_shader_parameter("ray_alpha", zone[3])
	mat.set_shader_parameter("aspect", vs.x / vs.y)
	_bg.material = mat
	_bg.size = vs
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bg)
	_shade = ColorRect.new()
	_shade.color = Constants.LAUNCH_BG # fully opaque at start = the launch screen
	_shade.size = vs
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_shade)
	_run()


func _on_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		_skip = true


## Waits `secs`, returning early when the player tapped to skip.
func _hold(secs: float) -> void:
	var until := Time.get_ticks_msec() + int(secs * 1000.0)
	while Time.get_ticks_msec() < until and not _skip:
		await get_tree().process_frame


func _run() -> void:
	await _studio()
	_skip = false
	await _game()
	var t := create_tween()
	t.tween_property(_root, "modulate:a", 0.0, 0.35)
	await t.finished
	finished.emit()
	queue_free()


# --- 1. Digital Diamonds ---------------------------------------------------------

func _studio() -> void:
	var vs := _root.size
	var glow := _Glow.new()
	glow.color = Color("#3B82F6")
	glow.size = Vector2(vs.x, vs.x)
	glow.position = Vector2(0, (vs.y - vs.x) * 0.5)
	glow.modulate.a = 0.0
	_root.add_child(glow)
	var logo := DigitalDiamondsLogo.new()
	var w := minf(vs.x * 0.82, 620.0)
	logo.size = Vector2(w, w / DigitalDiamondsLogo.aspect())
	logo.position = (vs - logo.size) * 0.5
	logo.pivot_offset = logo.size * 0.5
	logo.modulate.a = 0.0
	logo.scale = Vector2.ONE * 0.85
	_root.add_child(logo)

	var t := create_tween().set_parallel(true)
	# The studio logo appears on the launch colour (the shade stays opaque).
	t.tween_property(glow, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)
	t.tween_property(logo, "modulate:a", 1.0, 0.6).set_ease(Tween.EASE_OUT)
	t.tween_property(logo, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _hold(0.7)
	if not _skip:
		# Two shimmer pulses: opacity dip + a highlight sweeping over the facets.
		var p := create_tween()
		for i in 2:
			p.tween_property(logo, "modulate:a", 0.75, 0.38).set_trans(Tween.TRANS_SINE)
			p.tween_property(logo, "modulate:a", 1.0, 0.38).set_trans(Tween.TRANS_SINE)
		var s := create_tween()
		s.tween_property(logo, "shine", 1.0, 1.2).from(0.0).set_trans(Tween.TRANS_SINE)
		await _hold(1.52 + 0.6)
	var out := create_tween().set_parallel(true)
	out.tween_property(logo, "modulate:a", 0.0, 0.25 if _skip else 0.48).set_ease(Tween.EASE_IN)
	out.tween_property(glow, "modulate:a", 0.0, 0.25 if _skip else 0.48).set_ease(Tween.EASE_IN)
	await out.finished
	logo.queue_free()
	glow.queue_free()


# --- 2. Pufferfish Run ------------------------------------------------------------

func _game() -> void:
	var vs := _root.size
	var cx := vs.x / 2.0
	# Back from the studio's dark to the ocean.
	create_tween().tween_property(_shade, "color:a", 0.0, 0.35)

	var bubbles := BubbleField.new()
	bubbles.count = 9
	bubbles.fill_alpha = 0.12
	bubbles.start_below = true
	bubbles.duration_min = 1.6
	bubbles.duration_max = 2.6
	_root.add_child(bubbles)

	var fish := StaticFish.create(SaveManager.get_selected_skin(), 62.0, 10)
	fish.hat = SaveManager.selected_hat
	fish.position = Vector2(cx, vs.y * 0.40)
	fish.scale = Vector2(0.3, 0.3)
	fish.modulate.a = 0.0
	_root.add_child(fish)

	var puffer := UiUtil.label(_root, "PUFFERFISH", 42, Color.WHITE, cx, vs.y * 0.62, true)
	var run := UiUtil.label(_root, "RUN", 60, Constants.UI_ORANGE, cx, vs.y * 0.71, true)
	var tag := UiUtil.label(_root, tr("SURVIVE THE REEF"), 16, Color(1, 1, 1, 0.75), cx, vs.y * 0.77, true)
	for l in [puffer, run, tag]:
		l.modulate.a = 0.0

	await _hold(0.25)
	# Fish pops in (puffs up) with a bubble burst
	var fi := create_tween().set_parallel(true)
	fi.tween_property(fish, "modulate:a", 1.0, 0.25)
	fi.tween_property(fish, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	SoundManager.play_inflate()
	Haptics.light()
	await _hold(0.35)
	# Title arrives with a double "pulse" on the beat
	var ti := create_tween().set_parallel(true)
	ti.tween_property(puffer, "modulate:a", 1.0, 0.25)
	ti.tween_property(run, "modulate:a", 1.0, 0.25)
	run.scale = Vector2(1.35, 1.35)
	ti.tween_property(run, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if not _skip:
		SoundManager.play_splash()
		for beat in 2:
			fish.scale = Vector2(1.12, 1.12)
			fish.create_tween().tween_property(fish, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			await _hold(0.32)
		create_tween().tween_property(tag, "modulate:a", 1.0, 0.3)
		await _hold(0.75)


## Soft radial glow behind the studio logo.
class _Glow extends Control:
	var color := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		for i in 24:
			var k := 1.0 - float(i) / 24.0
			draw_circle(c, r * k, Color(color, 0.022 * (1.0 - k) + 0.006), true, -1.0, false)
