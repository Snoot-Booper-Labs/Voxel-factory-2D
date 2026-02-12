extends GutTest
## Unit tests for TileWorld and WorldSystem

# =============================================================================
# TileWorld Existence and Construction Tests
# =============================================================================

func test_tile_world_class_exists():
	# TileWorld class should exist and be instantiable
	var world = TileWorld.new(12345)
	assert_not_null(world, "TileWorld class should exist")


func test_tile_world_stores_seed():
	# TileWorld should store the world seed
	var world = TileWorld.new(42)
	assert_eq(world.world_seed, 42, "TileWorld should store the seed")


func test_tile_world_has_terrain_generator():
	# TileWorld should have a TerrainGenerator instance
	var world = TileWorld.new(12345)
	assert_not_null(world.terrain_generator, "Should have terrain_generator")
	assert_true(world.terrain_generator is TerrainGenerator, "terrain_generator should be TerrainGenerator")


func test_tile_world_default_seed_is_zero():
	# TileWorld with no seed argument should default to 0
	var world = TileWorld.new()
	assert_eq(world.world_seed, 0, "Default seed should be 0")


# =============================================================================
# get_block Tests
# =============================================================================

func test_get_block_returns_valid_block_type():
	# get_block should return a valid BlockType
	var world = TileWorld.new(12345)
	var block = world.get_block(0, 30)

	# Block should be a valid BlockType (0-14 based on BlockData)
	assert_true(block >= 0 and block <= 14, "Block should be valid BlockType (0-14)")


func test_get_block_generates_terrain_on_first_access():
	# get_block should use TerrainGenerator for blocks not yet stored
	var world = TileWorld.new(12345)
	var generator = TerrainGenerator.new(12345)

	# Both should return the same block for the same coordinates
	var world_block = world.get_block(100, 30)
	var generator_block = generator.get_block_at(100, 30)

	assert_eq(world_block, generator_block, "get_block should generate terrain on first access")


func test_get_block_caches_generated_blocks():
	# get_block should cache blocks after first access
	var world = TileWorld.new(12345)

	# Get block twice
	var block1 = world.get_block(100, 30)
	var block2 = world.get_block(100, 30)

	assert_eq(block1, block2, "get_block should return same cached value")


func test_get_block_deterministic_same_seed():
	# Same seed should produce same blocks
	var world1 = TileWorld.new(12345)
	var world2 = TileWorld.new(12345)

	var block1 = world1.get_block(500, 25)
	var block2 = world2.get_block(500, 25)

	assert_eq(block1, block2, "Same seed should produce same blocks")


func test_get_block_returns_air_above_terrain():
	# Blocks high above terrain should be AIR
	var world = TileWorld.new(12345)
	var block = world.get_block(0, 100)
	assert_eq(block, BlockData.BlockType.AIR, "High altitude should be AIR")


func test_get_block_returns_stone_deep_underground():
	# Blocks deep underground should be STONE
	var world = TileWorld.new(12345)
	var block = world.get_block(0, 1)
	assert_eq(block, BlockData.BlockType.STONE, "Deep underground should be STONE")


# =============================================================================
# set_block Tests
# =============================================================================

func test_set_block_changes_block():
	# set_block should change the block at the given coordinates
	var world = TileWorld.new(12345)

	# Get the original block
	var original = world.get_block(50, 30)

	# Set to a different block type
	var new_type = BlockData.BlockType.COBBLESTONE
	if original == new_type:
		new_type = BlockData.BlockType.PLANKS

	world.set_block(50, 30, new_type)

	# Get should now return the new type
	var result = world.get_block(50, 30)
	assert_eq(result, new_type, "set_block should change the block type")


func test_set_block_overrides_generated_terrain():
	# set_block should override procedurally generated terrain
	var world = TileWorld.new(12345)

	# First access generates terrain
	var generated = world.get_block(100, 30)

	# Set to something different
	var new_type = BlockData.BlockType.DIAMOND_ORE
	world.set_block(100, 30, new_type)

	# Should now return the new type
	var result = world.get_block(100, 30)
	assert_eq(result, new_type, "set_block should override generated terrain")


func test_set_block_emits_signal():
	# set_block should emit block_changed signal
	var world = TileWorld.new(12345)

	# Watch for the signal
	watch_signals(world)

	# Force block generation first
	var _original = world.get_block(60, 40)

	# Set a new block
	world.set_block(60, 40, BlockData.BlockType.GOLD_ORE)

	# Check signal was emitted
	assert_signal_emitted(world, "block_changed", "set_block should emit block_changed signal")


func test_set_block_signal_has_correct_parameters():
	# block_changed signal should include position, old_type, new_type
	var world = TileWorld.new(12345)

	# Watch for the signal
	watch_signals(world)

	# Force block generation and get the original type
	var original_type = world.get_block(70, 45)
	var new_type = BlockData.BlockType.IRON_ORE

	# Set the new block
	world.set_block(70, 45, new_type)

	# Check signal parameters
	var params = get_signal_parameters(world, "block_changed", 0)
	assert_eq(params[0], Vector2i(70, 45), "Signal should include position")
	assert_eq(params[1], original_type, "Signal should include old_type")
	assert_eq(params[2], new_type, "Signal should include new_type")


# =============================================================================
# is_solid Tests
# =============================================================================

