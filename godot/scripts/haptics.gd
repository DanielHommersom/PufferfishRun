class_name Haptics
## Short vibrations on mobile (respects the VIBRATION setting). No-op on desktop.


static func light() -> void:
	_buzz(12, 0.35)


static func medium() -> void:
	_buzz(22, 0.6)


static func heavy() -> void:
	_buzz(45, 1.0)


static func _buzz(ms: int, amplitude: float) -> void:
	if not SaveManager.vibration or not OS.has_feature("mobile"):
		return
	Input.vibrate_handheld(ms, amplitude)
