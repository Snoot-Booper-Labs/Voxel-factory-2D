extends GutTest
## Unit tests for WorldRenderer


# Helper function to create a test TileSet programmatically
func _create_test_tileset() -> TileSet:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)

	# Create an atlas source with a placeholder texture
	var atlas = TileSetAtlasSource.new()
	var texture = PlaceholderTexture2D.new()
	texture.size = Vector2i(256, 16)  # 16 tiles wide, 1 tile tall
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(16, 16)

	# Create tiles for all block types (0-14)
	for i in range(15):
		atlas.create_tile(Vector2i(i, 0))

	tileset.add_source(atlas, 0)  # Source ID 0
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
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set a block
	tile_world.set_block(5, 5, BlockData.BlockType.STONE)

	# Verify TileMapLayer was updated
	var cell_source_id = renderer.tile_map_layer.get_cell_source_id(Vector2i(5, 5))
	assert_eq(cell_source_id, 0, "Cell should have source ID 0")

	var atlas_coords = renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(5, 5))
	assert_eq(atlas_coords, Vector2i(BlockData.BlockType.STONE, 0),
		"Atlas coords should match BlockType")

	renderer.queue_free()


func test_on_block_changed_erases_air_blocks():
	# Setting block to AIR should erase the cell
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set a block first
	tile_world.set_block(10, 10, BlockData.BlockType.DIRT)

	# Verify it's set
	var cell_source_id = renderer.tile_map_layer.get_cell_source_id(Vector2i(10, 10))
	assert_eq(cell_source_id, 0, "Cell should be set")

	# Set to AIR
	tile_world.set_block(10, 10, BlockData.BlockType.AIR)

	# Cell should be erased (source_id = -1)
	cell_source_id = renderer.tile_map_layer.get_cell_source_id(Vector2i(10, 10))
	assert_eq(cell_source_id, -1, "Cell should be erased for AIR")

	renderer.queue_free()


func test_on_block_changed_multiple_blocks():
	# Should handle multiple block changes
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set multiple blocks
	tile_world.set_block(0, 0, BlockData.BlockType.GRASS)
	tile_world.set_block(1, 0, BlockData.BlockType.DIRT)
	tile_world.set_block(2, 0, BlockData.BlockType.STONE)

	# Verify all were updated
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(0, 0)),
		Vector2i(BlockData.BlockType.GRASS, 0), "GRASS should be at (1, 0)")
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(1, 0)),
		Vector2i(BlockData.BlockType.DIRT, 0), "DIRT should be at (2, 0)")
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(2, 0)),
		Vector2i(BlockData.BlockType.STONE, 0), "STONE should be at (3, 0)")

	renderer.queue_free()


func test_on_block_changed_all_block_types():
	# Should correctly map all BlockType values to atlas coords
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
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Pre-set some blocks
	tile_world.set_block(0, 0, BlockData.BlockType.STONE)
	tile_world.set_block(1, 0, BlockData.BlockType.DIRT)

	# Clear the tile map layer to test render_region
	renderer.clear()

	# Verify cleared
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(0, 0)), -1, "Should be cleared")

	# Render region
	renderer.render_region(Vector2i(0, 0), Vector2i(1, 0))

	# Verify rendered
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(0, 0)), 0, "Should be rendered")
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(1, 0)), 0, "Should be rendered")

	renderer.queue_free()


func test_render_region_skips_air():
	# render_region should not render AIR blocks
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set an AIR block
	tile_world.set_block(0, 100, BlockData.BlockType.AIR)

	# Clear and render
	renderer.clear()
	renderer.render_region(Vector2i(0, 100), Vector2i(0, 100))

	# AIR should not be rendered
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(0, 100)), -1,
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
# clear Tests
# =============================================================================

func test_clear_removes_all_tiles():
	# clear should remove all tiles from TileMapLayer
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set some blocks
	tile_world.set_block(0, 0, BlockData.BlockType.STONE)
	tile_world.set_block(5, 5, BlockData.BlockType.DIRT)

	# Clear
	renderer.clear()

	# Verify cleared
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(0, 0)), -1,
		"Cell should be cleared")
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(5, 5)), -1,
		"Cell should be cleared")

	renderer.queue_free()


# =============================================================================
# Integration Tests
# =============================================================================

func test_full_workflow():
	# Test complete workflow: create, connect, set blocks, verify
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set blocks of different types
	tile_world.set_block(0, 0, BlockData.BlockType.GRASS)
	tile_world.set_block(0, 1, BlockData.BlockType.DIRT)
	tile_world.set_block(0, 2, BlockData.BlockType.STONE)

	# Verify all are rendered correctly
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(0, 0)),
		Vector2i(BlockData.BlockType.GRASS, 0), "GRASS rendered correctly")
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(0, 1)),
		Vector2i(BlockData.BlockType.DIRT, 0), "DIRT rendered correctly")
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(0, 2)),
		Vector2i(BlockData.BlockType.STONE, 0), "STONE rendered correctly")

	# Change a block
	tile_world.set_block(0, 0, BlockData.BlockType.DIAMOND_ORE)
	assert_eq(renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(0, 0)),
		Vector2i(BlockData.BlockType.DIAMOND_ORE, 0), "Changed block rendered correctly")

	# Remove a block (set to AIR)
	tile_world.set_block(0, 1, BlockData.BlockType.AIR)
	assert_eq(renderer.tile_map_layer.get_cell_source_id(Vector2i(0, 1)), -1,
		"Removed block should have no cell")

	renderer.queue_free()


func test_negative_coordinates():
	# WorldRenderer should handle negative coordinates
	var renderer = _create_test_renderer()

	var tile_world = TileWorld.new(12345)
	renderer.set_tile_world(tile_world)

	# Set block at negative coordinates
	tile_world.set_block(-5, -10, BlockData.BlockType.COBBLESTONE)

	# Verify rendered
	var atlas_coords = renderer.tile_map_layer.get_cell_atlas_coords(Vector2i(-5, -10))
	assert_eq(atlas_coords, Vector2i(BlockData.BlockType.COBBLESTONE, 0),
		"Should handle negative coordinates")

	renderer.queue_free()
