class_name DimensionSystem
extends System
## ECS System for managing multiple dimensions (parallel worlds)
##
## Manages multiple TileWorld instances, each representing a different dimension.
## The overworld (ID 0) is created on setup. Pocket dimensions can be created
## dynamically with IDs starting at POCKET_DIMENSION_START (100).
## Entities exist independently of dimensions and persist across dimension changes.

# =============================================================================
# Constants
# =============================================================================

const OVERWORLD: int = 0
const POCKET_DIMENSION_START: int = 100

# =============================================================================
# Signals
# =============================================================================

signal dimension_changed(old_id: int, new_id: int)
signal dimension_created(dimension_id: int)

# =============================================================================
# Properties
# =============================================================================

## Dictionary mapping dimension_id -> TileWorld
var dimensions: Dictionary = {}

## Currently active dimension ID
var active_dimension: int = OVERWORLD

## Base world seed used to derive dimension-specific seeds
var world_seed: int = 0


# =============================================================================
# Lifecycle
# =============================================================================

func _init() -> void:
	required_components = []  # Dimension system doesn't need specific components


## Initialize the dimension system with a base seed and create the overworld
func setup(seed_value: int) -> void:
	world_seed = seed_value
	create_dimension(OVERWORLD)


# =============================================================================
# Dimension Management
# =============================================================================

## Creates a new dimension with the given ID and derived seed
## Returns the existing dimension if it already exists
func create_dimension(dimension_id: int) -> TileWorld:
	if dimensions.has(dimension_id):
		return dimensions[dimension_id]

	# Each dimension uses a different seed derived from base seed
	var dimension_seed := world_seed + dimension_id * 1000
	var world := TileWorld.new(dimension_seed)
	dimensions[dimension_id] = world
	dimension_created.emit(dimension_id)
	return world


## Returns the TileWorld for the given dimension ID, or null if not found
func get_dimension(dimension_id: int) -> TileWorld:
	if not dimensions.has(dimension_id):
		return null
	return dimensions[dimension_id]


## Returns the currently active dimension's TileWorld
func get_active_dimension() -> TileWorld:
	return get_dimension(active_dimension)


## Sets the active dimension, returns true on success, false if dimension doesn't exist
func set_active_dimension(dimension_id: int) -> bool:
	if not dimensions.has(dimension_id):
		return false
	var old := active_dimension
	active_dimension = dimension_id
	dimension_changed.emit(old, dimension_id)
	return true


## Creates a new pocket dimension with an auto-assigned ID
## Returns the new dimension's ID
func create_pocket_dimension() -> int:
	# Find next available pocket dimension ID
	var next_id := POCKET_DIMENSION_START
	while dimensions.has(next_id):
		next_id += 1
	create_dimension(next_id)
	return next_id


## Returns the number of dimensions currently loaded
func get_dimension_count() -> int:
	return dimensions.size()


## Returns true if a dimension with the given ID exists
func has_dimension(dimension_id: int) -> bool:
	return dimensions.has(dimension_id)


# =============================================================================
# Block Access (per-dimension)
# =============================================================================

## Get block in specific dimension
func get_block(dimension_id: int, x: int, y: int) -> int:
	var world := get_dimension(dimension_id)
	if world:
		return world.get_block(x, y)
	return BlockData.BlockType.AIR


## Set block in specific dimension
func set_block(dimension_id: int, x: int, y: int, block_type: int) -> void:
	var world := get_dimension(dimension_id)
	if world:
		world.set_block(x, y, block_type)
