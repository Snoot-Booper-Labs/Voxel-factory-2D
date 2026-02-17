extends GutTest
## Unit tests for terrain atlas dimensions and block type coverage


# =============================================================================
# Atlas Path Validation
# =============================================================================

func test_item_icon_atlas_path_is_valid():
	assert_true(SpriteDB.ITEM_ICON_ATLAS_PATH.begins_with("res://"),
		"ITEM_ICON_ATLAS_PATH should start with res://")
	assert_true(SpriteDB.ITEM_ICON_ATLAS_PATH.ends_with(".png"),
		"ITEM_ICON_ATLAS_PATH should end with .png")


# =============================================================================
# Block Type Coverage
# =============================================================================

func test_all_block_types_have_properties():
	for i in range(15):
		assert_true(BlockData.block_properties.has(i),
			"BlockType %d should have block_properties entry" % i)


func test_solid_blocks_are_consistent():
	assert_false(BlockData.is_solid(BlockData.BlockType.AIR),
		"AIR should not be solid")
	assert_false(BlockData.is_solid(BlockData.BlockType.WATER),
		"WATER should not be solid")
	assert_true(BlockData.is_solid(BlockData.BlockType.STONE),
		"STONE should be solid")
	assert_true(BlockData.is_solid(BlockData.BlockType.DIRT),
		"DIRT should be solid")


func test_block_type_enum_has_expected_range():
	assert_eq(BlockData.BlockType.AIR, 0, "AIR should be 0")
	assert_eq(BlockData.BlockType.BEDROCK, 14, "BEDROCK should be 14")
