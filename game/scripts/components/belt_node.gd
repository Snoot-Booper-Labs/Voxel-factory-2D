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

## Belt speed in items per second
const BELT_SPEED: float = 1.0


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


## Add an item to this belt at progress 0.0
func add_item(item_type: int) -> void:
	items.append({"item_type": item_type, "progress": 0.0})


## Check if this belt has any items
func has_items() -> bool:
	return items.size() > 0


## Get all items on this belt
func get_items() -> Array[Dictionary]:
	return items


## Move items along belt, return items that reached the end (progress >= 1.0)
func tick(delta: float) -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	var remaining: Array[Dictionary] = []

	for item in items:
		item["progress"] += BELT_SPEED * delta
		if item["progress"] >= 1.0:
			completed.append(item)
		else:
			remaining.append(item)

	items = remaining
	return completed
