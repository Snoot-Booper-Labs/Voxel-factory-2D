extends GutTest

var ui: MinerInventoryUI
var miner: Miner


func before_each() -> void:
	ui = MinerInventoryUI.new()
	miner = Miner.new()
	add_child(ui)
	await get_tree().process_frame


func after_each() -> void:
	ui.queue_free()
	miner.queue_free()


# =============================================================================
# Basic lifecycle
# =============================================================================

func test_exists() -> void:
	assert_not_null(ui)


func test_starts_hidden() -> void:
	assert_false(ui.is_open())
	assert_false(ui.visible)


func test_has_18_slots() -> void:
	assert_eq(ui.get_slot_count(), 18)


func test_open_makes_visible() -> void:
	ui.open()
	assert_true(ui.is_open())
	assert_true(ui.visible)


func test_close_hides() -> void:
	ui.open()
	ui.close()
	assert_false(ui.is_open())
	assert_false(ui.visible)


func test_toggle_opens_when_closed() -> void:
	ui.toggle()
	assert_true(ui.is_open())


func test_toggle_closes_when_open() -> void:
	ui.open()
	ui.toggle()
	assert_false(ui.is_open())


# =============================================================================
# Setup / miner binding
# =============================================================================

func test_setup_binds_miner() -> void:
	ui.setup(miner)
	assert_eq(ui.get_miner(), miner)


func test_setup_connects_inventory() -> void:
	ui.setup(miner)
	assert_eq(ui.inventory, miner.get_inventory())


func test_setup_with_null_clears_miner() -> void:
	ui.setup(miner)
	ui.setup(null)
	assert_null(ui.get_miner())
	assert_null(ui.inventory)


# =============================================================================
# Slot display
# =============================================================================

func test_slot_shows_item_count() -> void:
	ui.setup(miner)
	ui.open()
	miner.get_inventory().add_item(ItemData.ItemType.DIRT, 50)
	await get_tree().process_frame
	assert_eq(ui.get_slot_text(0), "50")


func test_empty_slot_shows_no_text() -> void:
	ui.setup(miner)
	ui.open()
	await get_tree().process_frame
	assert_eq(ui.get_slot_text(0), "")


func test_inventory_updated_refreshes_when_open() -> void:
	ui.setup(miner)
	ui.open()
	miner.get_inventory().add_item(ItemData.ItemType.STONE, 25)
	await get_tree().process_frame
	assert_eq(ui.get_slot_text(0), "25")


# =============================================================================
# Hold / pick-up
# =============================================================================

func test_starts_not_holding() -> void:
	assert_false(ui.is_holding())
	assert_eq(ui.get_held_slot(), -1)


func test_click_non_empty_slot_picks_up() -> void:
	ui.setup(miner)
	ui.open()
	miner.get_inventory().add_item(ItemData.ItemType.DIRT, 10)
	ui.handle_slot_click(0)
	assert_true(ui.is_holding())
	assert_eq(ui.get_held_slot(), 0)


func test_click_empty_slot_does_not_pick_up() -> void:
	ui.setup(miner)
	ui.open()
	ui.handle_slot_click(0)
	assert_false(ui.is_holding())


func test_click_same_slot_cancels_hold() -> void:
	ui.setup(miner)
	ui.open()
	miner.get_inventory().add_item(ItemData.ItemType.DIRT, 10)
	ui.handle_slot_click(0)
	ui.handle_slot_click(0)
	assert_false(ui.is_holding())


func test_close_cancels_hold() -> void:
	ui.setup(miner)
	ui.open()
	miner.get_inventory().add_item(ItemData.ItemType.DIRT, 10)
	ui.handle_slot_click(0)
	ui.close()
	assert_false(ui.is_holding())


# =============================================================================
# Drop / move
# =============================================================================

func test_drop_onto_empty_slot_moves_item() -> void:
	ui.setup(miner)
	ui.open()
	miner.get_inventory().add_item(ItemData.ItemType.DIRT, 10)
	ui.handle_slot_click(0)
	ui.handle_slot_click(5)

	var inv = miner.get_inventory()
	assert_eq(inv.get_slot(0).item, 0, "Source slot should be empty")
	assert_eq(inv.get_slot(5).item, ItemData.ItemType.DIRT, "Target should have item")
	assert_eq(inv.get_slot(5).count, 10)


func test_drop_clears_hold() -> void:
	ui.setup(miner)
	ui.open()
	miner.get_inventory().add_item(ItemData.ItemType.DIRT, 10)
	ui.handle_slot_click(0)
	ui.handle_slot_click(5)
	assert_false(ui.is_holding())


# =============================================================================
# Config toggle: leaves_belt
# =============================================================================

func test_belt_toggle_reads_miner_state_false() -> void:
	miner.leaves_belt = false
	ui.setup(miner)
	ui.open()
	assert_false(ui._belt_toggle.button_pressed, "Toggle should read miner's leaves_belt (false)")


func test_belt_toggle_reads_miner_state_true() -> void:
	miner.leaves_belt = true
	ui.setup(miner)
	ui.open()
	assert_true(ui._belt_toggle.button_pressed, "Toggle should read miner's leaves_belt (true)")


