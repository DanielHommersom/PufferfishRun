extends SceneTree
## Offline sound designer: synthesises every game sound in GDScript and writes them to
## res://assets/audio/*.wav (44.1 kHz, 16-bit mono). Re-run after tweaking:
##   godot --headless --path godot -s res://tools/generate_sfx.gd
## then `godot --headless --path godot --import` so Godot picks up the new files.

const SR := 44100
const OUT := "res://assets/audio/"

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 20261018 # deterministic: same sounds every run
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save("inflate", _inflate())
	_save("release", _release())
	_save("score", _score())
	_save("game_over", _game_over())
	_save("new_best", _new_best())
	_save("zone", _zone())
	_save("click", _click())
	_save("confirm", _confirm())
	_save("tick", _tick())
	_save("splash", _splash())
	_save("coin", _coin())
	_save("revive", _revive())
	_save("buy", _buy())
	_save("ambience", _ambience(), true)
	print("done")
	quit()


# ── Sounds ────────────────────────────────────────────────────────

## Puffing up: a clean rubbery "bloop" that rises in pitch, with bubbles on top (no noise).
func _inflate() -> PackedFloat32Array:
	var buf := _buffer(0.30)
	var phase := 0.0
	for i in buf.size():
		var t := float(i) / SR
		var f := 170.0 + 430.0 * (1.0 - exp(-t * 14.0)) + sin(t * 70.0) * 12.0
		phase += TAU * f / SR
		var env := _attack(t, 0.006) * exp(-t * 11.0)
		buf[i] += (sin(phase) * 0.8 + sin(phase * 2.0) * 0.18 + sin(phase * 3.0) * 0.06) * env * 0.55
	_add_bubble(buf, 0.05, 820.0, 0.09, 0.30)
	_add_bubble(buf, 0.12, 1250.0, 0.07, 0.18)
	return _finish(buf, 0.8)


## Letting go: a soft, low bubble that sinks in pitch (no noise).
func _release() -> PackedFloat32Array:
	var buf := _buffer(0.22)
	_add_bubble(buf, 0.0, 520.0, 0.07, 0.3, -0.8)
	_add_bubble(buf, 0.06, 380.0, 0.06, 0.15, -0.6)
	return _finish(buf, 0.35)


## Passing a pillar: bright two-note bell chime with an underwater echo.
func _score() -> PackedFloat32Array:
	var buf := _buffer(0.75)
	_add_bell(buf, 0.0, 1318.5, 0.9, 0.42) # E6
	_add_bell(buf, 0.075, 1975.5, 0.8, 0.36) # B6
	_add_bubble(buf, 0.0, 1500.0, 0.05, 0.12)
	_echo(buf, 0.11, 0.32, 3)
	return _finish(buf, 0.65)


## Death: a squashy pop, a sad descending "wah-wah" and a burst of escaping bubbles.
func _game_over() -> PackedFloat32Array:
	var buf := _buffer(1.5)
	# Pop / impact
	var ph := 0.0
	for i in int(0.25 * SR):
		var t := float(i) / SR
		ph += TAU * (160.0 * exp(-t * 9.0) + 45.0) / SR
		buf[i] += sin(ph) * exp(-t * 14.0) * 0.9
	_add_noise_burst(buf, 0.0, 0.12, 2500.0, 1.0, 0.5, 30.0)
	# Descending wah-wah (two steps), square-ish tone through a sweeping filter
	_add_wah(buf, 0.18, 0.32, 392.0, 349.2, 0.32)
	_add_wah(buf, 0.52, 0.75, 329.6, 246.9, 0.34)
	# Bubbles escaping upward
	for k in 9:
		_add_bubble(buf, 0.05 + k * 0.07 + _rng.randf() * 0.04, _rng.randf_range(500.0, 1500.0), _rng.randf_range(0.04, 0.09), _rng.randf_range(0.10, 0.22))
	_echo(buf, 0.13, 0.25, 2)
	return _finish(buf, 0.8)


