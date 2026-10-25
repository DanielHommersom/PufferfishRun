class_name UiUtil
## Label helpers. SKLabelNode positions are baselines; these place a Label so its baseline
## (or vertical centre) sits at the given y, centred on x. pivot_offset is the label centre.

const LABEL_WIDTH := 600.0


static func label(parent: Node, text: String, font_size: int, color: Color, center_x: float, baseline_y: float, shadow := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if shadow:
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", maxi(4, font_size / 7))
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.4))
		l.add_theme_constant_override("shadow_offset_x", 4)
		l.add_theme_constant_override("shadow_offset_y", 4)
		l.add_theme_constant_override("shadow_outline_size", 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f := DrawUtil.font()
	var h := f.get_height(font_size)
	l.size = Vector2(LABEL_WIDTH, h)
	l.position = Vector2(center_x - LABEL_WIDTH / 2.0, baseline_y - f.get_ascent(font_size))
	l.pivot_offset = l.size / 2.0
	parent.add_child(l)
	return l


static func label_middle(parent: Node, text: String, font_size: int, color: Color, center: Vector2) -> Label:
	var f := DrawUtil.font()
	var baseline := center.y + (f.get_ascent(font_size) - f.get_descent(font_size)) * 0.5
	return label(parent, text, font_size, color, center.x, baseline)


## Moves a label so its baseline sits at a new y (keeps x).
static func set_baseline(l: Label, baseline_y: float) -> void:
	var fs := l.get_theme_font_size("font_size")
	l.position.y = baseline_y - DrawUtil.font().get_ascent(fs)


## Rect fill helper for ColorRect backgrounds that ignore input.
static func color_rect(parent: Node, rect: Rect2, color: Color) -> ColorRect:
	var c := ColorRect.new()
	c.color = color
	c.position = rect.position
	c.size = rect.size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c


static func is_tap(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION
	return false


## Text that pops up at `pos`, rises and fades (e.g. "CLOSE! +1").
static func float_text(parent: Node, text: String, pos: Vector2, color: Color, size := 18) -> void:
	var l := label(parent, text, size, color, pos.x, pos.y, true)
	l.z_index = 15
	l.scale = Vector2(0.6, 0.6)
	var t := parent.create_tween().set_parallel()
	t.tween_property(l, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "position:y", l.position.y - 40.0, 0.9)
	t.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.5)
	t.chain().tween_callback(l.queue_free)


## Big centred banner, e.g. "~ KELP FOREST ~" on entering a zone.
static func banner(parent: Node, text: String, y: float, color := Color.WHITE) -> void:
	var w: float = parent.get_viewport().get_visible_rect().size.x
	var l := label(parent, text, 22, color, w / 2.0, y, true)
	l.z_index = 15
	l.modulate.a = 0.0
	var t := parent.create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.35)
	t.tween_interval(1.6)
	t.tween_property(l, "modulate:a", 0.0, 0.6)
	t.tween_callback(l.queue_free)
