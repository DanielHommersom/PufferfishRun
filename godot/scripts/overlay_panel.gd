class_name OverlayPanel
extends Node2D
## Modal panel over the current screen: dims the background, blocks input underneath, shows a
## title and a CLOSE link. Subclasses add content below `content_top`.

signal closed

var panel_size := Vector2(330, 420)
var title := ""
var closable := true ## false: no CLOSE link (e.g. the ATT explainer)
var content_top := 0.0
var panel_rect := Rect2()


func _ready() -> void:
	z_index = 60
	var s := get_viewport_rect().size
	var blocker := ColorRect.new()
	blocker.color = Color(0, 0, 0, 0.6)
	blocker.size = s
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(blocker)
	panel_rect = Rect2((s - panel_size) / 2.0, panel_size)
	var panel := ScorePanel.create(panel_rect, Color(0.102, 0.416, 0.478))
	panel.divider = false
	add_child(panel)
	UiUtil.label(self, tr(title), 20, Constants.UI_ORANGE, s.x / 2.0, panel_rect.position.y + 42, true)
	content_top = panel_rect.position.y + 64

	if closable:
		var close_label := UiUtil.label(self, tr("CLOSE"), 13, Constants.UI_MUTED_TEXT, s.x / 2.0, panel_rect.end.y - 16)
		close_label.z_index = 1
		var hit := Control.new()
		hit.size = Vector2(160, 40)
		hit.position = Vector2(s.x / 2.0 - 80, panel_rect.end.y - 42)
		hit.gui_input.connect(_on_close_input)
		add_child(hit)

	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	build()


## Override to add content.
func build() -> void:
	pass


func close() -> void:
	SoundManager.play_click()
	closed.emit()
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.15)
	t.tween_callback(queue_free)


func _on_close_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		close()
