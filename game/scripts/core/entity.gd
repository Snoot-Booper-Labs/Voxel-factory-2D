## Base Entity class for ECS architecture
## Entities are Node2D containers that hold Components
class_name Entity
extends Node2D

## Dictionary mapping component type names to Component instances
var components: Dictionary = {}


## Adds a component to this entity
## The component's entity back-reference is set automatically
func add_component(component: Component) -> void:
	components[component.get_type_name()] = component
	component.entity = self


## Returns the component with the given type name, or null if not found
func get_component(type_name: String) -> Component:
	return components.get(type_name)


## Returns true if this entity has a component with the given type name
func has_component(type_name: String) -> bool:
	return components.has(type_name)


## Removes a component with the given type name from this entity
## Clears the component's entity back-reference
func remove_component(type_name: String) -> void:
	if components.has(type_name):
		var component = components[type_name]
		component.entity = null
		components.erase(type_name)
