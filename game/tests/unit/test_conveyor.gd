extends GutTest
## Unit tests for Conveyor System (Factorio-style belt item transport)

# =============================================================================
# BeltNode Component Tests
# =============================================================================

func test_belt_node_exists():
	# BeltNode class should exist and be instantiable
	var belt = BeltNode.new()
	assert_not_null(belt, "BeltNode should be instantiable")


func test_belt_node_extends_component():
	var belt = BeltNode.new()
	assert_true(belt is Component, "BeltNode should extend Component")


func test_belt_node_get_type_name():
	var belt = BeltNode.new()
	assert_eq(belt.get_type_name(), "BeltNode", "get_type_name should return 'BeltNode'")


func test_belt_node_direction_enum_exists():
	# Direction enum should exist with UP, DOWN, LEFT, RIGHT
	assert_eq(BeltNode.Direction.UP, 0, "Direction.UP should be 0")
	assert_eq(BeltNode.Direction.DOWN, 1, "Direction.DOWN should be 1")
	assert_eq(BeltNode.Direction.LEFT, 2, "Direction.LEFT should be 2")
	assert_eq(BeltNode.Direction.RIGHT, 3, "Direction.RIGHT should be 3")


func test_belt_node_default_direction():
	var belt = BeltNode.new()
	assert_eq(belt.direction, BeltNode.Direction.RIGHT, "Default direction should be RIGHT")


func test_belt_node_set_direction():
	var belt = BeltNode.new()
	belt.set_direction(BeltNode.Direction.UP)
	assert_eq(belt.direction, BeltNode.Direction.UP, "set_direction should update direction")


func test_belt_node_default_position():
	var belt = BeltNode.new()
	assert_eq(belt.position, Vector2i.ZERO, "Default position should be Vector2i.ZERO")


func test_belt_node_set_position():
	var belt = BeltNode.new()
	belt.set_position(Vector2i(5, 10))
	assert_eq(belt.position, Vector2i(5, 10), "set_position should update position")


func test_belt_node_next_belt_starts_null():
	var belt = BeltNode.new()
	assert_null(belt.next_belt, "next_belt should start as null")


func test_belt_node_connect_to():
	var belt_a = BeltNode.new()
	var belt_b = BeltNode.new()
	belt_a.connect_to(belt_b)
	assert_eq(belt_a.next_belt, belt_b, "connect_to should set next_belt")


func test_belt_node_items_starts_empty():
	var belt = BeltNode.new()
	assert_eq(belt.items.size(), 0, "items should start empty")


func test_belt_node_add_item():
	var belt = BeltNode.new()
	belt.add_item(ItemData.ItemType.COAL)
	assert_eq(belt.items.size(), 1, "add_item should add an item")
	assert_eq(belt.items[0]["item_type"], ItemData.ItemType.COAL, "Item should have correct type")
	assert_eq(belt.items[0]["progress"], 0.0, "Item should start at progress 0.0")


func test_belt_node_add_item_returns_true():
	var belt = BeltNode.new()
	var accepted = belt.add_item(ItemData.ItemType.COAL)
	assert_true(accepted, "add_item should return true when belt has space")


func test_belt_node_is_full_after_max_items():
	var belt = BeltNode.new()
	belt.add_item(ItemData.ItemType.COAL)
	assert_true(belt.is_full(), "Belt should be full after reaching MAX_ITEMS")


func test_belt_node_rejects_item_when_full():
	var belt = BeltNode.new()
	belt.add_item(ItemData.ItemType.COAL)
	var accepted = belt.add_item(ItemData.ItemType.IRON_ORE)
	assert_false(accepted, "add_item should return false when belt is full")
	assert_eq(belt.items.size(), 1, "Belt should still have only MAX_ITEMS items")


func test_belt_node_has_items_false_when_empty():
	var belt = BeltNode.new()
	assert_false(belt.has_items(), "has_items should return false when empty")


func test_belt_node_has_items_true_when_not_empty():
	var belt = BeltNode.new()
	belt.add_item(ItemData.ItemType.COAL)
	assert_true(belt.has_items(), "has_items should return true when items present")


func test_belt_node_get_items():
	var belt = BeltNode.new()
	belt.add_item(ItemData.ItemType.COAL)
	var items = belt.get_items()
	assert_eq(items.size(), 1, "get_items should return items array")
	assert_eq(items[0]["item_type"], ItemData.ItemType.COAL, "get_items should return correct item")


