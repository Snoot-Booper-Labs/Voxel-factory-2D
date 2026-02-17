class_name ItemData
extends Resource
## Data-driven item definitions using static dictionaries

enum ItemType {
	NONE = 0,
	# Block items (1-19)
	DIRT = 1,
	STONE = 2,
	WOOD = 3,
	LEAVES = 4,
	SAND = 5,
	GRASS = 6,
	COBBLESTONE = 7,
	PLANKS = 8,
	BEDROCK = 9,
	# Entities (10-19)
	MINER = 10,
	CONVEYOR = 11,
	# Material items (20-39)
	COAL = 20,
	IRON_ORE = 21,
	GOLD_ORE = 22,
	IRON_INGOT = 23,
	GOLD_INGOT = 24,
	DIAMOND = 25,
	# Tools (40-59)
	WOODEN_PICKAXE = 40,
	STONE_PICKAXE = 41,
	IRON_PICKAXE = 42,
	WOODEN_AXE = 43,
	STONE_AXE = 44,
	IRON_AXE = 45,
	WOODEN_SHOVEL = 46,
	STONE_SHOVEL = 47,
	IRON_SHOVEL = 48
}

# Item properties: max_stack, name, placeable, block (if placeable)
static var item_properties: Dictionary = {
	ItemType.NONE: {"max_stack": 0, "name": "None", "placeable": false},
	# Block items
	ItemType.DIRT: {"max_stack": 64, "name": "Dirt", "placeable": true, "block": 2}, # BlockData.BlockType.DIRT
	ItemType.STONE: {"max_stack": 64, "name": "Stone", "placeable": true, "block": 3}, # BlockData.BlockType.STONE
	ItemType.WOOD: {"max_stack": 64, "name": "Wood", "placeable": true, "block": 4}, # BlockData.BlockType.WOOD
	ItemType.LEAVES: {"max_stack": 64, "name": "Leaves", "placeable": true, "block": 5}, # BlockData.BlockType.LEAVES
	ItemType.SAND: {"max_stack": 64, "name": "Sand", "placeable": true, "block": 6}, # BlockData.BlockType.SAND
	ItemType.GRASS: {"max_stack": 64, "name": "Grass", "placeable": true, "block": 1}, # BlockData.BlockType.GRASS
	ItemType.COBBLESTONE: {"max_stack": 64, "name": "Cobblestone", "placeable": true, "block": 12}, # BlockData.BlockType.COBBLESTONE
	ItemType.PLANKS: {"max_stack": 64, "name": "Planks", "placeable": true, "block": 13}, # BlockData.BlockType.PLANKS
	ItemType.BEDROCK: {"max_stack": 64, "name": "Bedrock", "placeable": true, "block": 14}, # BlockData.BlockType.BEDROCK
	# Entity items
	ItemType.MINER: {"max_stack": 1, "name": "Miner", "placeable": true, "is_entity": true},
	ItemType.CONVEYOR: {"max_stack": 64, "name": "Conveyor", "placeable": true, "is_entity": true},
	# Material items
	ItemType.COAL: {"max_stack": 64, "name": "Coal", "placeable": false},
	ItemType.IRON_ORE: {"max_stack": 64, "name": "Iron Ore", "placeable": false},
	ItemType.GOLD_ORE: {"max_stack": 64, "name": "Gold Ore", "placeable": false},
	ItemType.IRON_INGOT: {"max_stack": 64, "name": "Iron Ingot", "placeable": false},
	ItemType.GOLD_INGOT: {"max_stack": 64, "name": "Gold Ingot", "placeable": false},
	ItemType.DIAMOND: {"max_stack": 64, "name": "Diamond", "placeable": false},
	# Tools (stack to 1)
	ItemType.WOODEN_PICKAXE: {"max_stack": 1, "name": "Wooden Pickaxe", "placeable": false, "tool_type": "pickaxe", "tool_tier": 0},
	ItemType.STONE_PICKAXE: {"max_stack": 1, "name": "Stone Pickaxe", "placeable": false, "tool_type": "pickaxe", "tool_tier": 1},
	ItemType.IRON_PICKAXE: {"max_stack": 1, "name": "Iron Pickaxe", "placeable": false, "tool_type": "pickaxe", "tool_tier": 2},
	ItemType.WOODEN_AXE: {"max_stack": 1, "name": "Wooden Axe", "placeable": false, "tool_type": "axe", "tool_tier": 0},
	ItemType.STONE_AXE: {"max_stack": 1, "name": "Stone Axe", "placeable": false, "tool_type": "axe", "tool_tier": 1},
	ItemType.IRON_AXE: {"max_stack": 1, "name": "Iron Axe", "placeable": false, "tool_type": "axe", "tool_tier": 2},
	ItemType.WOODEN_SHOVEL: {"max_stack": 1, "name": "Wooden Shovel", "placeable": false, "tool_type": "shovel", "tool_tier": 0},
	ItemType.STONE_SHOVEL: {"max_stack": 1, "name": "Stone Shovel", "placeable": false, "tool_type": "shovel", "tool_tier": 1},
	ItemType.IRON_SHOVEL: {"max_stack": 1, "name": "Iron Shovel", "placeable": false, "tool_type": "shovel", "tool_tier": 2}
}


static func get_max_stack(item_type: int) -> int:
	if item_properties.has(item_type):
		return item_properties[item_type]["max_stack"]
	return 64


static func get_item_name(item_type: int) -> String:
	if item_properties.has(item_type):
		return item_properties[item_type]["name"]
	return "Unknown"


static func is_placeable(item_type: int) -> bool:
	if item_properties.has(item_type):
		return item_properties[item_type]["placeable"]
	return false


static func get_block_for_item(item_type: int) -> int:
	if item_properties.has(item_type) and item_properties[item_type].has("block"):
		return item_properties[item_type]["block"]
	return 0


static func is_entity(item_type: int) -> bool:
	if item_properties.has(item_type) and item_properties[item_type].has("is_entity"):
		return item_properties[item_type]["is_entity"]
	return false


static func get_type_from_name(name_str: String) -> int:
	name_str = name_str.to_lower()
	for type in item_properties:
		var item_name = item_properties[type]["name"].to_lower()
		if item_name == name_str:
			return type
		# Handle some common mismatches if needed (e.g. "wood" vs "log")
	return ItemType.NONE
