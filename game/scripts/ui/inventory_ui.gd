@tool
class_name InventoryUI
extends Control
## Full inventory grid panel
##
## Displays all inventory slots in a grid. Opens/closes with toggle.
## Supports click-to-select and shift-click-to-move items between slots.

signal slot_clicked(slot_index: int)

const COLUMNS: int = 9
const SLOT_SIZE: int = 48
const SLOT_MARGIN: int = 4

const COLOR_NORMAL := Color(1, 1, 1)
const COLOR_SELECTED := Color(1.2, 1.2, 0.8)
const COLOR_HOVER := Color(1.1, 1.1, 1.1)

var inventory: Inventory
var _slot_panels: Array[Panel] = []
var _slot_labels: Array[Label] = []
var _name_labels: Array[Label] = []
var _is_open: bool = false
var _selected_slot: int = -1


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
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		grid.add_child(panel)
		_slot_panels.append(panel)

		# Connect mouse input for click-to-select
		var slot_index = i
		panel.gui_input.connect(_on_slot_gui_input.bind(slot_index))
		panel.mouse_entered.connect(_on_slot_mouse_entered.bind(slot_index))
		panel.mouse_exited.connect(_on_slot_mouse_exited.bind(slot_index))

		# Add label for name
		var name_label = Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.anchors_preset = Control.PRESET_FULL_RECT
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(name_label)
		_name_labels.append(name_label)

		# Add label for count
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.anchors_preset = Control.PRESET_FULL_RECT
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
		_slot_labels.append(label)

	# Size and center the background
	var grid_width = COLUMNS * SLOT_SIZE + (COLUMNS - 1) * SLOT_MARGIN
	var grid_height = rows * SLOT_SIZE + (rows - 1) * SLOT_MARGIN
	var padding = 20

	background.custom_minimum_size = Vector2(grid_width + padding * 2, grid_height + padding * 2)
	grid.position = Vector2(padding, padding)


func toggle() -> void:
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		_refresh_all_slots()
	else:
		deselect()


func open() -> void:
	_is_open = true
	visible = true
	_refresh_all_slots()


func close() -> void:
	_is_open = false
	visible = false
	deselect()


func is_open() -> bool:
	return _is_open


## Returns the currently selected slot index, or -1 if none selected
func get_selected_slot() -> int:
	return _selected_slot


## Select a specific slot by index
func select_slot(index: int) -> void:
	if index < 0 or index >= _slot_panels.size():
		return
	_selected_slot = index
	_update_selection_visual()
	slot_clicked.emit(index)


## Deselect the currently selected slot
func deselect() -> void:
	_selected_slot = -1
	_update_selection_visual()


## Handle a click on a slot. If shift is held and a slot is already selected,
## moves the item from the selected slot to the clicked slot.
## Otherwise, selects the clicked slot (or deselects if clicking the same slot).
func handle_slot_click(slot_index: int, shift_held: bool) -> void:
	if inventory == null:
		return

	if shift_held and _selected_slot >= 0 and _selected_slot != slot_index:
		# Move/stack items from selected slot to clicked slot
		inventory.move_slot(_selected_slot, slot_index)
		deselect()
	elif _selected_slot == slot_index:
		# Clicking same slot deselects
		deselect()
	else:
		# Select the clicked slot
		select_slot(slot_index)


func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			handle_slot_click(slot_index, mb.shift_pressed)


func _on_slot_mouse_entered(slot_index: int) -> void:
	if Engine.is_editor_hint():
		return
	if slot_index != _selected_slot:
		_slot_panels[slot_index].modulate = COLOR_HOVER


func _on_slot_mouse_exited(slot_index: int) -> void:
	if Engine.is_editor_hint():
		return
	if slot_index != _selected_slot:
		_slot_panels[slot_index].modulate = COLOR_NORMAL


func _update_selection_visual() -> void:
	for i in range(_slot_panels.size()):
		if i == _selected_slot:
			_slot_panels[i].modulate = COLOR_SELECTED
		else:
			_slot_panels[i].modulate = COLOR_NORMAL


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
