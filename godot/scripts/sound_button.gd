class_name SoundButton
extends Control
## Round mute toggle (US-21). Drawn speaker icon instead of the 🔊/🔇 emoji (B7).
## Place it with `place(center)`; the hit area is 64×64.

const RADIUS := 30.0
const HIT := 64.0

var _bounce: Tween


static func create() -> SoundButton:
	return SoundButton.new()


func _ready() -> void:
	size = Vector2(HIT, HIT)
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20
	SaveManager.mute_changed.connect(_on_mute_changed)


func _on_mute_changed(_muted: bool) -> void:
	queue_redraw()


func place(center: Vector2) -> void:
	position = center - Vector2(HIT, HIT) / 2.0


## Places the button at (w−50, h−50), lifted above the home indicator when needed.
func place_default(viewport: Viewport) -> void:
	var s := viewport.get_visible_rect().size
	var lift := maxf(0.0, DrawUtil.safe_insets(viewport).bottom - 20.0)
	place(Vector2(s.x - 50, s.y - 50 - lift))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if SceneRouter.is_transitioning:
			return
		if _bounce:
			_bounce.kill()
		_bounce = create_tween()
		_bounce.tween_property(self, "scale", Vector2(0.88, 0.88), 0.08)
		_bounce.tween_property(self, "scale", Vector2.ONE, 0.08)
		SoundManager.set_muted(not SaveManager.is_muted)
		SoundManager.play_click() # only audible when sound was just switched on


func _draw() -> void:
	var c := size / 2.0
	draw_circle(c, RADIUS, Color.BLACK)
	DrawUtil.draw_circle_stroked(self, c, 27, Constants.UI_BLUE, Color.BLACK, 2)
	# Speaker: box + cone
	var o := c + Vector2(-5, 0)
	draw_rect(Rect2(o.x - 8, o.y - 4, 5, 8), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(o.x - 3, o.y - 4), Vector2(o.x + 4, o.y - 10), Vector2(o.x + 4, o.y + 10), Vector2(o.x - 3, o.y + 4),
	]), Color.WHITE)
	if SaveManager.is_muted:
		var x := c + Vector2(8, 0)
		draw_line(x + Vector2(-4, -4), x + Vector2(4, 4), Color(1, 0.35, 0.35), 2.5, true)
		draw_line(x + Vector2(-4, 4), x + Vector2(4, -4), Color(1, 0.35, 0.35), 2.5, true)
	else:
		draw_arc(o + Vector2(4, 0), 6, -0.9, 0.9, 12, Color.WHITE, 2, true)
		draw_arc(o + Vector2(4, 0), 11, -0.9, 0.9, 16, Color.WHITE, 2, true)
