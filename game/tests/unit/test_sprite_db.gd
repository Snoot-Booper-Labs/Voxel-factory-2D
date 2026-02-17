extends GutTest
## Unit tests for SpriteDB - static database mapping ItemTypes to icon atlas regions


# =============================================================================
# Constants
# =============================================================================

func test_icon_size_is_16():
	assert_eq(SpriteDB.ICON_SIZE, 16, "ICON_SIZE should be 16")


func test_atlas_columns_is_8():
	assert_eq(SpriteDB.ATLAS_COLUMNS, 8, "ATLAS_COLUMNS should be 8")


func test_atlas_rows_is_4():
	assert_eq(SpriteDB.ATLAS_ROWS, 4, "ATLAS_ROWS should be 4")


# =============================================================================
# Entity Sprite Path Keys
# =============================================================================

func test_entity_sprites_has_all_keys():
	var expected_keys = ["miner_idle", "miner_walk", "conveyor", "item_entity"]
	for key in expected_keys:
		assert_true(SpriteDB.ENTITY_SPRITES.has(key),
			"ENTITY_SPRITES should have key '%s'" % key)
	assert_eq(SpriteDB.ENTITY_SPRITES.size(), 4,
		"ENTITY_SPRITES should have exactly 4 entries")


# =============================================================================
# has_icon
# =============================================================================

func test_has_icon_for_all_item_types():
	var all_types = [
		ItemData.ItemType.NONE,
		ItemData.ItemType.DIRT,
		ItemData.ItemType.STONE,
		ItemData.ItemType.WOOD,
		ItemData.ItemType.LEAVES,
		ItemData.ItemType.SAND,
		ItemData.ItemType.GRASS,
		ItemData.ItemType.COBBLESTONE,
		ItemData.ItemType.PLANKS,
		ItemData.ItemType.BEDROCK,
		ItemData.ItemType.MINER,
		ItemData.ItemType.CONVEYOR,
		ItemData.ItemType.COAL,
		ItemData.ItemType.IRON_ORE,
		ItemData.ItemType.GOLD_ORE,
		ItemData.ItemType.IRON_INGOT,
		ItemData.ItemType.GOLD_INGOT,
		ItemData.ItemType.DIAMOND,
		ItemData.ItemType.WOODEN_PICKAXE,
		ItemData.ItemType.STONE_PICKAXE,
		ItemData.ItemType.IRON_PICKAXE,
		ItemData.ItemType.WOODEN_AXE,
		ItemData.ItemType.STONE_AXE,
		ItemData.ItemType.IRON_AXE,
		ItemData.ItemType.WOODEN_SHOVEL,
		ItemData.ItemType.STONE_SHOVEL,
		ItemData.ItemType.IRON_SHOVEL,
	]
	for item_type in all_types:
		assert_true(SpriteDB.has_icon(item_type),
			"has_icon should return true for ItemType %d" % item_type)


func test_has_icon_unknown_type_returns_false():
	assert_false(SpriteDB.has_icon(999),
		"has_icon should return false for unknown item type")


# =============================================================================
# get_icon_position
# =============================================================================

func test_get_icon_position_returns_valid_vector():
	var pos = SpriteDB.get_icon_position(ItemData.ItemType.DIRT)
	assert_eq(pos, Vector2i(1, 0),
		"DIRT icon should be at atlas position (1, 0)")


func test_get_icon_position_unknown_returns_negative():
	var pos = SpriteDB.get_icon_position(999)
	assert_eq(pos, Vector2i(-1, -1),
		"Unknown item type should return (-1, -1)")


