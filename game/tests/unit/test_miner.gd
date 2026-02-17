extends GutTest
## Unit tests for Miner entity, Program component, and MineBlock command

# =============================================================================
# Program Component Tests
# =============================================================================

func test_program_exists():
	# Program class should exist and be instantiable
	var program = Program.new()
	assert_not_null(program, "Program should be instantiable")


func test_program_extends_component():
	var program = Program.new()
	assert_true(program is Component, "Program should extend Component")


func test_program_get_type_name():
	var program = Program.new()
	assert_eq(program.get_type_name(), "Program", "Program type name should be 'Program'")


func test_program_has_executor():
	var program = Program.new()
	assert_not_null(program.executor, "Program should have executor")
	assert_true(program.executor is GraphExecutor, "Program executor should be GraphExecutor")


func test_program_start_block_starts_null():
	var program = Program.new()
	assert_null(program.start_block, "Program start_block should start as null")


func test_program_set_program_stores_start_block():
	var program = Program.new()
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	program.set_program(block)
	assert_eq(program.start_block, block, "set_program should store start block")


func test_program_set_program_sets_executor_program():
	var program = Program.new()
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	program.set_program(block)
	assert_eq(program.executor.start_block, block, "set_program should set executor's start block")


func test_program_start_starts_executor():
	var program = Program.new()
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	program.set_program(block)
	program.start()
	assert_true(program.executor.is_running(), "start should start executor")


func test_program_start_with_context():
	var program = Program.new()
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	program.set_program(block)
	var context = {"test": "value"}
	program.start(context)
	assert_eq(program.executor.execution_context, context, "start should pass context to executor")


func test_program_tick_executes():
	var program = Program.new()
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)
	program.set_program(block1)
	program.start()
	var result = program.tick()
	assert_true(result, "tick should return true while running")


func test_program_is_running():
	var program = Program.new()
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	program.set_program(block)
	assert_false(program.is_running(), "is_running should return false before start")
	program.start()
	assert_true(program.is_running(), "is_running should return true after start")


# =============================================================================
# MineBlock Tests
# =============================================================================

func test_mine_block_exists():
	# MineBlock class should exist and be instantiable
	var mine = MineBlock.new()
	assert_not_null(mine, "MineBlock should be instantiable")


func test_mine_block_extends_command_block():
	var mine = MineBlock.new()
	assert_true(mine is CommandBlock, "MineBlock should extend CommandBlock")


func test_mine_block_has_mine_type():
	var mine = MineBlock.new()
	assert_eq(mine.block_type, CommandBlock.BlockType.MINE, "MineBlock should have MINE block type")


func test_mine_block_execute_returns_next_block():
	var mine = MineBlock.new()
	var end = CommandBlock.new(CommandBlock.BlockType.END)
	mine.connect_next(end)
	var context = {}
	var result = mine.execute(context)
	assert_eq(result, end, "execute should return next block")


func test_mine_block_execute_mines_block_from_world():
	var mine = MineBlock.new()
	mine.set_parameter("x", 50)
	mine.set_parameter("y", 10)

	var world = TileWorld.new(12345)
	var inventory = Inventory.new()

	# Get the block type at position
	var original_block = world.get_block(50, 10)

	var context = {
		"world": world,
		"inventory": inventory
	}

	mine.execute(context)

	# Block should be AIR after mining
	var new_block = world.get_block(50, 10)
	assert_eq(new_block, BlockData.BlockType.AIR, "Block should be AIR after mining")


func test_mine_block_execute_adds_item_to_inventory():
	var mine = MineBlock.new()
	mine.set_parameter("x", 50)
	mine.set_parameter("y", 15)  # Deeper underground should have stone

	var world = TileWorld.new(12345)
	var inventory = Inventory.new()

	# Ensure there's a minable block
	world.set_block(50, 15, BlockData.BlockType.STONE)

	var context = {
		"world": world,
		"inventory": inventory
	}

	mine.execute(context)

	# Inventory should have cobblestone (stone drops cobblestone)
	assert_true(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1), "Inventory should have cobblestone after mining stone")


