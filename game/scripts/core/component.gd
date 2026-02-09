## Base Component class for ECS architecture
## Components are data containers attached to Entities
## Override get_type_name() in subclasses to return unique type identifiers
class_name Component
extends Resource

## Back-reference to the entity this component is attached to
var entity: Node2D = null


## Returns the type name of this component
## Override in subclasses to return a unique identifier
func get_type_name() -> String:
	return "Component"
