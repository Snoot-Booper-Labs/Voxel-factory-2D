## Program Component for ECS architecture
## Holds a GraphExecutor and manages program execution for an entity
class_name Program
extends Component

## The graph executor that runs the program
var executor: GraphExecutor

## The starting block of the program
var start_block: CommandBlock = null


func _init() -> void:
	executor = GraphExecutor.new()


## Returns the type name of this component
func get_type_name() -> String:
	return "Program"


## Sets the program to execute, starting from the given block
func set_program(start: CommandBlock) -> void:
	start_block = start
	executor.set_program(start)


## Starts execution of the program with an optional context
func start(context: Dictionary = {}) -> void:
	executor.start(context)


## Executes one block per tick
## Returns true if still running, false if completed or not running
func tick() -> bool:
	return executor.tick()


## Returns true if the executor is currently running
func is_running() -> bool:
	return executor.is_running()
