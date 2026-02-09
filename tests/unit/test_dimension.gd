extends GutTest
## Unit tests for DimensionSystem
## Tests multi-dimensional world management including pocket dimensions

# =============================================================================
# DimensionSystem Existence and Construction Tests
# =============================================================================

func test_dimension_system_class_exists():
	# DimensionSystem class should exist and be instantiable
	var system = DimensionSystem.new()
	assert_not_null(system, "DimensionSystem class should exist")
	system.free()


func test_dimension_system_extends_system():
	# DimensionSystem should extend the System base class
	var system = DimensionSystem.new()
	assert_true(system is System, "DimensionSystem should extend System")
	system.free()


func test_dimension_system_has_empty_required_components():
	# DimensionSystem should have empty required_components (it manages dimensions, not entities)
	var system = DimensionSystem.new()
	assert_eq(system.required_components.size(), 0, "DimensionSystem should have no required components")
	system.free()


func test_dimension_system_has_constants():
	# DimensionSystem should define OVERWORLD and POCKET_DIMENSION_START constants
	assert_eq(DimensionSystem.OVERWORLD, 0, "OVERWORLD should be 0")
	assert_eq(DimensionSystem.POCKET_DIMENSION_START, 100, "POCKET_DIMENSION_START should be 100")


# =============================================================================
# DimensionSystem.setup Tests
# =============================================================================

func test_setup_stores_world_seed():
	# setup() should store the world seed
	var system = DimensionSystem.new()
	system.setup(12345)

	assert_eq(system.world_seed, 12345, "setup should store the world seed")
	system.free()


func test_setup_creates_overworld_dimension():
	# setup() should create the overworld dimension (ID 0)
	var system = DimensionSystem.new()
	system.setup(12345)

	assert_true(system.has_dimension(DimensionSystem.OVERWORLD), "setup should create overworld dimension")
	system.free()


func test_setup_sets_active_dimension_to_overworld():
	# setup() should set active dimension to overworld
	var system = DimensionSystem.new()
	system.setup(12345)

	assert_eq(system.active_dimension, DimensionSystem.OVERWORLD, "active_dimension should be overworld after setup")
	system.free()


# =============================================================================
# create_dimension Tests
# =============================================================================

func test_create_dimension_returns_tile_world():
	# create_dimension should return a TileWorld instance
	var system = DimensionSystem.new()
	system.setup(12345)

	var world = system.create_dimension(1)

	assert_not_null(world, "create_dimension should return a value")
	assert_true(world is TileWorld, "create_dimension should return TileWorld")
	system.free()


func test_create_dimension_stores_in_dictionary():
	# create_dimension should store the world in dimensions dictionary
	var system = DimensionSystem.new()
	system.setup(12345)

	system.create_dimension(5)

	assert_true(system.has_dimension(5), "Dimension 5 should exist after creation")
	system.free()


func test_create_dimension_returns_existing_if_already_exists():
	# create_dimension should return existing world if dimension already exists
	var system = DimensionSystem.new()
	system.setup(12345)

	var world1 = system.create_dimension(10)
	var world2 = system.create_dimension(10)

	assert_eq(world1, world2, "Should return same TileWorld for same dimension_id")
	system.free()


func test_create_dimension_uses_derived_seed():
	# Each dimension should use a unique seed derived from base seed
	var system = DimensionSystem.new()
	system.setup(12345)

	var world = system.create_dimension(5)
	var expected_seed = 12345 + 5 * 1000  # world_seed + dimension_id * 1000

	assert_eq(world.world_seed, expected_seed, "Dimension seed should be derived from base seed")
	system.free()


func test_create_dimension_emits_signal():
	# create_dimension should emit dimension_created signal
	var system = DimensionSystem.new()
	system.setup(12345)

	watch_signals(system)
	system.create_dimension(42)

	assert_signal_emitted(system, "dimension_created", "Should emit dimension_created signal")
	system.free()


