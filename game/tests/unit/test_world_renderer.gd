extends GutTest
## Unit tests for WorldRenderer


# Helper function to create a test TileSet programmatically
func _create_test_tileset() -> TileSet:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)

	# Create an atlas source with a placeholder texture
	var atlas = TileSetAtlasSource.new()
	var texture = PlaceholderTexture2D.new()
	texture.size = Vector2i(256, 16) # 16 tiles wide, 1 tile tall
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(16, 16)

	# Create tiles for all block types (0-14)
	for i in range(15):
		atlas.create_tile(Vector2i(i, 0))

	tileset.add_source(atlas, 0) # Source ID 0
	return tileset


# Helper to create a renderer with test tileset
func _create_test_renderer() -> WorldRenderer:
	var renderer = WorldRenderer.new()
	add_child(renderer)
	renderer.set_tile_set(_create_test_tileset())
	return renderer


# =============================================================================
# WorldRenderer Existence and Construction Tests
# =============================================================================

func test_world_renderer_class_exists():
	# WorldRenderer class should exist and be instantiable
	var renderer = WorldRenderer.new()
	assert_not_null(renderer, "WorldRenderer class should exist")
	renderer.free()


func test_world_renderer_extends_node2d():
	# WorldRenderer should extend Node2D
	var renderer = WorldRenderer.new()
	assert_true(renderer is Node2D, "WorldRenderer should extend Node2D")
	renderer.free()


func test_world_renderer_has_tile_world_property():
	# WorldRenderer should have tile_world property
	var renderer = WorldRenderer.new()
	assert_true("tile_world" in renderer, "WorldRenderer should have tile_world property")
	renderer.free()


func test_world_renderer_has_tile_map_layer_property():
	# WorldRenderer should have tile_map_layer property
	var renderer = WorldRenderer.new()
	assert_true("tile_map_layer" in renderer, "WorldRenderer should have tile_map_layer property")
	renderer.free()


# =============================================================================
# WorldRenderer _ready Tests
# =============================================================================

func test_world_renderer_ready_creates_tile_map_layer():
	# _ready should create a TileMapLayer child
	var renderer = WorldRenderer.new()
	add_child(renderer)

	assert_not_null(renderer.tile_map_layer, "tile_map_layer should be created")
	assert_true(renderer.tile_map_layer is TileMapLayer, "tile_map_layer should be TileMapLayer")

	renderer.queue_free()


func test_world_renderer_tile_map_layer_is_child():
	# TileMapLayer should be added as child of WorldRenderer
	var renderer = WorldRenderer.new()
	add_child(renderer)

	var has_tile_map_layer_child = false
	for child in renderer.get_children():
		if child is TileMapLayer:
			has_tile_map_layer_child = true
			break

	assert_true(has_tile_map_layer_child, "TileMapLayer should be child of WorldRenderer")

	renderer.queue_free()


func test_world_renderer_tile_map_layer_has_tileset():
	# TileMapLayer should have the terrain tileset assigned (when set)
	var renderer = _create_test_renderer()

	assert_not_null(renderer.tile_map_layer.tile_set, "TileMapLayer should have tile_set")

	renderer.queue_free()


# =============================================================================
# set_tile_world Tests
# =============================================================================

func test_set_tile_world_stores_reference():
	# set_tile_world should store reference to TileWorld
	var renderer = WorldRenderer.new()
	add_child(renderer)

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	assert_eq(renderer.tile_world, tile_world, "tile_world should be stored")

	renderer.queue_free()


func test_set_tile_world_connects_signal():
	# set_tile_world should connect to block_changed signal
	var renderer = WorldRenderer.new()
	add_child(renderer)

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	assert_true(tile_world.block_changed.is_connected(renderer._on_block_changed),
		"Should connect to block_changed signal")

	renderer.queue_free()


func test_set_tile_world_null_disconnects():
	# set_tile_world(null) should disconnect from previous world
	var renderer = WorldRenderer.new()
	add_child(renderer)

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)
	renderer.set_tile_world(null)

	assert_false(tile_world.block_changed.is_connected(renderer._on_block_changed),
		"Should disconnect from block_changed when setting null")

	renderer.queue_free()


func test_set_tile_world_disconnects_previous():
	# set_tile_world should disconnect from previous world when setting new one
	var renderer = WorldRenderer.new()
	add_child(renderer)

	var tile_world1 = TileWorld.new(12345)
	var tile_world2 = TileWorld.new(54321)

	renderer.set_tile_world(tile_world1)
	renderer.set_tile_world(tile_world2)

	assert_false(tile_world1.block_changed.is_connected(renderer._on_block_changed),
		"Should disconnect from previous world")
	assert_true(tile_world2.block_changed.is_connected(renderer._on_block_changed),
		"Should connect to new world")

	renderer.queue_free()


# =============================================================================
# _on_block_changed Tests
# =============================================================================

