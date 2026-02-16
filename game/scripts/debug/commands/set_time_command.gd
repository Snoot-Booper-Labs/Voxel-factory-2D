## Set time command — set the day/night cycle time (placeholder)
class_name SetTimeCommand
extends BaseCommand


func get_name() -> String:
	return "set_time"


func get_description() -> String:
	return "Set the day/night cycle time — placeholder"


func get_usage() -> String:
	return "set_time <value>"


func execute(args: Array, _context: Dictionary) -> String:
	if args.size() < 1:
		return "Usage: %s" % get_usage()

	if not (args[0] as String).is_valid_float():
		return "Error: Time value must be a number."

	var time_value := float(args[0])
	# No day/night cycle system exists yet
	return "[color=yellow]Time set to %.1f[/color] (no effect — day/night cycle not yet implemented)" % time_value
