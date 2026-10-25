class_name AttExplainerPanel
extends OverlayPanel
## Our own explanation right before Apple's App Tracking Transparency dialog (as in PopPulse).
## Apple allows a pre-prompt as long as it doesn't pressure or reward; the only button continues
## to the system dialog, where the player decides.

signal continued


func _init() -> void:
	title = "KEEP PUFFERFISH RUN FREE"
	panel_size = Vector2(340, 380)
	closable = false # the only way on is the system dialog (Apple guideline 5.1.1(iv))


func build() -> void:
	var cx := panel_rect.get_center().x
	var y := content_top + 20.0
	for line in ["PUFFERFISH RUN IS FREE THANKS TO ADS.", "NEXT, IOS ASKS WHETHER ADS MAY USE", "YOUR ACTIVITY TO BE MORE RELEVANT.", "EITHER CHOICE IS FINE:", "THE GAME PLAYS EXACTLY THE SAME."]:
		UiUtil.label(self, tr(line), 12, Color.WHITE if y < content_top + 30 else Constants.UI_MUTED_TEXT, cx, y)
		y += 26.0
	var btn := PixelButton.create(tr("CONTINUE"), Constants.UI_GREEN, Color.WHITE, Vector2(240, 54), 16)
	btn.place_bottom_center(cx, panel_rect.end.y - 52)
	btn.pressed.connect(func():
		continued.emit()
		close())
	add_child(btn)
