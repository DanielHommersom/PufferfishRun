extends Node2D
## Shop (US-18, extended): tabs for skins, hats and bubble trails. Skins unlock by score or
## coins; hats and trails are bought with coins. A rewarded "free coins" button gives
## FREE_COINS_AMOUNT a few times per day. The grid scrolls when a tab has more items than fit.

const PANEL_H := 560.0
const COLS := 3
const SPACING := 12.0
const TABS := [["skin", "SKINS"], ["hat", "HATS"], ["trail", "TRAILS"]]

var _tab := "skin"
var _best := 0
var _selected := 0
var _cards: Array[SkinCard] = []
var _name_label: Label
var _status_label: Label
var _action_btn: PixelButton
var _free_btn: PixelButton
var _tab_btns: Array[PixelButton] = []
var _scroll: ScrollContainer
var _content: Control
var _coins: CoinCounter
var _leaving := false
var _top := 0.0
var _bottom := 0.0


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF # animated per frame
	var s := get_viewport_rect().size
	var cx := s.x / 2.0
	_best = SaveManager.high_score

	UiUtil.color_rect(self, Rect2(Vector2.ZERO, s), Constants.OCEAN_TOP)
	UiUtil.color_rect(self, Rect2(Vector2.ZERO, s), Color(0, 0, 0, 0.65))

	var panel_w := s.x - 40.0
	_top = s.y / 2.0 - PANEL_H / 2.0
	_bottom = _top + PANEL_H
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Constants.PANEL_BG
	sb.border_color = Color.BLACK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(20)
	sb.set_expand_margin_all(3)
	panel.add_theme_stylebox_override("panel", sb)
	panel.position = Vector2(20, _top)
	panel.size = Vector2(panel_w, PANEL_H)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	UiUtil.label(self, tr("SHOP"), 18, Color.WHITE, cx, _top + 40)
	UiUtil.label(self, tr("BEST: %d") % _best, 11, Constants.UI_GOLD_TEXT, cx, _top + 60)
	_coins = CoinCounter.new()
	_coins.font_size = 14
	_coins.value = SaveManager.coins
	_coins.position = Vector2(s.x - 20 - 86, _top + 24)
	add_child(_coins)

	# Rewarded free coins (top-left of the panel)
	_free_btn = PixelButton.create("", Color(0.49, 0.30, 0.78), Color.WHITE, Vector2(96, 30), 10)
	_free_btn.pulse = false
	_free_btn.shadow_offset = 2.0
	_free_btn.position = Vector2(34, _top + 12)
	_free_btn.pressed.connect(_on_free_coins)
	add_child(_free_btn)
	_refresh_free_btn()

	# Tabs
	var tab_w := (panel_w - 40.0 - 2 * 8.0) / 3.0
	for i in TABS.size():
		var b := PixelButton.create(TABS[i][1], Constants.UI_BLUE, Color.WHITE, Vector2(tab_w, 30), 12)
		b.pulse = false
		b.shadow_offset = 2.0
		b.position = Vector2(40 + i * (tab_w + 8.0), _top + 74)
		var kind: String = TABS[i][0]
		b.pressed.connect(func(): _switch_tab(kind))
		add_child(b)
		_tab_btns.append(b)

	# Grid area (top + 116 … bottom − 160), scrollable
	var grid_w := COLS * SkinCard.CARD_SIZE.x + (COLS - 1) * SPACING
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.position = Vector2(cx - grid_w / 2.0 - 4, _top + 116 - 4)
	_scroll.size = Vector2(grid_w + 8, (_bottom - 160.0) - (_top + 116.0) + 8)
	add_child(_scroll)

	_name_label = UiUtil.label(self, "", 14, Color.WHITE, cx, _bottom - 140)
	_status_label = UiUtil.label(self, "", 10, Constants.UI_GREEN, cx, _bottom - 118)

	_action_btn = PixelButton.create("SELECT", Constants.UI_GREEN, Color.WHITE, Vector2(240, 56), 14)
	_action_btn.pulse = false
	_action_btn.shadow_offset = 3.0
	_action_btn.place_bottom_center(cx, _bottom - 48)
	_action_btn.pressed.connect(_on_action)
	add_child(_action_btn)

	var back := UiUtil.label(self, tr("< BACK"), 13, Constants.UI_MUTED_TEXT, cx, _bottom - 14)
	back.z_index = 1
	var back_hit := Control.new()
	back_hit.size = Vector2(160, 40)
	back_hit.position = Vector2(cx - 80, _bottom - 40)
	back_hit.mouse_filter = Control.MOUSE_FILTER_STOP
	back_hit.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_leave())
	add_child(back_hit)

	_switch_tab("skin", true)


# ── Tabs & grid ───────────────────────────────────────────────────

func _switch_tab(kind: String, initial := false) -> void:
	if _leaving or (kind == _tab and not initial):
		return
	_tab = kind
	for i in TABS.size():
		_tab_btns[i].color = Constants.UI_ORANGE if TABS[i][0] == kind else Constants.UI_BLUE
		_tab_btns[i].text_color = Color.BLACK if TABS[i][0] == kind else Color.WHITE
	_build_grid()
	_selected = _equipped_index()
	_update_selection()


func _items() -> Array:
	if _tab == "skin":
		return SkinLibrary.get_all()
	return Cosmetics.list(_tab)


func _equipped_index() -> int:
	var items := _items()
	for i in items.size():
		if _is_equipped(i):
			return i
	return 0


func _is_equipped(i: int) -> bool:
	var it = _items()[i]
	match _tab:
		"skin":
			return it.id == SaveManager.selected_skin
		"hat":
			return it.id == SaveManager.selected_hat
		_:
			return it.id == SaveManager.selected_trail


