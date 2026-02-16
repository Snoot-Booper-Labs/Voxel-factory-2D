class_name MiningController
extends Node
## Handles click-to-mine interaction
##
## Checks mining range, removes blocks, and adds drops to inventory.

signal block_mined(position: Vector2i, block_type: int)

const MINING_RANGE: float = 80.0 # 5 tiles * 16 pixels

var tile_world: TileWorld
var inventory: Inventory
var player_position: Vector2 = Vector2.ZERO

## Maps drop string names to ItemData.ItemType enum values
static var _item_name_map: Dictionary = {
	"dirt": ItemData.ItemType.DIRT,
	"stone": ItemData.ItemType.STONE,
	"wood": ItemData.ItemType.WOOD,
	"leaves": ItemData.ItemType.LEAVES,
	"sand": ItemData.ItemType.SAND,
	"grass": ItemData.ItemType.GRASS,
	"cobblestone": ItemData.ItemType.COBBLESTONE,
	"planks": ItemData.ItemType.PLANKS,
	"coal": ItemData.ItemType.COAL,
	"iron_ore": ItemData.ItemType.IRON_ORE,
	"gold_ore": ItemData.ItemType.GOLD_ORE,
	"diamond": ItemData.ItemType.DIAMOND,
}


func setup(world: TileWorld, inv: Inventory) -> void:
	tile_world = world
	inventory = inv


func set_player_position(pos: Vector2) -> void:
	player_position = pos


func try_mine_at(world_position: Vector2) -> bool:
	## Attempt to mine block at world position
	## Returns true if mining succeeded
	if tile_world == null or inventory == null:
		return false

	# Check range
	var distance = player_position.distance_to(world_position)
	if distance > MINING_RANGE:
		return false

	# Convert to tile coordinates
	var tile_pos = WorldUtils.world_to_tile(world_position)

	# Get block type
	var block_type = tile_world.get_block(tile_pos.x, tile_pos.y)

	# Can't mine air
	if block_type == BlockData.BlockType.AIR:
		return false

	# Get drops before removing block
	var drops = BlockData.get_block_drops(block_type)

	# Remove block (set to air)
	tile_world.set_block(tile_pos.x, tile_pos.y, BlockData.BlockType.AIR)

	# Add drops to inventory (overflow spawns as item entity)
	if drops.has("item") and drops.item != "":
		var item_type = _get_item_type_from_name(drops.item)
		if item_type != ItemData.ItemType.NONE:
			var remaining := inventory.add_item(item_type, drops.count)
			if remaining > 0:
				# Spawn overflow as item entity at the mined block position
				var drop_pos := WorldUtils.tile_to_world(tile_pos) + Vector2(WorldUtils.TILE_SIZE / 2.0, WorldUtils.TILE_SIZE / 2.0)
				var parent := get_parent()
				if parent:
					ItemEntity.spawn(parent, item_type, remaining, drop_pos)

	block_mined.emit(tile_pos, block_type)
	return true


func is_in_range(world_position: Vector2) -> bool:
	return player_position.distance_to(world_position) <= MINING_RANGE


static func _get_item_type_from_name(item_name: String) -> int:
	## Convert a drop name string to an ItemType enum value
	if _item_name_map.has(item_name):
		return _item_name_map[item_name]
	return ItemData.ItemType.NONE
