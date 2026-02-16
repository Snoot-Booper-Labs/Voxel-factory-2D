class_name Main
extends Node2D
## Main game scene
##
## Wires together world, player, controllers, and UI.
## Manages save/load lifecycle via SaveManager.

var tile_world: TileWorld
var inventory: Inventory
var save_manager: SaveManager

@onready var world_renderer: WorldRenderer = $WorldRenderer
@onready var player: PlayerController = $Player
@onready var hotbar_ui: HotbarUI = $CanvasLayer/HotbarUI
@onready var inventory_ui: InventoryUI = $CanvasLayer/InventoryUI
@onready var miner_inventory_ui: InventoryUI = $CanvasLayer/MinerInventoryUI
@onready var input_manager: InputManager = $InputManager
@onready var mining_controller: MiningController = $MiningController
@onready var placement_controller: PlacementController = $PlacementController
@onready var bgparallax_controller: BGParallax = $BGParallax
@onready var pause_menu: PauseMenuController = $CanvasLayer/PauseMenu
@onready var debug_console: DebugConsoleController = $CanvasLayer/DebugConsole

var command_registry: CommandRegistry

const WORLD_SEED = 1
const INITIAL_RENDER_SIZE = 64
const PLAYER_SPAWN_X = 0


func _ready() -> void:
	# Create save manager
	save_manager = SaveManager.new()
	save_manager.name = "SaveManager"
	add_child(save_manager)

	# Try loading a save, otherwise start fresh
	if save_manager.has_save():
		_load_game()
	else:
		_new_game()

	# Setup world renderer
	world_renderer.set_tile_world(tile_world)
	world_renderer.set_tracking_target(player)

	# Setup controllers
	mining_controller.setup(tile_world, inventory)
	placement_controller.setup(tile_world, inventory)

	# Setup UI
	hotbar_ui.setup(inventory)
	inventory_ui.setup(inventory)

	# Setup input manager
	input_manager.setup(player, mining_controller, placement_controller, hotbar_ui, inventory_ui, miner_inventory_ui)
	input_manager.save_requested.connect(_on_save_requested)
	input_manager.load_requested.connect(_on_load_requested)

	# Setup pause menu
	input_manager.set_pause_menu(pause_menu)
	pause_menu.save_requested.connect(_on_pause_save_requested)
	pause_menu.load_requested.connect(_on_pause_load_requested)
	pause_menu.set_camera(player.get_node("Camera2D"))

	# Setup debug console
	_setup_debug_console()
	input_manager.set_debug_console(debug_console)

	# Setup background parallax (after spawn so camera position is set)
	bgparallax_controller.setup(player.get_node("Camera2D"))

	# Configure save manager references and start auto-save
	_update_save_manager_refs()
	save_manager.set_auto_save(true)


## Start a fresh game with default state
func _new_game() -> void:
	tile_world = TileWorld.new(WORLD_SEED)
	inventory = Inventory.new()
	inventory.add_item(ItemData.ItemType.MINER, 1)
	_spawn_player_above_terrain()


## Load game state from save file
func _load_game() -> void:
	var data := save_manager.load_game()
	if data.is_empty():
		# Fallback to new game if load fails
		_new_game()
		return

	# Restore world
	var world_data: Dictionary = data.get("world", {})
	tile_world = TileWorld.deserialize(world_data)

	# Restore player
	var player_data: Dictionary = data.get("player", {})
	if player_data.has("position"):
		player.deserialize(player_data)
	else:
		_spawn_player_above_terrain()

	# Restore player inventory
	inventory = Inventory.new()
	var inv_slots: Array = player_data.get("inventory", [])
	inventory.deserialize(inv_slots)

	# Restore entities (deferred to ensure scene tree is ready)
	var entities_data: Array = data.get("entities", [])
	if entities_data.size() > 0:
		EntitySaver.deserialize_all(entities_data, self, tile_world)


func _on_save_requested() -> void:
	_update_save_manager_refs()
	if save_manager.save_game():
		print("[Main] Game saved successfully")
	else:
		print("[Main] Failed to save game")


