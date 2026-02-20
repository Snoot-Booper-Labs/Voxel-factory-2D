## Miner Entity - A programmable machine that can mine blocks
## Has Inventory and Program components for storing items and executing mining programs
##
## Visual structure (composited sprite):
##   Body  — Sprite2D (48×16, static chassis/treads)
##   Head  — AnimatedSprite2D (16×16 frames, animated by state)
class_name Miner
extends Entity

enum State {IDLE, MOVING, MINING}

## Number of tiles the miner body occupies horizontally
const BODY_TILES: int = 3
## Frame size for the head sprite sheet
const HEAD_FRAME_SIZE: int = 16
## Number of frames per animation in the head sprite sheet
const HEAD_FRAMES_PER_ANIM: int = 4

@export var data: MinerData

var direction: Vector2i = Vector2i.RIGHT
var tile_world: TileWorld
var belt_system: BeltSystem
## When true, the miner places a conveyor belt on each tile it vacates.
## Belts face opposite to the miner's direction so items flow back.
var leaves_belt: bool = false
var is_paused: bool = false
var _state: State = State.IDLE
var _target_pos: Vector2
var _mine_progress: float = 0.0
var _current_mining_block_pos: Vector2i
## Tile the miner currently occupies (updated on arrival, used to place belt on departure)
var _current_tile: Vector2i
## Reference to the Head AnimatedSprite2D (set in _setup_sprite)
var _head: AnimatedSprite2D
## Tracks current animation to avoid redundant play() calls
var _current_anim: String = ""

func _ready() -> void:
	add_to_group("miners")
	_setup_sprite()


func _setup_sprite() -> void:
	## Load miner body texture at runtime for headless safety
	var body := get_node_or_null("Body") as Sprite2D
	if body:
		var body_tex: Texture2D = SpriteDB.get_entity_sprite("miner_body")
		if body_tex:
			body.texture = body_tex

	## Build SpriteFrames for the head from the miner_head sprite sheet
	_head = get_node_or_null("Head") as AnimatedSprite2D
	if _head == null:
		return

	var head_tex: Texture2D = SpriteDB.get_entity_sprite("miner_head")
	if head_tex == null:
		return
	_play_animation("default")
	# var sprite_frames := SpriteFrames.new()
	# # Remove the default animation if it exists
	# if sprite_frames.has_animation("default"):
	# 	sprite_frames.remove_animation("default")

	# # idle animation — frames 0-3 (x = 0, 16, 32, 48)
	# sprite_frames.add_animation("idle")
	# sprite_frames.set_animation_loop("idle", true)
	# sprite_frames.set_animation_speed("idle", 4.0)
	# for i in range(HEAD_FRAMES_PER_ANIM):
	# 	var atlas := AtlasTexture.new()
	# 	atlas.atlas = head_tex
	# 	atlas.region = Rect2(i * HEAD_FRAME_SIZE, 0, HEAD_FRAME_SIZE, HEAD_FRAME_SIZE)
	# 	sprite_frames.add_frame("idle", atlas)

	# # mining animation — frames 4-7 (x = 64, 80, 96, 112)
	# sprite_frames.add_animation("mining")
	# sprite_frames.set_animation_loop("mining", true)
	# sprite_frames.set_animation_speed("mining", 8.0)
	# for i in range(HEAD_FRAMES_PER_ANIM):
	# 	var atlas := AtlasTexture.new()
	# 	atlas.atlas = head_tex
	# 	atlas.region = Rect2((HEAD_FRAMES_PER_ANIM + i) * HEAD_FRAME_SIZE, 0, HEAD_FRAME_SIZE, HEAD_FRAME_SIZE)
	# 	sprite_frames.add_frame("mining", atlas)

	# _head.sprite_frames = sprite_frames
	# _play_animation("idle")


## Play an animation on the head, avoiding redundant calls.
func _play_animation(anim_name: String) -> void:
	if _head == null or _head.sprite_frames == null:
		return

	var target_anim := anim_name
	if not _head.sprite_frames.has_animation(target_anim):
		if _head.sprite_frames.has_animation("default"):
			target_anim = "default"
		else:
			return

	if _current_anim != target_anim:
		_current_anim = target_anim
		_head.play(target_anim)


const MINER_INVENTORY_SIZE: int = 18

func _init() -> void:
	# Add required components — miner has 18 inventory slots (2 rows of 9)
	add_component(Inventory.new(MINER_INVENTORY_SIZE))
	# Program component kept for future use, but not processed in this simple version
	add_component(Program.new())


