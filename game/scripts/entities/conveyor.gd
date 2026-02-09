## Conveyor Entity - a belt segment that transports items
## Contains a BeltNode component for handling item movement
class_name Conveyor
extends Entity


func _init(pos: Vector2i = Vector2i.ZERO, dir: BeltNode.Direction = BeltNode.Direction.RIGHT) -> void:
	var belt := BeltNode.new()
	belt.set_position(pos)
	belt.set_direction(dir)
	add_component(belt)


## Get the BeltNode component attached to this conveyor
func get_belt() -> BeltNode:
	return get_component("BeltNode") as BeltNode


## Add an item to this conveyor's belt
func add_item(item_type: int) -> void:
	get_belt().add_item(item_type)