func test_get_icon_position_all_within_atlas_bounds():
	var all_types = [
		ItemData.ItemType.NONE, ItemData.ItemType.DIRT, ItemData.ItemType.STONE,
		ItemData.ItemType.WOOD, ItemData.ItemType.LEAVES, ItemData.ItemType.SAND,
		ItemData.ItemType.GRASS, ItemData.ItemType.COBBLESTONE, ItemData.ItemType.PLANKS,
		ItemData.ItemType.BEDROCK, ItemData.ItemType.MINER, ItemData.ItemType.CONVEYOR,
		ItemData.ItemType.COAL, ItemData.ItemType.IRON_ORE, ItemData.ItemType.GOLD_ORE,
		ItemData.ItemType.IRON_INGOT, ItemData.ItemType.GOLD_INGOT, ItemData.ItemType.DIAMOND,
		ItemData.ItemType.WOODEN_PICKAXE, ItemData.ItemType.STONE_PICKAXE,
		ItemData.ItemType.IRON_PICKAXE, ItemData.ItemType.WOODEN_AXE,
		ItemData.ItemType.STONE_AXE, ItemData.ItemType.IRON_AXE,
		ItemData.ItemType.WOODEN_SHOVEL, ItemData.ItemType.STONE_SHOVEL,
		ItemData.ItemType.IRON_SHOVEL,
	]
	for item_type in all_types:
		var pos = SpriteDB.get_icon_position(item_type)
		assert_true(pos.x >= 0 and pos.x < SpriteDB.ATLAS_COLUMNS,
			"Icon x position for type %d should be within [0, %d)" % [item_type, SpriteDB.ATLAS_COLUMNS])
		assert_true(pos.y >= 0 and pos.y < SpriteDB.ATLAS_ROWS,
			"Icon y position for type %d should be within [0, %d)" % [item_type, SpriteDB.ATLAS_ROWS])


# =============================================================================
# get_icon_count
# =============================================================================

func test_get_icon_count_matches_expected():
	assert_eq(SpriteDB.get_icon_count(), 27,
		"Icon count should match all 27 ItemType entries")


# =============================================================================
# get_item_icon (headless safe)
# =============================================================================

func test_get_item_icon_unknown_returns_null():
	assert_null(SpriteDB.get_item_icon(999),
		"get_item_icon should return null for unknown item type")


func test_get_item_icon_returns_atlas_texture_or_null():
	var result = SpriteDB.get_item_icon(ItemData.ItemType.DIRT)
	if result != null:
		assert_true(result is AtlasTexture,
			"get_item_icon should return AtlasTexture when atlas is available")
		assert_eq(result.region.size, Vector2(16, 16),
			"AtlasTexture region should be 16x16")


# =============================================================================
# get_entity_sprite (headless safe)
# =============================================================================

func test_get_entity_sprite_valid_keys():
	var keys = ["miner_idle", "miner_walk", "conveyor", "item_entity"]
	for key in keys:
		var result = SpriteDB.get_entity_sprite(key)
		if result != null:
			assert_true(result is Texture2D,
				"get_entity_sprite('%s') should return Texture2D" % key)


func test_get_entity_sprite_unknown_key_returns_null():
	assert_null(SpriteDB.get_entity_sprite("nonexistent"),
		"get_entity_sprite should return null for unknown key")


# =============================================================================
# Cache Reset
# =============================================================================

func test_reset_cache_clears_loaded_flag():
	SpriteDB._reset_cache()
	# After reset, calling get_item_icon should reload (or return null in headless)
	var result = SpriteDB.get_item_icon(ItemData.ItemType.DIRT)
	# Should not crash — null or AtlasTexture are both valid
	if result != null:
		assert_true(result is AtlasTexture,
			"get_item_icon should still work after cache reset")


# =============================================================================
# Shared Cell
# =============================================================================

func test_iron_shovel_shares_cell_with_stone_shovel():
	var iron_pos = SpriteDB.get_icon_position(ItemData.ItemType.IRON_SHOVEL)
	var stone_pos = SpriteDB.get_icon_position(ItemData.ItemType.STONE_SHOVEL)
	assert_eq(iron_pos, stone_pos,
		"IRON_SHOVEL should share atlas cell with STONE_SHOVEL (temporary)")
