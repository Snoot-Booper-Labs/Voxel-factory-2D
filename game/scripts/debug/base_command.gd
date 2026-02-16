## Abstract base class for debug console commands
## Subclasses must implement get_name(), get_description(), get_usage(), and execute()
class_name BaseCommand
extends RefCounted

# =============================================================================
# Public API (Override in subclasses)
# =============================================================================

## Returns the command name used to invoke it (e.g. "help", "give", "tp")
func get_name() -> String:
	return ""


## Returns a short description of what the command does
func get_description() -> String:
	return ""


## Returns usage syntax (e.g. "give <item_name> [count]")
func get_usage() -> String:
	return get_name()


## Execute the command with the given arguments and context
## Returns the output string to display in the console
func execute(args: Array, context: Dictionary) -> String:
	return "Command not implemented."
