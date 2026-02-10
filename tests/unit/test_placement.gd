extends GutTest
## Unit tests for PlacementController

var placement_controller: PlacementController
var tile_world: TileWorld
var inventory: Inventory


func before_each() -> void:
	placement_controller = PlacementController.new()
	tile_world = TileWorld.new(12345)
	inventory = Inventory.new()
	placement_controller.setup(tile_world, inventory)
	add_child(placement_controller)


func after_each() -> void:
	placement_controller.queue_free()


# =============================================================================
# Basic Existence Tests
# =============================================================================

func test_placement_controller_exists() -> void:
	assert_not_null(placement_controller)


func test_placement_controller_extends_node() -> void:
	assert_true(placement_controller is Node, "PlacementController should extend Node")


func test_setup_stores_references() -> void:
	assert_eq(placement_controller.tile_world, tile_world)
	assert_eq(placement_controller.inventory, inventory)


# =============================================================================
# Slot Selection Tests
# =============================================================================

func test_set_selected_slot() -> void:
	placement_controller.set_selected_slot(5)
	assert_eq(placement_controller.selected_slot, 5)


func test_set_selected_slot_clamped_high() -> void:
	placement_controller.set_selected_slot(20)
	assert_eq(placement_controller.selected_slot, 8)


func test_set_selected_slot_clamped_low() -> void:
	placement_controller.set_selected_slot(-5)
	assert_eq(placement_controller.selected_slot, 0)


# =============================================================================
# Coordinate Conversion Tests
# Note: Screen Y is down, world Y is up, so world_to_tile negates Y
# =============================================================================

func test_world_to_tile_conversion() -> void:
	# Screen (32, -48) -> tile (2, 3) because -(-48)/16 = 3
	var result = placement_controller.world_to_tile(Vector2(32, -48))
	assert_eq(result, Vector2i(2, 3))


func test_world_to_tile_negative() -> void:
	# Screen (-16, 32) -> tile (-1, -2) because -(32)/16 = -2
	var result = placement_controller.world_to_tile(Vector2(-16, 32))
	assert_eq(result, Vector2i(-1, -2))


func test_world_to_tile_fractional() -> void:
	# Screen (17, -33) -> tile (1, 2) because -(-33)/16 = 2 (floor)
	var result = placement_controller.world_to_tile(Vector2(17, -33))
	assert_eq(result, Vector2i(1, 2))


func test_world_to_tile_zero() -> void:
	var result = placement_controller.world_to_tile(Vector2(0, 0))
	assert_eq(result, Vector2i(0, 0))


# =============================================================================
# Range Checking Tests
# =============================================================================

func test_is_in_range_true() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	assert_true(placement_controller.is_in_range(Vector2(48, 48)))


func test_is_in_range_false() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	assert_false(placement_controller.is_in_range(Vector2(200, 200)))


func test_is_in_range_at_boundary() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	# 80.0 is exactly the range limit
	assert_true(placement_controller.is_in_range(Vector2(80, 0)))


func test_is_in_range_just_beyond_boundary() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	assert_false(placement_controller.is_in_range(Vector2(81, 0)))


func test_player_position_updates() -> void:
	placement_controller.set_player_position(Vector2(100, 200))
	assert_eq(placement_controller.player_position, Vector2(100, 200))


# =============================================================================
# Placement Tests
# Note: Screen Y is down, world Y is up, so screen Y=-40 maps to tile Y=2
# =============================================================================

func test_try_place_succeeds() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	# Add dirt to inventory slot 0
	inventory.add_item(ItemData.ItemType.DIRT, 5)
	placement_controller.set_selected_slot(0)

	# Ensure target is air at world tile (2, 2)
	tile_world.set_block(2, 2, BlockData.BlockType.AIR)

	# Screen pos (40, -40) -> tile (2, 2)
	var result = placement_controller.try_place_at(Vector2(40, -40))

	assert_true(result)
	assert_eq(tile_world.get_block(2, 2), BlockData.BlockType.DIRT)


func test_try_place_removes_from_inventory() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	inventory.add_item(ItemData.ItemType.DIRT, 5)
	placement_controller.set_selected_slot(0)
	tile_world.set_block(2, 2, BlockData.BlockType.AIR)

	# Screen pos (40, -40) -> tile (2, 2)
	placement_controller.try_place_at(Vector2(40, -40))

	var slot = inventory.get_slot(0)
	assert_eq(slot.count, 4)


func test_try_place_out_of_range_fails() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	inventory.add_item(ItemData.ItemType.DIRT, 5)
	tile_world.set_block(20, 20, BlockData.BlockType.AIR)

	var result = placement_controller.try_place_at(Vector2(400, -400))

	assert_false(result)


func test_try_place_non_placeable_fails() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	# Coal is not placeable
	inventory.add_item(ItemData.ItemType.COAL, 5)
	placement_controller.set_selected_slot(0)
	tile_world.set_block(2, 2, BlockData.BlockType.AIR)

	# Screen pos (40, -40) -> tile (2, 2)
	var result = placement_controller.try_place_at(Vector2(40, -40))

	assert_false(result)


