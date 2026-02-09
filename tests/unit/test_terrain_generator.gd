extends GutTest
## Unit tests for TerrainGenerator - 2D procedural terrain generation

# =============================================================================
# TerrainGenerator Existence and Construction Tests
# =============================================================================

func test_terrain_generator_class_exists():
	# TerrainGenerator class should exist
	var generator = TerrainGenerator.new(12345)
	assert_not_null(generator, "TerrainGenerator class should exist")


func test_terrain_generator_stores_seed():
	# TerrainGenerator should store the world seed
	var generator = TerrainGenerator.new(42)
	assert_eq(generator.world_seed, 42, "TerrainGenerator should store seed")


func test_terrain_generator_has_biome_planner():
	# TerrainGenerator should have a BiomePlanner instance
	var generator = TerrainGenerator.new(12345)
	assert_not_null(generator.biome_planner, "Should have biome_planner")
	assert_true(generator.biome_planner is BiomePlanner, "biome_planner should be BiomePlanner")


func test_terrain_generator_has_height_noise():
	# TerrainGenerator should have a FastNoiseLite for height
	var generator = TerrainGenerator.new(12345)
	assert_not_null(generator.height_noise, "Should have height_noise")
	assert_true(generator.height_noise is FastNoiseLite, "height_noise should be FastNoiseLite")


# =============================================================================
# get_block_at Basic Tests
# =============================================================================

func test_get_block_at_returns_valid_block_type():
	# get_block_at should return a valid BlockType
	var generator = TerrainGenerator.new(12345)
	var block = generator.get_block_at(0, 30)

	# Block should be a valid BlockType (0-14 based on BlockData)
	assert_true(block >= 0 and block <= 14, "Block should be valid BlockType (0-14)")


func test_get_block_at_returns_air_above_terrain():
	# Blocks high above the terrain should be AIR
	var generator = TerrainGenerator.new(12345)
	# Y=100 should be above any terrain (mountains max at 80)
	var block = generator.get_block_at(0, 100)
	assert_eq(block, BlockData.BlockType.AIR, "High altitude should be AIR")


func test_get_block_at_returns_stone_deep_underground():
	# Blocks deep underground should be STONE
	var generator = TerrainGenerator.new(12345)
	# Y=1 should be deep underground
	var block = generator.get_block_at(0, 1)
	assert_eq(block, BlockData.BlockType.STONE, "Deep underground should be STONE")


# =============================================================================
# Determinism Tests
# =============================================================================

func test_get_block_at_deterministic_same_seed():
	# Same seed should produce same block at same position
	var generator1 = TerrainGenerator.new(12345)
	var generator2 = TerrainGenerator.new(12345)

	var block1 = generator1.get_block_at(100, 30)
	var block2 = generator2.get_block_at(100, 30)

	assert_eq(block1, block2, "Same seed should produce same block at same position")


func test_get_block_at_deterministic_multiple_calls():
	# Multiple calls to same position should return same block
	var generator = TerrainGenerator.new(12345)

	var block1 = generator.get_block_at(500, 30)
	var block2 = generator.get_block_at(500, 30)
	var block3 = generator.get_block_at(500, 30)

	assert_eq(block1, block2, "Multiple calls should return same block")
	assert_eq(block2, block3, "Multiple calls should return same block")


func test_get_block_at_different_seed_may_differ():
	# Different seeds should produce different blocks at same position
	# (statistically very likely with these seeds)
	var generator1 = TerrainGenerator.new(12345)
	var generator2 = TerrainGenerator.new(99999)

	# Test multiple positions to find at least one difference
	var found_difference := false
	for x in range(0, 1000, 50):
		for y in range(10, 50, 5):
			if generator1.get_block_at(x, y) != generator2.get_block_at(x, y):
				found_difference = true
				break
		if found_difference:
			break

	assert_true(found_difference, "Different seeds should produce different blocks somewhere")


