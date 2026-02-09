class_name WorldSystem
extends System
## ECS System for managing the tile-based world
##
## Wraps TileWorld to provide world access to the ECS architecture.
## Does not process entities - instead provides world data access methods.

var tile_world: TileWorld = null


func _init() -> void:
	required_components = []  # World system doesn't need specific components


func setup(seed_value: int) -> void:
	tile_world = TileWorld.new(seed_value)


func get_block(x: int, y: int) -> int:
	return tile_world.get_block(x, y)


func set_block(x: int, y: int, block_type: int) -> void:
	tile_world.set_block(x, y, block_type)


func is_solid(x: int, y: int) -> bool:
	return tile_world.is_solid(x, y)
