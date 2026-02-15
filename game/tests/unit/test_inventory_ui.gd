extends GutTest

var inventory_ui: InventoryUI
var inventory: Inventory


func before_each() -> void:
	inventory_ui = InventoryUI.new()
	inventory = Inventory.new()
	add_child(inventory_ui)
	await get_tree().process_frame


func after_each() -> void:
	inventory_ui.queue_free()


func test_inventory_ui_exists() -> void:
	assert_not_null(inventory_ui)


func test_has_36_slots() -> void:
	assert_eq(inventory_ui.get_slot_count(), 36)


func test_starts_closed() -> void:
	assert_false(inventory_ui.is_open())
	assert_false(inventory_ui.visible)


func test_setup_connects_inventory() -> void:
	inventory_ui.setup(inventory)
	assert_eq(inventory_ui.inventory, inventory)


func test_toggle_opens_when_closed() -> void:
	inventory_ui.toggle()
	assert_true(inventory_ui.is_open())
	assert_true(inventory_ui.visible)


func test_toggle_closes_when_open() -> void:
	inventory_ui.open()
	inventory_ui.toggle()
	assert_false(inventory_ui.is_open())
	assert_false(inventory_ui.visible)


func test_open_makes_visible() -> void:
	inventory_ui.open()
	assert_true(inventory_ui.is_open())
	assert_true(inventory_ui.visible)


func test_close_hides() -> void:
	inventory_ui.open()
	inventory_ui.close()
	assert_false(inventory_ui.is_open())
	assert_false(inventory_ui.visible)


func test_slot_shows_item_count() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 50)
	await get_tree().process_frame

	assert_eq(inventory_ui.get_slot_text(0), "50")


func test_empty_slot_shows_no_text() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	await get_tree().process_frame

	assert_eq(inventory_ui.get_slot_text(0), "")


func test_inventory_updated_refreshes_when_open() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()

	inventory.add_item(ItemData.ItemType.STONE, 25)
	await get_tree().process_frame

	assert_eq(inventory_ui.get_slot_text(0), "25")


func test_multiple_slots_display() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()

	# Fill multiple slots
	for i in range(5):
		inventory.add_item(ItemData.ItemType.DIRT, 64)  # Will stack then overflow
	await get_tree().process_frame

	# First slot should be full (64)
	assert_eq(inventory_ui.get_slot_text(0), "64")


# =============================================================================
# Hold / Pick-up Tests
# =============================================================================

func test_starts_not_holding() -> void:
	assert_false(inventory_ui.is_holding())
	assert_eq(inventory_ui.get_held_slot(), -1)


func test_click_non_empty_slot_picks_up() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	assert_true(inventory_ui.is_holding())
	assert_eq(inventory_ui.get_held_slot(), 0)


func test_click_empty_slot_does_not_pick_up() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()

	inventory_ui.handle_slot_click(0)
	assert_false(inventory_ui.is_holding(), "Clicking empty slot should not pick up")
	assert_eq(inventory_ui.get_held_slot(), -1)


func test_pick_up_emits_slot_clicked() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	watch_signals(inventory_ui)
	inventory_ui.handle_slot_click(0)
	assert_signal_emitted(inventory_ui, "slot_clicked")


func test_click_same_slot_cancels_hold() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	inventory_ui.handle_slot_click(0)
	assert_false(inventory_ui.is_holding())
	assert_eq(inventory_ui.get_held_slot(), -1)


func test_cancel_held_clears_hold() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	inventory_ui.cancel_held()
	assert_false(inventory_ui.is_holding())


func test_close_cancels_hold() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	inventory_ui.close()
	assert_false(inventory_ui.is_holding())


func test_toggle_close_cancels_hold() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	inventory_ui.toggle()
	assert_false(inventory_ui.is_holding())


# =============================================================================
# Drop / Place Tests
# =============================================================================

func test_drop_onto_empty_slot_moves_item() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)  # pick up
	inventory_ui.handle_slot_click(5)  # drop onto empty slot 5

	var slot0 = inventory.get_slot(0)
	var slot5 = inventory.get_slot(5)
	assert_eq(slot0.item, 0, "Source slot should be empty after drop")
	assert_eq(slot5.item, ItemData.ItemType.DIRT, "Target slot should have the item")
	assert_eq(slot5.count, 10, "Target slot should have correct count")


func test_drop_stacks_same_type() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.set_slot(0, ItemData.ItemType.STONE, 10)
	inventory.set_slot(1, ItemData.ItemType.STONE, 20)

	inventory_ui.handle_slot_click(0)  # pick up
	inventory_ui.handle_slot_click(1)  # drop onto same type

	var slot0 = inventory.get_slot(0)
	var slot1 = inventory.get_slot(1)
	assert_eq(slot0.item, 0, "Source should be empty after stacking")
	assert_eq(slot1.count, 30, "Target should have combined count")


func test_drop_swaps_different_types() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.set_slot(0, ItemData.ItemType.DIRT, 10)
	inventory.set_slot(1, ItemData.ItemType.STONE, 20)

	inventory_ui.handle_slot_click(0)  # pick up dirt
	inventory_ui.handle_slot_click(1)  # drop onto stone -- swaps

	var slot0 = inventory.get_slot(0)
	var slot1 = inventory.get_slot(1)
	assert_eq(slot0.item, ItemData.ItemType.STONE, "Source should have target's old item")
	assert_eq(slot0.count, 20, "Source should have target's old count")
	assert_eq(slot1.item, ItemData.ItemType.DIRT, "Target should have source's old item")
	assert_eq(slot1.count, 10, "Target should have source's old count")


func test_drop_clears_hold() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	inventory_ui.handle_slot_click(5)

	assert_false(inventory_ui.is_holding(), "Hold should be cleared after drop")


func test_handle_slot_click_without_inventory_does_nothing() -> void:
	# No inventory set up
	inventory_ui.open()
	inventory_ui.handle_slot_click(0)
	assert_false(inventory_ui.is_holding(), "Should not crash or hold without inventory")


# =============================================================================
# Visual Feedback Tests
# =============================================================================

func test_held_slot_has_highlight() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	assert_eq(inventory_ui._slot_panels[0].modulate, InventoryUI.COLOR_SELECTED, "Held slot should be highlighted")


func test_non_held_slots_have_normal_color() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	assert_eq(inventory_ui._slot_panels[1].modulate, InventoryUI.COLOR_NORMAL, "Non-held slot should have normal color")
	assert_eq(inventory_ui._slot_panels[5].modulate, InventoryUI.COLOR_NORMAL, "Non-held slot should have normal color")


func test_cancel_held_restores_normal_color() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	inventory_ui.cancel_held()
	assert_eq(inventory_ui._slot_panels[0].modulate, InventoryUI.COLOR_NORMAL, "Cancelled slot should return to normal color")


# =============================================================================
# Cursor Tests
# =============================================================================

func test_cursor_changes_to_drag_when_holding() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	assert_eq(inventory_ui._slot_panels[0].mouse_default_cursor_shape, InventoryUI.CURSOR_HELD,
		"Cursor should be drag/closed-hand while holding")


func test_cursor_restores_after_cancel() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	inventory_ui.cancel_held()
	assert_eq(inventory_ui._slot_panels[0].mouse_default_cursor_shape, InventoryUI.CURSOR_DEFAULT,
		"Cursor should restore to default after cancel")


func test_cursor_restores_after_drop() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0)
	inventory_ui.handle_slot_click(5)
	assert_eq(inventory_ui._slot_panels[0].mouse_default_cursor_shape, InventoryUI.CURSOR_DEFAULT,
		"Cursor should restore to default after drop")
