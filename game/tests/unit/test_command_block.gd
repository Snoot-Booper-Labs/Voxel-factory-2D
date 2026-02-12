extends GutTest
## Unit tests for CommandBlock - base class for visual programming blocks

# =============================================================================
# CommandBlock Existence Tests
# =============================================================================

func test_command_block_exists():
	# CommandBlock class should exist and be instantiable
	var block = CommandBlock.new()
	assert_not_null(block, "CommandBlock should be instantiable")


func test_command_block_extends_ref_counted():
	var block = CommandBlock.new()
	assert_true(block is RefCounted, "CommandBlock should extend RefCounted")


# =============================================================================
# BlockType Enum Tests
# =============================================================================

func test_block_type_enum_exists():
	# BlockType enum should exist with all required types
	assert_eq(CommandBlock.BlockType.START, 0, "START should be 0")
	assert_eq(CommandBlock.BlockType.MOVE, 1, "MOVE should be 1")
	assert_eq(CommandBlock.BlockType.MINE, 2, "MINE should be 2")
	assert_eq(CommandBlock.BlockType.PLACE, 3, "PLACE should be 3")
	assert_eq(CommandBlock.BlockType.CONDITION, 4, "CONDITION should be 4")
	assert_eq(CommandBlock.BlockType.LOOP, 5, "LOOP should be 5")
	assert_eq(CommandBlock.BlockType.WAIT, 6, "WAIT should be 6")
	assert_eq(CommandBlock.BlockType.END, 7, "END should be 7")


# =============================================================================
# Constructor Tests
# =============================================================================

func test_constructor_default_type():
	var block = CommandBlock.new()
	assert_eq(block.block_type, CommandBlock.BlockType.START, "Default block_type should be START")


func test_constructor_with_type():
	var block = CommandBlock.new(CommandBlock.BlockType.MOVE)
	assert_eq(block.block_type, CommandBlock.BlockType.MOVE, "Constructor should set block_type to MOVE")


func test_constructor_sets_block_id():
	var block = CommandBlock.new()
	assert_true(block.block_id != 0, "block_id should be set to a non-zero value")


func test_different_blocks_have_different_ids():
	var block1 = CommandBlock.new()
	# Small delay to ensure different timestamp
	await get_tree().process_frame
	var block2 = CommandBlock.new()
	assert_ne(block1.block_id, block2.block_id, "Different blocks should have different IDs")


# =============================================================================
# Get Block Type Tests
# =============================================================================

func test_get_block_type_returns_correct_type():
	var block = CommandBlock.new(CommandBlock.BlockType.MINE)
	assert_eq(block.get_block_type(), CommandBlock.BlockType.MINE, "get_block_type should return MINE")


func test_get_block_type_name_returns_string():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	assert_eq(block.get_block_type_name(), "START", "get_block_type_name should return 'START'")


func test_get_block_type_name_for_move():
	var block = CommandBlock.new(CommandBlock.BlockType.MOVE)
	assert_eq(block.get_block_type_name(), "MOVE", "get_block_type_name should return 'MOVE'")


func test_get_block_type_name_for_condition():
	var block = CommandBlock.new(CommandBlock.BlockType.CONDITION)
	assert_eq(block.get_block_type_name(), "CONDITION", "get_block_type_name should return 'CONDITION'")


# =============================================================================
# Connection Tests - next_block
# =============================================================================

func test_next_block_starts_null():
	var block = CommandBlock.new()
	assert_null(block.next_block, "next_block should start as null")


func test_connect_next_links_blocks():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.MOVE)
	block1.connect_next(block2)
	assert_eq(block1.next_block, block2, "connect_next should set next_block")


func test_get_next_returns_connected_block():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)
	assert_eq(block1.get_next(), block2, "get_next should return the connected block")


func test_get_next_returns_null_when_not_connected():
	var block = CommandBlock.new()
	assert_null(block.get_next(), "get_next should return null when not connected")


# =============================================================================
# Connection Tests - named outputs
# =============================================================================

func test_outputs_starts_empty():
	var block = CommandBlock.new()
	assert_eq(block.outputs.size(), 0, "outputs should start empty")


func test_connect_output_adds_named_output():
	var block = CommandBlock.new(CommandBlock.BlockType.CONDITION)
	var true_block = CommandBlock.new(CommandBlock.BlockType.MOVE)
	block.connect_output("true", true_block)
	assert_eq(block.outputs.size(), 1, "outputs should have one entry")