func test_belt_node_tick_moves_item_progress():
	var belt = BeltNode.new()
	belt.add_item(ItemData.ItemType.COAL)
	belt.tick(0.5)  # Half second at 1 item/sec
	assert_almost_eq(belt.items[0]["progress"], 0.5, 0.001, "tick should increase item progress")


func test_belt_node_tick_returns_completed_items():
	var belt = BeltNode.new()
	belt.add_item(ItemData.ItemType.COAL)
	var completed = belt.tick(1.0)  # Full second at 1 item/sec
	assert_eq(completed.size(), 1, "tick should return completed items")
	assert_eq(completed[0]["item_type"], ItemData.ItemType.COAL, "Completed item should have correct type")


func test_belt_node_tick_removes_completed_items():
	var belt = BeltNode.new()
	belt.add_item(ItemData.ItemType.COAL)
	belt.tick(1.0)  # Full second at 1 item/sec
	assert_false(belt.has_items(), "Completed items should be removed from belt")


func test_belt_node_tick_partial_does_not_complete():
	var belt = BeltNode.new()
	belt.add_item(ItemData.ItemType.COAL)
	# Move item partway
	belt.items[0]["progress"] = 0.4
	var completed = belt.tick(0.3)
	assert_eq(completed.size(), 0, "Item below 1.0 should not complete")
	assert_eq(belt.items.size(), 1, "Item should remain on belt")
	assert_almost_eq(belt.items[0]["progress"], 0.7, 0.001, "Progress should accumulate")


func test_belt_node_belt_speed_constant():
	assert_eq(BeltNode.BELT_SPEED, 1.0, "BELT_SPEED should be 1.0")


func test_belt_node_max_items_constant():
	assert_eq(BeltNode.MAX_ITEMS, 1, "MAX_ITEMS should be 1")


func test_belt_node_get_direction_vector_right():
	var belt = BeltNode.new()
	belt.set_direction(BeltNode.Direction.RIGHT)
	assert_eq(belt.get_direction_vector(), Vector2i(1, 0), "RIGHT should be (1, 0)")


func test_belt_node_get_direction_vector_left():
	var belt = BeltNode.new()
	belt.set_direction(BeltNode.Direction.LEFT)
	assert_eq(belt.get_direction_vector(), Vector2i(-1, 0), "LEFT should be (-1, 0)")


func test_belt_node_get_direction_vector_up():
	var belt = BeltNode.new()
	belt.set_direction(BeltNode.Direction.UP)
	assert_eq(belt.get_direction_vector(), Vector2i(0, 1), "UP should be (0, 1) in tile space")


func test_belt_node_get_direction_vector_down():
	var belt = BeltNode.new()
	belt.set_direction(BeltNode.Direction.DOWN)
	assert_eq(belt.get_direction_vector(), Vector2i(0, -1), "DOWN should be (0, -1) in tile space")


func test_belt_node_backpressure_stalls_item():
	# When next belt is full, item stalls at progress 1.0
	var belt_a = BeltNode.new()
	var belt_b = BeltNode.new()
	belt_a.connect_to(belt_b)
	belt_b.add_item(ItemData.ItemType.IRON_ORE)  # Fill belt_b

	belt_a.add_item(ItemData.ItemType.COAL)
	var completed = belt_a.tick(1.5)  # Would normally complete
	assert_eq(completed.size(), 0, "Item should not complete when next belt is full")
	assert_eq(belt_a.items.size(), 1, "Item should stall on belt_a")
	assert_eq(belt_a.items[0]["progress"], 1.0, "Item should stall at progress 1.0")


func test_belt_node_backpressure_releases_when_next_clears():
	# After next belt clears, stalled item can transfer
	var belt_a = BeltNode.new()
	var belt_b = BeltNode.new()
	belt_a.connect_to(belt_b)
	belt_b.add_item(ItemData.ItemType.IRON_ORE)

	belt_a.add_item(ItemData.ItemType.COAL)
	belt_a.tick(1.5)  # Stall
	assert_eq(belt_a.items.size(), 1, "Should stall initially")

	# Clear belt_b
	belt_b.items.clear()
	var completed = belt_a.tick(0.0)  # Zero delta, but item is already >= 1.0
	assert_eq(completed.size(), 1, "Item should complete after next belt clears")


