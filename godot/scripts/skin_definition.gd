class_name SkinDefinition
extends Resource
## One fish skin. `belly` is kept for data parity with SkinDefinition.swift; the renderer
## (like the original) derives the belly from body − 0.15.

@export var id: String = "default"
@export var display_name: String = "PUFFERFISH"
@export var unlock_score: int = 0 ## -1 = shop-only (can't be earned by score)
@export var price: int = 0 ## coins in the skin shop (0 = cannot be bought)
@export var body: Color = Color.WHITE
@export var belly: Color = Color.WHITE
@export var spine: Color = Color.WHITE
@export var eye: Color = Color.WHITE
@export var tail: Color = Color.WHITE


## Unlocked by reaching the score (original rule) or by buying it with coins.
func is_unlocked(best: int, owned: PackedStringArray = PackedStringArray()) -> bool:
	return (unlock_score >= 0 and best >= unlock_score) or owned.has(id)


func is_shop_only() -> bool:
	return unlock_score < 0
