extends GutTest
## Unit tests for BlockData and ItemData - data-driven block and item systems

# =============================================================================
# BlockData Tests
# =============================================================================

func test_block_data_class_exists():
	# BlockData class should exist
	var block_data = BlockData.new()
	assert_not_null(block_data, "BlockData class should exist")
	# Resource extends RefCounted, no need to free


func test_block_type_enum_exists():
	# BlockType enum should have expected values
	assert_eq(BlockData.BlockType.AIR, 0, "AIR should be 0")
	assert_eq(BlockData.BlockType.GRASS, 1, "GRASS should be 1")
	assert_eq(BlockData.BlockType.DIRT, 2, "DIRT should be 2")
	assert_eq(BlockData.BlockType.STONE, 3, "STONE should be 3")


func test_block_type_enum_has_all_blocks():
	# Verify all required block types exist
	assert_true(BlockData.BlockType.has("AIR"), "Should have AIR")
	assert_true(BlockData.BlockType.has("GRASS"), "Should have GRASS")
	assert_true(BlockData.BlockType.has("DIRT"), "Should have DIRT")
	assert_true(BlockData.BlockType.has("STONE"), "Should have STONE")
	assert_true(BlockData.BlockType.has("WOOD"), "Should have WOOD")
	assert_true(BlockData.BlockType.has("LEAVES"), "Should have LEAVES")
	assert_true(BlockData.BlockType.has("SAND"), "Should have SAND")
	assert_true(BlockData.BlockType.has("WATER"), "Should have WATER")
	assert_true(BlockData.BlockType.has("COAL_ORE"), "Should have COAL_ORE")
	assert_true(BlockData.BlockType.has("IRON_ORE"), "Should have IRON_ORE")
	assert_true(BlockData.BlockType.has("GOLD_ORE"), "Should have GOLD_ORE")
	assert_true(BlockData.BlockType.has("DIAMOND_ORE"), "Should have DIAMOND_ORE")
	assert_true(BlockData.BlockType.has("COBBLESTONE"), "Should have COBBLESTONE")
	assert_true(BlockData.BlockType.has("PLANKS"), "Should have PLANKS")
	assert_true(BlockData.BlockType.has("BEDROCK"), "Should have BEDROCK")


func test_get_block_hardness_returns_correct_value():
	# get_block_hardness should return the correct hardness for known blocks
	assert_eq(BlockData.get_block_hardness(BlockData.BlockType.AIR), 0.0, "AIR hardness should be 0")
	assert_eq(BlockData.get_block_hardness(BlockData.BlockType.GRASS), 0.6, "GRASS hardness should be 0.6")
	assert_eq(BlockData.get_block_hardness(BlockData.BlockType.STONE), 1.5, "STONE hardness should be 1.5")
	assert_eq(BlockData.get_block_hardness(BlockData.BlockType.BEDROCK), -1.0, "BEDROCK should be unbreakable (-1)")


func test_get_block_hardness_returns_default_for_unknown():
	# get_block_hardness should return 1.0 for unknown block types
	assert_eq(BlockData.get_block_hardness(999), 1.0, "Unknown block should have default hardness 1.0")


func test_is_solid_returns_true_for_solid_blocks():
	# is_solid should return true for solid blocks
	assert_true(BlockData.is_solid(BlockData.BlockType.GRASS), "GRASS should be solid")
	assert_true(BlockData.is_solid(BlockData.BlockType.DIRT), "DIRT should be solid")
	assert_true(BlockData.is_solid(BlockData.BlockType.STONE), "STONE should be solid")
	assert_true(BlockData.is_solid(BlockData.BlockType.BEDROCK), "BEDROCK should be solid")


func test_is_solid_returns_false_for_air():
	# is_solid should return false for AIR
	assert_false(BlockData.is_solid(BlockData.BlockType.AIR), "AIR should not be solid")


func test_is_solid_returns_false_for_water():
	# is_solid should return false for WATER
	assert_false(BlockData.is_solid(BlockData.BlockType.WATER), "WATER should not be solid")


func test_get_block_drops():
	# get_block_drops should return the correct drop info
	var dirt_drops = BlockData.get_block_drops(BlockData.BlockType.DIRT)
	assert_eq(dirt_drops["item"], "dirt", "DIRT should drop dirt item")
	assert_eq(dirt_drops["count"], 1, "DIRT should drop 1 item")

	var stone_drops = BlockData.get_block_drops(BlockData.BlockType.STONE)
	assert_eq(stone_drops["item"], "cobblestone", "STONE should drop cobblestone")


