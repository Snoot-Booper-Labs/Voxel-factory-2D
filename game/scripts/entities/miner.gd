## Miner Entity - A programmable machine that can mine blocks
## Has Inventory and Program components for storing items and executing mining programs
class_name Miner
extends Entity

enum State {IDLE, MOVING, MINING}

@export var data: MinerData

var direction: Vector2i = Vector2i.RIGHT
var tile_world: TileWorld
var _state: State = State.IDLE
var _target_pos: Vector2
var _mine_progress: float = 0.0
var _current_mining_block_pos: Vector2i

func _init() -> void:
	# Add required components
	add_component(Inventory.new())
	# Program component kept for future use, but not processed in this simple version
	add_component(Program.new())


func setup(world: TileWorld, start_pos: Vector2, start_dir: Vector2i) -> void:
	tile_world = world
	position = start_pos
	direction = start_dir
	_target_pos = position
	scale.x = 1.0 if direction == Vector2i.RIGHT else -1.0
	rotation = 0.0
	_state = State.MOVING


func _process(delta: float) -> void:
	if tile_world == null:
		return

	match _state:
		State.MOVING:
			_process_moving(delta)
		State.MINING:
			_process_mining(delta)


func _process_moving(delta: float) -> void:
	# Check if we are close to the target center
	if position.distance_to(_target_pos) < 1.0:
		# Snap to target
		position = _target_pos

		# Determine next tile
		var tile_pos = _world_to_tile(position)
		var next_tile_pos = tile_pos + direction
		# Visuals are 2 tiles wide, so the "front" is actually position + direction * 2?
		# Actually, if the miner is 2 blocks wide (0,0 and 1,0 relative), and moves right:
		# Front is at (1,0) local. Next block to mine is (2,0) local.
		# If moving left, Front is at (-1,0)?
		# Let's assume origin (0,0) is rear, (1,0) is front.
		# So mining check should be at pos + direction * 2?
		# Or if it occupies (0,0) and (1,0), it mines (2,0).

		# Let's simplify: Miner occupies current tile and the one behind it?
		# Scene: Body (0,0), Head (16,0). Total width 32.
		# Center/Output position is (0,0). Head is forward.
		# So if at tile (x,y), Head is at (x+1, y). Block to mine is at (x+2, y).

		var mine_target = tile_pos + (direction * 2)
		if direction == Vector2i.LEFT:
			# If facing left, and origin is rear (rightmost), head is left (-16, 0)?
			# Visuals rotation handles this. Origin is pivotal.
			# If rotated 180 (PI), (16,0) becomes (-16, 0).
			# So head is at (-1,0) relative to origin. Mine target is (-2,0) relative?
			pass

		# Check for block at mine_target
		if tile_world.is_solid(mine_target.x, mine_target.y):
			# Found wall, start mining
			_start_mining(mine_target)
		else:
			# Free to move
			_target_pos = position + Vector2(direction) * 16.0


	# Move towards target
	if position.distance_to(_target_pos) > 0.1:
		var speed = 16.0 / data.move_speed if data else 4.0
		position = position.move_toward(_target_pos, speed * delta)


func _start_mining(target_tile: Vector2i) -> void:
	_state = State.MINING
	_current_mining_block_pos = target_tile
	_mine_progress = 0.0


func _process_mining(delta: float) -> void:
	var block_type = tile_world.get_block(_current_mining_block_pos.x, _current_mining_block_pos.y)
	if block_type == BlockData.BlockType.AIR:
		# Block disappeared (maybe mined by something else), resume moving
		_state = State.MOVING
		return

	var hardness = BlockData.get_block_hardness(block_type)
	if hardness < 0:
		# Unbreakable
		return

	var power = data.mining_power if data else 1.0
	_mine_progress += power * delta

	if _mine_progress >= hardness:
		_complete_mining(block_type)


func _complete_mining(block_type: int) -> void:
	# Add to inventory
	var drops = BlockData.get_block_drops(block_type)
	if drops.item != "" and drops.count > 0:
		# Find ItemType ID from name (simple lookup or data method needed)
		# For now, simplistic mapping or skipping string lookup if ItemData doesn't support it easily
		# Actually ItemData needs ID.
		# BlockData stores string names "dirt", "cobblestone".
		# ItemData stores "Dirt", "Cobblestone".
		# I need a helper to get ItemID from name or directly from BlockType.
		# Temporary: specific drop logic or use BlockType directly if usually 1:1?
		# ItemData.get_item_from_block(block_type) would be useful.
		pass

	# Remove block
	tile_world.set_block(_current_mining_block_pos.x, _current_mining_block_pos.y, BlockData.BlockType.AIR)

	# Resume moving
	_state = State.MOVING


# Helper to convert world position to tile coordinates
func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / 16.0)),
		- int(floor(world_pos.y / 16.0))
	)

## Returns the Inventory component
func get_inventory() -> Inventory:
	return get_component("Inventory") as Inventory
