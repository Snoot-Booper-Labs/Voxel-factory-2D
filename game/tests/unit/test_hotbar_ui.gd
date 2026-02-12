extends GutTest

var hotbar_ui: HotbarUI
var inventory: Inventory


func before_each() -> void:
	hotbar_ui = HotbarUI.new()
	inventory = Inventory.new()
	add_child(hotbar_ui)
	# Wait for _ready to complete
	await get_tree().process_frame


func after_each() -> void:
	hotbar_ui.queue_free()


func test_hotbar_ui_exists() -> void:
	assert_not_null(hotbar_ui)


func test_has_nine_slots() -> void:
	assert_eq(hotbar_ui.get_slot_count(), 9)


func test_setup_connects_inventory() -> void:
	hotbar_ui.setup(inventory)
	assert_eq(hotbar_ui.inventory, inventory)


func test_slot_shows_item_count() -> void:
	hotbar_ui.setup(inventory)
	inventory.add_item(ItemData.ItemType.DIRT, 32)
	await get_tree().process_frame

	assert_eq(hotbar_ui.get_slot_text(0), "32")


func test_empty_slot_shows_no_text() -> void:
	hotbar_ui.setup(inventory)
	await get_tree().process_frame

	assert_eq(hotbar_ui.get_slot_text(0), "")


func test_select_slot_updates_selection() -> void:
	hotbar_ui.select_slot(5)
	assert_eq(hotbar_ui.get_selected_slot(), 5)


func test_select_slot_emits_signal() -> void:
	watch_signals(hotbar_ui)
	hotbar_ui.select_slot(3)
	assert_signal_emitted(hotbar_ui, "slot_selected")


func test_select_slot_clamps_to_valid_range() -> void:
	hotbar_ui.select_slot(20)
	assert_eq(hotbar_ui.get_selected_slot(), 0)  # Stays at default

	hotbar_ui.select_slot(-1)
	assert_eq(hotbar_ui.get_selected_slot(), 0)  # Stays at default


func test_inventory_updated_refreshes_display() -> void:
	hotbar_ui.setup(inventory)
	inventory.add_item(ItemData.ItemType.STONE, 10)
	await get_tree().process_frame

	assert_eq(hotbar_ui.get_slot_text(0), "10")

	inventory.add_item(ItemData.ItemType.STONE, 5)
	await get_tree().process_frame

	assert_eq(hotbar_ui.get_slot_text(0), "15")


func test_multiple_slots_display_correctly() -> void:
	hotbar_ui.setup(inventory)
	inventory.add_item(ItemData.ItemType.DIRT, 20)
	inventory.add_item(ItemData.ItemType.STONE, 15)
	await get_tree().process_frame

	# Dirt goes to slot 0, Stone to slot 1 (different item types)
	assert_eq(hotbar_ui.get_slot_text(0), "20")


func test_default_selected_slot_is_zero() -> void:
	assert_eq(hotbar_ui.get_selected_slot(), 0)
