extends GutTest
## Unit tests for ItemEntity - visual items that exist in the game world


# Clean up all item entities between tests to prevent cross-test contamination.
# queue_free() is deferred, so leftover entities from prior tests can pollute
# group queries (get_nodes_in_group("item_entities")) used by _try_merge_nearby()
# and EntitySaver.serialize_all().
func after_each() -> void:
	for node in get_tree().get_nodes_in_group("item_entities"):
		if is_instance_valid(node):
			node.free()


# =============================================================================
# Basic Existence and Structure
# =============================================================================

func test_item_entity_exists():
	var entity = ItemEntity.new()
	assert_not_null(entity, "ItemEntity should be instantiable")
	entity.free()


func test_item_entity_extends_area2d():
	var entity = ItemEntity.new()
	assert_true(entity is Area2D, "ItemEntity should extend Area2D")
	entity.free()


func test_item_entity_default_values():
	var entity = ItemEntity.new()
	assert_eq(entity.item_type, ItemData.ItemType.NONE, "Default item_type should be NONE")
	assert_eq(entity.count, 1, "Default count should be 1")
	assert_false(entity.on_belt, "Default on_belt should be false")
	entity.free()


# =============================================================================
# Setup
# =============================================================================

func test_item_entity_setup_sets_properties():
	var entity = ItemEntity.new()
	add_child(entity)
	entity.setup(ItemData.ItemType.DIRT, 5, Vector2(100, 200))
	assert_eq(entity.item_type, ItemData.ItemType.DIRT, "setup should set item_type")
	assert_eq(entity.count, 5, "setup should set count")
	assert_eq(entity.position, Vector2(100, 200), "setup should set position")
	entity.queue_free()


func test_item_entity_setup_stores_base_y():
	var entity = ItemEntity.new()
	add_child(entity)
	entity.setup(ItemData.ItemType.STONE, 1, Vector2(50, 150))
	assert_eq(entity._base_y, 150.0, "setup should store base_y for bobbing animation")
	entity.queue_free()


# =============================================================================
# Color Mapping
# =============================================================================

func test_item_entity_has_color_for_dirt():
	var color = ItemEntity._get_item_color(ItemData.ItemType.DIRT)
	assert_not_null(color, "Should return a color for DIRT")
	assert_ne(color, Color.BLACK, "Color should not be black")


func test_item_entity_has_color_for_stone():
	var color = ItemEntity._get_item_color(ItemData.ItemType.STONE)
	assert_not_null(color, "Should return a color for STONE")


func test_item_entity_has_color_for_diamond():
	var color = ItemEntity._get_item_color(ItemData.ItemType.DIAMOND)
	assert_not_null(color, "Should return a color for DIAMOND")


func test_item_entity_fallback_color_for_unknown():
	var color = ItemEntity._get_item_color(999)
	assert_not_null(color, "Should return a fallback color for unknown item type")


func test_item_entity_different_items_have_different_colors():
	var dirt_color = ItemEntity._get_item_color(ItemData.ItemType.DIRT)
	var stone_color = ItemEntity._get_item_color(ItemData.ItemType.STONE)
	assert_ne(dirt_color, stone_color, "Different items should have different colors")


# =============================================================================
# Serialization
# =============================================================================

func test_item_entity_serialize():
	var entity = ItemEntity.new()
	entity.item_type = ItemData.ItemType.COAL
	entity.count = 10
	entity.position = Vector2(64, -128)
	entity._base_y = -128.0

	var data = entity.serialize()
	assert_eq(data["type"], "ItemEntity", "Serialized type should be 'ItemEntity'")
	assert_eq(data["item_type"], ItemData.ItemType.COAL, "Serialized item_type should match")
	assert_eq(data["count"], 10, "Serialized count should match")
	assert_eq(data["position"]["x"], 64.0, "Serialized position.x should match")
	assert_eq(data["position"]["y"], -128.0, "Serialized position.y should match")
	assert_eq(data["on_belt"], false, "Serialized on_belt should match")
	entity.free()


