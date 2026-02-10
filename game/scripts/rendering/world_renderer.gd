class_name WorldRenderer
extends Node2D
## Bridges TileWorld to TileMapLayer for visual rendering
##
## Listens to TileWorld.block_changed signal and updates TileMapLayer cells.
## Uses the terrain_tileset.tres where BlockType values map to atlas X coordinates.

const TILESET_PATH = "res://game/resources/tiles/terrain_tileset.tres"

var tile_world: TileWorld
var tile_map_layer: TileMapLayer

const TILE_SOURCE_ID = 0  # Atlas source ID in TileSet


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