func test_belt_node_serialize():
	var belt = BeltNode.new()
	belt.set_position(Vector2i(3, 7))
	belt.set_direction(BeltNode.Direction.LEFT)
	belt.add_item(ItemData.ItemType.COAL)
	belt.items[0]["progress"] = 0.5

	var data = belt.serialize()
	assert_eq(data["position"]["x"], 3, "Serialized position x should match")
	assert_eq(data["position"]["y"], 7, "Serialized position y should match")
	assert_eq(data["direction"], BeltNode.Direction.LEFT, "Serialized direction should match")
	assert_eq(data["items"].size(), 1, "Serialized items should have 1 item")
	assert_eq(data["items"][0]["item_type"], ItemData.ItemType.COAL, "Serialized item type should match")


func test_belt_node_deserialize():
	var belt = BeltNode.new()
	var data = {
		"position": {"x": 5, "y": 2},
		"direction": BeltNode.Direction.UP,
		"items": [{"item_type": ItemData.ItemType.IRON_ORE, "progress": 0.3}],
	}
	belt.deserialize(data)
	assert_eq(belt.position, Vector2i(5, 2), "Deserialized position should match")
	assert_eq(belt.direction, BeltNode.Direction.UP, "Deserialized direction should match")
	assert_eq(belt.items.size(), 1, "Deserialized items should have 1 item")
	assert_eq(belt.items[0]["item_type"], ItemData.ItemType.IRON_ORE, "Deserialized item type should match")


# =============================================================================
# BeltSystem Tests
# =============================================================================

func test_belt_system_exists():
	var system = BeltSystem.new()
	assert_not_null(system, "BeltSystem should be instantiable")
	system.free()


func test_belt_system_extends_system():
	var system = BeltSystem.new()
	assert_true(system is System, "BeltSystem should extend System")
	system.free()


func test_belt_system_required_components():
	var system = BeltSystem.new()
	assert_true("BeltNode" in system.required_components, "BeltSystem should require BeltNode component")
	system.free()


func test_belt_system_belts_starts_empty():
	var system = BeltSystem.new()
	assert_eq(system.belts.size(), 0, "belts array should start empty")
	system.free()


func test_belt_system_register_belt():
	var system = BeltSystem.new()
	var belt = BeltNode.new()
	system.register_belt(belt)
	assert_eq(system.belts.size(), 1, "register_belt should add belt to array")
	assert_true(belt in system.belts, "Registered belt should be in belts array")
	system.free()


func test_belt_system_register_belt_no_duplicates():
	var system = BeltSystem.new()
	var belt = BeltNode.new()
	system.register_belt(belt)
	system.register_belt(belt)
	assert_eq(system.belts.size(), 1, "register_belt should not add duplicates")
	system.free()


func test_belt_system_unregister_belt():
	var system = BeltSystem.new()
	var belt = BeltNode.new()
	system.register_belt(belt)
	system.unregister_belt(belt)
	assert_eq(system.belts.size(), 0, "unregister_belt should remove belt")
	system.free()


func test_belt_system_process_belts_moves_items():
	var system = BeltSystem.new()
	var belt = BeltNode.new()
	system.register_belt(belt)
	belt.add_item(ItemData.ItemType.COAL)
	system.process_belts(0.5)
	assert_almost_eq(belt.items[0]["progress"], 0.5, 0.001, "process_belts should move items")
	system.free()


func test_belt_system_process_belts_transfers_to_next():
	var system = BeltSystem.new()
	var belt_a = BeltNode.new()
	var belt_b = BeltNode.new()
	belt_a.connect_to(belt_b)
	system.register_belt(belt_a)
	system.register_belt(belt_b)
	belt_a.add_item(ItemData.ItemType.COAL)
	system.process_belts(1.0)  # Full transfer
	assert_false(belt_a.has_items(), "Source belt should be empty after transfer")
	assert_true(belt_b.has_items(), "Destination belt should have item after transfer")
	system.free()


func test_belt_system_get_belt_at():
	var system = BeltSystem.new()
	var belt = BeltNode.new()
	belt.set_position(Vector2i(3, 5))
	system.register_belt(belt)
	var found = system.get_belt_at(Vector2i(3, 5))
	assert_eq(found, belt, "get_belt_at should find belt at position")
	system.free()


func test_belt_system_get_belt_at_returns_null_when_not_found():
	var system = BeltSystem.new()
	var found = system.get_belt_at(Vector2i(99, 99))
	assert_null(found, "get_belt_at should return null when no belt at position")
	system.free()


