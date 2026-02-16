class_name EntitySaver
extends RefCounted
## Collects and dispatches entity serialization/deserialization
##
## Iterates entity groups in the scene tree and delegates to each
## entity's own serialize()/deserialize() methods.
## Handles scene instantiation on load.


## Serialize all entities in the scene tree
static func serialize_all(tree: SceneTree) -> Array:
	var entities: Array = []
	for miner in tree.get_nodes_in_group("miners"):
		if miner is Miner and is_instance_valid(miner):
			entities.append(miner.serialize())
	# Serialize conveyors
	for conveyor in tree.get_nodes_in_group("conveyors"):
		if conveyor is Conveyor and is_instance_valid(conveyor):
			entities.append(conveyor.serialize())
	# Serialize item entities (only ground items, not belt items)
	for item in tree.get_nodes_in_group("item_entities"):
		if item is ItemEntity and is_instance_valid(item) and not item.on_belt:
			entities.append(item.serialize())
	return entities


## Deserialize all entities from saved data and add them to the scene.
## Returns the array of instantiated entities.
## belt_system is optional; when provided, loaded conveyors are registered.
static func deserialize_all(entities_data: Array, parent: Node, tile_world: TileWorld, belt_system: BeltSystem = null) -> Array:
	var result: Array = []
	for entity_data in entities_data:
		var type_name: String = entity_data.get("type", "")
		match type_name:
			"Miner":
				var miner := _instantiate_miner(entity_data, parent, tile_world, belt_system)
				if miner:
					result.append(miner)
			"Conveyor":
				var conveyor := _instantiate_conveyor(entity_data, parent, belt_system)
				if conveyor:
					result.append(conveyor)
			"ItemEntity":
				var item := _instantiate_item_entity(entity_data, parent)
				if item:
					result.append(item)

	# After all conveyors are loaded, rebuild connections
	if belt_system:
		belt_system.rebuild_connections()

	return result


## Instantiate a miner from saved data, add to scene, and restore state.
static func _instantiate_miner(data: Dictionary, parent: Node, tile_world: TileWorld, belt_system: BeltSystem = null) -> Miner:
	var miner_scene := load("res://scenes/entities/miner.tscn")
	if miner_scene == null:
		return null

	var miner: Miner = miner_scene.instantiate()
	parent.add_child(miner)

	# Extract position and direction for setup()
	var pos_data: Dictionary = data.get("position", {})
	var dir_data: Dictionary = data.get("direction", {})
	var spawn_pos := Vector2(
		float(pos_data.get("x", 0.0)),
		float(pos_data.get("y", 0.0))
	)
	var direction := Vector2i(
		int(dir_data.get("x", 1)),
		int(dir_data.get("y", 0))
	)

	miner.setup(tile_world, spawn_pos, direction, belt_system)
	miner.deserialize(data)

	return miner


## Instantiate a conveyor from saved data, add to scene, register with belt system.
static func _instantiate_conveyor(data: Dictionary, parent: Node, belt_system: BeltSystem = null) -> Conveyor:
	var conveyor_scene := load("res://scenes/entities/conveyor.tscn")
	if conveyor_scene == null:
		return null

	var conveyor: Conveyor = conveyor_scene.instantiate()
	parent.add_child(conveyor)
	conveyor.deserialize(data)

	if belt_system:
		belt_system.register_belt(conveyor.get_belt())

	return conveyor


## Instantiate an item entity from saved data, add to scene, and restore state.
static func _instantiate_item_entity(data: Dictionary, parent: Node) -> ItemEntity:
	var item_scene := load("res://scenes/entities/item_entity.tscn")
	if item_scene == null:
		return null

	var item: ItemEntity = item_scene.instantiate()
	parent.add_child(item)
	item.deserialize(data)

	return item
