extends GutTest
## Unit tests for Inventory Component (ECS component for item storage)

# =============================================================================
# Constants for testing
# =============================================================================
const NONE = 0
const MAX_STACK = 64
const DEFAULT_SIZE = 36


# =============================================================================
# Inventory Component Basic Tests
# =============================================================================

func test_inventory_exists():
	# Inventory class should exist and be instantiable
	var inventory = Inventory.new()
	assert_not_null(inventory, "Inventory should be instantiable")


func test_inventory_extends_component():
	var inventory = Inventory.new()
	assert_true(inventory is Component, "Inventory should extend Component")


func test_inventory_get_type_name():
	var inventory = Inventory.new()
	assert_eq(inventory.get_type_name(), "Inventory", "get_type_name should return 'Inventory'")


func test_inventory_has_default_size():
	var inventory = Inventory.new()
	assert_eq(inventory.size, DEFAULT_SIZE, "Inventory should have default size of 36")


func test_inventory_custom_size():
	var inventory = Inventory.new()
	inventory.size = 10
	inventory._initialize_slots()
	assert_eq(inventory._slots.size(), 10, "Inventory should support custom size")


# =============================================================================
# Slot Structure Tests
# =============================================================================

func test_inventory_slots_initialized():
	var inventory = Inventory.new()
	assert_eq(inventory._slots.size(), DEFAULT_SIZE, "Inventory should initialize with correct number of slots")


func test_inventory_empty_slot_structure():
	var inventory = Inventory.new()
	var slot = inventory.get_slot(0)
	assert_eq(slot.item, NONE, "Empty slot should have item type NONE (0)")
	assert_eq(slot.count, 0, "Empty slot should have count 0")


# =============================================================================
# add_item Tests
# =============================================================================

func test_add_item_to_empty_inventory():
	var inventory = Inventory.new()
	var remaining = inventory.add_item(1, 10)  # item_type=1, count=10
	assert_eq(remaining, 0, "Adding to empty inventory should return 0 remaining")


func test_add_item_updates_slot():
	var inventory = Inventory.new()
	inventory.add_item(1, 10)
	var slot = inventory.get_slot(0)
	assert_eq(slot.item, 1, "Slot should contain the added item type")
	assert_eq(slot.count, 10, "Slot should contain the correct count")


func test_add_item_stacks_same_type():
	var inventory = Inventory.new()
	inventory.add_item(1, 10)
	inventory.add_item(1, 20)
	var slot = inventory.get_slot(0)
	assert_eq(slot.count, 30, "Same item type should stack in same slot")


func test_add_item_different_types_use_different_slots():
	var inventory = Inventory.new()
	inventory.add_item(1, 10)
	inventory.add_item(2, 15)
	var slot0 = inventory.get_slot(0)
	var slot1 = inventory.get_slot(1)
	assert_eq(slot0.item, 1, "First item should be in slot 0")
	assert_eq(slot1.item, 2, "Second item should be in slot 1")


func test_add_item_respects_max_stack():
	var inventory = Inventory.new()
	inventory.add_item(1, MAX_STACK + 10)
	var slot0 = inventory.get_slot(0)
	var slot1 = inventory.get_slot(1)
	assert_eq(slot0.count, MAX_STACK, "First slot should be at max stack")
	assert_eq(slot1.count, 10, "Overflow should go to next slot")


func test_add_item_returns_remaining_when_full():
	var inventory = Inventory.new()
	inventory.size = 1
	inventory._initialize_slots()
	var remaining = inventory.add_item(1, MAX_STACK + 20)
	assert_eq(remaining, 20, "Should return items that couldn't be added")


# =============================================================================
# remove_item Tests
# =============================================================================

func test_remove_item_from_slot():
	var inventory = Inventory.new()
	inventory.add_item(1, 10)
	var removed = inventory.remove_item(0, 5)
	assert_eq(removed.item, 1, "Removed item should have correct type")
	assert_eq(removed.count, 5, "Removed should have correct count")


func test_remove_item_updates_slot():
	var inventory = Inventory.new()
	inventory.add_item(1, 10)
	inventory.remove_item(0, 5)
	var slot = inventory.get_slot(0)
	assert_eq(slot.count, 5, "Slot should have reduced count")


func test_remove_all_items_clears_slot():
	var inventory = Inventory.new()
	inventory.add_item(1, 10)
	inventory.remove_item(0, 10)
	var slot = inventory.get_slot(0)
	assert_eq(slot.item, NONE, "Removing all items should clear slot item type")
	assert_eq(slot.count, 0, "Removing all items should set count to 0")


func test_remove_more_than_available():
	var inventory = Inventory.new()
	inventory.add_item(1, 5)
	var removed = inventory.remove_item(0, 10)
	assert_eq(removed.count, 5, "Should only remove available amount")


