class_name WorldRenderer
extends Node2D
## Bridges TileWorld to TileMapLayer for visual rendering
##
## Listens to TileWorld.block_changed signal and updates TileMapLayer cells.
## Uses the terrain_tileset.tres where BlockType values map to atlas X coordinates.

const TILESET_PATH = "res://game/resources/tiles/terrain_tileset.tres"

var tile_world: TileWorld
var tile_map_layer: TileMapLayer

const TILE_SOURCE_ID = 0 # Atlas source ID in TileSet


func _ready() -> void:
	_setup_tile_map_layer()


func _setup_tile_map_layer() -> void:
	## Create and configure the TileMapLayer
	tile_map_layer = TileMapLayer.new()
	# Load tileset at runtime to avoid parse-time loading issues in headless mode
	# Use FileAccess check to avoid triggering resource parsing errors
	if FileAccess.file_exists(TILESET_PATH):
		var tileset = load(TILESET_PATH)
		if tileset:
			tile_map_layer.tile_set = tileset
	add_child(tile_map_layer)


func set_tile_set(tileset: TileSet) -> void:
	## Set a custom TileSet (useful for testing)
	if tile_map_layer:
		tile_map_layer.tile_set = tileset


func set_tile_world(world: TileWorld) -> void:
	## Connect to a TileWorld and listen for block changes
	if tile_world != null and tile_world.block_changed.is_connected(_on_block_changed):
		tile_world.block_changed.disconnect(_on_block_changed)

	tile_world = world
	if tile_world != null:
		tile_world.block_changed.connect(_on_block_changed)


func _on_block_changed(pos: Vector2i, _old_type: int, new_type: int) -> void:
	## Update TileMapLayer when a block changes in TileWorld
	## Negate Y because Godot screen Y is down, but world Y is up (altitude)
	var screen_pos := Vector2i(pos.x, -pos.y)
	if new_type == BlockData.BlockType.AIR:
		tile_map_layer.erase_cell(screen_pos)
	else:
		# BlockType value maps directly to atlas X coordinate
		tile_map_layer.set_cell(screen_pos, TILE_SOURCE_ID, Vector2i(new_type, 0))


const CHUNK_SIZE: int = 16
const RENDER_DISTANCE: int = 5 # Radius in chunks
const TILE_SIZE: int = 16 # Matches project settings

var tracking_target: Node2D
var _loaded_chunks: Dictionary = {} # Vector2i -> bool
var _last_chunk_pos: Vector2i = Vector2i(999999, 999999) # Initialize far away

signal chunk_loaded(chunk_pos: Vector2i)
signal chunk_unloaded(chunk_pos: Vector2i)


func _process(_delta: float) -> void:
	if tracking_target == null or tile_world == null:
		return

	var current_chunk = _get_chunk_coords(tracking_target.global_position)

	if current_chunk != _last_chunk_pos:
		_update_chunks(current_chunk)
		_last_chunk_pos = current_chunk


func set_tracking_target(target: Node2D) -> void:
	tracking_target = target
	# Force update
	_last_chunk_pos = Vector2i(999999, 999999)


func _get_chunk_coords(world_pos: Vector2) -> Vector2i:
	# World Y is up (positive), Screen Y is down (positive).
	# Tile coordinates: x = floor(world_x / 16), y = floor(-world_y / 16)
	var tile_x = floor(world_pos.x / TILE_SIZE)
	# Negate Y because Godot screen Y is down, but world Y is up (altitude)
	var tile_y = floor(-world_pos.y / TILE_SIZE)

	return Vector2i(
		int(floor(tile_x / CHUNK_SIZE)),
		int(floor(tile_y / CHUNK_SIZE))
	)


func _update_chunks(center_chunk: Vector2i) -> void:
	var needed_chunks = {}

	# Determine which chunks should be visible
	for y in range(center_chunk.y - RENDER_DISTANCE, center_chunk.y + RENDER_DISTANCE + 1):
		for x in range(center_chunk.x - RENDER_DISTANCE, center_chunk.x + RENDER_DISTANCE + 1):
			needed_chunks[Vector2i(x, y)] = true

	# Unload chunks that are no longer needed
	var chunks_to_remove = []
	for chunk in _loaded_chunks:
		if not needed_chunks.has(chunk):
			chunks_to_remove.append(chunk)

	for chunk in chunks_to_remove:
		_unload_chunk(chunk)

	# Load new chunks
	for chunk in needed_chunks:
		if not _loaded_chunks.has(chunk):
			_load_chunk(chunk)


func _load_chunk(chunk_pos: Vector2i) -> void:
	_loaded_chunks[chunk_pos] = true
	var start = chunk_pos * CHUNK_SIZE
	var end = start + Vector2i(CHUNK_SIZE - 1, CHUNK_SIZE - 1)
	render_region(start, end)
	chunk_loaded.emit(chunk_pos)


func _unload_chunk(chunk_pos: Vector2i) -> void:
	_loaded_chunks.erase(chunk_pos)
	var start_tile = chunk_pos * CHUNK_SIZE

	# Clear the cells in this chunk
	for y in range(CHUNK_SIZE):
		for x in range(CHUNK_SIZE):
			var tile_pos = start_tile + Vector2i(x, y)
			# Convert to screen coordinates
			var screen_pos = Vector2i(tile_pos.x, -tile_pos.y)
			tile_map_layer.erase_cell(screen_pos)

	chunk_unloaded.emit(chunk_pos)


func render_region(start: Vector2i, end: Vector2i) -> void:
	## Render all blocks in a rectangular region
	## Useful for initial world rendering or chunk loading
	if tile_world == null:
		return

	for y in range(start.y, end.y + 1):
		for x in range(start.x, end.x + 1):
			var block_type = tile_world.get_block(x, y)
			## Negate Y because Godot screen Y is down, but world Y is up (altitude)
			var screen_pos := Vector2i(x, -y)
			if block_type == BlockData.BlockType.AIR:
				tile_map_layer.erase_cell(screen_pos)
			else:
				tile_map_layer.set_cell(screen_pos, TILE_SOURCE_ID, Vector2i(block_type, 0))


func clear() -> void:
	## Clear all rendered tiles
	tile_map_layer.clear()
	_loaded_chunks.clear()
	_last_chunk_pos = Vector2i(999999, 999999)
