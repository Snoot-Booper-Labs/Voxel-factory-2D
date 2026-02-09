class_name TileWorld
extends RefCounted
## Dictionary-based tile storage for 2D world data
##
## Stores tiles in a Dictionary keyed by Vector2i coordinates.
## Generates terrain on demand using TerrainGenerator when a tile is first accessed.
## Emits signals when blocks are changed.

var world_seed: int = 0
var terrain_generator: TerrainGenerator
var _tiles: Dictionary = {}  # Vector2i -> int (BlockType)

signal block_changed(position: Vector2i, old_type: int, new_type: int)


func _init(seed_value: int = 0) -> void:
	world_seed = seed_value
	terrain_generator = TerrainGenerator.new(seed_value)


func get_block(x: int, y: int) -> int:
	var pos := Vector2i(x, y)
	if _tiles.has(pos):
		return _tiles[pos]
	# Generate on demand
	var block_type := terrain_generator.get_block_at(x, y)
	_tiles[pos] = block_type
	return block_type


func set_block(x: int, y: int, block_type: int) -> void:
	var pos := Vector2i(x, y)
	var old_type := get_block(x, y)
	_tiles[pos] = block_type
	block_changed.emit(pos, old_type, block_type)


func is_solid(x: int, y: int) -> bool:
	return BlockData.is_solid(get_block(x, y))
