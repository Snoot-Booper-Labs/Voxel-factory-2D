## Tick-based command graph interpreter for executing visual programs
## Executes one CommandBlock per tick, tracking execution state and progress
class_name GraphExecutor
extends RefCounted

## States for the graph executor
enum ExecutorState {
	IDLE,       ## Not running
	RUNNING,    ## Executing program
	PAUSED,     ## Temporarily paused
	COMPLETED   ## Finished execution
}

## Current execution state
var state: ExecutorState = ExecutorState.IDLE

## The first block in the program
var start_block: CommandBlock = null

## The block currently being executed
var current_block: CommandBlock = null

## Context dictionary passed to blocks during execution
var execution_context: Dictionary = {}

## Array of blocks that have been executed (in order)
var blocks_executed: Array[CommandBlock] = []

## Emitted when execution starts
signal execution_started

## Emitted after each block is executed
signal block_executed(block: CommandBlock)

## Emitted when execution completes (no more blocks)
signal execution_completed

## Emitted when execution is paused
signal execution_paused


## Sets the program to execute, starting from the given block
func set_program(start: CommandBlock) -> void:
	start_block = start
	current_block = null
	state = ExecutorState.IDLE
	blocks_executed.clear()


## Starts execution of the program with an optional context
func start(context: Dictionary = {}) -> void:
	if start_block == null:
		return
	execution_context = context
	current_block = start_block
	state = ExecutorState.RUNNING
	blocks_executed.clear()
	execution_started.emit()


## Executes one block per tick
## Returns true if still running, false if completed or not running
func tick() -> bool:
	if state != ExecutorState.RUNNING:
		return false

	if current_block == null:
		state = ExecutorState.COMPLETED
		execution_completed.emit()
		return false

	# Execute current block
	blocks_executed.append(current_block)
	var next := current_block.execute(execution_context)
	block_executed.emit(current_block)

	# Move to next
	current_block = next

	if current_block == null:
		state = ExecutorState.COMPLETED
		execution_completed.emit()
		return false

	return true


## Pauses execution if currently running
func pause() -> void:
	if state == ExecutorState.RUNNING:
		state = ExecutorState.PAUSED
		execution_paused.emit()


## Resumes execution if currently paused
func resume() -> void:
	if state == ExecutorState.PAUSED:
		state = ExecutorState.RUNNING


## Stops execution and resets to idle state
func stop() -> void:
	state = ExecutorState.IDLE
	current_block = null


## Returns true if the executor is currently running
func is_running() -> bool:
	return state == ExecutorState.RUNNING


## Returns the array of blocks that have been executed in order
func get_blocks_executed() -> Array[CommandBlock]:
	return blocks_executed
