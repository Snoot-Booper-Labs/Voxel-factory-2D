@tool
class_name BlockData
extends Resource
## Data-driven block definitions using static dictionaries

# Block IDs for 2D tile-based game
enum BlockType {
	AIR = 0,
	GRASS = 1,
	DIRT = 2,
	STONE = 3,
	WOOD = 4,
	LEAVES = 5,
	SAND = 6,
	WATER = 7,
	COAL_ORE = 8,
	IRON_ORE = 9,
	GOLD_ORE = 10,
	DIAMOND_ORE = 11,
	COBBLESTONE = 12,
	PLANKS = 13,
	BEDROCK = 14
}

# Block properties: hardness, tool_type, drop_item, drop_count
# hardness: time in seconds to break with bare hands (-1 = unbreakable)
# tool: preferred tool type for faster breaking
# drops: item name dropped when broken
# drop_count: number of items dropped
static var block_properties: Dictionary = {
	BlockType.AIR: {"hardness": 0.0, "tool": "", "drops": "", "drop_count": 0},
	BlockType.GRASS: {"hardness": 0.6, "tool": "shovel", "drops": "dirt", "drop_count": 1},
	BlockType.DIRT: {"hardness": 0.5, "tool": "shovel", "drops": "dirt", "drop_count": 1},
	BlockType.STONE: {"hardness": 1.5, "tool": "pickaxe", "drops": "cobblestone", "drop_count": 1},
	BlockType.WOOD: {"hardness": 2.0, "tool": "axe", "drops": "wood", "drop_count": 1},
	BlockType.LEAVES: {"hardness": 0.2, "tool": "", "drops": "", "drop_count": 0},
	BlockType.SAND: {"hardness": 0.5, "tool": "shovel", "drops": "sand", "drop_count": 1},
	BlockType.WATER: {"hardness": 0.0, "tool": "", "drops": "", "drop_count": 0},
	BlockType.COAL_ORE: {"hardness": 3.0, "tool": "pickaxe", "drops": "coal", "drop_count": 1},
	BlockType.IRON_ORE: {"hardness": 3.0, "tool": "pickaxe", "drops": "iron_ore", "drop_count": 1},
	BlockType.GOLD_ORE: {"hardness": 3.0, "tool": "pickaxe", "drops": "gold_ore", "drop_count": 1},
	BlockType.DIAMOND_ORE: {"hardness": 3.0, "tool": "pickaxe", "drops": "diamond", "drop_count": 1},
	BlockType.COBBLESTONE: {"hardness": 2.0, "tool": "pickaxe", "drops": "cobblestone", "drop_count": 1},
	BlockType.PLANKS: {"hardness": 2.0, "tool": "axe", "drops": "planks", "drop_count": 1},
	BlockType.BEDROCK: {"hardness": -1.0, "tool": "", "drops": "", "drop_count": 0}
}


static func get_block_hardness(block_type: int) -> float:
	if block_properties.has(block_type):
		return block_properties[block_type]["hardness"]
	return 1.0


static func is_solid(block_type: int) -> bool:
	return block_type != BlockType.AIR and block_type != BlockType.WATER


static func get_block_drops(block_type: int) -> Dictionary:
	if block_properties.has(block_type):
		return {
			"item": block_properties[block_type]["drops"],
			"count": block_properties[block_type]["drop_count"]
		}
	return {"item": "", "count": 0}


static func get_block_tool(block_type: int) -> String:
	if block_properties.has(block_type):
		return block_properties[block_type]["tool"]
	return ""