func test_mine_block_execute_does_not_mine_air():
	var mine = MineBlock.new()
	mine.set_parameter("x", 50)
	mine.set_parameter("y", 0)  # Above ground is AIR

	var world = TileWorld.new(12345)
	var inventory = Inventory.new()

	# Set to AIR explicitly
	world.set_block(50, 0, BlockData.BlockType.AIR)

	var context = {
		"world": world,
		"inventory": inventory
	}

	mine.execute(context)

	# Inventory should be empty
	assert_false(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1), "Inventory should be empty after mining air")
	assert_false(inventory.has_item(ItemData.ItemType.DIRT, 1), "Inventory should be empty after mining air")


func test_mine_block_emits_signals():
	var mine = MineBlock.new()
	watch_signals(mine)
	mine.execute({})
	assert_signal_emitted(mine, "execution_started", "MineBlock should emit execution_started")
	assert_signal_emitted(mine, "execution_completed", "MineBlock should emit execution_completed")


# =============================================================================
# Miner Entity Tests
# =============================================================================

func test_miner_exists():
	# Miner class should exist and be instantiable
	var miner = Miner.new()
	assert_not_null(miner, "Miner should be instantiable")
	miner.free()


func test_miner_extends_entity():
	var miner = Miner.new()
	assert_true(miner is Entity, "Miner should extend Entity")
	miner.free()


func test_miner_has_inventory_component():
	var miner = Miner.new()
	assert_true(miner.has_component("Inventory"), "Miner should have Inventory component")
	miner.free()


func test_miner_has_program_component():
	var miner = Miner.new()
	assert_true(miner.has_component("Program"), "Miner should have Program component")
	miner.free()


func test_miner_get_inventory():
	var miner = Miner.new()
	var inventory = miner.get_inventory()
	assert_not_null(inventory, "get_inventory should return Inventory")
	assert_true(inventory is Inventory, "get_inventory should return Inventory instance")
	miner.free()


func test_miner_get_program():
	var miner = Miner.new()
	var program = miner.get_program()
	assert_not_null(program, "get_program should return Program")
	assert_true(program is Program, "get_program should return Program instance")
	miner.free()


func test_miner_set_mining_program():
	var miner = Miner.new()
	var start = CommandBlock.new(CommandBlock.BlockType.START)
	miner.set_mining_program(start)
	assert_eq(miner.get_program().start_block, start, "set_mining_program should set program")
	miner.free()


func test_miner_start_mining():
	var miner = Miner.new()
	var start = CommandBlock.new(CommandBlock.BlockType.START)
	miner.set_mining_program(start)
	var world = TileWorld.new(12345)
	miner.start_mining(world)
	assert_true(miner.get_program().is_running(), "start_mining should start program")
	miner.free()


func test_miner_tick():
	var miner = Miner.new()
	var start = CommandBlock.new(CommandBlock.BlockType.START)
	var end = CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(end)
	miner.set_mining_program(start)
	var world = TileWorld.new(12345)
	miner.start_mining(world)
	var result = miner.tick()
	assert_true(result, "tick should return true while running")
	miner.free()


# =============================================================================
# Integration Tests - Full Mining Flow
# =============================================================================

func test_miner_executes_program_and_mines():
	var miner = Miner.new()
	var world = TileWorld.new(12345)

	# Set up a known block to mine
	var test_x = 50
	var test_y = 15
	world.set_block(test_x, test_y, BlockData.BlockType.STONE)

	# Create mining program: START -> MINE -> END
	var start = CommandBlock.new(CommandBlock.BlockType.START)
	var mine = MineBlock.new()
	mine.set_parameter("x", test_x)
	mine.set_parameter("y", test_y)
	var end = CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(mine)
	mine.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(world)

	# Execute ticks
	miner.tick()  # Execute START
	miner.tick()  # Execute MINE
	miner.tick()  # Execute END (completes)

	# Verify block was mined
	assert_eq(world.get_block(test_x, test_y), BlockData.BlockType.AIR, "Block should be mined to AIR")

	# Verify inventory has item (stone drops cobblestone)
	var inventory = miner.get_inventory()
	assert_true(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1), "Inventory should have cobblestone after mining")

	miner.free()


