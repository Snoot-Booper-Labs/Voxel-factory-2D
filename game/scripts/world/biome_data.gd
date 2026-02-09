@tool
class_name BiomeData
extends Resource
## Data-driven biome definitions using static dictionaries

# Biome IDs for 2D tile-based game
enum BiomeType {
	PLAINS = 0,
	FOREST = 1,
	DESERT = 2,
	MOUNTAINS = 3,
	OCEAN = 4
}

# Biome parameters: height ranges, surface blocks, etc.
static var biome_params: Dictionary = {
	BiomeType.PLAINS: {
		"name": "Plains",
		"height_range": Vector2i(20, 40),
		"surface_block": BlockData.BlockType.GRASS,
		"subsurface_block": BlockData.BlockType.DIRT,
		"vegetation_density": 0.1,
		"temperature": 0.5,
		"humidity": 0.5
	},
	BiomeType.FOREST: {
		"name": "Forest",
		"height_range": Vector2i(25, 45),
		"surface_block": BlockData.BlockType.GRASS,
		"subsurface_block": BlockData.BlockType.DIRT,
		"vegetation_density": 0.6,
		"temperature": 0.4,
		"humidity": 0.7
	},
	BiomeType.DESERT: {
		"name": "Desert",
		"height_range": Vector2i(15, 35),
		"surface_block": BlockData.BlockType.SAND,
		"subsurface_block": BlockData.BlockType.SAND,
		"vegetation_density": 0.02,
		"temperature": 0.8,
		"humidity": 0.2
	},
	BiomeType.MOUNTAINS: {
		"name": "Mountains",
		"height_range": Vector2i(50, 80),
		"surface_block": BlockData.BlockType.STONE,
		"subsurface_block": BlockData.BlockType.STONE,
		"vegetation_density": 0.05,
		"temperature": 0.2,
		"humidity": 0.4
	},
	BiomeType.OCEAN: {
		"name": "Ocean",
		"height_range": Vector2i(5, 15),
		"surface_block": BlockData.BlockType.WATER,
		"subsurface_block": BlockData.BlockType.SAND,
		"vegetation_density": 0.0,
		"temperature": 0.5,
		"humidity": 0.9
	}
}


static func get_biome_name(biome_type: int) -> String:
	if biome_params.has(biome_type):
		return biome_params[biome_type]["name"]
	return "Unknown"


static func get_biome_params(biome_type: int) -> Dictionary:
	if biome_params.has(biome_type):
		return biome_params[biome_type]
	return {}


static func get_biome_from_climate(temperature: float, humidity: float) -> int:
	# Climate to biome logic:
	# - Very wet (humid > 0.85) -> OCEAN
	# - Cold (temp < 0.3) -> MOUNTAINS
	# - Hot + Dry (temp > 0.6, humid < 0.4) -> DESERT
	# - Wet (humid > 0.6) -> FOREST
	# - Default -> PLAINS

	if humidity > 0.85:
		return BiomeType.OCEAN

	if temperature < 0.3:
		return BiomeType.MOUNTAINS

	if temperature > 0.6 and humidity < 0.4:
		return BiomeType.DESERT

	if humidity > 0.6:
		return BiomeType.FOREST

	return BiomeType.PLAINS