func _build_grid() -> void:
	if _content:
		_content.queue_free()
	_cards.clear()
	var items := _items()
	var grid_w := COLS * SkinCard.CARD_SIZE.x + (COLS - 1) * SPACING
	var rows := ceili(float(items.size()) / COLS)
	_content = Control.new()
	_content.custom_minimum_size = Vector2(grid_w + 8, rows * (SkinCard.CARD_SIZE.y + SPACING) - SPACING + 8)
	_content.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll.add_child(_content)
	_scroll.scroll_vertical = 0
	for i in items.size():
		var card := SkinCard.new()
		card.index = i
		card.kind = _tab
		if _tab == "skin":
			card.skin = items[i]
		else:
			card.item = items[i]
		card.best = _best
		card.owned = SaveManager.owned_skins
		card.equipped = _is_equipped(i)
		card.position = Vector2(4 + (i % COLS) * (SkinCard.CARD_SIZE.x + SPACING), 4 + (i / COLS) * (SkinCard.CARD_SIZE.y + SPACING))
		card.tapped.connect(_on_card_tapped)
		_content.add_child(card)
		_cards.append(card)


func _refresh_cards() -> void:
	for i in _cards.size():
		_cards[i].owned = SaveManager.owned_skins
		_cards[i].equipped = _is_equipped(i)
		_cards[i].queue_redraw()


func _on_card_tapped(index: int) -> void:
	if _leaving:
		return
	_selected = index
	SoundManager.play_click()
	_update_selection()


# ── Selection / buy / equip ───────────────────────────────────────

func _update_selection() -> void:
	for i in _cards.size():
		_cards[i].selected = i == _selected
	var card := _cards[_selected]
	var unlocked := card.is_unlocked()
	var price := card.price()
	var name: String = card.skin.display_name if _tab == "skin" else tr(str(card.item.name))
	_name_label.text = name
	_name_label.add_theme_color_override("font_color", Color.WHITE if unlocked else Constants.UI_MUTED_TEXT)

	if unlocked:
		_status_label.text = tr("UNLOCKED")
	elif _tab == "skin" and not card.skin.is_shop_only():
		_status_label.text = tr("REACH SCORE %d OR BUY FOR %d") % [card.skin.unlock_score, price]
	else:
		_status_label.text = tr("BUY FOR %d COINS") % price
	_status_label.add_theme_color_override("font_color", Constants.UI_GREEN if unlocked else Constants.UI_LOCK_ORANGE)

	_action_btn.interactive = true
	if unlocked and _is_equipped(_selected):
		_action_btn.color = Color(0.2, 0.45, 0.25)
		_action_btn.text = tr("EQUIPPED")
	elif unlocked:
		_action_btn.color = Constants.UI_GREEN
		_action_btn.text = tr("SELECT") if _tab == "skin" else tr("EQUIP")
	elif SaveManager.coins >= price:
		_action_btn.color = Constants.UI_ORANGE
		_action_btn.text = tr("BUY  %d COINS") % price
	else:
		_action_btn.color = Color(0.2, 0.2, 0.2)
		_action_btn.text = tr("NEED %d MORE") % (price - SaveManager.coins)


func _on_action() -> void:
	if _leaving:
		return
	var card := _cards[_selected]
	if not card.is_unlocked():
		_try_buy(card)
		return
	if _is_equipped(_selected):
		return
	SoundManager.play_confirm()
	_action_btn.press_bounce()
	if _tab == "skin":
		# Original behaviour: picking a skin returns to the menu
		_leaving = true
		SaveManager.selected_skin = card.skin.id
		await get_tree().create_timer(0.16).timeout
		SceneRouter.go_to("menu", SceneRouter.Transition.MOVE_IN_DOWN, 0.3)
		return
	SaveManager.equip_item(_tab, card.item.id)
	_refresh_cards()
	_update_selection()


func _try_buy(card: SkinCard) -> void:
	var ok := SaveManager.buy_skin(card.skin) if _tab == "skin" else SaveManager.buy_item(_tab, card.item.id)
	if not ok:
		return
	SoundManager.play_buy()
	_action_btn.press_bounce()
	_coins.value = SaveManager.coins
	_coins.pop()
	_refresh_cards()
	_update_selection()


# ── Free coins (rewarded) ─────────────────────────────────────────

func _refresh_free_btn() -> void:
	var left := SaveManager.free_coins_left()
	if left <= 0:
		_free_btn.text = tr("TOMORROW")
		_free_btn.color = Color(0.3, 0.3, 0.35)
		_free_btn.interactive = false
	elif not AdManager.can_show_rewarded():
		_free_btn.text = tr("NO AD YET")
		_free_btn.color = Color(0.3, 0.3, 0.35)
		_free_btn.interactive = false
	else:
		_free_btn.text = tr("+%d FREE (%d)") % [Constants.FREE_COINS_AMOUNT, left]
		_free_btn.color = Color(0.49, 0.30, 0.78)
		_free_btn.interactive = true


func _on_free_coins() -> void:
	if _leaving:
		return
	_free_btn.interactive = false
	AdManager.show_rewarded(_on_free_coins_done)


func _on_free_coins_done(earned: bool) -> void:
	if earned and SaveManager.claim_free_coins():
		SoundManager.play_coin()
		_coins.value = SaveManager.coins
		_coins.pop()
		_update_selection()
	_refresh_free_btn()


func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	SoundManager.play_click()
	SceneRouter.go_to("menu", SceneRouter.Transition.MOVE_IN_DOWN, 0.3)
