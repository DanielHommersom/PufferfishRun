class_name TutorialOverlay
extends Node2D
## "GET READY" state before a run starts: an animated hand shows HOLD / RELEASE, and the player
## can buy a starting shield. The run starts on the first tap (handled by the game scene).

signal shield_requested

var _hand: Node2D
var _shield_btn: PixelButton
var _time := 0.0


func _ready() -> void:
	z_index = 20
	var s := get_viewport_rect().size
	var cx := s.x / 2.0
	UiUtil.label(self, tr("HOLD TO SWIM UP"), 18, Color.WHITE, cx, s.y * 0.66, true)
	UiUtil.label(self, tr("RELEASE TO SINK"), 14, Constants.UI_GOLD_TEXT, cx, s.y * 0.70, true)
	_hand = Node2D.new()
	_hand.position = Vector2(cx + 40, s.y * 0.57)
	_hand.draw.connect(_draw_hand)
	add_child(_hand)

	var can_coins := SaveManager.coins >= Constants.START_SHIELD_PRICE
	var can_ad := AdManager.can_show_rewarded()
	if can_coins or can_ad:
		var text := tr("START WITH SHIELD  %d") % Constants.START_SHIELD_PRICE if can_coins else tr("START WITH SHIELD (AD)")
		_shield_btn = PixelButton.create(text, Color(0.25, 0.55, 0.85), Color.WHITE, Vector2(270, 46), 13)
		_shield_btn.pulse = false
		_shield_btn.shadow_offset = 3.0
		_shield_btn.place_bottom_center(cx, s.y * 0.80)
		_shield_btn.pressed.connect(func(): shield_requested.emit())
		add_child(_shield_btn)


func hide_shield_button() -> void:
	if _shield_btn:
		_shield_btn.queue_free()
		_shield_btn = null


func dismiss() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)


func _process(delta: float) -> void:
	_time += delta
	_hand.queue_redraw()


## Pointing hand that presses down, holds, then lifts — with a ripple while pressed.
func _draw_hand() -> void:
	var cycle := fmod(_time, 1.6)
	var pressed := cycle > 0.3 and cycle < 1.1
	var y := 6.0 if pressed else 0.0
	if pressed:
		var rip := (cycle - 0.3) / 0.8
		_hand.draw_arc(Vector2(-14, -38), 10 + rip * 22, 0, TAU, 24, Color(1, 1, 1, 0.6 * (1.0 - rip)), 2.5, true)
	var o := Vector2(0, y)
	# finger
	DrawUtil.draw_rounded_rect_bordered(_hand, Rect2(o + Vector2(-20, -40), Vector2(12, 34)), 6, Color.WHITE, Color.BLACK, 2)
	# palm
	DrawUtil.draw_rounded_rect_bordered(_hand, Rect2(o + Vector2(-24, -12), Vector2(40, 36)), 12, Color.WHITE, Color.BLACK, 2)
	for k in 3:
		_hand.draw_line(o + Vector2(-4 + k * 7, -10), o + Vector2(-4 + k * 7, -2), Color(0, 0, 0, 0.5), 1.5, true)