func test_miner_mines_multiple_blocks():
	var miner = Miner.new()
	var world = TileWorld.new(12345)

	# Set up blocks to mine
	world.set_block(50, 15, BlockData.BlockType.STONE)
	world.set_block(50, 16, BlockData.BlockType.DIRT)

	# Create mining program: START -> MINE(stone) -> MINE(dirt) -> END
	var start = CommandBlock.new(CommandBlock.BlockType.START)
	var mine1 = MineBlock.new()
	mine1.set_parameter("x", 50)
	mine1.set_parameter("y", 15)
	var mine2 = MineBlock.new()
	mine2.set_parameter("x", 50)
	mine2.set_parameter("y", 16)
	var end = CommandBlock.new(CommandBlock.BlockType.END)

	start.connect_next(mine1)
	mine1.connect_next(mine2)
	mine2.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(world)

	# Execute all ticks
	while miner.tick():
		pass

	# Verify both blocks were mined
	assert_eq(world.get_block(50, 15), BlockData.BlockType.AIR, "First block should be mined")
	assert_eq(world.get_block(50, 16), BlockData.BlockType.AIR, "Second block should be mined")

	# Verify inventory has both items
	var inventory = miner.get_inventory()
	assert_true(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1), "Inventory should have cobblestone")
	assert_true(inventory.has_item(ItemData.ItemType.DIRT, 1), "Inventory should have dirt")

	miner.free()


func test_miner_program_context_includes_inventory():
	var miner = Miner.new()
	var world = TileWorld.new(12345)

	world.set_block(50, 15, BlockData.BlockType.STONE)

	var start = CommandBlock.new(CommandBlock.BlockType.START)
	var mine = MineBlock.new()
	mine.set_parameter("x", 50)
	mine.set_parameter("y", 15)
	start.connect_next(mine)

	miner.set_mining_program(start)
	miner.start_mining(world)

	# Context should include inventory
	var context = miner.get_program().executor.execution_context
	assert_eq(context.get("inventory"), miner.get_inventory(), "Context should include miner's inventory")
	assert_eq(context.get("world"), world, "Context should include world")
	assert_eq(context.get("miner"), miner, "Context should include miner reference")

	miner.free()


# =============================================================================
# Belt-Laying Property Tests
# =============================================================================

func test_miner_leaves_belt_defaults_false():
	var miner = Miner.new()
	assert_false(miner.leaves_belt, "leaves_belt should default to false")
	miner.free()


func test_miner_belt_system_defaults_null():
	var miner = Miner.new()
	assert_null(miner.belt_system, "belt_system should default to null")
	miner.free()


func test_miner_setup_stores_belt_system():
	var miner = Miner.new()
	var world = TileWorld.new(12345)
	var belt_system = BeltSystem.new()
	miner.setup(world, Vector2.ZERO, Vector2i.RIGHT, belt_system)
	assert_eq(miner.belt_system, belt_system, "setup should store belt_system")
	miner.free()
	belt_system.free()


func test_miner_setup_without_belt_system():
	var miner = Miner.new()
	var world = TileWorld.new(12345)
	miner.setup(world, Vector2.ZERO, Vector2i.RIGHT)
	assert_null(miner.belt_system, "setup without belt_system should leave it null")
	miner.free()


func test_miner_setup_sets_current_tile():
	var miner = Miner.new()
	var world = TileWorld.new(12345)
	# Position (48, -32) -> tile (3, 2)
	miner.setup(world, Vector2(48, -32), Vector2i.RIGHT)
	assert_eq(miner._current_tile, Vector2i(3, 2), "setup should set _current_tile from position")
	miner.free()


func test_miner_setup_direction_right():
	var miner = Miner.new()
	var world = TileWorld.new(12345)
	miner.setup(world, Vector2.ZERO, Vector2i.RIGHT)
	assert_eq(miner.direction, Vector2i.RIGHT, "setup should set direction to RIGHT")
	assert_eq(miner.scale.x, 1.0, "RIGHT direction should have scale.x = 1.0")
	miner.free()


