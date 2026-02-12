extends GutTest
## Unit tests for GraphExecutor - tick-based command graph interpreter


# =============================================================================
# GraphExecutor Existence Tests
# =============================================================================

func test_graph_executor_exists():
	# GraphExecutor class should exist and be instantiable
	var executor = GraphExecutor.new()
	assert_not_null(executor, "GraphExecutor should be instantiable")


func test_graph_executor_extends_ref_counted():
	var executor = GraphExecutor.new()
	assert_true(executor is RefCounted, "GraphExecutor should extend RefCounted")


# =============================================================================
# ExecutorState Enum Tests
# =============================================================================

func test_executor_state_enum_exists():
	# ExecutorState enum should exist with all required states
	assert_eq(GraphExecutor.ExecutorState.IDLE, 0, "IDLE should be 0")
	assert_eq(GraphExecutor.ExecutorState.RUNNING, 1, "RUNNING should be 1")
	assert_eq(GraphExecutor.ExecutorState.PAUSED, 2, "PAUSED should be 2")
	assert_eq(GraphExecutor.ExecutorState.COMPLETED, 3, "COMPLETED should be 3")


func test_initial_state_is_idle():
	var executor = GraphExecutor.new()
	assert_eq(executor.state, GraphExecutor.ExecutorState.IDLE, "Initial state should be IDLE")


# =============================================================================
# Property Tests
# =============================================================================

func test_start_block_starts_null():
	var executor = GraphExecutor.new()
	assert_null(executor.start_block, "start_block should start as null")


func test_current_block_starts_null():
	var executor = GraphExecutor.new()
	assert_null(executor.current_block, "current_block should start as null")


func test_execution_context_starts_empty():
	var executor = GraphExecutor.new()
	assert_eq(executor.execution_context.size(), 0, "execution_context should start empty")


func test_blocks_executed_starts_empty():
	var executor = GraphExecutor.new()
	assert_eq(executor.blocks_executed.size(), 0, "blocks_executed should start empty")


# =============================================================================
# set_program Tests
# =============================================================================

func test_set_program_stores_start_block():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	assert_eq(executor.start_block, block, "set_program should store start block")


func test_set_program_resets_current_block():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	assert_null(executor.current_block, "set_program should reset current_block to null")


func test_set_program_resets_state_to_idle():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()

	# Set a new program - should reset to IDLE
	var new_block = CommandBlock.new(CommandBlock.BlockType.START)
	executor.set_program(new_block)
	assert_eq(executor.state, GraphExecutor.ExecutorState.IDLE, "set_program should reset state to IDLE")


func test_set_program_clears_blocks_executed():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()
	executor.tick()

	# Set a new program - should clear blocks_executed
	var new_block = CommandBlock.new(CommandBlock.BlockType.START)
	executor.set_program(new_block)
	assert_eq(executor.blocks_executed.size(), 0, "set_program should clear blocks_executed")


# =============================================================================
# start Tests
# =============================================================================

func test_start_changes_state_to_running():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	executor.start()
	assert_eq(executor.state, GraphExecutor.ExecutorState.RUNNING, "start should change state to RUNNING")


func test_start_sets_current_block_to_start_block():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	executor.start()
	assert_eq(executor.current_block, block, "start should set current_block to start_block")


func test_start_clears_blocks_executed():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	executor.start()
	assert_eq(executor.blocks_executed.size(), 0, "start should clear blocks_executed")


func test_start_stores_context():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	var context = {"player_pos": Vector2(5, 5)}
	executor.start(context)
	assert_eq(executor.execution_context, context, "start should store execution context")


func test_start_does_nothing_without_program():
	var executor = GraphExecutor.new()
	executor.start()
	assert_eq(executor.state, GraphExecutor.ExecutorState.IDLE, "start should do nothing without program")


func test_start_emits_execution_started_signal():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	watch_signals(executor)
	executor.start()
	assert_signal_emitted(executor, "execution_started", "start should emit execution_started signal")


# =============================================================================
# tick Tests - Basic Execution
# =============================================================================

func test_tick_executes_current_block():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	executor.start()
	executor.tick()
	assert_eq(executor.blocks_executed.size(), 1, "tick should execute current block")
	assert_eq(executor.blocks_executed[0], block, "blocks_executed should contain the executed block")


func test_tick_moves_to_next_block():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()
	executor.tick()
	assert_eq(executor.current_block, block2, "tick should move current_block to next block")


func test_tick_returns_true_while_running():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()
	var result = executor.tick()
	assert_true(result, "tick should return true while still running")


func test_tick_returns_false_when_completed():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	# No next block - will complete after first tick

	var executor = GraphExecutor.new()
	executor.set_program(block)
	executor.start()
	var result = executor.tick()
	assert_false(result, "tick should return false when completed")


func test_tick_sets_state_to_completed_when_done():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	# No next block - will complete after first tick

	var executor = GraphExecutor.new()
	executor.set_program(block)
	executor.start()
	executor.tick()
	assert_eq(executor.state, GraphExecutor.ExecutorState.COMPLETED, "tick should set state to COMPLETED when no more blocks")


func test_tick_emits_block_executed_signal():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	executor.start()
	watch_signals(executor)
	executor.tick()
	assert_signal_emitted(executor, "block_executed", "tick should emit block_executed signal")


func test_tick_emits_execution_completed_signal_when_done():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	executor.start()
	watch_signals(executor)
	executor.tick()
	assert_signal_emitted(executor, "execution_completed", "tick should emit execution_completed signal when done")


