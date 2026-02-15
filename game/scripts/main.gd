class_name Main
extends Node2D
## Main game scene
##
## Wires together world, player, controllers, and UI.

var tile_world: TileWorld
var inventory: Inventory

@onready var world_renderer: WorldRenderer = $WorldRenderer
@onready var player: PlayerController = $Player
@onready var hotbar_ui: HotbarUI = $CanvasLayer/HotbarUI
@onready var inventory_ui: InventoryUI = $CanvasLayer/InventoryUI
@onready var miner_inventory_ui: InventoryUI = $CanvasLayer/MinerInventoryUI
@onready var input_manager: InputManager = $InputManager
@onready var mining_controller: MiningController = $MiningController
@onready var placement_controller: PlacementController = $PlacementController
@onready var bgparallax_controller: BGParallax = $BGParallax

const WORLD_SEED = 1
const INITIAL_RENDER_SIZE = 64
const PLAYER_SPAWN_X = 0


func _ready() -> void:
	# Create core systems
	tile_world = TileWorld.new(WORLD_SEED)
	inventory = Inventory.new()
	# Add starting items
	inventory.add_item(ItemData.ItemType.MINER, 1)

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

	# Spawn player above terrain
	_spawn_player_above_terrain()

	# Setup background parallax (after spawn so camera position is set)
	bgparallax_controller.setup(player.get_node("Camera2D"))

	# # Debug logging
	# var cam = player.get_node("Camera2D") as Camera2D
	# var vp = get_viewport().get_visible_rect().size
	# print("[Main] player.position=%s  tile=%s" % [player.position, WorldUtils.world_to_tile(player.position)])
	# print("[Main] camera.zoom=%s  viewport=%s  visible_world=%s" % [cam.zoom, vp, vp / cam.zoom])
	# print("[Main] surface_y=%d  surface_world_y=%d" % [_find_surface_y(PLAYER_SPAWN_X), -_find_surface_y(PLAYER_SPAWN_X) * WorldUtils.TILE_SIZE])


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
