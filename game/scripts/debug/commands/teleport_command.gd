## Teleport command — teleport the player to world coordinates
class_name TeleportCommand
extends BaseCommand


func get_name() -> String:
	return "tp"


func get_description() -> String:
	return "Teleport the player to tile coordinates"


func get_usage() -> String:
	return "tp <x> <y>"


func execute(args: Array, context: Dictionary) -> String:
	if args.size() < 2:
		return "Usage: %s" % get_usage()

	var player: PlayerController = context.get("player")
	if player == null:
		return "Error: Player not available."

	if not (args[0] as String).is_valid_int() or not (args[1] as String).is_valid_int():
		return "Error: Coordinates must be integers. Usage: %s" % get_usage()

	var tile_x := int(args[0])
	var tile_y := int(args[1])

	# Convert tile coordinates to world/screen coordinates
	var world_pos := WorldUtils.tile_to_world(Vector2i(tile_x, tile_y))
	player.position = world_pos
	player.velocity = Vector2.ZERO

	return "Teleported to tile (%d, %d) — world position (%d, %d)" % [tile_x, tile_y, int(world_pos.x), int(world_pos.y)]
