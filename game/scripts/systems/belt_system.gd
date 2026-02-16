## BeltSystem for processing conveyor belt item transport
## Manages all registered belts and handles item movement/transfer.
## Spawns visual ItemEntity nodes that move along belt segments.
class_name BeltSystem
extends System

## Array of all registered belt nodes
var belts: Array[BeltNode] = []

## Parent node for spawning dropped item entities (set by Main or owner)
var item_drop_parent: Node = null

## Signal emitted when an item falls off the end of a belt with no connection
signal item_dropped(item_type: int, world_pos: Vector2)


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

		# Update visual positions for items still on this belt
		_update_belt_item_visuals(belt)

		# Queue transfers for items that completed
		for item in completed:
			if belt.next_belt:
				transfers.append({"belt": belt.next_belt, "item_type": item["item_type"]})
			else:
				# Item fell off the end of the belt — spawn as world item
				var drop_pos := _belt_end_world_pos(belt)
				item_dropped.emit(item["item_type"], drop_pos)
				if item_drop_parent and is_instance_valid(item_drop_parent):
					ItemEntity.spawn(item_drop_parent, item["item_type"], 1, drop_pos)

	# Second pass: apply all transfers
	for transfer in transfers:
		transfer["belt"].add_item(transfer["item_type"])


## Find a belt at the given grid position
func get_belt_at(pos: Vector2i) -> BeltNode:
	for belt in belts:
		if belt.position == pos:
			return belt
	return null


## Update visual positions of ItemEntity nodes riding a belt segment.
## Items on belts are represented as ItemEntity nodes with `on_belt = true`.
func _update_belt_item_visuals(belt: BeltNode) -> void:
	if belt.entity == null or not is_instance_valid(belt.entity):
		return

	var belt_entity: Node2D = belt.entity as Node2D
	if belt_entity == null:
		return

	# Get direction vector for interpolation
	var dir_vec := _belt_direction_vector(belt.direction)
	var tile_size := float(WorldUtils.TILE_SIZE)

	# Match visual item entities to belt item data
	# We look for ItemEntity children of the belt's entity node
	var visual_items := _get_belt_visual_items(belt_entity)
	var data_items := belt.get_items()

	# Spawn missing visuals
	while visual_items.size() < data_items.size():
		var idx := visual_items.size()
		var item_data: Dictionary = data_items[idx]
		var item_entity := ItemEntity.new()
		item_entity.item_type = item_data["item_type"]
		item_entity.count = 1
		item_entity.on_belt = true
		item_entity.name = "BeltItem_%d" % idx
		item_entity.add_to_group("item_entities")
		belt_entity.add_child(item_entity)
		visual_items.append(item_entity)

	# Remove excess visuals
	while visual_items.size() > data_items.size():
		var excess: ItemEntity = visual_items.pop_back()
		if is_instance_valid(excess):
			excess.queue_free()

	# Update positions based on progress
	for i in range(data_items.size()):
		if i < visual_items.size() and is_instance_valid(visual_items[i]):
			var progress: float = data_items[i]["progress"]
			visual_items[i].position = dir_vec * progress * tile_size


## Get all ItemEntity children of a belt entity node
func _get_belt_visual_items(belt_entity: Node2D) -> Array:
	var result: Array = []
	for child in belt_entity.get_children():
		if child is ItemEntity and child.on_belt:
			result.append(child)
	return result


## Calculate the world position at the end of a belt segment
func _belt_end_world_pos(belt: BeltNode) -> Vector2:
	var dir_vec := _belt_direction_vector(belt.direction)
	return WorldUtils.tile_to_world(belt.position) + dir_vec * float(WorldUtils.TILE_SIZE)


## Convert BeltNode.Direction to a Vector2 direction
func _belt_direction_vector(dir: BeltNode.Direction) -> Vector2:
	match dir:
		BeltNode.Direction.RIGHT:
			return Vector2(1, 0)
		BeltNode.Direction.LEFT:
			return Vector2(-1, 0)
		BeltNode.Direction.UP:
			return Vector2(0, -1)  # Screen Y is inverted
		BeltNode.Direction.DOWN:
			return Vector2(0, 1)
	return Vector2.ZERO
