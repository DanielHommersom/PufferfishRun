class_name SkinLibrary
extends Resource
## Ordered list of all skins. Add a SkinDefinition to data/skins.tres to add a skin.

const PATH := "res://data/skins.tres"

@export var skins: Array[SkinDefinition] = []

static var _cached: SkinLibrary


static func get_all() -> Array[SkinDefinition]:
	if _cached == null:
		_cached = load(PATH)
	return _cached.skins


static func get_by_id(id: String) -> SkinDefinition:
	for skin in get_all():
		if skin.id == id:
			return skin
	return get_all()[0]


static func has_id(id: String) -> bool:
	for skin in get_all():
		if skin.id == id:
			return true
	return false


static func index_of(id: String) -> int:
	var all := get_all()
	for i in all.size():
		if all[i].id == id:
			return i
	return 0
