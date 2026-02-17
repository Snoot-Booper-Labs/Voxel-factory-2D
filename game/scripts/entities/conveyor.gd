## Conveyor Entity - a belt segment that transports items
## Contains a BeltNode component for handling item movement.
## Provides visual representation (colored square + direction arrow).
class_name Conveyor
extends Entity


func _init(pos: Vector2i = Vector2i.ZERO, dir: BeltNode.Direction = BeltNode.Direction.RIGHT) -> void:
	var belt := BeltNode.new()
	belt.set_position(pos)
	belt.set_direction(dir)
	add_component(belt)


func _ready() -> void:
	add_to_group("conveyors")
	_create_visuals()


## Get the BeltNode component attached to this conveyor
func get_belt() -> BeltNode:
	return get_component("BeltNode") as BeltNode


## Add an item to this conveyor's belt. Returns true if accepted.
func add_item(item_type: int) -> bool:
	return get_belt().add_item(item_type)


## Set up this conveyor after instantiation (called by PlacementController / EntitySaver)
func setup(pos: Vector2i, dir: BeltNode.Direction) -> void:
	var belt := get_belt()
	belt.set_position(pos)
	belt.set_direction(dir)
	position = WorldUtils.tile_to_world(pos)
	_update_visuals()


# =========================================================================
# Visuals
# =========================================================================

const BELT_COLOR := Color(0.35, 0.35, 0.4)
const ARROW_COLOR := Color(0.85, 0.85, 0.2)

var _body: ColorRect
var _arrow: ColorRect


func _create_visuals() -> void:
	# Belt body - fills the 16x16 tile
	_body = ColorRect.new()
	_body.name = "Body"
	_body.size = Vector2(WorldUtils.TILE_SIZE, WorldUtils.TILE_SIZE)
	_body.color = BELT_COLOR
	add_child(_body)

	# Direction arrow indicator (small rectangle inside)
	_arrow = ColorRect.new()
	_arrow.name = "Arrow"
	_arrow.size = Vector2(6, 4)
	_arrow.color = ARROW_COLOR
	add_child(_arrow)

	_update_visuals()


func _update_visuals() -> void:
	if _arrow == null:
		return
	var belt := get_belt()
	if belt == null:
		return
	# Center the arrow inside the tile and shift it towards the direction
	var tile := float(WorldUtils.TILE_SIZE)
	var center := Vector2(tile / 2.0, tile / 2.0)
	match belt.direction:
		BeltNode.Direction.RIGHT:
			_arrow.size = Vector2(6, 4)
			_arrow.position = center + Vector2(1, -2)
		BeltNode.Direction.LEFT:
			_arrow.size = Vector2(6, 4)
			_arrow.position = center + Vector2(-7, -2)
		BeltNode.Direction.UP:
			_arrow.size = Vector2(4, 6)
			_arrow.position = center + Vector2(-2, -7)
		BeltNode.Direction.DOWN:
			_arrow.size = Vector2(4, 6)
			_arrow.position = center + Vector2(-2, 1)


# =========================================================================
# Serialization
# =========================================================================

func serialize() -> Dictionary:
	var belt := get_belt()
	var data := {
		"type": "Conveyor",
		"position": {"x": position.x, "y": position.y},
	}
	if belt:
		data["belt"] = belt.serialize()
	return data


func deserialize(data: Dictionary) -> void:
	# Restore screen position
	var pos_data: Dictionary = data.get("position", {})
	position = Vector2(
		float(pos_data.get("x", 0.0)),
		float(pos_data.get("y", 0.0))
	)

	# Restore belt state
	var belt := get_belt()
	var belt_data: Dictionary = data.get("belt", {})
	if belt and not belt_data.is_empty():
		belt.deserialize(belt_data)

	_update_visuals()
