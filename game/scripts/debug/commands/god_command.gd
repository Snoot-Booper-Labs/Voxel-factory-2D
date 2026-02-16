## God command — toggle invincibility (placeholder until health system exists)
class_name GodCommand
extends BaseCommand


func get_name() -> String:
	return "god"


func get_description() -> String:
	return "Toggle god mode (invincibility) — placeholder"


func get_usage() -> String:
	return "god"


func execute(_args: Array, _context: Dictionary) -> String:
	# No health system exists yet, so this is a no-op placeholder
	return "[color=yellow]God mode toggled[/color] (no effect — health system not yet implemented)"