func test_item_entity_deserialize():
	var entity = ItemEntity.new()
	add_child(entity)
	var data = {
		"type": "ItemEntity",
		"item_type": ItemData.ItemType.GOLD_ORE,
		"count": 3,
		"position": {"x": 32.0, "y": -64.0},
		"on_belt": false,
	}
	entity.deserialize(data)
	assert_eq(entity.item_type, ItemData.ItemType.GOLD_ORE, "Deserialized item_type should match")
	assert_eq(entity.count, 3, "Deserialized count should match")
	assert_eq(entity.position.x, 32.0, "Deserialized position.x should match")
	assert_eq(entity.position.y, -64.0, "Deserialized position.y should match")
	assert_eq(entity._base_y, -64.0, "Deserialized base_y should match position.y")
	entity.queue_free()


func test_item_entity_serialize_roundtrip():
	var entity1 = ItemEntity.new()
	entity1.item_type = ItemData.ItemType.IRON_INGOT
	entity1.count = 7
	entity1.position = Vector2(200, -300)
	entity1._base_y = -300.0

	var data = entity1.serialize()
	entity1.free()

	var entity2 = ItemEntity.new()
	add_child(entity2)
	entity2.deserialize(data)

	assert_eq(entity2.item_type, ItemData.ItemType.IRON_INGOT, "Roundtrip item_type should match")
	assert_eq(entity2.count, 7, "Roundtrip count should match")
	assert_eq(entity2.position.x, 200.0, "Roundtrip position.x should match")
	assert_eq(entity2.position.y, -300.0, "Roundtrip position.y should match")
	entity2.queue_free()


# =============================================================================
# Pickup
# =============================================================================

func test_item_entity_try_pickup_adds_to_inventory():
	var entity = ItemEntity.new()
	entity.item_type = ItemData.ItemType.STONE
	entity.count = 5
	add_child(entity)
	entity._pickup_ready = true  # Must be set AFTER add_child; _ready() resets it

	var inventory = Inventory.new()
	var picked = entity.try_pickup(inventory)

	assert_eq(picked, 5, "Should pick up all 5 items")
	assert_true(inventory.has_item(ItemData.ItemType.STONE, 5), "Inventory should have 5 stone")
	# Entity will be freed via queue_free, handled by engine


func test_item_entity_try_pickup_not_ready():
	var entity = ItemEntity.new()
	entity.item_type = ItemData.ItemType.STONE
	entity.count = 5
	entity._pickup_ready = false
	add_child(entity)

	var inventory = Inventory.new()
	var picked = entity.try_pickup(inventory)

	assert_eq(picked, 0, "Should not pick up when not ready")
	assert_false(inventory.has_item(ItemData.ItemType.STONE, 1), "Inventory should be empty")
	entity.queue_free()


func test_item_entity_try_pickup_partial():
	var entity = ItemEntity.new()
	entity.item_type = ItemData.ItemType.DIRT
	entity.count = 100
	add_child(entity)
	entity._pickup_ready = true  # Must be set AFTER add_child; _ready() resets it

	# Create a nearly full inventory (1 slot, max 64)
	var inventory = Inventory.new()
	inventory.size = 1
	inventory._initialize_slots()
	inventory.add_item(ItemData.ItemType.DIRT, 60) # 4 space left

	var picked = entity.try_pickup(inventory)
	assert_eq(picked, 4, "Should pick up only what fits (4 items)")
	assert_eq(entity.count, 96, "Entity should have 96 items remaining")
	entity.queue_free()


func test_item_entity_try_pickup_emits_signal():
	var entity = ItemEntity.new()
	entity.item_type = ItemData.ItemType.WOOD
	entity.count = 3
	add_child(entity)
	entity._pickup_ready = true  # Must be set AFTER add_child; _ready() resets it

	watch_signals(entity)
	var inventory = Inventory.new()
	entity.try_pickup(inventory)

	assert_signal_emitted(entity, "picked_up", "Should emit picked_up signal")


func test_item_entity_try_pickup_when_merging():
	var entity = ItemEntity.new()
	entity.item_type = ItemData.ItemType.STONE
	entity.count = 5
	entity._pickup_ready = true
	entity._merging = true
	add_child(entity)

	var inventory = Inventory.new()
	var picked = entity.try_pickup(inventory)

	assert_eq(picked, 0, "Should not pick up when merging")
	entity.queue_free()