func test_miner_setup_direction_left():
	var miner = Miner.new()
	var world = TileWorld.new(12345)
	miner.setup(world, Vector2.ZERO, Vector2i.LEFT)
	assert_eq(miner.direction, Vector2i.LEFT, "setup should set direction to LEFT")
	assert_eq(miner.scale.x, -1.0, "LEFT direction should have scale.x = -1.0")
	miner.free()


# =============================================================================
# Serialize / Deserialize with leaves_belt
# =============================================================================

func test_miner_serialize_includes_leaves_belt():
	var miner = Miner.new()
	miner.leaves_belt = true
	var data = miner.serialize()
	assert_true(data.has("leaves_belt"), "serialize should include leaves_belt")
	assert_true(data["leaves_belt"], "serialize should store leaves_belt value")
	miner.free()


func test_miner_serialize_leaves_belt_false():
	var miner = Miner.new()
	var data = miner.serialize()
	assert_false(data["leaves_belt"], "serialize should store false when leaves_belt is false")
	miner.free()


func test_miner_deserialize_restores_leaves_belt_true():
	var miner = Miner.new()
	miner.deserialize({"leaves_belt": true})
	assert_true(miner.leaves_belt, "deserialize should restore leaves_belt = true")
	miner.free()


func test_miner_deserialize_restores_leaves_belt_false():
	var miner = Miner.new()
	miner.leaves_belt = true  # Set to true first
	miner.deserialize({"leaves_belt": false})
	assert_false(miner.leaves_belt, "deserialize should restore leaves_belt = false")
	miner.free()


func test_miner_deserialize_defaults_leaves_belt_false():
	var miner = Miner.new()
	miner.leaves_belt = true  # Set to true first
	miner.deserialize({})  # No leaves_belt key
	assert_false(miner.leaves_belt, "deserialize should default leaves_belt to false")
	miner.free()


func test_miner_serialize_deserialize_roundtrip():
	var miner = Miner.new()
	miner.position = Vector2(64, -48)
	miner.direction = Vector2i.LEFT
	miner.leaves_belt = true
	miner.get_inventory().add_item(ItemData.ItemType.COAL, 5)

	var data = miner.serialize()

	var miner2 = Miner.new()
	miner2.deserialize(data)
	assert_true(miner2.leaves_belt, "Round-trip should preserve leaves_belt")
	assert_true(miner2.get_inventory().has_item(ItemData.ItemType.COAL, 5),
		"Round-trip should preserve inventory")

	miner.free()
	miner2.free()


# =============================================================================
# Push Items to Belt Tests
# =============================================================================

func test_push_items_to_belt_returns_all_when_no_belt_system():
	var miner = Miner.new()
	# No belt_system set, _push_items_to_belt should return full count
	# But _push_items_to_belt checks belt_system internally, and it's called
	# from _complete_mining only when belt_system is not null.
	# Test the fallback: belt_system exists but no belt at tile.
	var belt_system = BeltSystem.new()
	miner.belt_system = belt_system
	miner.position = Vector2.ZERO
	miner.direction = Vector2i.RIGHT
	var remaining = miner._push_items_to_belt(ItemData.ItemType.COAL, 3)
	assert_eq(remaining, 3, "Should return all items when no belt behind miner")
	miner.free()
	belt_system.free()


func test_push_items_to_belt_pushes_to_belt_behind():
	var miner = Miner.new()
	var belt_system = BeltSystem.new()
	miner.belt_system = belt_system
	# Miner at tile (2, 0) facing RIGHT -> behind tile is (1, 0)
	miner.position = WorldUtils.tile_to_world(Vector2i(2, 0))
	miner.direction = Vector2i.RIGHT

	var belt = BeltNode.new()
	belt.set_position(Vector2i(1, 0))
	belt_system.register_belt(belt)

	var remaining = miner._push_items_to_belt(ItemData.ItemType.COAL, 1)
	assert_eq(remaining, 0, "Should place item on belt behind miner")
	assert_true(belt.has_items(), "Belt should have the item")
	assert_eq(belt.items[0]["item_type"], ItemData.ItemType.COAL, "Belt item should be correct type")

	miner.free()
	belt_system.free()


