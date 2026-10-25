extends Node2D
## Settings (monetisation 7): sound, restore purchases, privacy options (UMP), privacy policy,
## support contact and version.

const PANEL_H := 560.0
const BTN := Vector2(260, 46)
const HALF := Vector2(126, 44)
const LANGUAGES := ["auto", "en", "nl", "de", "fr", "es", "pt_BR", "ja"]
const LANGUAGE_NAMES := {"auto": "AUTO", "en": "ENGLISH", "nl": "NEDERLANDS", "de": "DEUTSCH", "fr": "FRANÇAIS", "es": "ESPAÑOL", "pt_BR": "PORTUGUÊS", "ja": "日本語"}

var _sound_btn: PixelButton
var _ads_btn: PixelButton
var _vib_btn: PixelButton
var _shake_btn: PixelButton
var _lang_btn: PixelButton
var _leaving := false


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF # animated per frame
	var s := get_viewport_rect().size
	var cx := s.x / 2.0
	var ocean := OceanBackground.new()
	ocean.parallax = false
	ocean.bubble_count = 6
	add_child(ocean)
	UiUtil.color_rect(self, Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.55))

	var top := s.y / 2.0 - PANEL_H / 2.0
	var bottom := top + PANEL_H
	add_child(ScorePanel.create(Rect2(20, top, s.x - 40, PANEL_H), Color(0.102, 0.416, 0.478)))
	get_child(get_child_count() - 1).divider = false
	UiUtil.label(self, tr("SETTINGS"), 22, Color.WHITE, cx, top + 46, true)

	# Toggles in two columns
	var y := top + 70.0
	var lx := cx - HALF.x - 4.0
	var rx := cx + 4.0
	_sound_btn = _half(lx, y, _toggle_sound)
	_vib_btn = _half(rx, y, func():
		SaveManager.vibration = not SaveManager.vibration
		Haptics.medium()
		_refresh_toggles())
	y += 52.0
	_shake_btn = _half(lx, y, func():
		SaveManager.screen_shake = not SaveManager.screen_shake
		_refresh_toggles())
	_lang_btn = _half(rx, y, _next_language)
	_refresh_sound()
	_refresh_toggles()
	y += 60.0
	var step := 54.0
	_ads_btn = _button("", Constants.UI_ORANGE, y, _buy_remove_ads)
	_refresh_ads()
	y += step
	_button(tr("RESTORE PURCHASES"), Constants.UI_BLUE, y, _restore)
	y += step
	if AdManager.is_privacy_options_required() or OS.is_debug_build():
		_button(tr("PRIVACY OPTIONS"), Constants.UI_BLUE, y, _privacy_options)
		y += step
	_button(tr("PRIVACY POLICY"), Constants.UI_BLUE, y, func(): OS.shell_open(Constants.PRIVACY_POLICY_URL))
	y += step
	_button(tr("CONTACT SUPPORT"), Constants.UI_BLUE, y, func(): OS.shell_open("mailto:%s?subject=Pufferfish%%20Run" % Constants.SUPPORT_EMAIL))

	var version := str(ProjectSettings.get_setting("application/config/version", "1.0"))
	UiUtil.label(self, "PUFFERFISH RUN v%s" % version, 10, Constants.UI_MUTED_TEXT, cx, bottom - 50)

	var back := UiUtil.label(self, tr("< BACK"), 13, Constants.UI_MUTED_TEXT, cx, bottom - 18)
	back.z_index = 1
	var hit := Control.new()
	hit.size = Vector2(160, 40)
	hit.position = Vector2(cx - 80, bottom - 44)
	hit.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_leave())
	add_child(hit)
	SaveManager.mute_changed.connect(_on_mute_changed)
	SaveManager.ads_removed_changed.connect(_on_ads_removed_changed)
	PurchaseManager.price_updated.connect(_on_price_updated)
	PurchaseManager.purchase_finished.connect(_on_purchase_finished)
	PurchaseManager.restore_finished.connect(_on_restore_finished)