func test_on_block_changed_updates_tile_map_layer():
	# When block_changed is emitted, TileMapLayer should be updated
	# Note: WorldRenderer negates Y for screen coords (screen Y down, world Y up)
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set a block at world pos (5, 5)
	tile_world.set_block(5, 5, BlockData.BlockType.STONE)

	# Verify TileMapLayer was updated at screen pos (5, -5)
	var cell_source_id = renderer.tile_map_layer.get_cell_source_id(Vector2i(5, -5))
	assert_eq(cell_source_id, 0, "Cell should have source ID 0")

	var atlas_coords = renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(5, -5))
	assert_eq(atlas_coords, Vector2i(BlockData.BlockType.STONE, 0),
		"Atlas coords should match BlockType")

	renderer.queue_free()


func test_on_block_changed_erases_air_blocks():
	# Setting block to AIR should erase the cell
	# Note: WorldRenderer negates Y for screen coords (screen Y down, world Y up)
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set a block first at world pos (10, 10)
	tile_world.set_block(10, 10, BlockData.BlockType.DIRT)

	# Verify it's set at screen pos (10, -10)
	var cell_source_id = renderer.tile_map_layer.get_cell_source_id(Vector2i(10, -10))
	assert_eq(cell_source_id, 0, "Cell should be set")

	# Set to AIR
	tile_world.set_block(10, 10, BlockData.BlockType.AIR)

	# Cell should be erased (source_id = -1)
	cell_source_id = renderer.tile_map_layer.get_cell_source_id(Vector2i(10, -10))
	assert_eq(cell_source_id, -1, "Cell should be erased for AIR")

	renderer.queue_free()


func test_on_block_changed_multiple_blocks():
	# Should handle multiple block changes
	# Note: WorldRenderer negates Y for screen coords (screen Y down, world Y up)
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set multiple blocks at world Y=0, screen Y=0 (0 negated is still 0)
	tile_world.set_block(0, 0, BlockData.BlockType.GRASS)
	tile_world.set_block(1, 0, BlockData.BlockType.DIRT)
	tile_world.set_block(2, 0, BlockData.BlockType.STONE)

	# Verify all were updated (Y=0 -> screen Y=0)
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(0, 0)),
		Vector2i(BlockData.BlockType.GRASS, 0), "GRASS should be at screen (0, 0)")
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(1, 0)),
		Vector2i(BlockData.BlockType.DIRT, 0), "DIRT should be at screen (1, 0)")
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(2, 0)),
		Vector2i(BlockData.BlockType.STONE, 0), "STONE should be at screen (2, 0)")

	renderer.queue_free()


func test_on_block_changed_all_block_types():
	# Should correctly map all BlockType values to atlas coords
	# Note: WorldRenderer negates Y for screen coords (screen Y down, world Y up)
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	var block_types = [
		BlockData.BlockType.GRASS,
		BlockData.BlockType.DIRT,
		BlockData.BlockType.STONE,
		BlockData.BlockType.WOOD,
		BlockData.BlockType.LEAVES,
		BlockData.BlockType.SAND,
		BlockData.BlockType.WATER,
		BlockData.BlockType.COAL_ORE,
		BlockData.BlockType.IRON_ORE,
		BlockData.BlockType.GOLD_ORE,
		BlockData.BlockType.DIAMOND_ORE,
		BlockData.BlockType.COBBLESTONE,
		BlockData.BlockType.PLANKS,
		BlockData.BlockType.BEDROCK,
	]

	for i in range(block_types.size()):
		var block_type = block_types[i]
		# Set at world Y=0, which maps to screen Y=0
		tile_world.set_block(i, 0, block_type)

		var atlas_coords = renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(i, 0))
		assert_eq(atlas_coords, Vector2i(block_type, 0),
			"BlockType %d should map to atlas coords (%d, 0)" % [block_type, block_type])

	renderer.queue_free()


# =============================================================================
# render_region Tests
# =============================================================================

func test_render_region_renders_blocks():
	# render_region should render all blocks in the specified region
	# Note: WorldRenderer negates Y for screen coords (screen Y down, world Y up)
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Pre-set some blocks at world Y=0 -> screen Y=0
	tile_world.set_block(0, 0, BlockData.BlockType.STONE)
	tile_world.set_block(1, 0, BlockData.BlockType.DIRT)

	# Clear the tile map layer to test render_region
	renderer.clear()

	# Verify cleared
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(0, 0)), -1, "Should be cleared")

	# Render region at world coords
	renderer.render_region(Vector2i(0, 0), Vector2i(1, 0))

	# Verify rendered at screen coords (Y=0 -> screen Y=0)
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(0, 0)), 0, "Should be rendered")
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(1, 0)), 0, "Should be rendered")

	renderer.queue_free()


func test_render_region_skips_air():
	# render_region should not render AIR blocks
	# Note: WorldRenderer negates Y for screen coords (screen Y down, world Y up)
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set an AIR block at world Y=100
	tile_world.set_block(0, 100, BlockData.BlockType.AIR)

	# Clear and render
	renderer.clear()
	renderer.render_region(Vector2i(0, 100), Vector2i(0, 100))

	# AIR should not be rendered at screen Y=-100
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(0, -100)), -1,
		"AIR should not be rendered")

	renderer.queue_free()