# =============================================================================
# Max Stack
# =============================================================================

func test_item_entity_get_max_stack():
	var entity = ItemEntity.new()
	entity.item_type = ItemData.ItemType.DIRT
	assert_eq(entity.get_max_stack(), 64, "Dirt max stack should be 64")
	entity.free()


func test_item_entity_get_max_stack_tool():
	var entity = ItemEntity.new()
	entity.item_type = ItemData.ItemType.WOODEN_PICKAXE
	assert_eq(entity.get_max_stack(), 1, "Tool max stack should be 1")
	entity.free()


# =============================================================================
# Item Group
# =============================================================================

func test_item_entity_adds_to_group():
	var entity = ItemEntity.new()
	add_child(entity)
	assert_true(entity.is_in_group("item_entities"), "Should be in 'item_entities' group")
	entity.queue_free()


# =============================================================================
# Spawn Factory
# =============================================================================

func test_item_entity_spawn_creates_entity():
	var parent = Node2D.new()
	add_child(parent)

	var entity = ItemEntity.spawn(parent, ItemData.ItemType.COAL, 3, Vector2(100, -50))

	assert_not_null(entity, "spawn should return non-null entity")
	assert_eq(entity.item_type, ItemData.ItemType.COAL, "Spawned entity item_type should match")
	assert_eq(entity.count, 3, "Spawned entity count should match")
	assert_eq(entity.position, Vector2(100, -50), "Spawned entity position should match")
	assert_true(entity.is_inside_tree(), "Spawned entity should be in the scene tree")

	parent.queue_free()


func test_item_entity_spawn_adds_to_parent():
	var parent = Node2D.new()
	add_child(parent)

	ItemEntity.spawn(parent, ItemData.ItemType.SAND, 1, Vector2.ZERO)

	var children = parent.get_children()
	assert_gt(children.size(), 0, "Parent should have child after spawn")

	parent.queue_free()


# =============================================================================
# Merging
# =============================================================================

func test_item_entity_merge_same_type():
	var parent = Node2D.new()
	add_child(parent)

	var entity1 = ItemEntity.new()
	entity1.item_type = ItemData.ItemType.STONE
	entity1.count = 10
	entity1.position = Vector2(100, 100)
	entity1._base_y = 100
	parent.add_child(entity1)

	var entity2 = ItemEntity.new()
	entity2.item_type = ItemData.ItemType.STONE
	entity2.count = 5
	entity2.position = Vector2(110, 100) # Within MERGE_RADIUS (24px)
	entity2._base_y = 100
	parent.add_child(entity2)

	# Trigger merge manually
	entity1._try_merge_nearby()

	assert_eq(entity1.count, 15, "Entity1 should have merged count of 15")
	assert_true(entity2._merging, "Entity2 should be marked as merging (will be freed)")

	parent.queue_free()


func test_item_entity_no_merge_different_type():
	var parent = Node2D.new()
	add_child(parent)

	var entity1 = ItemEntity.new()
	entity1.item_type = ItemData.ItemType.STONE
	entity1.count = 10
	entity1.position = Vector2(100, 100)
	entity1._base_y = 100
	parent.add_child(entity1)

	var entity2 = ItemEntity.new()
	entity2.item_type = ItemData.ItemType.DIRT
	entity2.count = 5
	entity2.position = Vector2(110, 100)
	entity2._base_y = 100
	parent.add_child(entity2)

	entity1._try_merge_nearby()

	assert_eq(entity1.count, 10, "Entity1 should not merge with different type")
	assert_eq(entity2.count, 5, "Entity2 should not be merged")

	parent.queue_free()


func test_item_entity_no_merge_too_far():
	var parent = Node2D.new()
	add_child(parent)

	var entity1 = ItemEntity.new()
	entity1.item_type = ItemData.ItemType.STONE
	entity1.count = 10
	entity1.position = Vector2(100, 100)
	entity1._base_y = 100
	parent.add_child(entity1)

	var entity2 = ItemEntity.new()
	entity2.item_type = ItemData.ItemType.STONE
	entity2.count = 5
	entity2.position = Vector2(200, 100) # Beyond MERGE_RADIUS (24px)
	entity2._base_y = 100
	parent.add_child(entity2)

	entity1._try_merge_nearby()

	assert_eq(entity1.count, 10, "Entity1 should not merge with faraway entity")
	assert_eq(entity2.count, 5, "Entity2 should not be merged")

	parent.queue_free()


