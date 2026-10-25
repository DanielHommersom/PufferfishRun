class_name StaticFish
extends Node2D
## A non-playable fish drawn with DrawUtil.draw_menu_fish (menu, splash).

var skin: SkinDefinition
var radius := 52.0
var spine_count := 8
var hat := "none"


static func create(p_skin: SkinDefinition, p_radius: float, p_spines: int) -> StaticFish:
	var f := StaticFish.new()
	f.skin = p_skin
	f.radius = p_radius
	f.spine_count = p_spines
	return f


var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	DrawUtil.draw_menu_fish(self, skin, radius, spine_count, _time)
	Cosmetics.draw_hat(self, hat, radius)
