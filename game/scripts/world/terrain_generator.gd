class_name TerrainGenerator
extends RefCounted
## 2D procedural terrain generation using FastNoiseLite and BiomePlanner
##
## Generates terrain blocks based on biome settings from BiomePlanner.
## Y-axis: Y=0 is bedrock level, higher Y is higher altitude.
## X-axis: Horizontal position, terrain height varies with X using simplex noise.

const SUBSURFACE_DEPTH: int = 4  # Number of subsurface blocks before deep underground

var world_seed: int = 0
var biome_planner: BiomePlanner
var height_noise: FastNoiseLite


func _init(seed_value: int = 0) -> void:
	world_seed = seed_value
	biome_planner = BiomePlanner.new(seed_value)
	_setup_noise()


func _setup_noise() -> void:
	height_noise = FastNoiseLite.new()
	height_noise.seed = world_seed
	height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	height_noise.frequency = 1.0 / 64.0  # Smoother terrain for 2D


func get_block_at(x: int, y: int) -> int:
	# Get biome at this horizontal position (use x for horizontal biome lookup)
	var biome_type := biome_planner.get_biome_at(x, 0)
	var params := BiomeData.get_biome_params(biome_type)

	# Calculate terrain height at this x position
	var terrain_height := _get_terrain_height(x, params)

	# Determine block type based on y relative to terrain height
	if y > terrain_height:
		return BlockData.BlockType.AIR
	elif y == terrain_height:
		return params["surface_block"]
	elif y > terrain_height - SUBSURFACE_DEPTH:
		return params["subsurface_block"]
	else:
		# Deep underground - stone or ore
		return _get_underground_block(x, y)


func _get_terrain_height(x: int, params: Dictionary) -> int:
	var height_range: Vector2i = params["height_range"]
	var noise_val := (height_noise.get_noise_1d(float(x)) + 1.0) / 2.0  # Normalize to 0-1
	return int(lerp(float(height_range.x), float(height_range.y), noise_val))


func _get_underground_block(x: int, y: int) -> int:
	# Simple underground generation - could add ore veins later
	# For now, return STONE for all deep underground blocks
	return BlockData.BlockType.STONE