func test_get_block_tool():
	# get_block_tool should return the preferred tool
	assert_eq(BlockData.get_block_tool(BlockData.BlockType.GRASS), "shovel", "GRASS requires shovel")
	assert_eq(BlockData.get_block_tool(BlockData.BlockType.STONE), "pickaxe", "STONE requires pickaxe")
	assert_eq(BlockData.get_block_tool(BlockData.BlockType.WOOD), "axe", "WOOD requires axe")


# =============================================================================
# ItemData Tests
# =============================================================================

func test_item_data_class_exists():
	# ItemData class should exist
	var item_data = ItemData.new()
	assert_not_null(item_data, "ItemData class should exist")
	# Resource extends RefCounted, no need to free


func test_item_type_enum_exists():
	# ItemType enum should have expected values
	assert_eq(ItemData.ItemType.NONE, 0, "NONE should be 0")


func test_item_type_enum_has_block_items():
	# Block items should exist
	assert_true(ItemData.ItemType.has("DIRT"), "Should have DIRT item")
	assert_true(ItemData.ItemType.has("STONE"), "Should have STONE item")
	assert_true(ItemData.ItemType.has("WOOD"), "Should have WOOD item")
	assert_true(ItemData.ItemType.has("COBBLESTONE"), "Should have COBBLESTONE item")


func test_item_type_enum_has_material_items():
	# Material items should exist
	assert_true(ItemData.ItemType.has("COAL"), "Should have COAL item")
	assert_true(ItemData.ItemType.has("IRON_INGOT"), "Should have IRON_INGOT item")
	assert_true(ItemData.ItemType.has("GOLD_INGOT"), "Should have GOLD_INGOT item")
	assert_true(ItemData.ItemType.has("DIAMOND"), "Should have DIAMOND item")


func test_item_type_enum_has_tools():
	# Tool items should exist
	assert_true(ItemData.ItemType.has("WOODEN_PICKAXE"), "Should have WOODEN_PICKAXE")
	assert_true(ItemData.ItemType.has("STONE_PICKAXE"), "Should have STONE_PICKAXE")


func test_get_max_stack_returns_correct_value():
	# get_max_stack should return the correct stack size
	assert_eq(ItemData.get_max_stack(ItemData.ItemType.NONE), 0, "NONE should have 0 max stack")
	assert_eq(ItemData.get_max_stack(ItemData.ItemType.DIRT), 64, "DIRT should stack to 64")
	assert_eq(ItemData.get_max_stack(ItemData.ItemType.STONE), 64, "STONE should stack to 64")


func test_get_max_stack_tools_stack_to_one():
	# Tools should only stack to 1
	assert_eq(ItemData.get_max_stack(ItemData.ItemType.WOODEN_PICKAXE), 1, "Tools should stack to 1")


func test_get_max_stack_returns_default_for_unknown():
	# get_max_stack should return 64 for unknown items
	assert_eq(ItemData.get_max_stack(999), 64, "Unknown item should have default stack 64")


func test_get_item_name_returns_correct_name():
	# get_item_name should return human-readable names
	assert_eq(ItemData.get_item_name(ItemData.ItemType.NONE), "None", "NONE name should be 'None'")
	assert_eq(ItemData.get_item_name(ItemData.ItemType.DIRT), "Dirt", "DIRT name should be 'Dirt'")
	assert_eq(ItemData.get_item_name(ItemData.ItemType.STONE), "Stone", "STONE name should be 'Stone'")
	assert_eq(ItemData.get_item_name(ItemData.ItemType.WOODEN_PICKAXE), "Wooden Pickaxe", "WOODEN_PICKAXE name")


func test_get_item_name_returns_unknown_for_invalid():
	# get_item_name should return "Unknown" for invalid items
	assert_eq(ItemData.get_item_name(999), "Unknown", "Unknown item should have name 'Unknown'")


func test_is_placeable_returns_true_for_blocks():
	# is_placeable should return true for block items
	assert_true(ItemData.is_placeable(ItemData.ItemType.DIRT), "DIRT should be placeable")
	assert_true(ItemData.is_placeable(ItemData.ItemType.STONE), "STONE should be placeable")


func test_is_placeable_returns_false_for_non_blocks():
	# is_placeable should return false for non-block items
	assert_false(ItemData.is_placeable(ItemData.ItemType.COAL), "COAL should not be placeable")
	assert_false(ItemData.is_placeable(ItemData.ItemType.WOODEN_PICKAXE), "Tools should not be placeable")


func test_get_block_for_item():
	# get_block_for_item should return the associated block type
	assert_eq(ItemData.get_block_for_item(ItemData.ItemType.DIRT), BlockData.BlockType.DIRT, "DIRT item -> DIRT block")
	assert_eq(ItemData.get_block_for_item(ItemData.ItemType.STONE), BlockData.BlockType.STONE, "STONE item -> STONE block")
