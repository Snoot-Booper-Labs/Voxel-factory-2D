## Inventory Component for ECS architecture
## Slot-based item storage with stacking support
class_name Inventory
extends Component

# =============================================================================
# Constants
# =============================================================================
const NONE = 0
const MAX_STACK = 64
const DEFAULT_SIZE = 36

# =============================================================================
# Signals
# =============================================================================
signal inventory_updated

# =============================================================================
# Properties
# =============================================================================
@export var size: int = DEFAULT_SIZE

## Internal slot storage - array of {item: int, count: int} dictionaries
var _slots: Array[Dictionary] = []

# =============================================================================
# Lifecycle
# =============================================================================

func _init(p_size: int = DEFAULT_SIZE) -> void:
	size = p_size
	_initialize_slots()


## Initialize or reinitialize slots array
func _initialize_slots() -> void:
	_slots.clear()
	for i in range(size):
		_slots.append({item = NONE, count = 0})


# =============================================================================
# Public API
# =============================================================================

## Returns the type name of this component
func get_type_name() -> String:
	return "Inventory"


## Add items to inventory, returns count of items that couldn't be added
func add_item(item_type: int, count: int) -> int:
	var remaining = count

	# First try to stack with existing slots of same type
	for i in range(_slots.size()):
		if remaining <= 0:
			break
		if _slots[i].item == item_type and _slots[i].count < MAX_STACK:
			var space = MAX_STACK - _slots[i].count
			var to_add = mini(remaining, space)
			_slots[i].count += to_add
			remaining -= to_add

	# Then fill empty slots
	for i in range(_slots.size()):
		if remaining <= 0:
			break
		if _slots[i].item == NONE:
			var to_add = mini(remaining, MAX_STACK)
			_slots[i].item = item_type
			_slots[i].count = to_add
			remaining -= to_add

	inventory_updated.emit()
	return remaining


## Remove items from a specific slot, returns {item: int, count: int} of what was removed
func remove_item(slot_index: int, count: int) -> Dictionary:
	if slot_index < 0 or slot_index >= _slots.size():
		return {item = NONE, count = 0}

	var slot = _slots[slot_index]
	if slot.item == NONE:
		return {item = NONE, count = 0}

	var to_remove = mini(count, slot.count)
	var removed_item = slot.item
	slot.count -= to_remove

	# Clear slot if empty
	if slot.count <= 0:
		slot.item = NONE
		slot.count = 0

	inventory_updated.emit()
	return {item = removed_item, count = to_remove}


## Get slot data at index, returns {item: int, count: int}
func get_slot(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= _slots.size():
		return {item = NONE, count = 0}
	return _slots[slot_index].duplicate()


## Check if inventory has at least 'count' of item_type across all slots
func has_item(item_type: int, count: int) -> bool:
	var total = 0
	for slot in _slots:
		if slot.item == item_type:
			total += slot.count
	return total >= count


## Check if all slots are at max capacity
func is_full() -> bool:
	for slot in _slots:
		if slot.item == NONE or slot.count < MAX_STACK:
			return false
	return true


## Check if at least some of the items can be added
func can_add_item(item_type: int, count: int) -> bool:
	# Check existing stacks for space
	for slot in _slots:
		if slot.item == item_type and slot.count < MAX_STACK:
			return true

	# Check for empty slots
	for slot in _slots:
		if slot.item == NONE:
			return true

	return false


## Set the contents of a specific slot directly
func set_slot(slot_index: int, item_type: int, count: int) -> void:
	if slot_index < 0 or slot_index >= _slots.size():
		return

	if count <= 0:
		_slots[slot_index].item = NONE
		_slots[slot_index].count = 0
	else:
		_slots[slot_index].item = item_type
		_slots[slot_index].count = count

	inventory_updated.emit()


## Swap the contents of two slots
func swap_slots(index_a: int, index_b: int) -> void:
	if index_a < 0 or index_a >= _slots.size():
		return
	if index_b < 0 or index_b >= _slots.size():
		return
	if index_a == index_b:
		return

	var temp_item = _slots[index_a].item
	var temp_count = _slots[index_a].count
	_slots[index_a].item = _slots[index_b].item
	_slots[index_a].count = _slots[index_b].count
	_slots[index_b].item = temp_item
	_slots[index_b].count = temp_count

	inventory_updated.emit()


## Serialize inventory to a sparse array of non-empty slots.
## Format: [{"slot": index, "item": type, "count": n}, ...]
func serialize() -> Array:
	var result: Array = []
	for i in range(_slots.size()):
		var slot := _slots[i]
		if slot.item != NONE and slot.count > 0:
			result.append({"slot": i, "item": slot.item, "count": slot.count})
	return result


## Deserialize inventory from a sparse array of slot dictionaries.
## Clears all slots first, then restores only the saved non-empty ones.
func deserialize(data: Array) -> void:
	_initialize_slots()
	for entry in data:
		if entry is Dictionary and entry.has("slot") and entry.has("item") and entry.has("count"):
			var idx: int = int(entry["slot"])
			if idx >= 0 and idx < _slots.size():
				_slots[idx].item = int(entry["item"])
				_slots[idx].count = int(entry["count"])
	inventory_updated.emit()


## Move items from one slot to another. If the target slot has the same item type,
## items are stacked. If different types, the slots are swapped.
## If shift is true, moves the entire stack to the target slot.
func move_slot(from_index: int, to_index: int) -> void:
	if from_index < 0 or from_index >= _slots.size():
		return
	if to_index < 0 or to_index >= _slots.size():
		return
	if from_index == to_index:
		return

	var from_slot = _slots[from_index]
	var to_slot = _slots[to_index]

	# If target is empty, just move
	if to_slot.item == NONE:
		_slots[to_index].item = from_slot.item
		_slots[to_index].count = from_slot.count
		_slots[from_index].item = NONE
		_slots[from_index].count = 0
	# If same item type, try to stack
	elif to_slot.item == from_slot.item:
		var space = MAX_STACK - to_slot.count
		var to_move = mini(from_slot.count, space)
		_slots[to_index].count += to_move
		_slots[from_index].count -= to_move
		if _slots[from_index].count <= 0:
			_slots[from_index].item = NONE
			_slots[from_index].count = 0
	# Different types: swap
	else:
		swap_slots(from_index, to_index)
		return  # swap_slots already emits

	inventory_updated.emit()
