extends Node
## Scene transitions (US-03). Replaces SKTransition.fade / SKTransition.moveIn.
## Every screen root is a Node2D without CanvasLayers, so a move-in can slide the whole screen.

enum Transition { NONE, FADE, MOVE_IN_UP, MOVE_IN_DOWN }

const SCENES := {
	"menu": "res://scenes/menu.tscn",
	"skin_select": "res://scenes/skin_select.tscn",
	"game": "res://scenes/game.tscn",
	"game_over": "res://scenes/game_over.tscn",
	"settings": "res://scenes/settings.tscn",
	"missions": "res://scenes/missions.tscn",
}
const MOVE_IN_Z := 100

## Parameters for the scene being opened (e.g. {"score": 12} for GameOver).
var params: Dictionary = {}
var is_transitioning := false

var _layer: CanvasLayer
var _fade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_fade)


## `scene` is a key of SCENES, a res:// path or a PackedScene.
func go_to(scene, transition: Transition = Transition.FADE, duration: float = 0.3, new_params: Dictionary = {}) -> void:
	if is_transitioning:
		return
	var packed := _resolve(scene)
	if packed == null:
		push_error("SceneRouter: unknown scene %s" % [scene])
		return
	is_transitioning = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	params = new_params
	match transition:
		Transition.FADE:
			await _fade_to(packed, duration)
		Transition.MOVE_IN_UP:
			await _move_in(packed, duration, 1.0)
		Transition.MOVE_IN_DOWN:
			await _move_in(packed, duration, -1.0)
		_:
			get_tree().change_scene_to_packed(packed)
			await get_tree().process_frame
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false


func _resolve(scene) -> PackedScene:
	if scene is PackedScene:
		return scene
	var path: String = SCENES.get(scene, scene)
	return load(path) as PackedScene


## SKTransition.fade: fade to black and back in, over the full duration.
func _fade_to(packed: PackedScene, duration: float) -> void:
	var half := duration * 0.5
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, half)
	await t.finished
	get_tree().change_scene_to_packed(packed)
	await get_tree().process_frame
	t = create_tween()
	t.tween_property(_fade, "color:a", 0.0, half)
	await t.finished


## SKTransition.moveIn: the new scene slides over the old one, which stays visible underneath.
## direction 1 = enters from the bottom moving up, -1 = enters from the top moving down.
func _move_in(packed: PackedScene, duration: float, direction: float) -> void:
	var tree := get_tree()
	var old := tree.current_scene
	var h := get_viewport().get_visible_rect().size.y
	var new_scene := packed.instantiate()
	var slider := new_scene as Node2D
	if slider:
		slider.z_index = MOVE_IN_Z
		slider.position.y = h * direction
	tree.root.add_child(new_scene)
	tree.current_scene = new_scene
	if slider:
		var t := create_tween()
		t.tween_property(slider, "position:y", 0.0, duration)
		await t.finished
		slider.z_index = 0
	if is_instance_valid(old):
		old.queue_free()