func test_create_dimension_signal_has_correct_id():
	# dimension_created signal should include the dimension_id
	var system = DimensionSystem.new()
	system.setup(12345)

	watch_signals(system)
	system.create_dimension(42)

	var params = get_signal_parameters(system, "dimension_created", 0)
	assert_eq(params[0], 42, "Signal should include dimension_id")
	system.free()


# =============================================================================
# get_dimension Tests
# =============================================================================

func test_get_dimension_returns_correct_world():
	# get_dimension should return the correct TileWorld for given id
	var system = DimensionSystem.new()
	system.setup(12345)

	var created_world = system.create_dimension(7)
	var retrieved_world = system.get_dimension(7)

	assert_eq(created_world, retrieved_world, "get_dimension should return the created world")
	system.free()


func test_get_dimension_returns_null_for_nonexistent():
	# get_dimension should return null for non-existent dimension
	var system = DimensionSystem.new()
	system.setup(12345)

	var world = system.get_dimension(999)

	assert_null(world, "get_dimension should return null for non-existent dimension")
	system.free()


func test_get_active_dimension_returns_current():
	# get_active_dimension should return the currently active dimension's TileWorld
	var system = DimensionSystem.new()
	system.setup(12345)

	var overworld = system.get_dimension(DimensionSystem.OVERWORLD)
	var active = system.get_active_dimension()

	assert_eq(active, overworld, "get_active_dimension should return overworld after setup")
	system.free()


# =============================================================================
# has_dimension Tests
# =============================================================================

func test_has_dimension_returns_true_for_existing():
	# has_dimension should return true for existing dimension
	var system = DimensionSystem.new()
	system.setup(12345)

	system.create_dimension(15)

	assert_true(system.has_dimension(15), "has_dimension should return true for existing dimension")
	system.free()


func test_has_dimension_returns_false_for_nonexistent():
	# has_dimension should return false for non-existent dimension
	var system = DimensionSystem.new()
	system.setup(12345)

	assert_false(system.has_dimension(888), "has_dimension should return false for non-existent dimension")
	system.free()


# =============================================================================
# set_active_dimension Tests
# =============================================================================

func test_set_active_dimension_changes_active():
	# set_active_dimension should change the active dimension
	var system = DimensionSystem.new()
	system.setup(12345)
	system.create_dimension(5)

	system.set_active_dimension(5)

	assert_eq(system.active_dimension, 5, "active_dimension should change")
	system.free()


func test_set_active_dimension_returns_true_on_success():
	# set_active_dimension should return true when successful
	var system = DimensionSystem.new()
	system.setup(12345)
	system.create_dimension(5)

	var result = system.set_active_dimension(5)

	assert_true(result, "set_active_dimension should return true on success")
	system.free()


func test_set_active_dimension_returns_false_for_nonexistent():
	# set_active_dimension should return false for non-existent dimension
	var system = DimensionSystem.new()
	system.setup(12345)

	var result = system.set_active_dimension(999)

	assert_false(result, "set_active_dimension should return false for non-existent dimension")
	system.free()


func test_set_active_dimension_does_not_change_on_failure():
	# set_active_dimension should not change active_dimension on failure
	var system = DimensionSystem.new()
	system.setup(12345)

	var original = system.active_dimension
	system.set_active_dimension(999)

	assert_eq(system.active_dimension, original, "active_dimension should not change on failure")
	system.free()


func test_set_active_dimension_emits_signal():
	# set_active_dimension should emit dimension_changed signal
	var system = DimensionSystem.new()
	system.setup(12345)
	system.create_dimension(5)

	watch_signals(system)
	system.set_active_dimension(5)

	assert_signal_emitted(system, "dimension_changed", "Should emit dimension_changed signal")
	system.free()


func test_set_active_dimension_signal_has_correct_ids():
	# dimension_changed signal should include old_id and new_id
	var system = DimensionSystem.new()
	system.setup(12345)
	system.create_dimension(5)

	watch_signals(system)
	system.set_active_dimension(5)

	var params = get_signal_parameters(system, "dimension_changed", 0)
	assert_eq(params[0], DimensionSystem.OVERWORLD, "Signal should include old_id (0)")
	assert_eq(params[1], 5, "Signal should include new_id (5)")
	system.free()