func _on_pause_save_requested() -> void:
	_update_save_manager_refs()
	var success := save_manager.save_game()
	pause_menu.show_save_feedback(success)
	if success:
		print("[Main] Game saved via pause menu")
	else:
		print("[Main] Failed to save game via pause menu")


func _on_pause_load_requested() -> void:
	_on_load_requested()


func _on_load_requested() -> void:
	# Remove existing miners and item entities before loading
	_remove_all_miners()
	_remove_all_item_entities()

	var data := save_manager.load_game()
	if data.is_empty():
		print("[Main] No save file to load")
		return

	# Restore world
	var world_data: Dictionary = data.get("world", {})
	tile_world = TileWorld.deserialize(world_data)

	# Reconnect world to renderer and controllers
	world_renderer.set_tile_world(tile_world)
	mining_controller.setup(tile_world, inventory)
	placement_controller.setup(tile_world, inventory)

	# Restore player
	var player_data: Dictionary = data.get("player", {})
	if player_data.has("position"):
		player.deserialize(player_data)

	# Restore player inventory
	var inv_slots: Array = player_data.get("inventory", [])
	inventory.deserialize(inv_slots)

	# Restore entities
	var entities_data: Array = data.get("entities", [])
	if entities_data.size() > 0:
		EntitySaver.deserialize_all(entities_data, self, tile_world)

	_update_save_manager_refs()
	_update_debug_context()
	print("[Main] Game loaded successfully")


func _update_save_manager_refs() -> void:
	save_manager.tile_world = tile_world
	save_manager.player_inventory = inventory
	save_manager.player_node = player
	save_manager.scene_tree = get_tree()
	save_manager.entity_parent = self


## Setup the debug console with command registry and built-in commands
func _setup_debug_console() -> void:
	command_registry = CommandRegistry.new()

	# Register all built-in commands
	command_registry.register(HelpCommand.new())
	command_registry.register(ClearCommand.new())
	command_registry.register(GiveCommand.new())
	command_registry.register(FlyCommand.new())
	command_registry.register(NoclipCommand.new())
	command_registry.register(TeleportCommand.new())
	command_registry.register(SpawnCommand.new())
	command_registry.register(SeedCommand.new())
	command_registry.register(DimensionCommand.new())
	command_registry.register(GodCommand.new())
	command_registry.register(SetTimeCommand.new())

	# Setup console with registry and context
	debug_console.setup(command_registry, _build_debug_context())


## Build the context dictionary passed to every command execution
func _build_debug_context() -> Dictionary:
	return {
		"player": player,
		"inventory": inventory,
		"world": tile_world,
		"scene_tree": get_tree(),
		"entity_parent": self,
		"registry": command_registry,
		"console": debug_console,
	}


## Update the debug console context after game state changes (e.g. load)
func _update_debug_context() -> void:
	if debug_console:
		debug_console.set_context(_build_debug_context())


func _remove_all_miners() -> void:
	for miner in get_tree().get_nodes_in_group("miners"):
		if is_instance_valid(miner):
			miner.queue_free()


func _remove_all_item_entities() -> void:
	for item in get_tree().get_nodes_in_group("item_entities"):
		if is_instance_valid(item):
			item.queue_free()


func _spawn_player_above_terrain() -> void:
	var surface_y = _find_surface_y(PLAYER_SPAWN_X)
	# Negate Y because Godot screen Y is down, but world Y is up (altitude)
	# surface_y + 2 places player 2 tiles above the surface in world coords
	# Negating converts to screen coords where negative Y is up
	player.position = Vector2(PLAYER_SPAWN_X * WorldUtils.TILE_SIZE, - (surface_y + 2) * WorldUtils.TILE_SIZE)


func _find_surface_y(x: int) -> int:
	for y in range(100, -100, -1):
		if tile_world.is_solid(x, y):
			return y + 1
	return 0


func _physics_process(_delta: float) -> void:
	# Update controller positions
	mining_controller.set_player_position(player.global_position)
	placement_controller.set_player_position(player.global_position)
