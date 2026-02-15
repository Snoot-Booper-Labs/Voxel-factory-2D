class_name TileWorld
extends RefCounted
## Dictionary-based tile storage for 2D world data
##
## Stores tiles in a Dictionary keyed by Vector2i coordinates.
## Generates terrain on demand using TerrainGenerator when a tile is first accessed.
## Emits signals when blocks are changed.
## Tracks player-modified tiles separately for efficient serialization.

var world_seed: int = 0
var terrain_generator: TerrainGenerator
var _tiles: Dictionary = {}  # Vector2i -> int (BlockType)
var _modified_tiles: Dictionary = {}  # Vector2i -> int (only player-changed tiles)

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
	_modified_tiles[pos] = block_type
	block_changed.emit(pos, old_type, block_type)


func is_solid(x: int, y: int) -> bool:
	return BlockData.is_solid(get_block(x, y))


## Returns a dictionary of all player-modified tiles for serialization.
## Format: { "x,y": block_type_int, ... }
func get_modified_tiles() -> Dictionary:
	var result := {}
	for pos in _modified_tiles:
		var key := "%d,%d" % [pos.x, pos.y]
		result[key] = _modified_tiles[pos]
	return result


## Restores modified tiles from a serialized dictionary.
## Overwrites generated terrain with saved values.
func load_modified_tiles(data: Dictionary) -> void:
	for key in data:
		var parts := (key as String).split(",")
		if parts.size() != 2:
			continue
		var x := int(parts[0])
		var y := int(parts[1])
		var block_type: int = int(data[key])
		var pos := Vector2i(x, y)
		_tiles[pos] = block_type
		_modified_tiles[pos] = block_type


## Serialize world state to a dictionary.
## Only includes the seed and player-modified tiles.
func serialize() -> Dictionary:
	return {
		"seed": world_seed,
		"modified_tiles": get_modified_tiles(),
	}


## Create a new TileWorld from serialized data.
## Restores seed and modified tiles; unmodified terrain regenerates on demand.
static func deserialize(data: Dictionary) -> TileWorld:
	var seed_value: int = int(data.get("seed", 0))
	var world := TileWorld.new(seed_value)
	var modified: Dictionary = data.get("modified_tiles", {})
	world.load_modified_tiles(modified)
	return world
