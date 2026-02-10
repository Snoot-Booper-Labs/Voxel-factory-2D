extends GutTest
## Unit tests for MiningController

var mining_controller: MiningController
var tile_world: TileWorld
var inventory: Inventory


func before_each() -> void:
	mining_controller = MiningController.new()
	tile_world = TileWorld.new(12345)
	inventory = Inventory.new()
	mining_controller.setup(tile_world, inventory)
	add_child(mining_controller)


func after_each() -> void:
	mining_controller.queue_free()


# =============================================================================
# Basic Existence Tests
# =============================================================================

func test_mining_controller_exists() -> void:
	assert_not_null(mining_controller)


func test_mining_controller_extends_node() -> void:
	assert_true(mining_controller is Node, "MiningController should extend Node")


func test_setup_stores_references() -> void:
	assert_eq(mining_controller.tile_world, tile_world)
	assert_eq(mining_controller.inventory, inventory)


# =============================================================================
# Coordinate Conversion Tests
# =============================================================================

func test_world_to_tile_conversion() -> void:
	var result = mining_controller.world_to_tile(Vector2(32, 48))
	assert_eq(result, Vector2i(2, 3))


func test_world_to_tile_negative() -> void:
	var result = mining_controller.world_to_tile(Vector2(-16, -32))
	assert_eq(result, Vector2i(-1, -2))


func test_world_to_tile_fractional() -> void:
	var result = mining_controller.world_to_tile(Vector2(17, 33))
	assert_eq(result, Vector2i(1, 2))


func test_world_to_tile_zero() -> void:
	var result = mining_controller.world_to_tile(Vector2(0, 0))
	assert_eq(result, Vector2i(0, 0))


# =============================================================================
# Range Checking Tests
# =============================================================================

func test_is_in_range_true() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	assert_true(mining_controller.is_in_range(Vector2(48, 48)))


func test_is_in_range_false() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	assert_false(mining_controller.is_in_range(Vector2(200, 200)))


func test_is_in_range_at_boundary() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	# 80.0 is exactly the range limit
	assert_true(mining_controller.is_in_range(Vector2(80, 0)))


func test_is_in_range_just_beyond_boundary() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	assert_false(mining_controller.is_in_range(Vector2(81, 0)))


func test_player_position_updates() -> void:
	mining_controller.set_player_position(Vector2(100, 200))
	assert_eq(mining_controller.player_position, Vector2(100, 200))


# =============================================================================
# Mining Tests
# =============================================================================

func test_try_mine_removes_block() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	# Set a stone block
	tile_world.set_block(1, 1, BlockData.BlockType.STONE)

	# Mine it
	var result = mining_controller.try_mine_at(Vector2(20, 20))

	assert_true(result)
	assert_eq(tile_world.get_block(1, 1), BlockData.BlockType.AIR)


func test_try_mine_adds_to_inventory() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	tile_world.set_block(1, 1, BlockData.BlockType.STONE)

	mining_controller.try_mine_at(Vector2(20, 20))

	# Stone drops cobblestone (ItemType.COBBLESTONE = 7)
	assert_true(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1))


func test_try_mine_dirt_adds_dirt_to_inventory() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	tile_world.set_block(1, 1, BlockData.BlockType.DIRT)

	mining_controller.try_mine_at(Vector2(20, 20))

	# Dirt drops dirt (ItemType.DIRT = 1)
	assert_true(inventory.has_item(ItemData.ItemType.DIRT, 1))


func test_try_mine_out_of_range_fails() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	tile_world.set_block(10, 10, BlockData.BlockType.STONE)

	var result = mining_controller.try_mine_at(Vector2(200, 200))

	assert_false(result)
	assert_ne(tile_world.get_block(10, 10), BlockData.BlockType.AIR)


func test_try_mine_air_fails() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	tile_world.set_block(1, 1, BlockData.BlockType.AIR)

	var result = mining_controller.try_mine_at(Vector2(20, 20))

	assert_false(result)


func test_try_mine_without_setup_fails() -> void:
	var controller = MiningController.new()
	add_child(controller)
	controller.set_player_position(Vector2(0, 0))

	var result = controller.try_mine_at(Vector2(20, 20))

	assert_false(result)
	controller.queue_free()


func test_try_mine_leaves_no_drop() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	tile_world.set_block(1, 1, BlockData.BlockType.LEAVES)

	var result = mining_controller.try_mine_at(Vector2(20, 20))

	# Leaves should be mined but drop nothing
	assert_true(result)
	assert_eq(tile_world.get_block(1, 1), BlockData.BlockType.AIR)


# =============================================================================
# Signal Tests
# =============================================================================

func test_block_mined_signal_emitted() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	tile_world.set_block(1, 1, BlockData.BlockType.DIRT)

	watch_signals(mining_controller)
	mining_controller.try_mine_at(Vector2(20, 20))

	assert_signal_emitted(mining_controller, "block_mined")


func test_block_mined_signal_has_correct_parameters() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	tile_world.set_block(2, 3, BlockData.BlockType.STONE)

	watch_signals(mining_controller)
	mining_controller.try_mine_at(Vector2(40, 56))

	var params = get_signal_parameters(mining_controller, "block_mined", 0)
	assert_eq(params[0], Vector2i(2, 3), "Signal should include tile position")
	assert_eq(params[1], BlockData.BlockType.STONE, "Signal should include original block type")


func test_block_mined_signal_not_emitted_on_failure() -> void:
	mining_controller.set_player_position(Vector2(0, 0))
	tile_world.set_block(1, 1, BlockData.BlockType.AIR)

	watch_signals(mining_controller)
	mining_controller.try_mine_at(Vector2(20, 20))

	assert_signal_not_emitted(mining_controller, "block_mined")


# =============================================================================
# Edge Cases
# =============================================================================

func test_mining_range_constant() -> void:
	assert_eq(MiningController.MINING_RANGE, 80.0, "Mining range should be 80 pixels (5 tiles)")


func test_tile_size_constant() -> void:
	assert_eq(MiningController.TILE_SIZE, 16, "Tile size should be 16 pixels")
