## Base System class for ECS architecture
## Systems process entities that have specific components
## Override required_components and process_entity() in subclasses
class_name System
extends Node

## Array of component type names that entities must have to be processed by this system
var required_components: Array[String] = []


## Called each physics frame to process matching entities
## Override get_matching_entities() to provide entity query logic
func _physics_process(delta: float) -> void:
	for entity in get_matching_entities():
		process_entity(entity, delta)


## Process a single entity
## Override in subclasses to implement system-specific logic
func process_entity(entity: Entity, delta: float) -> void:
	pass


## Returns an array of entities that have all required components
## Override to implement entity query logic (e.g., from a world registry)
func get_matching_entities() -> Array[Entity]:
	return []