func test_belt_toggle_writes_miner_state() -> void:
	miner.leaves_belt = false
	ui.setup(miner)
	ui.open()
	# Simulate toggling ON
	ui._belt_toggle.button_pressed = true
	assert_true(miner.leaves_belt, "Toggling ON should set miner.leaves_belt = true")


func test_belt_toggle_writes_miner_state_off() -> void:
	miner.leaves_belt = true
	ui.setup(miner)
	ui.open()
	# Simulate toggling OFF
	ui._belt_toggle.button_pressed = false
	assert_false(miner.leaves_belt, "Toggling OFF should set miner.leaves_belt = false")


func test_switching_miner_updates_toggle() -> void:
	var miner2 = Miner.new()
	miner.leaves_belt = true
	miner2.leaves_belt = false

	ui.setup(miner)
	ui.open()
	assert_true(ui._belt_toggle.button_pressed)

	ui.setup(miner2)
	assert_false(ui._belt_toggle.button_pressed, "Toggle should update when switching miners")

	miner2.queue_free()


func test_toggle_does_not_affect_previous_miner() -> void:
	var miner2 = Miner.new()
	miner.leaves_belt = false
	miner2.leaves_belt = false

	ui.setup(miner)
	ui.open()
	ui.setup(miner2)
	ui._belt_toggle.button_pressed = true

	assert_false(miner.leaves_belt, "Previous miner should not be affected")
	assert_true(miner2.leaves_belt, "Current miner should be affected")

	miner2.queue_free()


# =============================================================================
# Config toggle: run_miner
# =============================================================================

func test_run_toggle_reads_miner_state_paused() -> void:
	miner.is_paused = true
	ui.setup(miner)
	ui.open()
	assert_false(ui._run_toggle.button_pressed, "Toggle should read miner's is_paused (true -> button_pressed false)")


func test_run_toggle_reads_miner_state_running() -> void:
	miner.is_paused = false
	ui.setup(miner)
	ui.open()
	assert_true(ui._run_toggle.button_pressed, "Toggle should read miner's is_paused (false -> button_pressed true)")


func test_run_toggle_writes_miner_state_paused() -> void:
	miner.is_paused = false
	ui.setup(miner)
	ui.open()
	# Simulate toggling OFF
	ui._run_toggle.button_pressed = false
	assert_true(miner.is_paused, "Toggling OFF should set miner.is_paused = true")


func test_run_toggle_writes_miner_state_running() -> void:
	miner.is_paused = true
	ui.setup(miner)
	ui.open()
	# Simulate toggling ON
	ui._run_toggle.button_pressed = true
	assert_false(miner.is_paused, "Toggling ON should set miner.is_paused = false")


func test_run_switching_miner_updates_toggle() -> void:
	var miner2 = Miner.new()
	miner.is_paused = true # not pressed
	miner2.is_paused = false # pressed

	ui.setup(miner)
	ui.open()
	assert_false(ui._run_toggle.button_pressed)

	ui.setup(miner2)
	assert_true(ui._run_toggle.button_pressed, "Toggle should update when switching miners")

	miner2.queue_free()


func test_run_toggle_does_not_affect_previous_miner() -> void:
	var miner2 = Miner.new()
	miner.is_paused = false
	miner2.is_paused = false

	ui.setup(miner)
	ui.open()
	ui.setup(miner2)
	ui._run_toggle.button_pressed = false # pauses miner2

	assert_false(miner.is_paused, "Previous miner should not be affected")
	assert_true(miner2.is_paused, "Current miner should be affected")

	miner2.queue_free()


# =============================================================================
# Program info placeholder
# =============================================================================

func test_program_label_exists() -> void:
	assert_not_null(ui._program_label)


func test_program_label_shows_placeholder() -> void:
	assert_eq(ui._program_label.text, "Program: (none)")


# =============================================================================
# Visual feedback
# =============================================================================

func test_held_slot_has_highlight() -> void:
	ui.setup(miner)
	ui.open()
	miner.get_inventory().add_item(ItemData.ItemType.DIRT, 10)
	ui.handle_slot_click(0)
	assert_eq(ui._slot_panels[0].modulate, MinerInventoryUI.COLOR_SELECTED)


func test_cancel_held_restores_normal_color() -> void:
	ui.setup(miner)
	ui.open()
	miner.get_inventory().add_item(ItemData.ItemType.DIRT, 10)
	ui.handle_slot_click(0)
	ui.cancel_held()
	assert_eq(ui._slot_panels[0].modulate, MinerInventoryUI.COLOR_NORMAL)


# =============================================================================
# Miner inventory size
# =============================================================================

func test_miner_inventory_has_18_slots() -> void:
	var inv = miner.get_inventory()
	assert_eq(inv.size, 18, "Miner inventory should have 18 slots")


func test_miner_inventory_full_at_18() -> void:
	var inv = miner.get_inventory()
	for i in range(18):
		inv.set_slot(i, ItemData.ItemType.DIRT, 64)
	assert_true(inv.is_full(), "Miner inventory should be full after filling 18 slots")


func test_miner_inventory_overflow_at_18() -> void:
	var inv = miner.get_inventory()
	# Fill all 18 slots
	for i in range(18):
		inv.set_slot(i, ItemData.ItemType.DIRT, 64)
	# Try adding more — should return remaining
	var remaining = inv.add_item(ItemData.ItemType.STONE, 10)
	assert_eq(remaining, 10, "Should not be able to add to full 18-slot inventory")
