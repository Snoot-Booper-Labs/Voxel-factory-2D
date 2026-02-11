class_name PlacementController
extends Node
## Handles block placement from inventory
##
## Places blocks from selected hotbar slot within range.

signal block_placed(position: Vector2i, block_type: int)

const PLACEMENT_RANGE: float = 80.0 # 5 tiles * 16 pixels
const TILE_SIZE: int = 16

var tile_world: TileWorld
var inventory: Inventory
var player_position: Vector2 = Vector2.ZERO
var selected_slot: int = 0 # Current hotbar slot


func setup(world: TileWorld, inv: Inventory) -> void:
	tile_world = world
	inventory = inv


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
	var tile_pos = world_to_tile(world_position)

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
		var tile_pos = world_to_tile(world_pos)

		# Check if space is clear (2 blocks wide) -> Wait, entities can overlap blocks?
		# Prompt says "placed down should mine straight left or right".
		# Assuming it needs space? Or replaces blocks?
		# "placed down should mine... don't worry about drawing that inventory".
		# "make it a 2 block wide... with the 'front' being a darker...".
		# Let's assume it requires empty space to be placed initially.
		# Check (x,y) and (x+1,y) or just (x,y)?
		# Let's check the origin tile for now.
		if tile_world.is_solid(tile_pos.x, tile_pos.y):
			return false

		# Determine direction based on player relative position
		# If click is to the right of player, face right. Else left.
		var direction = Vector2i.RIGHT
		if world_pos.x < player_position.x:
			direction = Vector2i.LEFT

		# Instantiate Miner
		# Note: We need a better way to get the scene path, but hardcoding for this task
		var miner_scene = load("res://game/scenes/entities/miner.tscn")
		if miner_scene:
			var miner = miner_scene.instantiate()
			# Add to Main scene root (owner of placement controller usually Main)
			# Find main scene
			var main = get_node("/root/Main") # Might be unsafe if scene name changes
			# Better: use get_tree().current_scene if it is Main, or owner if setup correctly
			# For now, let's try adding to parent of this node (Main)
			get_parent().add_child(miner)

			# Setup miner
			# Position: centered on tile? Tiles are 16x16.
			# Origin is usually top-left of tile in this system?
			# world_to_tile truncates.
			# tile * 16 is top-left.
			# Miner scene visuals are 0,0 to 32,16.
			# Let's place at tile_pos * 16. Y is inverted.
			var spawn_pos = Vector2(tile_pos.x * 16.0, -tile_pos.y * 16.0)

			if miner.has_method("setup"):
				miner.setup(tile_world, spawn_pos, direction)

			# Remove item
			inventory.remove_item(selected_slot, 1)
			return true

	return false


func is_in_range(world_position: Vector2) -> bool:
	return player_position.distance_to(world_position) <= PLACEMENT_RANGE


func world_to_tile(world_pos: Vector2) -> Vector2i:
	## Convert screen position to tile coordinates
	## Negate Y because screen Y is down but tile world Y is up (altitude)
	return Vector2i(
		int(floor(world_pos.x / TILE_SIZE)),
		- int(floor(world_pos.y / TILE_SIZE))
	)


func get_selected_item() -> int:
	if inventory == null:
		return 0
	var slot_data = inventory.get_slot(selected_slot)
	return slot_data.item
