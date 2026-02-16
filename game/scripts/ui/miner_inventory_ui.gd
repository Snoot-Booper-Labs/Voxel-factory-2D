class_name MinerInventoryUI
extends Control
## Miner-specific inventory panel
##
## Displays the miner's 18-slot inventory grid along with configuration
## controls (top-left) and a program info area (top-right, placeholder).
## Delegates slot interactions (pick-up / drop / swap) to an embedded
## InventoryUI-style grid built programmatically.

signal slot_clicked(slot_index: int)

# =========================================================================
# Layout constants
# =========================================================================
const COLUMNS: int = 9
const SLOT_SIZE: int = 48
const SLOT_MARGIN: int = 4
const PADDING: int = 20
const HEADER_HEIGHT: int = 40
const HEADER_GAP: int = 12

const COLOR_NORMAL := Color(1, 1, 1)
const COLOR_SELECTED := Color(1.2, 1.2, 0.8)
const COLOR_HOVER := Color(1.1, 1.1, 1.1)

const CURSOR_HELD := Control.CURSOR_DRAG
const CURSOR_DEFAULT := Control.CURSOR_POINTING_HAND

# =========================================================================
# State
# =========================================================================
var inventory: Inventory
var _miner: Miner
var _slot_panels: Array[Panel] = []
var _slot_labels: Array[Label] = []
var _name_labels: Array[Label] = []
var _is_open: bool = false
var _held_slot: int = -1

## Config controls
var _belt_toggle: CheckButton
## Program info placeholder
var _program_label: Label


func _ready() -> void:
	visible = false
	_create_panel()


# =========================================================================
# Public API
# =========================================================================

## Bind a miner to this UI. Connects the miner's inventory and reads config.
func setup(miner: Miner) -> void:
	# Disconnect previous inventory signal
	if inventory != null and inventory.inventory_updated.is_connected(_on_inventory_updated):
		inventory.inventory_updated.disconnect(_on_inventory_updated)

	_miner = miner
	if _miner == null:
		inventory = null
		return

	inventory = _miner.get_inventory()
	if inventory != null:
		inventory.inventory_updated.connect(_on_inventory_updated)

	# Sync config controls to this miner's state
	_sync_config_from_miner()
	_refresh_all_slots()


func open() -> void:
	_is_open = true
	visible = true
	_sync_config_from_miner()
	_refresh_all_slots()


func close() -> void:
	_is_open = false
	visible = false
	cancel_held()


func toggle() -> void:
	if _is_open:
		close()
	else:
		open()


func is_open() -> bool:
	return _is_open


func is_holding() -> bool:
	return _held_slot >= 0


func get_held_slot() -> int:
	return _held_slot


func cancel_held() -> void:
	_held_slot = -1
	_update_visuals()


# Legacy alias kept for InputManager compatibility
func get_selected_slot() -> int:
	return _held_slot


func deselect() -> void:
	cancel_held()


func get_slot_count() -> int:
	return _slot_labels.size()


func get_slot_text(index: int) -> String:
	if index >= 0 and index < _slot_labels.size():
		return _slot_labels[index].text
	return ""


## Returns the currently-bound miner, or null.
func get_miner() -> Miner:
	return _miner


# =========================================================================
# Click handling
# =========================================================================

func handle_slot_click(slot_index: int) -> void:
	if inventory == null:
		return

	if _held_slot < 0:
		var slot_data = inventory.get_slot(slot_index)
		if slot_data.item != 0 and slot_data.count > 0:
			_held_slot = slot_index
			_update_visuals()
			slot_clicked.emit(slot_index)
	elif _held_slot == slot_index:
		cancel_held()
	else:
		inventory.move_slot(_held_slot, slot_index)
		cancel_held()


func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			handle_slot_click(slot_index)


func _on_slot_mouse_entered(slot_index: int) -> void:
	if slot_index != _held_slot:
		_slot_panels[slot_index].modulate = COLOR_HOVER


func _on_slot_mouse_exited(slot_index: int) -> void:
	if slot_index != _held_slot:
		_slot_panels[slot_index].modulate = COLOR_NORMAL


# =========================================================================
# Config callbacks
# =========================================================================

func _on_belt_toggle_changed(toggled_on: bool) -> void:
	if _miner != null:
		_miner.leaves_belt = toggled_on


func _sync_config_from_miner() -> void:
	if _miner == null:
		return
	if _belt_toggle != null:
		# Temporarily disconnect to avoid feedback loop
		if _belt_toggle.toggled.is_connected(_on_belt_toggle_changed):
			_belt_toggle.toggled.disconnect(_on_belt_toggle_changed)
		_belt_toggle.button_pressed = _miner.leaves_belt
		_belt_toggle.toggled.connect(_on_belt_toggle_changed)


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


# =========================================================================
# Panel construction
# =========================================================================

func _create_panel() -> void:
	for child in get_children():
		child.queue_free()
	_slot_panels.clear()
	_slot_labels.clear()
	_name_labels.clear()

	# --- Measurements ---
	var grid_cols = COLUMNS
	var slot_count = Miner.MINER_INVENTORY_SIZE  # 18
	var grid_rows = int(ceil(float(slot_count) / grid_cols))
	var grid_width = grid_cols * SLOT_SIZE + (grid_cols - 1) * SLOT_MARGIN
	var grid_height = grid_rows * SLOT_SIZE + (grid_rows - 1) * SLOT_MARGIN
	var panel_width = grid_width + PADDING * 2
	var panel_height = PADDING + HEADER_HEIGHT + HEADER_GAP + grid_height + PADDING

	# --- Background panel ---
	var background = Panel.new()
	background.name = "Background"
	background.custom_minimum_size = Vector2(panel_width, panel_height)
	add_child(background)

	# --- Header row: config (left) + program info (right) ---
	var header_y = PADDING

	# Config section — left side
	_belt_toggle = CheckButton.new()
	_belt_toggle.text = "Leave Belts"
	_belt_toggle.button_pressed = false
	_belt_toggle.position = Vector2(PADDING, header_y)
	_belt_toggle.toggled.connect(_on_belt_toggle_changed)
	background.add_child(_belt_toggle)

	# Program info — right side placeholder
	_program_label = Label.new()
	_program_label.text = "Program: (none)"
	_program_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_program_label.position = Vector2(panel_width - PADDING - 160, header_y + 4)
	_program_label.custom_minimum_size = Vector2(160, HEADER_HEIGHT)
	background.add_child(_program_label)

	# --- Inventory grid ---
	var grid = GridContainer.new()
	grid.columns = grid_cols
	grid.add_theme_constant_override("h_separation", SLOT_MARGIN)
	grid.add_theme_constant_override("v_separation", SLOT_MARGIN)
	grid.position = Vector2(PADDING, header_y + HEADER_HEIGHT + HEADER_GAP)
	background.add_child(grid)

	for i in range(slot_count):
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.mouse_default_cursor_shape = CURSOR_DEFAULT
		grid.add_child(panel)
		_slot_panels.append(panel)

		var slot_index = i
		panel.gui_input.connect(_on_slot_gui_input.bind(slot_index))
		panel.mouse_entered.connect(_on_slot_mouse_entered.bind(slot_index))
		panel.mouse_exited.connect(_on_slot_mouse_exited.bind(slot_index))

		# Item name label (centered)
		var name_label = Label.new()
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.anchors_preset = Control.PRESET_FULL_RECT
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(name_label)
		_name_labels.append(name_label)

		# Count label (bottom-right)
		var label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.anchors_preset = Control.PRESET_FULL_RECT
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)
		_slot_labels.append(label)