## New record: a quick rising arpeggio fanfare with sparkle.
func _new_best() -> PackedFloat32Array:
	var buf := _buffer(1.3)
	var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5] # C5 E5 G5 C6 E6
	for k in notes.size():
		_add_pluck(buf, k * 0.085, notes[k], 0.5 if k < 4 else 0.9, 0.32)
		_add_bell(buf, k * 0.085, notes[k] * 2.0, 0.4, 0.08)
	_add_bell(buf, 0.43, 2093.0, 0.9, 0.18)
	for k in 6:
		_add_bell(buf, 0.45 + k * 0.06, _rng.randf_range(2600.0, 4200.0), 0.18, 0.05)
	_echo(buf, 0.12, 0.3, 3)
	return _finish(buf, 0.7)


## Entering a deeper zone: a deep sonar ping that echoes away, with a low swell.
func _zone() -> PackedFloat32Array:
	var buf := _buffer(2.6)
	_add_bell(buf, 0.0, 587.3, 1.6, 0.45, false)
	var ph := 0.0
	for i in buf.size():
		var t := float(i) / SR
		ph += TAU * 73.4 / SR
		var env := _attack(t, 0.6) * exp(-t * 1.6)
		buf[i] += sin(ph) * env * 0.35
	_echo(buf, 0.38, 0.45, 4)
	return _finish(buf, 0.55)


## UI button: short watery pop.
func _click() -> PackedFloat32Array:
	var buf := _buffer(0.12)
	_add_bubble(buf, 0.0, 700.0, 0.045, 0.7, 1.4)
	_add_noise_burst(buf, 0.0, 0.015, 4000.0, 1.0, 0.15, 60.0)
	return _finish(buf, 0.55)


## Selecting a skin: two-note "ding-ding" upward.
func _confirm() -> PackedFloat32Array:
	var buf := _buffer(0.6)
	_add_pluck(buf, 0.0, 880.0, 0.35, 0.4)
	_add_pluck(buf, 0.09, 1318.5, 0.5, 0.4)
	_add_bubble(buf, 0.0, 900.0, 0.05, 0.2)
	_echo(buf, 0.1, 0.25, 2)
	return _finish(buf, 0.6)


## Score count-up on the game-over screen: tiny tick.
func _tick() -> PackedFloat32Array:
	var buf := _buffer(0.05)
	_add_bell(buf, 0.0, 2400.0, 0.04, 0.5, false)
	return _finish(buf, 0.25)


## Title splash: a cluster of rising bubbles with a gentle whoosh.
func _splash() -> PackedFloat32Array:
	var buf := _buffer(1.4)
	_add_noise_burst(buf, 0.0, 1.0, 600.0, 0.7, 0.25, 3.0, 0.25)
	for k in 14:
		var t := 0.05 + k * 0.065 + _rng.randf() * 0.04
		_add_bubble(buf, t, 400.0 + k * 70.0 + _rng.randf() * 200.0, _rng.randf_range(0.05, 0.1), _rng.randf_range(0.12, 0.25))
	_echo(buf, 0.15, 0.3, 2)
	return _finish(buf, 0.6)


## Coin pickup: classic bright two-step "bling".
func _coin() -> PackedFloat32Array:
	var buf := _buffer(0.4)
	_add_pluck(buf, 0.0, 987.8, 0.12, 0.35) # B5
	_add_pluck(buf, 0.06, 1318.5, 0.35, 0.4) # E6
	_add_bell(buf, 0.06, 2637.0, 0.25, 0.08)
	_echo(buf, 0.08, 0.2, 2)
	return _finish(buf, 0.6)


