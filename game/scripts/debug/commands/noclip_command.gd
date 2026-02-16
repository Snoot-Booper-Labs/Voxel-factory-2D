## Noclip command — toggle noclip mode (disable collision + enable fly)
class_name NoclipCommand
extends BaseCommand


func get_name() -> String:
	return "noclip"


func get_description() -> String:
	return "Toggle noclip mode (disable collision + fly)"


func get_usage() -> String:
	return "noclip"


func execute(_args: Array, context: Dictionary) -> String:
	var player: PlayerController = context.get("player")
	if player == null:
		return "Error: Player not available."

	if not player.has_method("toggle_noclip_mode"):
		return "Error: Player does not support noclip mode."

	var is_noclipping: bool = player.toggle_noclip_mode()
	if is_noclipping:
		return "[color=green]Noclip mode enabled[/color] — No collision, free movement"
	else:
		return "[color=red]Noclip mode disabled[/color]"