func test_is_solid_returns_true_for_solid_blocks():
	# is_solid should return true for solid blocks like STONE
	var world = TileWorld.new(12345)

	# Set a known solid block
	world.set_block(80, 50, BlockData.BlockType.STONE)

	assert_true(world.is_solid(80, 50), "STONE should be solid")


func test_is_solid_returns_false_for_air():
	# is_solid should return false for AIR
	var world = TileWorld.new(12345)

	# High altitude is AIR
	assert_false(world.is_solid(0, 100), "AIR should not be solid")


func test_is_solid_returns_false_for_water():
	# is_solid should return false for WATER
	var world = TileWorld.new(12345)

	# Set water block
	world.set_block(90, 55, BlockData.BlockType.WATER)

	assert_false(world.is_solid(90, 55), "WATER should not be solid")


func test_is_solid_uses_block_data():
	# is_solid should use BlockData.is_solid for consistency
	var world = TileWorld.new(12345)

	# Test multiple block types
	var test_cases = [
		[BlockData.BlockType.GRASS, true],
		[BlockData.BlockType.DIRT, true],
		[BlockData.BlockType.AIR, false],
		[BlockData.BlockType.WATER, false],
		[BlockData.BlockType.COBBLESTONE, true],
	]

	for test in test_cases:
		var block_type = test[0]
		var expected = test[1]
		world.set_block(0, 0, block_type)
		var result = world.is_solid(0, 0)
		assert_eq(result, expected, "is_solid for block type %d should be %s" % [block_type, expected])


# =============================================================================
# Edge Cases
# =============================================================================

func test_get_block_negative_coordinates():
	# Should handle negative coordinates
	var world = TileWorld.new(12345)
	var block = world.get_block(-100, -50)
	assert_true(block >= 0 and block <= 14, "Should handle negative coordinates")


func test_get_block_large_coordinates():
	# Should handle large coordinates
	var world = TileWorld.new(12345)
	var block = world.get_block(10000, 30)
	assert_true(block >= 0 and block <= 14, "Should handle large coordinates")


func test_set_block_at_ungenerated_position():
	# set_block should work even if block wasn't generated yet
	var world = TileWorld.new(12345)

	# Set block without getting first
	world.set_block(999, 999, BlockData.BlockType.BEDROCK)

	# Should return what we set
	var result = world.get_block(999, 999)
	assert_eq(result, BlockData.BlockType.BEDROCK, "set_block should work at ungenerated position")


# =============================================================================
# WorldSystem Existence and Construction Tests
# =============================================================================

func test_world_system_class_exists():
	# WorldSystem class should exist and be instantiable
	var system = WorldSystem.new()
	assert_not_null(system, "WorldSystem class should exist")
	system.free()


func test_world_system_extends_system():
	# WorldSystem should extend the System base class
	var system = WorldSystem.new()
	assert_true(system is System, "WorldSystem should extend System")
	system.free()


func test_world_system_has_empty_required_components():
	# WorldSystem should have empty required_components (it manages world, not entities)
	var system = WorldSystem.new()
	assert_eq(system.required_components.size(), 0, "WorldSystem should have no required components")
	system.free()


# =============================================================================
# WorldSystem.setup Tests
# =============================================================================

func test_world_system_setup_creates_tile_world():
	# setup() should create a TileWorld instance
	var system = WorldSystem.new()
	system.setup(12345)

	assert_not_null(system.tile_world, "setup should create tile_world")
	assert_true(system.tile_world is TileWorld, "tile_world should be TileWorld")
	system.free()


func test_world_system_setup_passes_seed():
	# setup() should pass the seed to TileWorld
	var system = WorldSystem.new()
	system.setup(42)

	assert_eq(system.tile_world.world_seed, 42, "setup should pass seed to TileWorld")
	system.free()


func test_world_system_tile_world_initially_null():
	# tile_world should be null before setup is called
	var system = WorldSystem.new()
	assert_null(system.tile_world, "tile_world should be null before setup")
	system.free()


# =============================================================================
# WorldSystem Proxy Methods Tests
# =============================================================================

func test_world_system_get_block_delegates_to_tile_world():
	# WorldSystem.get_block should delegate to TileWorld
	var system = WorldSystem.new()
	system.setup(12345)

	var world = TileWorld.new(12345)

	var system_block = system.get_block(100, 30)
	var world_block = world.get_block(100, 30)

	assert_eq(system_block, world_block, "get_block should delegate to tile_world")
	system.free()


func test_world_system_set_block_delegates_to_tile_world():
	# WorldSystem.set_block should delegate to TileWorld
	var system = WorldSystem.new()
	system.setup(12345)

	# Set block through system
	system.set_block(200, 40, BlockData.BlockType.DIAMOND_ORE)

	# Get through tile_world directly
	var result = system.tile_world.get_block(200, 40)

	assert_eq(result, BlockData.BlockType.DIAMOND_ORE, "set_block should delegate to tile_world")
	system.free()


func test_world_system_is_solid_delegates_to_tile_world():
	# WorldSystem.is_solid should delegate to TileWorld
	var system = WorldSystem.new()
	system.setup(12345)

	# High altitude is AIR
	assert_false(system.is_solid(0, 100), "is_solid should delegate to tile_world for AIR")

	# Set a solid block
	system.set_block(0, 50, BlockData.BlockType.STONE)
	assert_true(system.is_solid(0, 50), "is_solid should delegate to tile_world for STONE")
	system.free()
