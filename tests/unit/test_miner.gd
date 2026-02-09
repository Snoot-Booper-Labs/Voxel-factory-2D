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
