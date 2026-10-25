class_name Haptics
## Vibrations on mobile (respects the VIBRATION setting). No-op on desktop.
##
## iOS: Godot drives Core Haptics, but the CHHapticEngine has to be started explicitly via the
## "AppleEmbedded" singleton — and again after the app returns from the background. Without that
## the patterns play silently. (Godot also logs "Could not vibrate using haptic engine: (null)"
## after EVERY call, even successful ones — "(null)" means no error; the message is misleading.)
## Continuous events shorter than ~30 ms are barely perceptible, hence these durations.

const IOS_SINGLETON := "AppleEmbedded"


## Starts the iOS haptic engine. Call at launch and whenever the app is resumed.
static func start_engine() -> void:
	if not OS.has_feature("ios") or not Engine.has_singleton(IOS_SINGLETON):
		return
	var ios: Object = Engine.get_singleton(IOS_SINGLETON)
	if ios.supports_haptic_engine():
		ios.start_haptic_engine()


static func light() -> void:
	_buzz(35, 0.55)


static func medium() -> void:
	_buzz(60, 0.8)


static func heavy() -> void:
	_buzz(110, 1.0)


static func _buzz(ms: int, amplitude: float) -> void:
	if not SaveManager.vibration or not OS.has_feature("mobile"):
		return
	Input.vibrate_handheld(ms, amplitude)
