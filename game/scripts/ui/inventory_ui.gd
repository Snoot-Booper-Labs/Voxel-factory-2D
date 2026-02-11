@tool
class_name InventoryUI
extends Control
## Full inventory grid panel
##
## Displays all inventory slots in a grid. Opens/closes with toggle.

signal slot_clicked(slot_index: int)

const COLUMNS: int = 9
const SLOT_SIZE: int = 48
const SLOT_MARGIN: int = 4

var inventory: Inventory
var _slot_panels: Array[Panel] = []
var _slot_labels: Array[Label] = []
var _name_labels: Array[Label] = []
var _is_open: bool = false


func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = false
	else:
		visible = true
	_create_grid()


func setup(inv: Inventory) -> void:
	if inventory != null and inventory.inventory_updated.is_connected(_on_inventory_updated):
		inventory.inventory_updated.disconnect(_on_inventory_updated)

	inventory = inv
	if inventory != null:
		inventory.inventory_updated.connect(_on_inventory_updated)
		_refresh_all_slots()


func _create_grid() -> void:
	# Clear existing children to prevent duplicates in tool mode
	for child in get_children():
		child.queue_free()
	_slot_panels.clear()
	_slot_labels.clear()
	_name_labels.clear()

	# Create centered panel background
	var background = Panel.new()
	background.name = "Background"
	add_child(background)

	# Create grid container
	var grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", SLOT_MARGIN)
	grid.add_theme_constant_override("v_separation", SLOT_MARGIN)
	background.add_child(grid)

	# Calculate size for 36 slots (4 rows x 9 columns)
	var slot_count = 36
	var rows = int(ceil(float(slot_count) / COLUMNS))

	for i in range(slot_count):
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		grid.add_child(panel)
		_slot_panels.append(panel)

		# Add label for name
		var name_label = Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.anchors_preset = Control.PRESET_FULL_RECT
		name_label.add_theme_font_size_override("font_size", 10)
		panel.add_child(name_label)
		_name_labels.append(name_label)

		# Add label for count
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.anchors_preset = Control.PRESET_FULL_RECT
		panel.add_child(label)
		_slot_labels.append(label)

	# Size and center the background
	var grid_width = COLUMNS * SLOT_SIZE + (COLUMNS - 1) * SLOT_MARGIN
	var grid_height = rows * SLOT_SIZE + (rows - 1) * SLOT_MARGIN
	var padding = 20

	background.custom_minimum_size = Vector2(grid_width + padding * 2, grid_height + padding * 2)
	grid.position = Vector2(padding, padding)

	# Center on screen - depreciated for lower position
	#anchor_left = 0.5
	#anchor_right = 0.5
	#anchor_top = 0.5
	#anchor_bottom = 0.5
	#offset_left = - (grid_width + padding * 2) / 2
	#offset_right = (grid_width + padding * 2) / 2
	#offset_top = - (grid_height + padding * 2) / 2
	#offset_bottom = (grid_height + padding * 2) / 2


func toggle() -> void:
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		_refresh_all_slots()


func open() -> void:
	_is_open = true
	visible = true
	_refresh_all_slots()


func close() -> void:
	_is_open = false
	visible = false


func is_open() -> bool:
	return _is_open


func _on_inventory_updated() -> void:
	if _is_open:
		_refresh_all_slots()


func _refresh_all_slots() -> void:
	if inventory == null:
		return

	for i in range(_slot_labels.size()):
		_update_slot(i)


func _update_slot(index: int) -> void:
	if inventory == null or index >= _slot_labels.size():
		return

	var slot_data = inventory.get_slot(index)
	var label = _slot_labels[index]
	var name_label = _name_labels[index]

	if slot_data.item == 0 or slot_data.count <= 0:
		label.text = ""
		name_label.text = ""
	else:
		label.text = str(slot_data.count)
		name_label.text = ItemData.get_item_name(slot_data.item)


func get_slot_count() -> int:
	return _slot_labels.size()


func get_slot_text(index: int) -> String:
	if index >= 0 and index < _slot_labels.size():
		return _slot_labels[index].text
	return ""
