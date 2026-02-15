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
# Selection Tests
# =============================================================================

func test_starts_with_no_selection() -> void:
	assert_eq(inventory_ui.get_selected_slot(), -1)


func test_select_slot() -> void:
	inventory_ui.open()
	inventory_ui.select_slot(5)
	assert_eq(inventory_ui.get_selected_slot(), 5)


func test_select_slot_emits_slot_clicked() -> void:
	inventory_ui.open()
	watch_signals(inventory_ui)
	inventory_ui.select_slot(3)
	assert_signal_emitted(inventory_ui, "slot_clicked")


func test_deselect_clears_selection() -> void:
	inventory_ui.open()
	inventory_ui.select_slot(5)
	inventory_ui.deselect()
	assert_eq(inventory_ui.get_selected_slot(), -1)


func test_close_deselects() -> void:
	inventory_ui.open()
	inventory_ui.select_slot(5)
	inventory_ui.close()
	assert_eq(inventory_ui.get_selected_slot(), -1)


func test_toggle_close_deselects() -> void:
	inventory_ui.open()
	inventory_ui.select_slot(5)
	inventory_ui.toggle()
	assert_eq(inventory_ui.get_selected_slot(), -1)


func test_select_invalid_slot_does_nothing() -> void:
	inventory_ui.open()
	inventory_ui.select_slot(-1)
	assert_eq(inventory_ui.get_selected_slot(), -1)
	inventory_ui.select_slot(100)
	assert_eq(inventory_ui.get_selected_slot(), -1)


# =============================================================================
# Click Interaction Tests
# =============================================================================

func test_handle_slot_click_selects_slot() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory_ui.handle_slot_click(3, false)
	assert_eq(inventory_ui.get_selected_slot(), 3)


func test_handle_slot_click_same_slot_deselects() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory_ui.handle_slot_click(3, false)
	inventory_ui.handle_slot_click(3, false)
	assert_eq(inventory_ui.get_selected_slot(), -1)


func test_handle_slot_click_different_slot_reselects() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory_ui.handle_slot_click(3, false)
	inventory_ui.handle_slot_click(7, false)
	assert_eq(inventory_ui.get_selected_slot(), 7)


func test_shift_click_moves_item_to_empty_slot() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	# Select slot 0 (has dirt), then shift-click slot 5 (empty)
	inventory_ui.handle_slot_click(0, false)
	inventory_ui.handle_slot_click(5, true)

	var slot0 = inventory.get_slot(0)
	var slot5 = inventory.get_slot(5)
	assert_eq(slot0.item, 0, "Source slot should be empty after shift-click move")
	assert_eq(slot5.item, ItemData.ItemType.DIRT, "Target slot should have the item")
	assert_eq(slot5.count, 10, "Target slot should have correct count")


func test_shift_click_stacks_same_type() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.set_slot(0, ItemData.ItemType.STONE, 10)
	inventory.set_slot(1, ItemData.ItemType.STONE, 20)

	inventory_ui.handle_slot_click(0, false)
	inventory_ui.handle_slot_click(1, true)

	var slot0 = inventory.get_slot(0)
	var slot1 = inventory.get_slot(1)
	assert_eq(slot0.item, 0, "Source should be empty after stacking")
	assert_eq(slot1.count, 30, "Target should have combined count")


func test_shift_click_swaps_different_types() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.set_slot(0, ItemData.ItemType.DIRT, 10)
	inventory.set_slot(1, ItemData.ItemType.STONE, 20)

	inventory_ui.handle_slot_click(0, false)
	inventory_ui.handle_slot_click(1, true)

	var slot0 = inventory.get_slot(0)
	var slot1 = inventory.get_slot(1)
	assert_eq(slot0.item, ItemData.ItemType.STONE, "Source should have target's old item")
	assert_eq(slot1.item, ItemData.ItemType.DIRT, "Target should have source's old item")


func test_shift_click_deselects_after_move() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()
	inventory.add_item(ItemData.ItemType.DIRT, 10)

	inventory_ui.handle_slot_click(0, false)
	inventory_ui.handle_slot_click(5, true)

	assert_eq(inventory_ui.get_selected_slot(), -1, "Selection should be cleared after shift-click move")


func test_shift_click_without_selection_selects() -> void:
	inventory_ui.setup(inventory)
	inventory_ui.open()

	# Shift-click with no selection should just select (shift is ignored without a prior selection)
	inventory_ui.handle_slot_click(3, true)
	# No prior selection, so shift has no effect - behaves as normal click
	assert_eq(inventory_ui.get_selected_slot(), 3)


func test_handle_slot_click_without_inventory_does_nothing() -> void:
	# No inventory set up
	inventory_ui.open()
	inventory_ui.handle_slot_click(0, false)
	# Should not crash, selection should not change
	assert_eq(inventory_ui.get_selected_slot(), -1)


# =============================================================================
# Visual Feedback Tests
# =============================================================================

func test_selected_slot_has_highlight() -> void:
	inventory_ui.open()
	inventory_ui.select_slot(3)
	assert_eq(inventory_ui._slot_panels[3].modulate, InventoryUI.COLOR_SELECTED, "Selected slot should be highlighted")


func test_unselected_slots_have_normal_color() -> void:
	inventory_ui.open()
	inventory_ui.select_slot(3)
	assert_eq(inventory_ui._slot_panels[0].modulate, InventoryUI.COLOR_NORMAL, "Non-selected slot should have normal color")
	assert_eq(inventory_ui._slot_panels[5].modulate, InventoryUI.COLOR_NORMAL, "Non-selected slot should have normal color")


func test_deselect_restores_normal_color() -> void:
	inventory_ui.open()
	inventory_ui.select_slot(3)
	inventory_ui.deselect()
	assert_eq(inventory_ui._slot_panels[3].modulate, InventoryUI.COLOR_NORMAL, "Deselected slot should return to normal color")
