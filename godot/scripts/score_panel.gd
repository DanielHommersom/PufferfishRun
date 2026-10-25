class_name ScorePanel
extends Node2D
## Game-over score panel: 4 px glow ring (radius 22) around a PANEL_BG panel (radius 20) with a
## black border and a 2 px UI_BLUE divider at 48 % height.

var rect := Rect2()
var glow := Color.WHITE
var divider := true


static func create(p_rect: Rect2, p_glow: Color) -> ScorePanel:
	var p := ScorePanel.new()
	p.rect = p_rect
	p.glow = p_glow
	return p


func _draw() -> void:
	DrawUtil.draw_rounded_rect(self, rect.grow(4), 22, glow)
	DrawUtil.draw_rounded_rect_bordered(self, rect, 20, Constants.PANEL_BG, Color.BLACK, 3)
	if not divider:
		return
	var divider_y := rect.end.y - rect.size.y * 0.48 - 2.0
	draw_rect(Rect2(rect.position.x + 20, divider_y, rect.size.x - 40, 2), Constants.UI_BLUE)