func test_item_entity_merge_respects_max_stack():
	var parent = Node2D.new()
	add_child(parent)

	var entity1 = ItemEntity.new()
	entity1.item_type = ItemData.ItemType.STONE
	entity1.count = 60
	entity1.position = Vector2(100, 100)
	entity1._base_y = 100
	parent.add_child(entity1)

	var entity2 = ItemEntity.new()
	entity2.item_type = ItemData.ItemType.STONE
	entity2.count = 10
	entity2.position = Vector2(110, 100)
	entity2._base_y = 100
	parent.add_child(entity2)

	entity1._try_merge_nearby()

	# Max stack is 64, so entity1 can only absorb 4 more
	assert_eq(entity1.count, 64, "Entity1 should be capped at max stack")
	assert_eq(entity2.count, 6, "Entity2 should have remaining items")
	assert_false(entity2._merging, "Entity2 should not be freed (still has items)")

	parent.queue_free()


func test_item_entity_no_merge_on_belt():
	var parent = Node2D.new()
	add_child(parent)

	var entity1 = ItemEntity.new()
	entity1.item_type = ItemData.ItemType.STONE
	entity1.count = 10
	entity1.position = Vector2(100, 100)
	entity1._base_y = 100
	entity1.on_belt = true
	parent.add_child(entity1)

	var entity2 = ItemEntity.new()
	entity2.item_type = ItemData.ItemType.STONE
	entity2.count = 5
	entity2.position = Vector2(110, 100)
	entity2._base_y = 100
	parent.add_child(entity2)

	entity1._try_merge_nearby()

	assert_eq(entity1.count, 10, "Belt items should not merge")

	parent.queue_free()


func test_item_entity_merge_emits_signal():
	var parent = Node2D.new()
	add_child(parent)

	var entity1 = ItemEntity.new()
	entity1.item_type = ItemData.ItemType.STONE
	entity1.count = 10
	entity1.position = Vector2(100, 100)
	entity1._base_y = 100
	parent.add_child(entity1)

	var entity2 = ItemEntity.new()
	entity2.item_type = ItemData.ItemType.STONE
	entity2.count = 5
	entity2.position = Vector2(110, 100)
	entity2._base_y = 100
	parent.add_child(entity2)

	watch_signals(entity1)
	entity1._try_merge_nearby()

	assert_signal_emitted(entity1, "merged", "Should emit merged signal")

	parent.queue_free()


# =============================================================================
# EntitySaver Integration
# =============================================================================

func test_entity_saver_serializes_item_entities():
	var parent = Node2D.new()
	add_child(parent)

	var entity = ItemEntity.new()
	entity.item_type = ItemData.ItemType.DIAMOND
	entity.count = 2
	entity.position = Vector2(50, -100)
	entity._base_y = -100
	parent.add_child(entity)

	var all_data = EntitySaver.serialize_all(get_tree())

	var found = false
	for data in all_data:
		if data.get("type") == "ItemEntity":
			found = true
			assert_eq(data["item_type"], ItemData.ItemType.DIAMOND, "Serialized item_type should match")
			assert_eq(data["count"], 2, "Serialized count should match")

	assert_true(found, "EntitySaver should serialize item entities")

	parent.queue_free()


func test_entity_saver_skips_belt_items():
	var parent = Node2D.new()
	add_child(parent)

	var entity = ItemEntity.new()
	entity.item_type = ItemData.ItemType.COAL
	entity.count = 1
	entity.on_belt = true
	parent.add_child(entity)

	var all_data = EntitySaver.serialize_all(get_tree())

	var found = false
	for data in all_data:
		if data.get("type") == "ItemEntity":
			found = true

	assert_false(found, "EntitySaver should skip items on belts")

	parent.queue_free()