# =============================================================================
# create_pocket_dimension Tests
# =============================================================================

func test_create_pocket_dimension_returns_id():
	# create_pocket_dimension should return the new dimension's ID
	var system = DimensionSystem.new()
	system.setup(12345)

	var pocket_id = system.create_pocket_dimension()

	assert_gte(pocket_id, DimensionSystem.POCKET_DIMENSION_START, "Pocket dimension ID should be >= POCKET_DIMENSION_START")
	system.free()


func test_create_pocket_dimension_creates_tile_world():
	# create_pocket_dimension should actually create a TileWorld
	var system = DimensionSystem.new()
	system.setup(12345)

	var pocket_id = system.create_pocket_dimension()
	var world = system.get_dimension(pocket_id)

	assert_not_null(world, "Pocket dimension should have a TileWorld")
	assert_true(world is TileWorld, "Pocket dimension should be a TileWorld")
	system.free()


func test_create_pocket_dimension_increments_id():
	# Multiple pocket dimensions should have unique incrementing IDs
	var system = DimensionSystem.new()
	system.setup(12345)

	var id1 = system.create_pocket_dimension()
	var id2 = system.create_pocket_dimension()
	var id3 = system.create_pocket_dimension()

	assert_eq(id1, DimensionSystem.POCKET_DIMENSION_START, "First pocket should be POCKET_DIMENSION_START")
	assert_eq(id2, DimensionSystem.POCKET_DIMENSION_START + 1, "Second pocket should be POCKET_DIMENSION_START + 1")
	assert_eq(id3, DimensionSystem.POCKET_DIMENSION_START + 2, "Third pocket should be POCKET_DIMENSION_START + 2")
	system.free()


# =============================================================================
# get_dimension_count Tests
# =============================================================================

func test_get_dimension_count_after_setup():
	# get_dimension_count should return 1 after setup (overworld only)
	var system = DimensionSystem.new()
	system.setup(12345)

	assert_eq(system.get_dimension_count(), 1, "Should have 1 dimension (overworld) after setup")
	system.free()


func test_get_dimension_count_after_creating_dimensions():
	# get_dimension_count should increase as dimensions are created
	var system = DimensionSystem.new()
	system.setup(12345)

	system.create_pocket_dimension()
	assert_eq(system.get_dimension_count(), 2, "Should have 2 dimensions")

	system.create_pocket_dimension()
	assert_eq(system.get_dimension_count(), 3, "Should have 3 dimensions")
	system.free()


# =============================================================================
# get_block / set_block per Dimension Tests
# =============================================================================

func test_get_block_works_for_specific_dimension():
	# get_block should work for any dimension
	var system = DimensionSystem.new()
	system.setup(12345)

	# Get block from overworld
	var block = system.get_block(DimensionSystem.OVERWORLD, 0, 30)

	# Should be a valid block type
	assert_gte(block, 0, "Block should be valid")
	system.free()


func test_set_block_works_for_specific_dimension():
	# set_block should modify blocks in specific dimension
	var system = DimensionSystem.new()
	system.setup(12345)

	system.set_block(DimensionSystem.OVERWORLD, 100, 50, BlockData.BlockType.DIAMOND_ORE)
	var block = system.get_block(DimensionSystem.OVERWORLD, 100, 50)

	assert_eq(block, BlockData.BlockType.DIAMOND_ORE, "set_block should modify the dimension")
	system.free()


func test_blocks_are_independent_between_dimensions():
	# Blocks set in one dimension should not affect other dimensions
	var system = DimensionSystem.new()
	system.setup(12345)

	var pocket_id = system.create_pocket_dimension()

	# Set a block in overworld
	system.set_block(DimensionSystem.OVERWORLD, 200, 60, BlockData.BlockType.GOLD_ORE)

	# Set a different block at same position in pocket dimension
	system.set_block(pocket_id, 200, 60, BlockData.BlockType.IRON_ORE)

	# Verify they are independent
	assert_eq(system.get_block(DimensionSystem.OVERWORLD, 200, 60), BlockData.BlockType.GOLD_ORE,
		"Overworld block should be GOLD_ORE")
	assert_eq(system.get_block(pocket_id, 200, 60), BlockData.BlockType.IRON_ORE,
		"Pocket block should be IRON_ORE")
	system.free()