# =============================================================================
# Terrain Height Variation Tests
# =============================================================================

func test_terrain_height_varies_with_x():
	# Terrain height should vary across x positions
	var generator = TerrainGenerator.new(12345)

	# Find where air starts for different x positions
	var heights := []
	for x in [0, 200, 400, 600, 800]:
		# Scan upward to find the air boundary
		for y in range(100, 0, -1):
			if generator.get_block_at(x, y) == BlockData.BlockType.AIR:
				continue
			heights.append(y)
			break

	# Heights should vary (not all the same)
	var unique_heights := {}
	for h in heights:
		unique_heights[h] = true

	assert_true(unique_heights.size() > 1, "Terrain height should vary with x position")


# =============================================================================
# Biome-Aware Terrain Tests
# =============================================================================

func test_surface_block_matches_biome():
	# Surface block should match the biome's surface_block setting
	var generator = TerrainGenerator.new(12345)

	# Sample multiple positions to find surface blocks
	var surface_blocks_match_biome := true
	for x in range(0, 1000, 100):
		var biome_type = generator.biome_planner.get_biome_at(x, 0)
		var params = BiomeData.get_biome_params(biome_type)
		var expected_surface = params["surface_block"]

		# Find the surface block at this x
		for y in range(100, 0, -1):
			var block = generator.get_block_at(x, y)
			if block == BlockData.BlockType.AIR:
				continue
			# This is the surface block
			if block != expected_surface:
				surface_blocks_match_biome = false
			break

	assert_true(surface_blocks_match_biome, "Surface blocks should match biome settings")


func test_subsurface_blocks_exist_below_surface():
	# Blocks just below surface should be subsurface blocks
	var generator = TerrainGenerator.new(12345)

	# Sample a position
	var x := 50
	var surface_y := -1
	var biome_type = generator.biome_planner.get_biome_at(x, 0)
	var params = BiomeData.get_biome_params(biome_type)
	var expected_subsurface = params["subsurface_block"]

	# Find surface
	for y in range(100, 0, -1):
		if generator.get_block_at(x, y) != BlockData.BlockType.AIR:
			surface_y = y
			break

	# Check blocks just below surface (1-3 blocks down)
	assert_true(surface_y > 3, "Should find a surface to test")
	var block_below = generator.get_block_at(x, surface_y - 2)
	assert_eq(block_below, expected_subsurface, "Blocks below surface should be subsurface type")


func test_get_terrain_height_returns_valid_height():
	# _get_terrain_height should return height within biome's range
	var generator = TerrainGenerator.new(12345)

	for x in range(0, 500, 50):
		var biome_type = generator.biome_planner.get_biome_at(x, 0)
		var params = BiomeData.get_biome_params(biome_type)
		var height_range: Vector2i = params["height_range"]

		var height = generator._get_terrain_height(x, params)

		assert_true(height >= height_range.x, "Height should be >= min for biome")
		assert_true(height <= height_range.y, "Height should be <= max for biome")


# =============================================================================
# Edge Cases
# =============================================================================

func test_get_block_at_negative_x():
	# Should handle negative x coordinates
	var generator = TerrainGenerator.new(12345)
	var block = generator.get_block_at(-100, 30)
	assert_true(block >= 0 and block <= 14, "Should handle negative x")


func test_get_block_at_y_zero():
	# Y=0 should be solid (bedrock or stone)
	var generator = TerrainGenerator.new(12345)
	var block = generator.get_block_at(0, 0)
	assert_true(block == BlockData.BlockType.STONE or block == BlockData.BlockType.BEDROCK,
		"Y=0 should be stone or bedrock")


func test_get_block_at_large_coordinates():
	# Should handle large coordinates
	var generator = TerrainGenerator.new(12345)
	var block = generator.get_block_at(10000, 30)
	assert_true(block >= 0 and block <= 14, "Should handle large x coordinates")
