## BeltSystem for processing conveyor belt item transport
## Manages all registered belts and handles item movement/transfer
class_name BeltSystem
extends System

## Array of all registered belt nodes
var belts: Array[BeltNode] = []


func _init() -> void:
	required_components = ["BeltNode"]


## Register a belt node with this system
func register_belt(belt: BeltNode) -> void:
	if belt not in belts:
		belts.append(belt)


## Unregister a belt node from this system
func unregister_belt(belt: BeltNode) -> void:
	belts.erase(belt)


## Process all belts, moving items and handling transfers
func process_belts(delta: float) -> void:
	# First pass: tick all belts and collect transfers
	# This ensures items transferred this tick don't advance until next tick
	var transfers: Array[Dictionary] = []

	for belt in belts:
		var completed := belt.tick(delta)

		# Queue transfers for items that completed
		for item in completed:
			if belt.next_belt:
				transfers.append({"belt": belt.next_belt, "item_type": item["item_type"]})
			# If no next belt, items fall off (could emit signal in future)

	# Second pass: apply all transfers
	for transfer in transfers:
		transfer["belt"].add_item(transfer["item_type"])


## Find a belt at the given grid position
func get_belt_at(pos: Vector2i) -> BeltNode:
	for belt in belts:
		if belt.position == pos:
			return belt
	return null