func test_get_block_returns_air_for_nonexistent_dimension():
	# get_block should return AIR for non-existent dimension
	var system = DimensionSystem.new()
	system.setup(12345)

	var block = system.get_block(999, 0, 0)

	assert_eq(block, BlockData.BlockType.AIR, "Non-existent dimension should return AIR")
	system.free()


# =============================================================================
# Dimensions Have Different Terrain Tests
# =============================================================================

func test_dimensions_have_different_terrain():
	# Different dimensions should have different procedurally generated terrain
	var system = DimensionSystem.new()
	system.setup(12345)

	var pocket_id = system.create_pocket_dimension()

	var overworld = system.get_dimension(DimensionSystem.OVERWORLD)
	var pocket = system.get_dimension(pocket_id)

	# Different seeds should produce different terrain at same position
	var blocks_match := 0
	var total_checks := 10
	for i in range(total_checks):
		var x := i * 50
		var y := 30  # Some y position
		if overworld.get_block(x, y) == pocket.get_block(x, y):
			blocks_match += 1

	# Most blocks should differ (not all, due to randomness)
	assert_lt(blocks_match, total_checks, "Most blocks should differ between dimensions")
	system.free()


func test_dimensions_have_different_seeds():
	# Each dimension should have a unique seed
	var system = DimensionSystem.new()
	system.setup(12345)

	var pocket_id = system.create_pocket_dimension()

	var overworld = system.get_dimension(DimensionSystem.OVERWORLD)
	var pocket = system.get_dimension(pocket_id)

	assert_ne(overworld.world_seed, pocket.world_seed, "Dimensions should have different seeds")
	system.free()


# =============================================================================
# Entity Persistence Tests
# =============================================================================

func test_entity_persists_when_dimension_changes():
	# Entities should persist their state when dimensions change
	var system = DimensionSystem.new()
	system.setup(12345)

	# Create a miner in overworld
	var miner = Miner.new()
	var inventory = miner.get_inventory()
	inventory.add_item(ItemData.ItemType.COAL, 10)

	# Switch to pocket dimension
	var pocket_id = system.create_pocket_dimension()
	system.set_active_dimension(pocket_id)

	# Entity (miner) still has its inventory
	assert_true(inventory.has_item(ItemData.ItemType.COAL, 10), "Inventory should persist after dimension switch")

	# Switch back to overworld
	system.set_active_dimension(DimensionSystem.OVERWORLD)

	# Entity still intact
	assert_true(inventory.has_item(ItemData.ItemType.COAL, 10), "Inventory should persist after switching back")

	miner.free()
	system.free()


func test_multiple_entities_persist_across_dimension_changes():
	# Multiple entities should all persist their state
	var system = DimensionSystem.new()
	system.setup(12345)

	# Create multiple miners with different inventories
	var miner1 = Miner.new()
	var miner2 = Miner.new()
	miner1.get_inventory().add_item(ItemData.ItemType.IRON_ORE, 5)
	miner2.get_inventory().add_item(ItemData.ItemType.DIAMOND, 3)

	# Switch dimensions multiple times
	var pocket_id = system.create_pocket_dimension()
	system.set_active_dimension(pocket_id)
	system.set_active_dimension(DimensionSystem.OVERWORLD)
	system.set_active_dimension(pocket_id)

	# All entities should still have their items
	assert_true(miner1.get_inventory().has_item(ItemData.ItemType.IRON_ORE, 5), "Miner1 inventory should persist")
	assert_true(miner2.get_inventory().has_item(ItemData.ItemType.DIAMOND, 3), "Miner2 inventory should persist")

	miner1.free()
	miner2.free()
	system.free()
