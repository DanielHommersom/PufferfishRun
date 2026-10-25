class_name Debug
## Debug-only toggles (US-08 hitboxes, US-09 forced enemy type). Inert in release builds.
## Keys in the game scene (debug builds only): H = hitboxes, 0 = random enemies,
## 1/2/3 = force jellyfish/shark/urchin.

static var show_hitboxes := false
static var forced_enemy := -1 # -1 = random, otherwise Enemy.Type


static func handle_key(event: InputEvent) -> bool:
	if not OS.is_debug_build() or not (event is InputEventKey) or not event.pressed or event.echo:
		return false
	match event.keycode:
		KEY_H:
			show_hitboxes = not show_hitboxes
		KEY_0:
			forced_enemy = -1
		KEY_1, KEY_2, KEY_3:
			forced_enemy = event.keycode - KEY_1
		_:
			return false
	print("[Debug] hitboxes=%s forced_enemy=%d" % [show_hitboxes, forced_enemy])
	return true