# =============================================================================
# Conveyor Entity Tests
# =============================================================================

func test_conveyor_exists():
	var conveyor = Conveyor.new()
	assert_not_null(conveyor, "Conveyor should be instantiable")
	conveyor.free()


func test_conveyor_extends_entity():
	var conveyor = Conveyor.new()
	assert_true(conveyor is Entity, "Conveyor should extend Entity")
	conveyor.free()


func test_conveyor_has_belt_node_component():
	var conveyor = Conveyor.new()
	assert_true(conveyor.has_component("BeltNode"), "Conveyor should have BeltNode component")
	conveyor.free()


func test_conveyor_get_belt():
	var conveyor = Conveyor.new()
	var belt = conveyor.get_belt()
	assert_not_null(belt, "get_belt should return BeltNode")
	assert_true(belt is BeltNode, "get_belt should return a BeltNode instance")
	conveyor.free()


func test_conveyor_init_with_position():
	var conveyor = Conveyor.new(Vector2i(5, 10))
	var belt = conveyor.get_belt()
	assert_eq(belt.position, Vector2i(5, 10), "Conveyor should initialize belt position")
	conveyor.free()


func test_conveyor_init_with_direction():
	var conveyor = Conveyor.new(Vector2i.ZERO, BeltNode.Direction.UP)
	var belt = conveyor.get_belt()
	assert_eq(belt.direction, BeltNode.Direction.UP, "Conveyor should initialize belt direction")
	conveyor.free()


func test_conveyor_add_item():
	var conveyor = Conveyor.new()
	conveyor.add_item(ItemData.ItemType.COAL)
	assert_true(conveyor.get_belt().has_items(), "add_item should add item to belt")
	conveyor.free()


# =============================================================================
# Integration Test: Item Moves Along Belt Chain
# =============================================================================

func test_item_moves_from_belt_a_to_belt_b():
	var system = BeltSystem.new()

	var belt_a = BeltNode.new()
	belt_a.set_position(Vector2i(0, 0))

	var belt_b = BeltNode.new()
	belt_b.set_position(Vector2i(1, 0))

	belt_a.connect_to(belt_b)

	system.register_belt(belt_a)
	system.register_belt(belt_b)

	# Add item to first belt
	belt_a.add_item(ItemData.ItemType.COAL)

	# Process enough time for item to transfer
	system.process_belts(1.0)  # 1 second at 1 item/sec

	# Item should now be on belt_b
	assert_false(belt_a.has_items(), "Source belt should be empty after transfer")
	assert_true(belt_b.has_items(), "Destination belt should have item after transfer")
	assert_eq(belt_b.items[0]["item_type"], ItemData.ItemType.COAL, "Transferred item should have correct type")

	system.free()


func test_item_chain_transfer_three_belts():
	var system = BeltSystem.new()

	var belt_a = BeltNode.new()
	var belt_b = BeltNode.new()
	var belt_c = BeltNode.new()

	belt_a.set_position(Vector2i(0, 0))
	belt_b.set_position(Vector2i(1, 0))
	belt_c.set_position(Vector2i(2, 0))

	belt_a.connect_to(belt_b)
	belt_b.connect_to(belt_c)

	system.register_belt(belt_a)
	system.register_belt(belt_b)
	system.register_belt(belt_c)

	belt_a.add_item(ItemData.ItemType.COAL)

	# First tick: item moves from A to B
	system.process_belts(1.0)
	assert_false(belt_a.has_items(), "Belt A should be empty")
	assert_true(belt_b.has_items(), "Belt B should have item")
	assert_false(belt_c.has_items(), "Belt C should still be empty")

	# Second tick: item moves from B to C
	system.process_belts(1.0)
	assert_false(belt_a.has_items(), "Belt A should be empty")
	assert_false(belt_b.has_items(), "Belt B should be empty")
	assert_true(belt_c.has_items(), "Belt C should have item")

	system.free()


func test_item_falls_off_end_of_belt():
	var system = BeltSystem.new()

	var belt = BeltNode.new()
	system.register_belt(belt)

	belt.add_item(ItemData.ItemType.COAL)

	# Process with no next belt - item should disappear
	system.process_belts(1.0)

	assert_false(belt.has_items(), "Item should fall off belt with no next")

	system.free()
