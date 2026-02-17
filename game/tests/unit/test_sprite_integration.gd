extends GutTest
## Integration tests for entity scenes using sprite-based visuals


# =============================================================================
# Entity Instantiation
# =============================================================================

func test_miner_entity_instantiable():
	var miner = Miner.new()
	assert_not_null(miner, "Miner should be instantiable")
	miner.free()


func test_item_entity_instantiable():
	var entity = ItemEntity.new()
	assert_not_null(entity, "ItemEntity should be instantiable")
	entity.free()


func test_conveyor_instantiable():
	var conveyor = Conveyor.new()
	assert_not_null(conveyor, "Conveyor should be instantiable")
	conveyor.free()


# =============================================================================
# Color Fallback (backward compatibility)
# =============================================================================

func test_item_entity_color_fallback_still_works():
	var color = ItemEntity._get_item_color(ItemData.ItemType.DIRT)
	assert_not_null(color, "Should return a color for DIRT")


func test_item_entity_color_fallback_unknown_type():
	var color = ItemEntity._get_item_color(999)
	assert_not_null(color, "Should return a fallback color for unknown item type")


# =============================================================================
# SpriteDB Coverage Matches ItemData
# =============================================================================

func test_sprite_db_icon_coverage_matches_item_data():
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
		assert_true(SpriteDB.has_icon(item_type),
			"SpriteDB should have icon for ItemType %d (%s)" % [item_type, ItemData.get_item_name(item_type)])


func test_sprite_db_entity_sprites_match_known_entities():
	assert_true(SpriteDB.ENTITY_SPRITES.has("miner_idle"),
		"ENTITY_SPRITES should have miner_idle")
	assert_true(SpriteDB.ENTITY_SPRITES.has("conveyor"),
		"ENTITY_SPRITES should have conveyor")
	assert_true(SpriteDB.ENTITY_SPRITES.has("item_entity"),
		"ENTITY_SPRITES should have item_entity")
