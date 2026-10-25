class_name Toast
## Short message near the bottom of the screen, on a dark rounded pill so it reads on any
## background. Only one toast is visible at a time: a new one replaces the previous.

const META := "_active_toast"


static func show(parent: Node, text: String) -> void:
	var s := parent.get_viewport().get_visible_rect().size
	var tree := parent.get_tree()
	var old = tree.root.get_meta(META) if tree.root.has_meta(META) else null
	if old != null and is_instance_valid(old):
		old.queue_free()

	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.06, 0.1, 0.92)
	sb.border_color = Color(0, 0, 0, 1)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	l.add_theme_stylebox_override("normal", sb)
	var width := minf(s.x - 32.0, DrawUtil.font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 36.0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size = Vector2(width, 0)
	l.position = Vector2((s.x - width) / 2.0, s.y * 0.86)
	l.z_index = 50
	l.modulate.a = 0.0
	parent.add_child(l)
	tree.root.set_meta(META, l)

	var t := l.create_tween()
	t.tween_property(l, "modulate:a", 1.0, 0.15)
	t.tween_interval(1.8)
	t.tween_property(l, "modulate:a", 0.0, 0.35)
	t.tween_callback(l.queue_free)
