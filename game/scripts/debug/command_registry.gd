## Registry for debug console commands
## Maps command names to BaseCommand instances, handles parsing and execution
class_name CommandRegistry
extends RefCounted

# =============================================================================
# Properties
# =============================================================================

## Dictionary mapping command name (String) -> BaseCommand instance
var _commands: Dictionary = {}


# =============================================================================
# Public API
# =============================================================================

## Register a command. Overwrites if a command with the same name exists.
func register(command: BaseCommand) -> void:
	var name := command.get_name()
	if name.is_empty():
		return
	_commands[name] = command


## Unregister a command by name. Returns true if it existed.
func unregister(name: String) -> bool:
	return _commands.erase(name)


## Execute a raw input string. Parses into command name + args, dispatches.
## Returns the output string to display.
func execute(input: String, context: Dictionary) -> String:
	var trimmed := input.strip_edges()
	if trimmed.is_empty():
		return ""

	var parts := trimmed.split(" ", false)
	if parts.is_empty():
		return ""

	var name := parts[0].to_lower()
	var args: Array = []
	for i in range(1, parts.size()):
		args.append(parts[i])

	if not _commands.has(name):
		return "Unknown command: '%s'. Type 'help' for available commands." % name

	return _commands[name].execute(args, context)


## Returns true if a command with the given name is registered
func has_command(name: String) -> bool:
	return _commands.has(name)


## Returns the BaseCommand for the given name, or null
func get_command(name: String) -> BaseCommand:
	if _commands.has(name):
		return _commands[name]
	return null


## Returns a sorted array of all registered command names
func get_command_names() -> Array:
	var names: Array = _commands.keys()
	names.sort()
	return names


## Returns all registered commands as a dictionary (name -> BaseCommand)
func get_all_commands() -> Dictionary:
	return _commands


## Returns command names that start with the given prefix (for tab completion)
func get_completions(prefix: String) -> Array:
	var matches: Array = []
	var lower_prefix := prefix.to_lower()
	for name in _commands:
		if (name as String).begins_with(lower_prefix):
			matches.append(name)
	matches.sort()
	return matches