func setup(world: TileWorld, start_pos: Vector2, start_dir: Vector2i, p_belt_system: BeltSystem = null) -> void:
	tile_world = world
	belt_system = p_belt_system
	position = start_pos
	direction = start_dir
	_target_pos = position
	_current_tile = WorldUtils.world_to_tile(position)
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

	if is_paused:
		_play_animation("idle")
		return

	match _state:
		State.MOVING:
			_play_animation("idle")
			_process_moving(delta)
		State.MINING:
			_play_animation("mining")
			_process_mining(delta)
		State.IDLE:
			_play_animation("idle")


func _process_moving(delta: float) -> void:
	# Check if we are close to the target center
	if position.distance_to(_target_pos) < 1.0:
		# Snap to target
		position = _target_pos

		# Determine next tile
		var tile_pos = WorldUtils.world_to_tile(position)

		# If we arrived at a new tile, place a belt on the tile we just left
		if tile_pos != _current_tile and leaves_belt:
			_place_belt_behind(_current_tile)
		_current_tile = tile_pos

		var mine_target = tile_pos + (direction * BODY_TILES)

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
	# Get drops for this block type
	var drops = BlockData.get_block_drops(block_type)
	if drops.item != "" and drops.count > 0:
		var item_type = ItemData.get_type_from_name(drops.item)
		if item_type != ItemData.ItemType.NONE:
			var remaining: int = drops.count

			# Try belt first: push items onto the belt behind the miner
			if belt_system:
				remaining = _push_items_to_belt(item_type, remaining)

			# Remaining items go to miner inventory
			if remaining > 0:
				remaining = get_inventory().add_item(item_type, remaining)

			# If inventory is also full, drop as world entity
			if remaining > 0:
				_drop_item_entity(item_type, remaining)

	# Remove block
	tile_world.set_block(_current_mining_block_pos.x, _current_mining_block_pos.y, BlockData.BlockType.AIR)

	# Resume moving
	_state = State.MOVING


## Push items onto the conveyor belt behind the miner.
## Returns the number of items that could NOT be placed (belt full or missing).
func _push_items_to_belt(item_type: int, item_count: int) -> int:
	var miner_tile := WorldUtils.world_to_tile(position)
	var behind_tile := miner_tile - direction
	var belt := belt_system.get_belt_at(behind_tile)
	if belt == null:
		return item_count

	var remaining := item_count
	for i in range(item_count):
		if belt.is_full():
			break
		belt.add_item(item_type)
		remaining -= 1
	return remaining


## Place a conveyor belt on the given tile, facing opposite to the miner's direction.
## The belt is added to the scene tree and registered with the belt system.
func _place_belt_behind(tile_pos: Vector2i) -> void:
	if belt_system == null or not is_inside_tree():
		return

	# Don't place on top of an existing belt
	if belt_system.get_belt_at(tile_pos) != null:
		return

	# Don't place on solid blocks
	if tile_world and tile_world.is_solid(tile_pos.x, tile_pos.y):
		return

	# Belt direction is opposite to miner direction (items flow back)
	var belt_dir: BeltNode.Direction
	match direction:
		Vector2i.RIGHT:
			belt_dir = BeltNode.Direction.LEFT
		Vector2i.LEFT:
			belt_dir = BeltNode.Direction.RIGHT
		_:
			belt_dir = BeltNode.Direction.LEFT

	var conveyor_scene = load("res://scenes/entities/conveyor.tscn")
	if conveyor_scene == null:
		return

	var conveyor: Conveyor = conveyor_scene.instantiate()
	get_parent().add_child(conveyor)
	conveyor.setup(tile_pos, belt_dir)
	belt_system.register_belt(conveyor.get_belt())


## Actually spawn a physical ItemEntity in the world
func _drop_item_entity(item_type: int, item_count: int) -> void:
	if not is_inside_tree():
		return
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
		"leaves_belt": leaves_belt,
		"is_paused": is_paused,
		"inventory": get_inventory().serialize(),
	}


## Restore miner state from a dictionary.
## Call after setup() so position/direction are overwritten with saved values.
func deserialize(data: Dictionary) -> void:
	var state_val: int = int(data.get("state", State.IDLE))
	_state = state_val as State
	leaves_belt = data.get("leaves_belt", false)
	is_paused = data.get("is_paused", false)

	var inv_data: Array = data.get("inventory", [])
	if inv_data.size() > 0:
		get_inventory().deserialize(inv_data)
