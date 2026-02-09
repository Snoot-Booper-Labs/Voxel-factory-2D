## MineBlock command - mines a block at a specified position
## Removes the block from the world and adds drops to inventory
class_name MineBlock
extends CommandBlock


func _init() -> void:
	super(BlockType.MINE)


## Executes the mine command
## Gets position from parameters, mines block from world, adds drops to inventory
func execute(context: Dictionary) -> CommandBlock:
	execution_started.emit()

	# Get mining position from parameters
	var target_x: int = get_parameter("x", 0)
	var target_y: int = get_parameter("y", 0)

	# Get world and inventory from context
	var world: TileWorld = context.get("world")
	var inventory: Inventory = context.get("inventory")

	if world and inventory:
		var block_type := world.get_block(target_x, target_y)
		if block_type != BlockData.BlockType.AIR:
			# Get drops for this block
			var drops := BlockData.get_block_drops(block_type)
			if drops["item"] != "":
				# Convert drop name to ItemType
				var item_type := _get_item_for_drop(drops["item"])
				if item_type != ItemData.ItemType.NONE:
					inventory.add_item(item_type, drops["count"])
			# Remove the block
			world.set_block(target_x, target_y, BlockData.BlockType.AIR)

	execution_completed.emit(next_block)
	return next_block


## Maps drop names to ItemType enum values
func _get_item_for_drop(drop_name: String) -> int:
	match drop_name:
		"dirt":
			return ItemData.ItemType.DIRT
		"stone":
			return ItemData.ItemType.STONE
		"cobblestone":
			return ItemData.ItemType.COBBLESTONE
		"coal":
			return ItemData.ItemType.COAL
		"sand":
			return ItemData.ItemType.SAND
		"wood":
			return ItemData.ItemType.WOOD
		"iron_ore":
			return ItemData.ItemType.IRON_ORE
		"gold_ore":
			return ItemData.ItemType.GOLD_ORE
		"diamond":
			return ItemData.ItemType.DIAMOND
		"planks":
			return ItemData.ItemType.PLANKS
		_:
			return ItemData.ItemType.NONE
