@tool
class_name InventoryUI
extends Control
## Full inventory grid panel
##
## Displays all inventory slots in a grid. Opens/closes with toggle.
## Click a non-empty slot to "pick up" the item (highlights slot, changes cursor).
## Click another slot to "drop" it there (move/stack/swap). Click same slot or
## press ESC to cancel. Picking up is visual only -- the item stays in the slot
## until it is placed somewhere.

signal slot_clicked(slot_index: int)

const COLUMNS: int = 9
const SLOT_SIZE: int = 48
const SLOT_MARGIN: int = 4
const DEFAULT_SLOT_COUNT: int = 36

## Number of inventory slots to display. Set before _ready() or call rebuild_grid().
@export var slot_count: int = DEFAULT_SLOT_COUNT

const COLOR_NORMAL := Color(1, 1, 1)
const COLOR_SELECTED := Color(1.2, 1.2, 0.8)
const COLOR_HOVER := Color(1.1, 1.1, 1.1)

## Cursor shown while an item is "held"
const CURSOR_HELD := Control.CURSOR_DRAG
## Default cursor for hovering over a slot
const CURSOR_DEFAULT := Control.CURSOR_POINTING_HAND

var inventory: Inventory
var _slot_panels: Array[Panel] = []
var _slot_labels: Array[Label] = []
var _name_labels: Array[Label] = []
var _is_open: bool = false
## Index of the slot whose item the player is "holding", or -1
var _held_slot: int = -1


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

	# Calculate grid dimensions from configurable slot_count
	var rows = int(ceil(float(slot_count) / COLUMNS))

	for i in range(slot_count):
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = CURSOR_DEFAULT
		grid.add_child(panel)
		_slot_panels.append(panel)

		# Connect mouse input for click interactions
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
		cancel_held()


func open() -> void:
	_is_open = true
	visible = true
	_refresh_all_slots()


func close() -> void:
	_is_open = false
	visible = false
	cancel_held()


func is_open() -> bool:
	return _is_open


# =========================================================================
# Held-item API
# =========================================================================

## Returns the slot index of the item being held, or -1 if nothing held
func get_held_slot() -> int:
	return _held_slot


## True when the player is holding an item
func is_holding() -> bool:
	return _held_slot >= 0


## Cancel the current hold -- put nothing down, restore cursor
func cancel_held() -> void:
	_held_slot = -1
	_update_visuals()


# Legacy alias kept for InputManager compatibility
func get_selected_slot() -> int:
	return _held_slot


func deselect() -> void:
	cancel_held()


# =========================================================================
# Click handling
# =========================================================================

## Core interaction: first click picks up, second click drops.
func handle_slot_click(slot_index: int) -> void:
	if inventory == null:
		return

	if _held_slot < 0:
		# Nothing held yet -- pick up if slot is non-empty
		var slot_data = inventory.get_slot(slot_index)
		if slot_data.item != 0 and slot_data.count > 0:
			_held_slot = slot_index
			_update_visuals()
			slot_clicked.emit(slot_index)
	elif _held_slot == slot_index:
		# Clicking the same slot cancels the hold
		cancel_held()
	else:
		# Drop onto a different slot (move / stack / swap)
		inventory.move_slot(_held_slot, slot_index)
		cancel_held()


func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			handle_slot_click(slot_index)


func _on_slot_mouse_entered(slot_index: int) -> void:
	if Engine.is_editor_hint():
		return
	if slot_index != _held_slot:
		_slot_panels[slot_index].modulate = COLOR_HOVER


func _on_slot_mouse_exited(slot_index: int) -> void:
	if Engine.is_editor_hint():
		return
	if slot_index != _held_slot:
		_slot_panels[slot_index].modulate = COLOR_NORMAL


# =========================================================================
# Visuals
# =========================================================================

func _update_visuals() -> void:
	_update_selection_visual()
	_update_cursor()


func _update_selection_visual() -> void:
	for i in range(_slot_panels.size()):
		if i == _held_slot:
			_slot_panels[i].modulate = COLOR_SELECTED
		else:
			_slot_panels[i].modulate = COLOR_NORMAL


func _update_cursor() -> void:
	var shape = CURSOR_HELD if _held_slot >= 0 else CURSOR_DEFAULT
	for panel in _slot_panels:
		panel.mouse_default_cursor_shape = shape


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


## Rebuild the grid with the current slot_count. Useful after changing slot_count at runtime.
func rebuild_grid() -> void:
	_create_grid()
	if inventory != null:
		_refresh_all_slots()


func get_slot_text(index: int) -> String:
	if index >= 0 and index < _slot_labels.size():
		return _slot_labels[index].text
	return ""
