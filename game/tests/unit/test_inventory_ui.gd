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
