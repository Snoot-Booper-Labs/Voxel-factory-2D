## Clear command — clears the console output
class_name ClearCommand
extends BaseCommand


func get_name() -> String:
	return "clear"


func get_description() -> String:
	return "Clear the console output"


func get_usage() -> String:
	return "clear"


func execute(_args: Array, context: Dictionary) -> String:
	var console = context.get("console")
	if console and console.has_method("clear_output"):
		console.clear_output()
	return ""
