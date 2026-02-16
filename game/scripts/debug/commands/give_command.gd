## Give command — add items to the player inventory
class_name GiveCommand
extends BaseCommand


func get_name() -> String:
	return "give"


func get_description() -> String:
	return "Add items to the player inventory"


func get_usage() -> String:
	return "give <item_name> [count]"


func execute(args: Array, context: Dictionary) -> String:
	if args.size() < 1:
		return "Usage: %s" % get_usage()

	var inventory: Inventory = context.get("inventory")
	if inventory == null:
		return "Error: Player inventory not available."

	# Join multi-word item names with spaces, but last arg might be count
	var item_name: String
	var count := 1

	# Check if last arg is a number (the count)
	if args.size() >= 2 and args[args.size() - 1].is_valid_int():
		count = int(args[args.size() - 1])
		# Item name is everything except the last arg
		var name_parts: Array = args.slice(0, args.size() - 1)
		item_name = " ".join(name_parts)
	else:
		item_name = " ".join(args)

	# Look up item type by name
	var item_type := ItemData.get_type_from_name(item_name)
	if item_type == ItemData.ItemType.NONE:
		# Try matching with underscores replaced by spaces
		item_type = ItemData.get_type_from_name(item_name.replace("_", " "))

	if item_type == ItemData.ItemType.NONE:
		var available := _get_item_names()
		return "Unknown item: '%s'. Available items: %s" % [item_name, ", ".join(available)]

	if count <= 0:
		return "Count must be positive."

	var remaining := inventory.add_item(item_type, count)
	var added := count - remaining
	var display_name := ItemData.get_item_name(item_type)

	if remaining > 0:
		return "Added %d x %s (inventory full, %d couldn't be added)" % [added, display_name, remaining]
	return "Added %d x %s" % [added, display_name]


func _get_item_names() -> Array:
	var names: Array = []
	for type in ItemData.item_properties:
		if type != ItemData.ItemType.NONE:
			names.append(ItemData.item_properties[type]["name"])
	return names
