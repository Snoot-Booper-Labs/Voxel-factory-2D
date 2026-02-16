## Help command — lists all commands or shows usage for a specific command
class_name HelpCommand
extends BaseCommand


func get_name() -> String:
	return "help"


func get_description() -> String:
	return "List all commands or show usage for a specific command"


func get_usage() -> String:
	return "help [command]"


func execute(args: Array, context: Dictionary) -> String:
	var registry: CommandRegistry = context.get("registry")
	if registry == null:
		return "Error: Command registry not available."

	# Show help for a specific command
	if args.size() > 0:
		var cmd_name: String = args[0].to_lower()
		var command := registry.get_command(cmd_name)
		if command == null:
			return "Unknown command: '%s'" % cmd_name
		var lines: Array[String] = []
		lines.append("[color=yellow]%s[/color] — %s" % [command.get_name(), command.get_description()])
		lines.append("  Usage: [color=cyan]%s[/color]" % command.get_usage())
		return "\n".join(lines)

	# List all commands
	var names := registry.get_command_names()
	if names.is_empty():
		return "No commands registered."

	var lines: Array[String] = []
	lines.append("[color=cyan]Available commands:[/color]")
	for cmd_name in names:
		var command := registry.get_command(cmd_name as String)
		if command:
			lines.append("  [color=yellow]%s[/color] — %s" % [command.get_name(), command.get_description()])
	lines.append("\nType [color=yellow]help <command>[/color] for detailed usage.")
	return "\n".join(lines)
