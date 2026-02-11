@tool
class_name HotbarUI
extends Control
## 9-slot hotbar display at bottom of screen
##
## Connects to Inventory to display items with counts.
## Supports slot selection via number keys 1-9.

signal slot_selected(slot_index: int)

const SLOT_COUNT: int = 9
const SLOT_SIZE: int = 48
const SLOT_MARGIN: int = 4

var inventory: Inventory
var selected_slot: int = 0
var _slot_panels: Array[Panel] = []
var _slot_labels: Array[Label] = []
var _name_labels: Array[Label] = []


func _ready() -> void:
	_create_slots()
	_update_selection_visual()


func setup(inv: Inventory) -> void:
	if inventory != null and inventory.inventory_updated.is_connected(_on_inventory_updated):
		inventory.inventory_updated.disconnect(_on_inventory_updated)

	inventory = inv
	if inventory != null:
		inventory.inventory_updated.connect(_on_inventory_updated)
		_refresh_all_slots()


func _create_slots() -> void:
	# Clear existing children to prevent duplicates in tool mode
	for child in get_children():
		child.queue_free()
	_slot_panels.clear()
	_slot_labels.clear()
	_name_labels.clear()

	# Create horizontal container for slots
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", SLOT_MARGIN)
	add_child(container)


	for i in range(SLOT_COUNT):
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		container.add_child(panel)
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

	# Center at bottom of screen
	anchor_top = 1.0
	anchor_bottom = 1.0
	anchor_left = 0.5
	anchor_right = 0.5
	offset_top = - (SLOT_SIZE + 20)
	offset_bottom = -20
	var total_width = SLOT_COUNT * SLOT_SIZE + (SLOT_COUNT - 1) * SLOT_MARGIN
	offset_left = - total_width / 2
	offset_right = total_width / 2


func select_slot(index: int) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	selected_slot = index
	_update_selection_visual()
	slot_selected.emit(selected_slot)


func get_selected_slot() -> int:
	return selected_slot


func _on_inventory_updated() -> void:
	_refresh_all_slots()


func _refresh_all_slots() -> void:
	if inventory == null:
		return

	for i in range(SLOT_COUNT):
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


func _update_selection_visual() -> void:
	for i in range(_slot_panels.size()):
		var panel = _slot_panels[i]
		if i == selected_slot:
			panel.modulate = Color(1.2, 1.2, 0.8) # Highlighted
		else:
			panel.modulate = Color(1, 1, 1) # Normal


func get_slot_count() -> int:
	return _slot_labels.size()


func get_slot_text(index: int) -> String:
	if index >= 0 and index < _slot_labels.size():
		return _slot_labels[index].text
	return ""
