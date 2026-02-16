## Fly command — toggle fly mode (disable gravity, WASD movement in all directions)
class_name FlyCommand
extends BaseCommand


func get_name() -> String:
	return "fly"


func get_description() -> String:
	return "Toggle fly mode (disable gravity, move freely)"


func get_usage() -> String:
	return "fly"


func execute(_args: Array, context: Dictionary) -> String:
	var player: PlayerController = context.get("player")
	if player == null:
		return "Error: Player not available."

	if not player.has_method("toggle_fly_mode"):
		return "Error: Player does not support fly mode."

	var is_flying: bool = player.toggle_fly_mode()
	if is_flying:
		return "[color=green]Fly mode enabled[/color] — Use WASD + Space/Shift to move"
	else:
		return "[color=red]Fly mode disabled[/color]"
