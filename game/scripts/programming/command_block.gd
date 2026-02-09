## Base class for all command blocks in the visual programming system
## Each command block represents an action that can be executed in a program
class_name CommandBlock
extends RefCounted

## Types of command blocks available in the programming system
enum BlockType {
	START,      ## Entry point of a program
	MOVE,       ## Move in a direction
	MINE,       ## Mine block at position
	PLACE,      ## Place block
	CONDITION,  ## If/else branch
	LOOP,       ## Repeat N times
	WAIT,       ## Wait for ticks
	END         ## End of program
}

## The type of this command block
var block_type: BlockType = BlockType.START

## Unique ID for this block instance
var block_id: int = 0

## Default next block to execute (for linear flow)
var next_block: CommandBlock = null

## Named outputs for branching (e.g., "true", "false" for conditions)
var outputs: Dictionary = {}

## Block-specific parameters (e.g., direction for MOVE, count for LOOP)
var parameters: Dictionary = {}

## Emitted when the block starts executing
signal execution_started

## Emitted when the block finishes executing, passes the next block to execute
signal execution_completed(next_block: CommandBlock)


## Creates a new command block of the specified type
func _init(type: BlockType = BlockType.START) -> void:
	block_type = type
	block_id = _generate_id()


## Generates a unique ID based on current time
func _generate_id() -> int:
	return hash(Time.get_ticks_usec())


## Returns the block type enum value
func get_block_type() -> BlockType:
	return block_type


## Returns the block type as a string (e.g., "START", "MOVE")
func get_block_type_name() -> String:
	return BlockType.keys()[block_type]


## Connects this block to the next block in the execution flow
func connect_next(block: CommandBlock) -> void:
	next_block = block


## Connects a named output to another block (for branching)
func connect_output(name: String, block: CommandBlock) -> void:
	outputs[name] = block


## Gets a named output block, or null if not found
func get_output(name: String) -> CommandBlock:
	return outputs.get(name)


## Gets the default next block
func get_next() -> CommandBlock:
	return next_block


## Sets a parameter value for this block
func set_parameter(key: String, value: Variant) -> void:
	parameters[key] = value


## Gets a parameter value, returning default if not found
func get_parameter(key: String, default: Variant = null) -> Variant:
	return parameters.get(key, default)


## Executes this block and returns the next block to execute
## Override in subclasses to implement specific behavior
func execute(context: Dictionary) -> CommandBlock:
	execution_started.emit()
	# Default: just go to next block
	var result := next_block
	execution_completed.emit(result)
	return result
