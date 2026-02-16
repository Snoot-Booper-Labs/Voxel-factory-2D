## BeltNode Component for conveyor belt item transport
## Handles direction, connections, and item movement along belt segments
class_name BeltNode
extends Component

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

## Direction this belt segment moves items
var direction: Direction = Direction.RIGHT

## Grid position of this belt segment
var position: Vector2i = Vector2i.ZERO

## Connected output belt (items transfer here when complete)
var next_belt: BeltNode = null

## Items on this belt segment: [{item_type: int, progress: float}]
var items: Array[Dictionary] = []

## Belt speed in tiles per second (progress 0.0 -> 1.0)
const BELT_SPEED: float = 1.0

## Maximum number of items a single belt segment can hold
const MAX_ITEMS: int = 1


func _init() -> void:
	pass


## Returns the type name of this component
func get_type_name() -> String:
	return "BeltNode"


## Set the direction of item movement
func set_direction(dir: Direction) -> void:
	direction = dir


## Set the grid position of this belt
func set_position(pos: Vector2i) -> void:
	position = pos


## Connect this belt's output to another belt
func connect_to(belt: BeltNode) -> void:
	next_belt = belt


## Whether this belt is at capacity and cannot accept new items
func is_full() -> bool:
	return items.size() >= MAX_ITEMS


## Add an item to this belt at progress 0.0.
## Returns true if the item was accepted, false if belt is full.
func add_item(item_type: int) -> bool:
	if is_full():
		return false
	items.append({"item_type": item_type, "progress": 0.0})
	return true


## Check if this belt has any items
func has_items() -> bool:
	return items.size() > 0


## Get all items on this belt
func get_items() -> Array[Dictionary]:
	return items


## Get the direction vector for this belt (in tile-space)
func get_direction_vector() -> Vector2i:
	match direction:
		Direction.RIGHT:
			return Vector2i(1, 0)
		Direction.LEFT:
			return Vector2i(-1, 0)
		Direction.UP:
			return Vector2i(0, 1)   # Tile Y is up
		Direction.DOWN:
			return Vector2i(0, -1)  # Tile Y is up
	return Vector2i.ZERO


## Move items along belt, return items that reached the end (progress >= 1.0).
## If next_belt is full, the leading item stalls at progress 1.0 instead of completing.
func tick(delta: float) -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	var remaining: Array[Dictionary] = []

	for item in items:
		item["progress"] += BELT_SPEED * delta
		if item["progress"] >= 1.0:
			# Check backpressure: if next belt is full (or absent but we still
			# report it as completed for the system to decide), let it through.
			# The BeltSystem handles the actual transfer/drop decision.
			# But if the next belt is full we stall.
			if next_belt != null and next_belt.is_full():
				item["progress"] = 1.0  # Stall at the end
				remaining.append(item)
			else:
				completed.append(item)
		else:
			remaining.append(item)

	items = remaining
	return completed


## Serialize belt node state to a dictionary
func serialize() -> Dictionary:
	var serialized_items: Array = []
	for item in items:
		serialized_items.append({
			"item_type": item["item_type"],
			"progress": item["progress"],
		})
	return {
		"position": {"x": position.x, "y": position.y},
		"direction": direction,
		"items": serialized_items,
	}


## Restore belt node state from a dictionary
func deserialize(data: Dictionary) -> void:
	var pos_data: Dictionary = data.get("position", {})
	position = Vector2i(
		int(pos_data.get("x", 0)),
		int(pos_data.get("y", 0))
	)
	direction = int(data.get("direction", Direction.RIGHT)) as Direction

	items.clear()
	var saved_items: Array = data.get("items", [])
	for item_data in saved_items:
		items.append({
			"item_type": int(item_data.get("item_type", 0)),
			"progress": float(item_data.get("progress", 0.0)),
		})
