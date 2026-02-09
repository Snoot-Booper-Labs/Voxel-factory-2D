extends GutTest
## Unit tests for ECS Core: Entity, Component, and System classes

# =============================================================================
# Entity Tests
# =============================================================================

func test_entity_exists():
	# Entity class should exist and be instantiable
	var entity = Entity.new()
	assert_not_null(entity, "Entity should be instantiable")
	entity.free()


func test_entity_starts_with_no_components():
	var entity = Entity.new()
	assert_eq(entity.components.size(), 0, "Entity should start with empty components dictionary")
	entity.free()


func test_entity_add_component():
	var entity = Entity.new()
	var component = Component.new()
	entity.add_component(component)
	assert_true(entity.has_component("Component"), "Entity should have component after adding")
	entity.free()


func test_entity_get_component_returns_added_component():
	var entity = Entity.new()
	var component = Component.new()
	entity.add_component(component)
	var retrieved = entity.get_component("Component")
	assert_eq(retrieved, component, "get_component should return the same component that was added")
	entity.free()


func test_entity_has_component_returns_false_before_add():
	var entity = Entity.new()
	assert_false(entity.has_component("Component"), "has_component should return false before adding")
	entity.free()


func test_entity_has_component_returns_true_after_add():
	var entity = Entity.new()
	var component = Component.new()
	entity.add_component(component)
	assert_true(entity.has_component("Component"), "has_component should return true after adding")
	entity.free()


func test_entity_get_component_returns_null_if_not_present():
	var entity = Entity.new()
	var retrieved = entity.get_component("NonExistent")
	assert_null(retrieved, "get_component should return null for non-existent component")
	entity.free()


func test_entity_component_back_reference():
	var entity = Entity.new()
	var component = Component.new()
	entity.add_component(component)
	assert_eq(component.entity, entity, "Component should have back-reference to entity")
	entity.free()


func test_entity_remove_component():
	var entity = Entity.new()
	var component = Component.new()
	entity.add_component(component)
	entity.remove_component("Component")
	assert_false(entity.has_component("Component"), "has_component should return false after removal")
	entity.free()


func test_entity_remove_component_clears_back_reference():
	var entity = Entity.new()
	var component = Component.new()
	entity.add_component(component)
	entity.remove_component("Component")
	assert_null(component.entity, "Component back-reference should be null after removal")
	entity.free()


# =============================================================================
# Component Tests
# =============================================================================

func test_component_exists():
	var component = Component.new()
	assert_not_null(component, "Component should be instantiable")


func test_component_get_type_name():
	var component = Component.new()
	assert_eq(component.get_type_name(), "Component", "Base component type name should be 'Component'")


func test_component_entity_starts_null():
	var component = Component.new()
	assert_null(component.entity, "Component entity should start as null")


# =============================================================================
# System Tests
# =============================================================================

func test_system_exists():
	var system = System.new()
	assert_not_null(system, "System should be instantiable")
	system.free()


func test_system_has_required_components_array():
	var system = System.new()
	assert_not_null(system.required_components, "System should have required_components array")
	assert_eq(system.required_components.size(), 0, "required_components should start empty")
	system.free()


func test_system_process_entity_exists():
	var system = System.new()
	# Should not error when called
	var entity = Entity.new()
	system.process_entity(entity, 0.016)
	assert_true(true, "process_entity should exist and be callable")
	entity.free()
	system.free()
