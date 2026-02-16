## Dimension command — switch to a different dimension
class_name DimensionCommand
extends BaseCommand


func get_name() -> String:
	return "dim"


func get_description() -> String:
	return "Switch to a dimension by ID"


func get_usage() -> String:
	return "dim <id>"


func execute(args: Array, context: Dictionary) -> String:
	if args.size() < 1:
		return "Usage: %s" % get_usage()

	var dimension_system: DimensionSystem = context.get("dimension_system")
	if dimension_system == null:
		return "Error: Dimension system not available."

	if not (args[0] as String).is_valid_int():
		return "Error: Dimension ID must be an integer."

	var dim_id := int(args[0])

	# Create the dimension if it doesn't exist
	if not dimension_system.has_dimension(dim_id):
		dimension_system.create_dimension(dim_id)

	var success := dimension_system.set_active_dimension(dim_id)
	if success:
		return "Switched to dimension [color=yellow]%d[/color]" % dim_id
	else:
		return "Error: Failed to switch to dimension %d" % dim_id