func test_push_items_to_belt_respects_belt_capacity():
	var miner = Miner.new()
	var belt_system = BeltSystem.new()
	miner.belt_system = belt_system
	miner.position = WorldUtils.tile_to_world(Vector2i(2, 0))
	miner.direction = Vector2i.RIGHT

	var belt = BeltNode.new()
	belt.set_position(Vector2i(1, 0))
	belt.add_item(ItemData.ItemType.IRON_ORE)  # Fill the belt (MAX_ITEMS=1)
	belt_system.register_belt(belt)

	var remaining = miner._push_items_to_belt(ItemData.ItemType.COAL, 1)
	assert_eq(remaining, 1, "Should return item count when belt is full")

	miner.free()
	belt_system.free()


func test_push_items_to_belt_left_facing_miner():
	var miner = Miner.new()
	var belt_system = BeltSystem.new()
	miner.belt_system = belt_system
	# Miner at tile (2, 0) facing LEFT -> behind tile is (3, 0)
	miner.position = WorldUtils.tile_to_world(Vector2i(2, 0))
	miner.direction = Vector2i.LEFT

	var belt = BeltNode.new()
	belt.set_position(Vector2i(3, 0))
	belt_system.register_belt(belt)

	var remaining = miner._push_items_to_belt(ItemData.ItemType.COAL, 1)
	assert_eq(remaining, 0, "Left-facing miner should push to belt at tile + RIGHT")
	assert_true(belt.has_items(), "Belt behind left-facing miner should have item")

	miner.free()
	belt_system.free()


# =============================================================================
# Complete Mining Output Priority Tests
# =============================================================================