func test_try_place_on_solid_fails() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	inventory.add_item(ItemData.ItemType.DIRT, 5)
	placement_controller.set_selected_slot(0)
	# Target is stone, not air at world tile (2, 2)
	tile_world.set_block(2, 2, BlockData.BlockType.STONE)

	# Screen pos (40, -40) -> tile (2, 2)
	var result = placement_controller.try_place_at(Vector2(40, -40))

	assert_false(result)


func test_try_place_empty_slot_fails() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	placement_controller.set_selected_slot(0)
	tile_world.set_block(2, 2, BlockData.BlockType.AIR)

	# Screen pos (40, -40) -> tile (2, 2)
	var result = placement_controller.try_place_at(Vector2(40, -40))

	assert_false(result)


func test_try_place_without_setup_fails() -> void:
	var controller = PlacementController.new()
	add_child(controller)
	controller.set_player_position(Vector2(0, 0))

	var result = controller.try_place_at(Vector2(20, -20))

	assert_false(result)
	controller.queue_free()


func test_try_place_stone_block() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	inventory.add_item(ItemData.ItemType.STONE, 3)
	placement_controller.set_selected_slot(0)
	tile_world.set_block(1, 1, BlockData.BlockType.AIR)

	# Screen pos (20, -20) -> tile (1, 1)
	var result = placement_controller.try_place_at(Vector2(20, -20))

	assert_true(result)
	assert_eq(tile_world.get_block(1, 1), BlockData.BlockType.STONE)


func test_try_place_wood_block() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	inventory.add_item(ItemData.ItemType.WOOD, 10)
	placement_controller.set_selected_slot(0)
	tile_world.set_block(3, 3, BlockData.BlockType.AIR)

	# Screen pos (48, -48) -> tile (3, 3)
	var result = placement_controller.try_place_at(Vector2(48, -48))

	assert_true(result)
	assert_eq(tile_world.get_block(3, 3), BlockData.BlockType.WOOD)


# =============================================================================
# Signal Tests
# Note: Screen Y is down, world Y is up
# =============================================================================

func test_block_placed_signal_emitted() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	inventory.add_item(ItemData.ItemType.DIRT, 5)
	placement_controller.set_selected_slot(0)
	tile_world.set_block(2, 2, BlockData.BlockType.AIR)

	watch_signals(placement_controller)
	# Screen pos (40, -40) -> tile (2, 2)
	placement_controller.try_place_at(Vector2(40, -40))

	assert_signal_emitted(placement_controller, "block_placed")


func test_block_placed_signal_has_correct_parameters() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	inventory.add_item(ItemData.ItemType.STONE, 5)
	placement_controller.set_selected_slot(0)
	tile_world.set_block(2, 3, BlockData.BlockType.AIR)

	watch_signals(placement_controller)
	# Screen pos (40, -56) -> tile (2, 3)
	placement_controller.try_place_at(Vector2(40, -56))

	var params = get_signal_parameters(placement_controller, "block_placed", 0)
	assert_eq(params[0], Vector2i(2, 3), "Signal should include tile position")
	assert_eq(params[1], BlockData.BlockType.STONE, "Signal should include placed block type")


func test_block_placed_signal_not_emitted_on_failure() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	tile_world.set_block(2, 2, BlockData.BlockType.STONE)

	watch_signals(placement_controller)
	# Screen pos (40, -40) -> tile (2, 2) which has STONE
	placement_controller.try_place_at(Vector2(40, -40))

	assert_signal_not_emitted(placement_controller, "block_placed")


# =============================================================================
# Get Selected Item Tests
# =============================================================================

func test_get_selected_item() -> void:
	inventory.add_item(ItemData.ItemType.STONE, 10)
	placement_controller.set_selected_slot(0)

	assert_eq(placement_controller.get_selected_item(), ItemData.ItemType.STONE)


func test_get_selected_item_empty_slot() -> void:
	placement_controller.set_selected_slot(5)

	assert_eq(placement_controller.get_selected_item(), 0)


func test_get_selected_item_without_inventory() -> void:
	var controller = PlacementController.new()
	add_child(controller)

	assert_eq(controller.get_selected_item(), 0)
	controller.queue_free()


# =============================================================================
# Edge Cases
# =============================================================================

func test_placement_range_constant() -> void:
	assert_eq(PlacementController.PLACEMENT_RANGE, 80.0, "Placement range should be 80 pixels (5 tiles)")


func test_tile_size_constant() -> void:
	assert_eq(PlacementController.TILE_SIZE, 16, "Tile size should be 16 pixels")


func test_try_place_last_item_clears_slot() -> void:
	placement_controller.set_player_position(Vector2(0, 0))
	inventory.add_item(ItemData.ItemType.DIRT, 1)
	placement_controller.set_selected_slot(0)
	tile_world.set_block(2, 2, BlockData.BlockType.AIR)

	# Screen pos (40, -40) -> tile (2, 2)
	placement_controller.try_place_at(Vector2(40, -40))

	var slot = inventory.get_slot(0)
	assert_eq(slot.item, 0, "Slot should be cleared after placing last item")
	assert_eq(slot.count, 0)
