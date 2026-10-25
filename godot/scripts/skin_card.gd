class_name SkinCard
extends Control
## One 80×110 shop card (US-18): a skin, hat or trail with lock/price/owned state.

signal tapped(index: int)

const CARD_SIZE := Vector2(80, 110)

var index := 0
var kind := "skin" ## "skin" | "hat" | "trail"
var skin: SkinDefinition ## for kind == "skin"
var item: Dictionary = {} ## for hats/trails: {id, name, price}
var best := 0
var owned := PackedStringArray()
var equipped := false
var selected := false:
	set(v):
		selected = v
		queue_redraw()


func _ready() -> void:
	size = CARD_SIZE
	custom_minimum_size = CARD_SIZE
	mouse_filter = Control.MOUSE_FILTER_PASS


func is_unlocked() -> bool:
	if kind == "skin":
		return skin.is_unlocked(best, owned)
	return SaveManager.owns_item(kind, item.id)


func price() -> int:
	return skin.price if kind == "skin" else int(item.price)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(index)


func _draw() -> void:
	var unlocked := is_unlocked()
	var fill := Constants.UI_BLUE if selected else Color(0.024, 0.078, 0.125)
	var border := Constants.UI_ORANGE if selected else Color.BLACK
	DrawUtil.draw_rounded_rect_bordered(self, Rect2(Vector2.ZERO, size), 10, fill, border, 3)

	var center := Vector2(size.x / 2.0, size.y - size.y * 0.58)
	match kind:
		"skin":
			draw_set_transform(center)
			# Score-earnable skins stay a mystery silhouette; shop-only skins show a preview
			DrawUtil.draw_card_fish(self, skin, not unlocked and not skin.is_shop_only())
			draw_set_transform(Vector2.ZERO)
		"hat":
			draw_set_transform(center + Vector2(0, 6))
			DrawUtil.draw_card_fish(self, SaveManager.get_selected_skin(), false)
			Cosmetics.draw_hat(self, item.id, 22.0)
			draw_set_transform(Vector2.ZERO)
		"trail":
			Cosmetics.draw_trail_preview(self, item.id, center + Vector2(-4, 0))
			draw_set_transform(center + Vector2(20, 0), 0.0, Vector2(0.55, 0.55))
			DrawUtil.draw_card_fish(self, SaveManager.get_selected_skin(), false)
			draw_set_transform(Vector2.ZERO)
	if not unlocked and not (kind == "skin" and not skin.is_shop_only()):
		DrawUtil.draw_rounded_rect(self, Rect2(3, 3, size.x - 6, size.y - 6), 8, Color(0, 0, 0, 0.35))

	# Bottom label
	var label := ""
	var label_color := Constants.UI_GREEN
	if equipped:
		label = tr("EQUIPPED")
	elif kind == "skin" and owned.has(skin.id) or (kind != "skin" and unlocked and price() > 0):
		label = tr("OWNED")
	elif unlocked:
		label = tr("FREE") if price() == 0 and (kind != "skin" or skin.unlock_score == 0) else tr("UNLOCKED")
	elif kind == "skin" and not skin.is_shop_only():
		label = tr("SCORE %d") % skin.unlock_score
		label_color = Constants.UI_LOCK_ORANGE
	else:
		label = tr("%d COINS") % price()
		label_color = Constants.UI_LOCK_ORANGE
	DrawUtil.draw_text_centered(self, label, Vector2(size.x / 2.0, size.y - 8), DrawUtil.fit_font_size(label, 7, size.x - 6), label_color)

	# Progress bar: score towards an earnable skin, or coins towards a shop-only item
	var bar_w := size.x - 6
	var progress := 1.0
	if not unlocked:
		if kind == "skin" and not skin.is_shop_only():
			progress = 0.0 if skin.unlock_score <= 0 else minf(float(best) / skin.unlock_score, 1.0)
		elif price() > 0:
			progress = minf(float(SaveManager.coins) / price(), 1.0)
	draw_rect(Rect2(3, size.y - 5, bar_w, 3), Color.BLACK)
	if progress > 0.0:
		draw_rect(Rect2(3, size.y - 5, bar_w * progress, 3), Constants.UI_GREEN if progress >= 1.0 else Constants.UI_LOCK_ORANGE)

	# Coin price badge on locked items
	if not unlocked and price() > 0:
		var text := str(price())
		var f := DrawUtil.font()
		var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
		var badge := Rect2(size.x / 2.0 - (w + 18) / 2.0, 6, w + 18, 14)
		DrawUtil.draw_rounded_rect(self, badge, 7, Color(0, 0, 0, 0.6))
		DrawUtil.draw_coin(self, badge.position + Vector2(8, 7), 4.5)
		draw_string(f, badge.position + Vector2(15, 11), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Constants.UI_GOLD_TEXT)