func _half(x: float, y: float, action: Callable) -> PixelButton:
	var b := PixelButton.create("", Constants.UI_BLUE, Color.WHITE, HALF, 12)
	b.pulse = false
	b.shadow_offset = 3.0
	b.position = Vector2(x, y)
	b.pressed.connect(action)
	add_child(b)
	return b


func _toggle_style(b: PixelButton, label: String, on: bool) -> void:
	b.text = tr(label) + ": " + (tr("ON") if on else tr("OFF"))
	b.color = Constants.UI_GREEN if on else Color(0.35, 0.35, 0.4)


func _refresh_toggles() -> void:
	_toggle_style(_vib_btn, "VIBRATION", SaveManager.vibration)
	_toggle_style(_shake_btn, "SHAKE", SaveManager.screen_shake)
	_lang_btn.text = tr("LANGUAGE") + ": " + tr(LANGUAGE_NAMES.get(SaveManager.language, "AUTO"))
	_lang_btn.color = Constants.UI_BLUE


func _next_language() -> void:
	var i := LANGUAGES.find(SaveManager.language)
	SaveManager.language = LANGUAGES[(i + 1) % LANGUAGES.size()]
	# Rebuild the screen so every label picks up the new language
	SceneRouter.go_to("settings", SceneRouter.Transition.NONE)


func _button(text: String, color: Color, top_y: float, action: Callable) -> PixelButton:
	var b := PixelButton.create(text, color, Color.WHITE, BTN, 14)
	b.pulse = false
	b.shadow_offset = 3.0
	b.position = Vector2(get_viewport_rect().size.x / 2.0 - BTN.x / 2.0, top_y)
	b.pressed.connect(action)
	add_child(b)
	return b


func _toggle_sound() -> void:
	SoundManager.set_muted(not SaveManager.is_muted)


func _on_mute_changed(_muted: bool) -> void:
	_refresh_sound()


func _refresh_sound() -> void:
	_toggle_style(_sound_btn, "SOUND", not SaveManager.is_muted)


func _refresh_ads() -> void:
	if SaveManager.ads_removed:
		_ads_btn.text = tr("ADS REMOVED - THANK YOU!")
		_ads_btn.color = Color(0.35, 0.35, 0.4)
		_ads_btn.interactive = false
	else:
		_ads_btn.text = tr("REMOVE ADS  %s") % PurchaseManager.remove_ads_price
		_ads_btn.color = Constants.UI_ORANGE


func _buy_remove_ads() -> void:
	if not PurchaseManager.is_available():
		Toast.show(self, tr("STORE NOT AVAILABLE"))
		return
	PurchaseManager.buy_remove_ads()


func _on_ads_removed_changed(_removed: bool) -> void:
	_refresh_ads()


func _on_price_updated(_id: String, _price: String) -> void:
	_refresh_ads()


func _on_purchase_finished(_id: String, success: bool, _message: String) -> void:
	if success:
		SoundManager.play_buy()
		Toast.show(self, tr("ADS REMOVED. THANK YOU!"))
	else:
		Toast.show(self, tr("PURCHASE NOT COMPLETED"))


func _restore() -> void:
	Toast.show(self, tr("RESTORING PURCHASES..."))
	PurchaseManager.restore()


func _on_restore_finished(restored: int) -> void:
	Toast.show(self, tr("PURCHASES RESTORED") if restored > 0 else tr("NO PURCHASES TO RESTORE"))


func _privacy_options() -> void:
	if AdManager.is_privacy_options_required():
		AdManager.show_privacy_options()
	else:
		Toast.show(self, tr("NOT AVAILABLE ON THIS DEVICE"))


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	SoundManager.play_click()
	SceneRouter.go_to("menu", SceneRouter.Transition.FADE, 0.3)