func test_render_region_does_nothing_without_tile_world():
	# render_region should do nothing if tile_world is null
	var renderer = WorldRenderer.new()
	add_child(renderer)

	# No tile_world set, should not crash
	renderer.render_region(Vector2i(0, 0), Vector2i(10, 10))

	# Just checking it didn't crash
	assert_true(true, "render_region should not crash without tile_world")

	renderer.queue_free()


# =============================================================================
# Dynamic Chunk Loading Tests
# =============================================================================

func test_set_tracking_target_updates_chunks():
	# set_tracking_target should trigger chunk loading around the target
	var renderer = _create_test_renderer()
	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	var target = Node2D.new()
	# Position at (0, 0)
	target.global_position = Vector2.ZERO

	watch_signals(renderer)
	renderer.set_tracking_target(target)

	# Manually call _process because we are in a unit test
	renderer._process(0.1)

	# Should load chunk (0, 0) and surrounding radius
	# Radius is 5, so checks -5 to 5.
	assert_signal_emitted(renderer, "chunk_loaded", "Should emit chunk_loaded")

	# Check if chunk (0, 0) was loaded
	assert_true(renderer._loaded_chunks.has(Vector2i(0, 0)), "Center chunk should be loaded")

	target.free()
	renderer.queue_free()


func test_moving_target_loads_new_chunks():
	# moving target should load new chunks and unload old ones
	var renderer = _create_test_renderer()
	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	var target = Node2D.new()
	target.global_position = Vector2.ZERO
	renderer.set_tracking_target(target)
	renderer._process(0.1)

	# Move target far away (e.g. 20 chunks away)
	# Chunk size 16 * 16 pixels = 256 pixels
	# Move 20 chunks right = 20 * 256 = 5120 pixels
	target.global_position = Vector2(5120, 0)

	watch_signals(renderer)
	renderer._process(0.1)

	# Should have loaded new chunks
	var new_center = Vector2i(20, 0)
	assert_true(renderer._loaded_chunks.has(new_center), "New center chunk should be loaded")

	# Should have unloaded old chunks (0, 0)
	assert_signal_emitted(renderer, "chunk_unloaded", "Should emit chunk_unloaded")
	assert_false(renderer._loaded_chunks.has(Vector2i(0, 0)), "Old center chunk should be unloaded")

	target.free()
	renderer.queue_free()


# =============================================================================
# clear Tests
# =============================================================================

func test_clear_removes_all_tiles():
	# clear should remove all tiles from TileMapLayer
	# Note: WorldRenderer negates Y for screen coords (screen Y down, world Y up)
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set some blocks at world coords
	tile_world.set_block(0, 0, BlockData.BlockType.STONE)
	tile_world.set_block(5, 5, BlockData.BlockType.DIRT)

	# Clear
	renderer.clear()

	# Verify cleared at screen coords (world Y=0 -> screen Y=0, world Y=5 -> screen Y=-5)
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(0, 0)), -1,
		"Cell should be cleared")
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(5, -5)), -1,
		"Cell should be cleared")

	renderer.queue_free()


# =============================================================================
# Integration Tests
# =============================================================================

func test_full_workflow():
	# Test complete workflow: create, connect, set blocks, verify
	# Note: WorldRenderer negates Y for screen coords (screen Y down, world Y up)
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set blocks of different types at world coords (0, 0), (0, 1), (0, 2)
	tile_world.set_block(0, 0, BlockData.BlockType.GRASS)
	tile_world.set_block(0, 1, BlockData.BlockType.DIRT)
	tile_world.set_block(0, 2, BlockData.BlockType.STONE)

	# Verify all are rendered correctly at screen coords (0, 0), (0, -1), (0, -2)
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(0, 0)),
		Vector2i(BlockData.BlockType.GRASS, 0), "GRASS rendered correctly")
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(0, -1)),
		Vector2i(BlockData.BlockType.DIRT, 0), "DIRT rendered correctly")
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(0, -2)),
		Vector2i(BlockData.BlockType.STONE, 0), "STONE rendered correctly")

	# Change a block
	tile_world.set_block(0, 0, BlockData.BlockType.DIAMOND_ORE)
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(0, 0)),
		Vector2i(BlockData.BlockType.DIAMOND_ORE, 0), "Changed block rendered correctly")

	# Remove a block (set to AIR)
	tile_world.set_block(0, 1, BlockData.BlockType.AIR)
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(0, -1)), -1,
		"Removed block should have no cell")

	renderer.queue_free()


func test_negative_coordinates():
	# WorldRenderer should handle negative coordinates
	# Note: WorldRenderer negates Y for screen coords (screen Y down, world Y up)
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set block at negative world coordinates (-5, -10)
	tile_world.set_block(-5, -10, BlockData.BlockType.COBBLESTONE)

	# Verify rendered at screen coords (-5, 10) since screen Y = -world Y
	var atlas_coords = renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(-5, 10))
	assert_eq(atlas_coords, Vector2i(BlockData.BlockType.COBBLESTONE, 0),
		"Should handle negative coordinates")

	renderer.queue_free()