## Revive: rising shimmering sweep + chord, "back in the game".
func _revive() -> PackedFloat32Array:
	var buf := _buffer(1.2)
	var ph := 0.0
	for i in int(0.6 * SR):
		var t := float(i) / SR
		ph += TAU * (300.0 + 900.0 * t / 0.6) / SR
		buf[i] += sin(ph) * _attack(t, 0.05) * (1.0 - t / 0.6) * 0.25
	for n in [523.25, 659.25, 783.99, 1046.5]:
		_add_pluck(buf, 0.5, n, 0.6, 0.22)
	for k in 8:
		_add_bell(buf, 0.1 + k * 0.06, 1500.0 + k * 250.0, 0.2, 0.06)
	_echo(buf, 0.12, 0.3, 3)
	return _finish(buf, 0.65)


## Buying a skin: coins pouring + confirm chord.
func _buy() -> PackedFloat32Array:
	var buf := _buffer(0.9)
	for k in 6:
		_add_pluck(buf, k * 0.045, 1318.5 + _rng.randf_range(-80.0, 160.0), 0.12, 0.18)
	for n in [659.25, 830.6, 987.8]:
		_add_pluck(buf, 0.3, n, 0.55, 0.25)
	_echo(buf, 0.1, 0.25, 2)
	return _finish(buf, 0.65)


## Seamless 8 s underwater bed: deep rumble, slow swell and occasional distant bubbles.
func _ambience() -> PackedFloat32Array:
	var dur := 8.0
	var buf := _buffer(dur)
	var lp := 0.0
	var lp2 := 0.0
	var a := 1.0 - exp(-TAU * 260.0 / SR)
	var a2 := 1.0 - exp(-TAU * 90.0 / SR)
	for i in buf.size():
		var t := float(i) / SR
		var n := _rng.randf_range(-1.0, 1.0)
		lp += a * (n - lp)
		lp2 += a2 * (lp - lp2)
		var swell := 0.65 + 0.35 * sin(TAU * t / dur * 2.0) # integer cycles → loops cleanly
		buf[i] = lp2 * 4.0 * swell + sin(TAU * 55.0 * t) * 0.03 * swell
	for k in 10:
		_add_bubble(buf, _rng.randf_range(0.2, dur - 0.4), _rng.randf_range(350.0, 900.0), _rng.randf_range(0.06, 0.12), _rng.randf_range(0.05, 0.12))
	_crossfade_loop(buf, int(0.5 * SR))
	return _finish(buf, 0.35)


# ── Building blocks ───────────────────────────────────────────────

func _buffer(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * SR))
	return b


func _attack(t: float, time: float) -> float:
	return clampf(t / time, 0.0, 1.0)


## Minnaert-style bubble: sine whose pitch rises as the bubble closes, fast exponential decay.
func _add_bubble(buf: PackedFloat32Array, start: float, f0: float, decay: float, amp: float, rise := 2.2) -> void:
	var s := int(start * SR)
	var n := mini(int(decay * 6.0 * SR), buf.size() - s)
	var ph := 0.0
	for i in n:
		var t := float(i) / SR
		var f := f0 * (1.0 + rise * t / decay * 0.25)
		ph += TAU * f / SR
		buf[s + i] += sin(ph) * exp(-t / decay * 2.5) * _attack(t, 0.002) * amp


## Filtered noise burst; `q` shapes a state-variable band-pass around `fc`.
func _add_noise_burst(buf: PackedFloat32Array, start: float, dur: float, fc: float, q: float, amp: float, decay := 10.0, attack := 0.003) -> void:
	var s := int(start * SR)
	var n := mini(int(dur * SR), buf.size() - s)
	var f := 2.0 * sin(PI * fc / SR)
	var low := 0.0
	var band := 0.0
	for i in n:
		var t := float(i) / SR
		var x := _rng.randf_range(-1.0, 1.0)
		low += f * band
		var high := x - low - q * band
		band += f * high
		var env := _attack(t, attack) * exp(-t * decay)
		buf[s + i] += band * env * amp