func test_get_output_returns_named_output():
	var block = CommandBlock.new(CommandBlock.BlockType.CONDITION)
	var true_block = CommandBlock.new(CommandBlock.BlockType.MOVE)
	var false_block = CommandBlock.new(CommandBlock.BlockType.WAIT)
	block.connect_output("true", true_block)
	block.connect_output("false", false_block)
	assert_eq(block.get_output("true"), true_block, "get_output('true') should return true_block")
	assert_eq(block.get_output("false"), false_block, "get_output('false') should return false_block")


func test_get_output_returns_null_for_missing():
	var block = CommandBlock.new()
	assert_null(block.get_output("nonexistent"), "get_output should return null for missing output")


# =============================================================================
# Parameter Tests
# =============================================================================

func test_parameters_starts_empty():
	var block = CommandBlock.new()
	assert_eq(block.parameters.size(), 0, "parameters should start empty")


func test_set_parameter_stores_value():
	var block = CommandBlock.new(CommandBlock.BlockType.MOVE)
	block.set_parameter("direction", "north")
	assert_eq(block.parameters["direction"], "north", "set_parameter should store value")


func test_get_parameter_retrieves_value():
	var block = CommandBlock.new(CommandBlock.BlockType.LOOP)
	block.set_parameter("count", 5)
	assert_eq(block.get_parameter("count"), 5, "get_parameter should retrieve stored value")


func test_get_parameter_returns_default_for_missing():
	var block = CommandBlock.new()
	assert_null(block.get_parameter("missing"), "get_parameter should return null by default for missing keys")


func test_get_parameter_returns_custom_default_for_missing():
	var block = CommandBlock.new()
	assert_eq(block.get_parameter("missing", 42), 42, "get_parameter should return custom default for missing keys")


func test_parameters_support_various_types():
	var block = CommandBlock.new()
	block.set_parameter("int_val", 10)
	block.set_parameter("float_val", 3.14)
	block.set_parameter("string_val", "hello")
	block.set_parameter("vector_val", Vector2(1, 2))
	block.set_parameter("array_val", [1, 2, 3])

	assert_eq(block.get_parameter("int_val"), 10, "Should store int")
	assert_eq(block.get_parameter("float_val"), 3.14, "Should store float")
	assert_eq(block.get_parameter("string_val"), "hello", "Should store string")
	assert_eq(block.get_parameter("vector_val"), Vector2(1, 2), "Should store Vector2")
	assert_eq(block.get_parameter("array_val"), [1, 2, 3], "Should store array")


# =============================================================================
# Execute Tests
# =============================================================================

func test_execute_returns_next_block():
	var block1 = CommandBlock.new(CommandBlock.BlockType.MOVE)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)
	var context = {}
	var result = block1.execute(context)
	assert_eq(result, block2, "execute should return next_block by default")


func test_execute_returns_null_when_no_next():
	var block = CommandBlock.new(CommandBlock.BlockType.END)
	var context = {}
	var result = block.execute(context)
	assert_null(result, "execute should return null when no next_block")


# =============================================================================
# Signal Tests
# =============================================================================

func test_execution_started_signal_exists():
	var block = CommandBlock.new()
	assert_true(block.has_signal("execution_started"), "CommandBlock should have execution_started signal")


func test_execution_completed_signal_exists():
	var block = CommandBlock.new()
	assert_true(block.has_signal("execution_completed"), "CommandBlock should have execution_completed signal")


func test_execute_emits_execution_started():
	var block = CommandBlock.new()
	watch_signals(block)
	block.execute({})
	assert_signal_emitted(block, "execution_started", "execute should emit execution_started signal")


func test_execute_emits_execution_completed():
	var block = CommandBlock.new()
	watch_signals(block)
	block.execute({})
	assert_signal_emitted(block, "execution_completed", "execute should emit execution_completed signal")


func test_execute_completed_signal_passes_next_block():
	var block1 = CommandBlock.new(CommandBlock.BlockType.MOVE)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	# Use an array to capture the signal parameter (arrays are passed by reference)
	var captured := []
	block1.execution_completed.connect(func(next): captured.append(next))
	block1.execute({})

	assert_eq(captured.size(), 1, "Signal should have been emitted once")
	assert_eq(captured[0], block2, "execution_completed should pass next_block as parameter")
