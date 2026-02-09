## Miner Entity - A programmable machine that can mine blocks
## Has Inventory and Program components for storing items and executing mining programs
class_name Miner
extends Entity


func _init() -> void:
	# Add required components
	add_component(Inventory.new())
	add_component(Program.new())


## Returns the Inventory component
func get_inventory() -> Inventory:
	return get_component("Inventory") as Inventory


## Returns the Program component
func get_program() -> Program:
	return get_component("Program") as Program


## Sets the mining program to execute
func set_mining_program(start_block: CommandBlock) -> void:
	get_program().set_program(start_block)


## Starts mining with the given world context
func start_mining(world: TileWorld) -> void:
	var context := {
		"world": world,
		"inventory": get_inventory(),
		"miner": self
	}
	get_program().start(context)


## Executes one tick of the mining program
## Returns true if still running, false if completed
func tick() -> bool:
	return get_program().tick()