func test_remove_from_empty_slot():
	var inventory = Inventory.new()
	var removed = inventory.remove_item(0, 5)
	assert_eq(removed.item, NONE, "Removing from empty slot should return NONE type")
	assert_eq(removed.count, 0, "Removing from empty slot should return 0 count")


# =============================================================================
# get_slot Tests
# =============================================================================

func test_get_slot_returns_dictionary():
	var inventory = Inventory.new()
	var slot = inventory.get_slot(0)
	assert_true(slot is Dictionary, "get_slot should return a Dictionary")
	assert_true(slot.has("item"), "Slot should have 'item' key")
	assert_true(slot.has("count"), "Slot should have 'count' key")


func test_get_slot_invalid_index_returns_empty():
	var inventory = Inventory.new()
	var slot = inventory.get_slot(-1)
	assert_eq(slot.item, NONE, "Invalid index should return empty slot")
	slot = inventory.get_slot(100)
	assert_eq(slot.item, NONE, "Out of bounds index should return empty slot")


# =============================================================================
# has_item Tests
# =============================================================================

func test_has_item_returns_true_when_present():
	var inventory = Inventory.new()
	inventory.add_item(1, 10)
	assert_true(inventory.has_item(1, 5), "has_item should return true when enough items present")


func test_has_item_returns_true_for_exact_count():
	var inventory = Inventory.new()
	inventory.add_item(1, 10)
	assert_true(inventory.has_item(1, 10), "has_item should return true for exact count")


func test_has_item_returns_false_when_not_enough():
	var inventory = Inventory.new()
	inventory.add_item(1, 5)
	assert_false(inventory.has_item(1, 10), "has_item should return false when not enough items")


func test_has_item_returns_false_when_missing():
	var inventory = Inventory.new()
	assert_false(inventory.has_item(1, 1), "has_item should return false when item type not present")


func test_has_item_counts_across_slots():
	var inventory = Inventory.new()
	inventory.add_item(1, MAX_STACK)
	inventory.add_item(1, 10)
	assert_true(inventory.has_item(1, MAX_STACK + 5), "has_item should count items across multiple slots")


# =============================================================================
# is_full Tests
# =============================================================================

func test_is_full_returns_false_for_empty_inventory():
	var inventory = Inventory.new()
	assert_false(inventory.is_full(), "Empty inventory should not be full")


func test_is_full_returns_false_with_space():
	var inventory = Inventory.new()
	inventory.add_item(1, 10)
	assert_false(inventory.is_full(), "Inventory with space should not be full")


func test_is_full_returns_true_when_all_slots_maxed():
	var inventory = Inventory.new()
	inventory.size = 2
	inventory._initialize_slots()
	inventory.add_item(1, MAX_STACK)
	inventory.add_item(2, MAX_STACK)
	assert_true(inventory.is_full(), "Inventory should be full when all slots at max stack")


# =============================================================================
# can_add_item Tests
# =============================================================================

func test_can_add_item_returns_true_when_empty():
	var inventory = Inventory.new()
	assert_true(inventory.can_add_item(1, 10), "Should be able to add to empty inventory")


func test_can_add_item_returns_true_when_can_stack():
	var inventory = Inventory.new()
	inventory.add_item(1, 10)
	assert_true(inventory.can_add_item(1, 10), "Should be able to stack more items")


func test_can_add_item_returns_false_when_full():
	var inventory = Inventory.new()
	inventory.size = 1
	inventory._initialize_slots()
	inventory.add_item(1, MAX_STACK)
	assert_false(inventory.can_add_item(2, 1), "Should not be able to add when full with different type")


func test_can_add_item_returns_true_when_can_partial_stack():
	var inventory = Inventory.new()
	inventory.size = 1
	inventory._initialize_slots()
	inventory.add_item(1, MAX_STACK - 10)
	assert_true(inventory.can_add_item(1, 5), "Should be able to add when space in existing stack")


func test_can_add_item_returns_false_when_no_space():
	var inventory = Inventory.new()
	inventory.size = 1
	inventory._initialize_slots()
	inventory.add_item(1, MAX_STACK)
	assert_false(inventory.can_add_item(1, 1), "Should not be able to add when slot is at max")


# =============================================================================
# Signal Tests
# =============================================================================

func test_inventory_updated_signal_exists():
	var inventory = Inventory.new()
	assert_true(inventory.has_signal("inventory_updated"), "Inventory should have inventory_updated signal")


func test_add_item_emits_signal():
	var inventory = Inventory.new()
	watch_signals(inventory)
	inventory.add_item(1, 10)
	assert_signal_emitted(inventory, "inventory_updated", "add_item should emit inventory_updated signal")


func test_remove_item_emits_signal():
	var inventory = Inventory.new()
	inventory.add_item(1, 10)
	watch_signals(inventory)
	inventory.remove_item(0, 5)
	assert_signal_emitted(inventory, "inventory_updated", "remove_item should emit inventory_updated signal")
