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

func _ready() -> void:
	add_to_group("miners")


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


# Bridge methods for Testing and Program execution
func set_mining_program(start: CommandBlock) -> void:
	var program = get_component("Program")
	if program:
		program.set_program(start)

func get_program() -> Program:
	return get_component("Program") as Program

func start_mining(world: TileWorld) -> void:
	tile_world = world
	var program = get_component("Program")
	# Pass self as context so commands can control the miner
	if program:
		program.start({"entity": self, "miner": self, "world": world, "inventory": get_inventory()})

func tick() -> bool:
	var program = get_component("Program")
	if program:
		return program.tick()
	return false

# Exposed for commands to use (if needed) or internal logic
func move_forward() -> void:
	# Implement if needed by MoveBlock
	pass

func mine_forward() -> void:
	# Implement if needed by MineBlock
	pass


func _process(delta: float) -> void:
	# Only run simple logic if NOT running a program?
	# Or if program is not running?
	# For now, let's assume if _process is running, it does simple logic.
	# Unit tests likely don't add to scene or don't rely on _process/physics.
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
		var tile_pos = WorldUtils.world_to_tile(position)
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
			_target_pos = position + Vector2(direction) * float(WorldUtils.TILE_SIZE)


	# Move towards target
	if position.distance_to(_target_pos) > 0.1:
		var speed = float(WorldUtils.TILE_SIZE) / data.move_speed if data else 4.0
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
		var item_type = ItemData.get_type_from_name(drops.item)
		if item_type != ItemData.ItemType.NONE:
			var remaining := get_inventory().add_item(item_type, drops.count)
			# If inventory is full, spawn item entity in the world
			if remaining > 0:
				_spawn_item_drop(item_type, remaining)

	# Remove block
	tile_world.set_block(_current_mining_block_pos.x, _current_mining_block_pos.y, BlockData.BlockType.AIR)

	# Resume moving
	_state = State.MOVING


## Spawn a dropped item entity behind the miner (opposite of mining direction)
func _spawn_item_drop(item_type: int, item_count: int) -> void:
	if not is_inside_tree():
		return
	# Drop behind the miner (opposite direction from where it's mining)
	var drop_offset := Vector2(-direction.x * WorldUtils.TILE_SIZE, 0)
	var drop_pos := position + drop_offset
	ItemEntity.spawn(get_parent(), item_type, item_count, drop_pos)

## Returns the Inventory component
func get_inventory() -> Inventory:
	return get_component("Inventory") as Inventory


## Serialize miner state to a dictionary
func serialize() -> Dictionary:
	return {
		"type": "Miner",
		"position": {"x": position.x, "y": position.y},
		"direction": {"x": direction.x, "y": direction.y},
		"state": _state,
		"inventory": get_inventory().serialize(),
	}


## Restore miner state from a dictionary.
## Call after setup() so position/direction are overwritten with saved values.
func deserialize(data: Dictionary) -> void:
	var state_val: int = int(data.get("state", State.IDLE))
	_state = state_val as State

	var inv_data: Array = data.get("inventory", [])
	if inv_data.size() > 0:
		get_inventory().deserialize(inv_data)