func test_tick_does_nothing_when_not_running():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	# Don't call start - state is IDLE
	var result = executor.tick()
	assert_false(result, "tick should return false when not running")
	assert_eq(executor.blocks_executed.size(), 0, "tick should not execute when not running")


# =============================================================================
# 3-Block Chain Execution Test (Key Integration Test)
# =============================================================================

func test_executes_3_block_chain_in_order():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.MOVE)
	var block3 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)
	block2.connect_next(block3)
	# block3 has no next (ends program)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()

	# Tick 1: execute block1
	assert_true(executor.tick(), "First tick should return true (still running)")
	assert_eq(executor.current_block, block2, "After tick 1, current_block should be block2")

	# Tick 2: execute block2
	assert_true(executor.tick(), "Second tick should return true (still running)")
	assert_eq(executor.current_block, block3, "After tick 2, current_block should be block3")

	# Tick 3: execute block3, returns false (completed)
	assert_false(executor.tick(), "Third tick should return false (completed)")
	assert_eq(executor.state, GraphExecutor.ExecutorState.COMPLETED, "State should be COMPLETED after last tick")

	# Verify execution order
	var executed = executor.get_blocks_executed()
	assert_eq(executed.size(), 3, "Should have executed 3 blocks")
	assert_eq(executed[0], block1, "First executed block should be block1")
	assert_eq(executed[1], block2, "Second executed block should be block2")
	assert_eq(executed[2], block3, "Third executed block should be block3")


# =============================================================================
# pause/resume Tests
# =============================================================================

func test_pause_changes_state_to_paused():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()
	executor.pause()
	assert_eq(executor.state, GraphExecutor.ExecutorState.PAUSED, "pause should change state to PAUSED")


func test_pause_emits_execution_paused_signal():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()
	watch_signals(executor)
	executor.pause()
	assert_signal_emitted(executor, "execution_paused", "pause should emit execution_paused signal")


func test_pause_does_nothing_when_not_running():
	var executor = GraphExecutor.new()
	executor.pause()
	assert_eq(executor.state, GraphExecutor.ExecutorState.IDLE, "pause should do nothing when not running")


func test_resume_changes_state_to_running():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()
	executor.pause()
	executor.resume()
	assert_eq(executor.state, GraphExecutor.ExecutorState.RUNNING, "resume should change state to RUNNING")


func test_resume_does_nothing_when_not_paused():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	executor.start()
	executor.resume()  # Already running, not paused
	assert_eq(executor.state, GraphExecutor.ExecutorState.RUNNING, "resume should do nothing when not paused")


func test_tick_does_nothing_when_paused():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()
	executor.pause()
	var result = executor.tick()
	assert_false(result, "tick should return false when paused")
	assert_eq(executor.blocks_executed.size(), 0, "tick should not execute when paused")


# =============================================================================
# stop Tests
# =============================================================================

func test_stop_resets_state_to_idle():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()
	executor.tick()
	executor.stop()
	assert_eq(executor.state, GraphExecutor.ExecutorState.IDLE, "stop should reset state to IDLE")


func test_stop_clears_current_block():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()
	executor.tick()
	executor.stop()
	assert_null(executor.current_block, "stop should clear current_block")


# =============================================================================
# is_running Tests
# =============================================================================

func test_is_running_returns_true_when_running():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	executor.start()
	assert_true(executor.is_running(), "is_running should return true when running")


func test_is_running_returns_false_when_idle():
	var executor = GraphExecutor.new()
	assert_false(executor.is_running(), "is_running should return false when idle")


func test_is_running_returns_false_when_paused():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()
	executor.pause()
	assert_false(executor.is_running(), "is_running should return false when paused")


func test_is_running_returns_false_when_completed():
	var block = CommandBlock.new(CommandBlock.BlockType.START)
	var executor = GraphExecutor.new()
	executor.set_program(block)
	executor.start()
	executor.tick()
	assert_false(executor.is_running(), "is_running should return false when completed")


# =============================================================================
# get_blocks_executed Tests
# =============================================================================

func test_get_blocks_executed_returns_array():
	var executor = GraphExecutor.new()
	var result = executor.get_blocks_executed()
	assert_true(result is Array, "get_blocks_executed should return an Array")


func test_get_blocks_executed_returns_executed_blocks():
	var block1 = CommandBlock.new(CommandBlock.BlockType.START)
	var block2 = CommandBlock.new(CommandBlock.BlockType.END)
	block1.connect_next(block2)

	var executor = GraphExecutor.new()
	executor.set_program(block1)
	executor.start()
	executor.tick()

	var executed = executor.get_blocks_executed()
	assert_eq(executed.size(), 1, "get_blocks_executed should return one block after one tick")
	assert_eq(executed[0], block1, "First executed block should be block1")


# =============================================================================
# Signal Existence Tests
# =============================================================================

func test_execution_started_signal_exists():
	var executor = GraphExecutor.new()
	assert_true(executor.has_signal("execution_started"), "GraphExecutor should have execution_started signal")


func test_block_executed_signal_exists():
	var executor = GraphExecutor.new()
	assert_true(executor.has_signal("block_executed"), "GraphExecutor should have block_executed signal")


func test_execution_completed_signal_exists():
	var executor = GraphExecutor.new()
	assert_true(executor.has_signal("execution_completed"), "GraphExecutor should have execution_completed signal")


func test_execution_paused_signal_exists():
	var executor = GraphExecutor.new()
	assert_true(executor.has_signal("execution_paused"), "GraphExecutor should have execution_paused signal")