func test_complete_mining_to_belt_first():
	# _complete_mining should push to belt before inventory
	var miner = Miner.new()
	var world = TileWorld.new(12345)
	var belt_system = BeltSystem.new()

	miner.tile_world = world
	miner.belt_system = belt_system
	miner.direction = Vector2i.RIGHT
	# Miner at tile (5, 0)
	miner.position = WorldUtils.tile_to_world(Vector2i(5, 0))
	miner._current_mining_block_pos = Vector2i(7, 0)  # Mine target

	# Place a belt behind the miner at tile (4, 0)
	var belt = BeltNode.new()
	belt.set_position(Vector2i(4, 0))
	belt_system.register_belt(belt)

	# Set up a stone block to mine
	world.set_block(7, 0, BlockData.BlockType.STONE)

	# Call _complete_mining directly (stone drops cobblestone x1)
	miner._complete_mining(BlockData.BlockType.STONE)

	# Item should be on the belt, not in inventory
	assert_true(belt.has_items(), "Item should be on belt")
	assert_eq(belt.items[0]["item_type"], ItemData.ItemType.COBBLESTONE, "Belt should have cobblestone")
	assert_false(miner.get_inventory().has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Inventory should be empty when belt accepted item")

	miner.free()
	belt_system.free()


func test_complete_mining_falls_back_to_inventory():
	# When belt is full, items should go to inventory
	var miner = Miner.new()
	var world = TileWorld.new(12345)
	var belt_system = BeltSystem.new()

	miner.tile_world = world
	miner.belt_system = belt_system
	miner.direction = Vector2i.RIGHT
	miner.position = WorldUtils.tile_to_world(Vector2i(5, 0))
	miner._current_mining_block_pos = Vector2i(7, 0)

	# Belt behind miner is full
	var belt = BeltNode.new()
	belt.set_position(Vector2i(4, 0))
	belt.add_item(ItemData.ItemType.IRON_ORE)  # Fill belt
	belt_system.register_belt(belt)

	world.set_block(7, 0, BlockData.BlockType.STONE)
	miner._complete_mining(BlockData.BlockType.STONE)

	# Item should be in inventory since belt was full
	assert_true(miner.get_inventory().has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Inventory should have cobblestone when belt is full")

	miner.free()
	belt_system.free()


func test_complete_mining_no_belt_system_goes_to_inventory():
	# Without belt_system, items go straight to inventory
	var miner = Miner.new()
	var world = TileWorld.new(12345)

	miner.tile_world = world
	miner.direction = Vector2i.RIGHT
	miner.position = WorldUtils.tile_to_world(Vector2i(5, 0))
	miner._current_mining_block_pos = Vector2i(7, 0)

	world.set_block(7, 0, BlockData.BlockType.STONE)
	miner._complete_mining(BlockData.BlockType.STONE)

	assert_true(miner.get_inventory().has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Inventory should have cobblestone without belt_system")

	miner.free()


func test_complete_mining_no_belt_behind_goes_to_inventory():
	# Belt system exists but no belt behind miner -> inventory
	var miner = Miner.new()
	var world = TileWorld.new(12345)
	var belt_system = BeltSystem.new()

	miner.tile_world = world
	miner.belt_system = belt_system
	miner.direction = Vector2i.RIGHT
	miner.position = WorldUtils.tile_to_world(Vector2i(5, 0))
	miner._current_mining_block_pos = Vector2i(7, 0)

	# No belt placed behind miner
	world.set_block(7, 0, BlockData.BlockType.STONE)
	miner._complete_mining(BlockData.BlockType.STONE)

	assert_true(miner.get_inventory().has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Inventory should have cobblestone when no belt behind miner")

	miner.free()
	belt_system.free()


func test_complete_mining_removes_block():
	var miner = Miner.new()
	var world = TileWorld.new(12345)
	miner.tile_world = world
	miner.direction = Vector2i.RIGHT
	miner.position = WorldUtils.tile_to_world(Vector2i(5, 0))
	miner._current_mining_block_pos = Vector2i(7, 0)

	world.set_block(7, 0, BlockData.BlockType.STONE)
	miner._complete_mining(BlockData.BlockType.STONE)

	assert_eq(world.get_block(7, 0), BlockData.BlockType.AIR,
		"Block should be set to AIR after mining completes")

	miner.free()


func test_complete_mining_resumes_moving():
	var miner = Miner.new()
	var world = TileWorld.new(12345)
	miner.tile_world = world
	miner.direction = Vector2i.RIGHT
	miner.position = WorldUtils.tile_to_world(Vector2i(5, 0))
	miner._current_mining_block_pos = Vector2i(7, 0)
	miner._state = Miner.State.MINING

	world.set_block(7, 0, BlockData.BlockType.STONE)
	miner._complete_mining(BlockData.BlockType.STONE)

	assert_eq(miner._state, Miner.State.MOVING,
		"Miner should resume MOVING after completing mining")

	miner.free()


# =============================================================================
# Place Belt Behind Tests (requires scene tree)
# =============================================================================

func test_place_belt_behind_creates_conveyor():
	var parent = Node2D.new()
	add_child(parent)
	var miner = Miner.new()
	parent.add_child(miner)
	var world = TileWorld.new(12345)
	var belt_system = BeltSystem.new()
	miner.tile_world = world
	miner.belt_system = belt_system
	miner.direction = Vector2i.RIGHT

	# Ensure the tile is AIR (not solid)
	world.set_block(3, 5, BlockData.BlockType.AIR)

	miner._place_belt_behind(Vector2i(3, 5))

	# Belt should be registered
	assert_eq(belt_system.belts.size(), 1, "Belt system should have one belt")
	var belt = belt_system.belts[0]
	assert_eq(belt.position, Vector2i(3, 5), "Belt should be at the specified tile")

	parent.queue_free()
	belt_system.free()


func test_place_belt_behind_direction_opposite_right():
	var parent = Node2D.new()
	add_child(parent)
	var miner = Miner.new()
	parent.add_child(miner)
	var world = TileWorld.new(12345)
	var belt_system = BeltSystem.new()
	miner.tile_world = world
	miner.belt_system = belt_system
	miner.direction = Vector2i.RIGHT

	world.set_block(3, 5, BlockData.BlockType.AIR)
	miner._place_belt_behind(Vector2i(3, 5))

	assert_eq(belt_system.belts[0].direction, BeltNode.Direction.LEFT,
		"RIGHT miner should place LEFT belt (items flow back)")

	parent.queue_free()
	belt_system.free()


func test_place_belt_behind_direction_opposite_left():
	var parent = Node2D.new()
	add_child(parent)
	var miner = Miner.new()
	parent.add_child(miner)
	var world = TileWorld.new(12345)
	var belt_system = BeltSystem.new()
	miner.tile_world = world
	miner.belt_system = belt_system
	miner.direction = Vector2i.LEFT

	world.set_block(3, 5, BlockData.BlockType.AIR)
	miner._place_belt_behind(Vector2i(3, 5))

	assert_eq(belt_system.belts[0].direction, BeltNode.Direction.RIGHT,
		"LEFT miner should place RIGHT belt (items flow back)")

	parent.queue_free()
	belt_system.free()


func test_place_belt_behind_skips_existing_belt():
	var parent = Node2D.new()
	add_child(parent)
	var miner = Miner.new()
	parent.add_child(miner)
	var world = TileWorld.new(12345)
	var belt_system = BeltSystem.new()
	miner.tile_world = world
	miner.belt_system = belt_system
	miner.direction = Vector2i.RIGHT

	# Pre-register a belt at the target position
	var existing_belt = BeltNode.new()
	existing_belt.set_position(Vector2i(3, 5))
	belt_system.register_belt(existing_belt)

	world.set_block(3, 5, BlockData.BlockType.AIR)
	miner._place_belt_behind(Vector2i(3, 5))

	assert_eq(belt_system.belts.size(), 1, "Should not place belt on existing belt")

	parent.queue_free()
	belt_system.free()


func test_place_belt_behind_skips_solid_block():
	var parent = Node2D.new()
	add_child(parent)
	var miner = Miner.new()
	parent.add_child(miner)
	var world = TileWorld.new(12345)
	var belt_system = BeltSystem.new()
	miner.tile_world = world
	miner.belt_system = belt_system
	miner.direction = Vector2i.RIGHT

	# Solid block at the target
	world.set_block(3, 5, BlockData.BlockType.STONE)
	miner._place_belt_behind(Vector2i(3, 5))

	assert_eq(belt_system.belts.size(), 0, "Should not place belt on solid block")

	parent.queue_free()
	belt_system.free()


func test_place_belt_behind_no_belt_system():
	var miner = Miner.new()
	miner.belt_system = null
	# Should not crash when belt_system is null
	miner._place_belt_behind(Vector2i(3, 5))
	# If we get here without error, the test passes
	assert_true(true, "Should not crash when belt_system is null")
	miner.free()


func test_place_belt_behind_auto_connects():
	var parent = Node2D.new()
	add_child(parent)
	var miner = Miner.new()
	parent.add_child(miner)
	var world = TileWorld.new(12345)
	var belt_system = BeltSystem.new()
	miner.tile_world = world
	miner.belt_system = belt_system
	miner.direction = Vector2i.RIGHT

	# Place first belt at (4, 0) facing LEFT
	world.set_block(4, 0, BlockData.BlockType.AIR)
	miner._place_belt_behind(Vector2i(4, 0))

	# Place second belt at (5, 0) facing LEFT
	# LEFT belt at (5,0) has direction_vector (-1,0), target = (4,0)
	# So belt at (5,0) should auto-connect to belt at (4,0)
	world.set_block(5, 0, BlockData.BlockType.AIR)
	miner._place_belt_behind(Vector2i(5, 0))

	assert_eq(belt_system.belts.size(), 2, "Should have two belts")
	# Belt at (5,0) should connect to belt at (4,0)
	var belt_at_5 = belt_system.get_belt_at(Vector2i(5, 0))
	var belt_at_4 = belt_system.get_belt_at(Vector2i(4, 0))
	assert_not_null(belt_at_5, "Belt at (5,0) should exist")
	assert_not_null(belt_at_4, "Belt at (4,0) should exist")
	assert_eq(belt_at_5.next_belt, belt_at_4,
		"Belt at (5,0) should auto-connect to belt at (4,0)")

	parent.queue_free()
	belt_system.free()
