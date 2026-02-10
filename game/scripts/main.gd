class_name Main
extends Node2D
## Main game scene script
##
## Creates the TileWorld and connects it to WorldRenderer for visualization.
## Renders an initial visible region around the origin.

var tile_world: TileWorld
@onready var world_renderer: WorldRenderer = $WorldRenderer

const WORLD_SEED = 12345
const INITIAL_RENDER_SIZE = 64  # Render 64x64 area initially


func _ready() -> void:
	tile_world = TileWorld.new(WORLD_SEED)
	world_renderer.set_tile_world(tile_world)

	# Render initial area centered around origin
	var half = INITIAL_RENDER_SIZE / 2
	world_renderer.render_region(
		Vector2i(-half, -half),
		Vector2i(half, half)
	)
