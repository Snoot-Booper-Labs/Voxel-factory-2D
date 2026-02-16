class_name PlacementController
extends Node
## Handles block placement from inventory
##
## Places blocks from selected hotbar slot within range.

signal block_placed(position: Vector2i, block_type: int)

const PLACEMENT_RANGE: float = 80.0 # 5 tiles * 16 pixels

var tile_world: TileWorld
var inventory: Inventory
var belt_system: BeltSystem
var player_position: Vector2 = Vector2.ZERO
var selected_slot: int = 0 # Current hotbar slot


func setup(world: TileWorld, inv: Inventory, p_belt_system: BeltSystem = null) -> void:
	tile_world = world
	inventory = inv
	if p_belt_system:
		belt_system = p_belt_system


func set_player_position(pos: Vector2) -> void:
	player_position = pos


func set_selected_slot(slot: int) -> void:
	selected_slot = clamp(slot, 0, 8) # Hotbar slots 0-8


func try_place_at(world_position: Vector2) -> bool:
	## Returns true if placement succeeded
	if tile_world == null or inventory == null:
		return false

	# Check range
	if not is_in_range(world_position):
		return false

	# Get selected item
	var slot_data = inventory.get_slot(selected_slot)
	if slot_data.item == 0 or slot_data.count <= 0:
		return false

	# Check if item is placeable
	if not ItemData.is_placeable(slot_data.item):
		return false

	# Convert to tile coordinates
	var tile_pos = WorldUtils.world_to_tile(world_position)

	# Check if mining/entity placement logic applies
	if ItemData.is_entity(slot_data.item):
		return _try_place_entity(slot_data.item, world_position)

	# Block placement logic
	# Check if target is empty (air)
	if tile_world.get_block(tile_pos.x, tile_pos.y) != BlockData.BlockType.AIR:
		return false

	# Get block type for item
	var block_type = ItemData.get_block_for_item(slot_data.item)

	# Place the block
	tile_world.set_block(tile_pos.x, tile_pos.y, block_type)

	# Remove item from inventory
	inventory.remove_item(selected_slot, 1)

	block_placed.emit(tile_pos, block_type)
	return true


func _try_place_entity(item_type: int, world_pos: Vector2) -> bool:
	if item_type == ItemData.ItemType.MINER:
		return _try_place_miner(world_pos)
	elif item_type == ItemData.ItemType.CONVEYOR:
		return _try_place_conveyor(world_pos)
	return false


func _try_place_miner(world_pos: Vector2) -> bool:
	var tile_pos = WorldUtils.world_to_tile(world_pos)

	# Check if space is clear
	if tile_world.is_solid(tile_pos.x, tile_pos.y):
		return false

	# Determine direction based on player relative position
	var direction = Vector2i.RIGHT
	if world_pos.x < player_position.x:
		direction = Vector2i.LEFT

	var miner_scene = load("res://scenes/entities/miner.tscn")
	if miner_scene:
		var miner = miner_scene.instantiate()
		get_parent().add_child(miner)

		var spawn_pos = WorldUtils.tile_to_world(tile_pos)
		if miner.has_method("setup"):
			miner.setup(tile_world, spawn_pos, direction, belt_system)

		inventory.remove_item(selected_slot, 1)
		return true

	return false


func _try_place_conveyor(world_pos: Vector2) -> bool:
	var tile_pos = WorldUtils.world_to_tile(world_pos)

	# Don't place on solid blocks
	if tile_world.is_solid(tile_pos.x, tile_pos.y):
		return false

	# Don't place on top of an existing belt
	if belt_system and belt_system.get_belt_at(tile_pos) != null:
		return false

	# Determine direction based on player relative position
	var dir := BeltNode.Direction.RIGHT
	if world_pos.x < player_position.x:
		dir = BeltNode.Direction.LEFT

	var conveyor_scene = load("res://scenes/entities/conveyor.tscn")
	if conveyor_scene:
		var conveyor: Conveyor = conveyor_scene.instantiate()
		get_parent().add_child(conveyor)
		conveyor.setup(tile_pos, dir)

		# Register with belt system
		if belt_system:
			belt_system.register_belt(conveyor.get_belt())

		inventory.remove_item(selected_slot, 1)
		return true

	return false


func is_in_range(world_position: Vector2) -> bool:
	return player_position.distance_to(world_position) <= PLACEMENT_RANGE


func get_selected_item() -> int:
	if inventory == null:
		return 0
	var slot_data = inventory.get_slot(selected_slot)
	return slot_data.item
