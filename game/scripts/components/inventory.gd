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

func _init() -> void:
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
