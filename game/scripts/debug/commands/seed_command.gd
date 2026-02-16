## Seed command — display the current world seed
class_name SeedCommand
extends BaseCommand


func get_name() -> String:
	return "seed"


func get_description() -> String:
	return "Display the current world seed"


func get_usage() -> String:
	return "seed"


func execute(_args: Array, context: Dictionary) -> String:
	var world: TileWorld = context.get("world")
	if world == null:
		return "Error: World not available."

	return "World seed: [color=yellow]%d[/color]" % world.world_seed