## Bell: inharmonic partials with individual decays (glassy, good underwater).
func _add_bell(buf: PackedFloat32Array, start: float, f: float, dur: float, amp: float, shimmer := true) -> void:
	var s := int(start * SR)
	var n := mini(int(dur * SR), buf.size() - s)
	var partials := [[1.0, 1.0, 1.0], [2.76, 0.45, 1.8], [5.40, 0.22, 3.0], [8.93, 0.1, 4.5]]
	for i in n:
		var t := float(i) / SR
		var v := 0.0
		for p in partials:
			v += sin(TAU * f * p[0] * t) * p[1] * exp(-t / dur * 4.0 * p[2])
		if shimmer:
			v *= 1.0 + 0.08 * sin(TAU * 6.0 * t)
		buf[s + i] += v * _attack(t, 0.002) * amp


## Plucked tone (soft square through decay) for arpeggios.
func _add_pluck(buf: PackedFloat32Array, start: float, f: float, dur: float, amp: float) -> void:
	var s := int(start * SR)
	var n := mini(int(dur * SR), buf.size() - s)
	for i in n:
		var t := float(i) / SR
		var ph := TAU * f * t
		var v := sin(ph) + sin(ph * 3.0) / 3.0 * exp(-t * 18.0) + sin(ph * 2.0) * 0.25
		buf[s + i] += v * _attack(t, 0.003) * exp(-t / dur * 5.0) * amp


## Trombone-ish "wah": square-ish tone gliding f0→f1 through a closing low-pass.
func _add_wah(buf: PackedFloat32Array, start: float, dur: float, f0: float, f1: float, amp: float) -> void:
	var s := int(start * SR)
	var n := mini(int(dur * SR), buf.size() - s)
	var ph := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / SR
		var u := t / dur
		var f := lerpf(f0, f1, u * u) * (1.0 + 0.012 * sin(TAU * 5.5 * t))
		ph += TAU * f / SR
		var x := tanh(sin(ph) * 2.5)
		var cutoff := lerpf(2400.0, 500.0, u) * (0.6 + 0.4 * sin(PI * minf(u * 3.0, 1.0)))
		lp += (1.0 - exp(-TAU * cutoff / SR)) * (x - lp)
		var env := _attack(t, 0.03) * (1.0 - smoothstep(0.7, 1.0, u))
		buf[s + i] += lp * env * amp


## Feedback-free multi-tap echo (taps decay geometrically).
func _echo(buf: PackedFloat32Array, delay: float, gain: float, taps: int) -> void:
	var src := buf.duplicate()
	var d := int(delay * SR)
	for k in range(1, taps + 1):
		var g := pow(gain, k)
		var off := d * k
		var lp := 0.0
		for i in range(off, buf.size()):
			lp += 0.35 * (src[i - off] - lp) # each echo darker, like distance underwater
			buf[i] += lp * g


## Makes the end flow into the start for seamless looping.
func _crossfade_loop(buf: PackedFloat32Array, fade: int) -> void:
	var n := buf.size()
	for i in fade:
		var w := float(i) / fade
		buf[i] = buf[i] * w + buf[n - fade + i] * (1.0 - w)
	buf.resize(n - fade)


## Removes DC, applies 3 ms fades and normalises to `peak`.
func _finish(buf: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var mean := 0.0
	for v in buf:
		mean += v
	mean /= maxf(1.0, buf.size())
	var mx := 0.0001
	for i in buf.size():
		buf[i] -= mean
		mx = maxf(mx, absf(buf[i]))
	var g := peak / mx
	var fade := mini(int(0.003 * SR), buf.size() / 2)
	for i in buf.size():
		var w := 1.0
		if i >= buf.size() - fade:
			w = float(buf.size() - 1 - i) / fade
		buf[i] *= g * w
	return buf


func _save(name: String, buf: PackedFloat32Array, loop := false) -> void:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = buf.size()
	var path := ProjectSettings.globalize_path(OUT + name + ".wav")
	wav.save_to_wav(path)
	print("  %-10s %.2fs" % [name, float(buf.size()) / SR])
