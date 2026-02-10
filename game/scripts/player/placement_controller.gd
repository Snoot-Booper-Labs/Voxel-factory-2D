class_name PlacementController
extends Node
## Handles block placement from inventory
##
## Places blocks from selected hotbar slot within range.

signal block_placed(position: Vector2i, block_type: int)

const PLACEMENT_RANGE: float = 80.0  # 5 tiles * 16 pixels
const TILE_SIZE: int = 16

var tile_world: TileWorld
var inventory: Inventory
var player_position: Vector2 = Vector2.ZERO
var selected_slot: int = 0  # Current hotbar slot


func setup(world: TileWorld, inv: Inventory) -> void:
	tile_world = world
	inventory = inv


func set_player_position(pos: Vector2) -> void:
	player_position = pos


func set_selected_slot(slot: int) -> void:
	selected_slot = clamp(slot, 0, 8)  # Hotbar slots 0-8


func try_place_at(world_position: Vector2) -> bool:
	## Attempt to place block at world position from selected slot
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
	var tile_pos = world_to_tile(world_position)

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


func is_in_range(world_position: Vector2) -> bool:
	return player_position.distance_to(world_position) <= PLACEMENT_RANGE


func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / TILE_SIZE)),
		int(floor(world_pos.y / TILE_SIZE))
	)


func get_selected_item() -> int:
	if inventory == null:
		return 0
	var slot_data = inventory.get_slot(selected_slot)
	return slot_data.item
