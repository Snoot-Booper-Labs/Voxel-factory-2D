## Spawn command — spawn an entity at a position
class_name SpawnCommand
extends BaseCommand


func get_name() -> String:
	return "spawn"


func get_description() -> String:
	return "Spawn an entity at a position (default: player position)"


func get_usage() -> String:
	return "spawn <entity_type> [x] [y]"


func execute(args: Array, context: Dictionary) -> String:
	if args.size() < 1:
		return "Usage: %s\nAvailable entities: miner" % get_usage()

	var entity_type: String = (args[0] as String).to_lower()
	var player: PlayerController = context.get("player")
	var world: TileWorld = context.get("world")
	var scene_tree: SceneTree = context.get("scene_tree")
	var entity_parent: Node = context.get("entity_parent")

	if player == null:
		return "Error: Player not available."
	if world == null:
		return "Error: World not available."

	# Determine spawn position
	var spawn_pos: Vector2 = player.global_position
	if args.size() >= 3:
		if not (args[1] as String).is_valid_int() or not (args[2] as String).is_valid_int():
			return "Error: Coordinates must be integers."
		var tile_x := int(args[1])
		var tile_y := int(args[2])
		spawn_pos = WorldUtils.tile_to_world(Vector2i(tile_x, tile_y))

	match entity_type:
		"miner":
			return _spawn_miner(spawn_pos, world, entity_parent)
		_:
			return "Unknown entity type: '%s'. Available entities: miner" % entity_type


func _spawn_miner(pos: Vector2, world: TileWorld, parent: Node) -> String:
	if parent == null:
		return "Error: Cannot spawn entity — no parent node available."

	var miner_scene := load("res://scenes/entities/miner.tscn")
	if miner_scene == null:
		return "Error: Could not load miner scene."

	var miner: Miner = miner_scene.instantiate()
	parent.add_child(miner)
	miner.setup(world, pos, Vector2i.RIGHT)

	var tile_pos := WorldUtils.world_to_tile(pos)
	return "Spawned miner at tile (%d, %d)" % [tile_pos.x, tile_pos.y]
