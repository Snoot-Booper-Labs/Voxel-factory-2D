extends GutTest
## Unit tests for the Save/Load system
##
## Tests TileWorld, Miner, Inventory, PlayerController serialization,
## EntitySaver dispatching, and SaveManager orchestration.


## Create a PlayerController with the required child nodes for testing.
## PlayerController._ready() expects a "PlayerSpriteAnimation2D" child.
func _create_test_player() -> PlayerController:
	var player = PlayerController.new()
	var sprite = AnimatedSprite2D.new()
	sprite.name = "PlayerSpriteAnimation2D"
	var frames = SpriteFrames.new()
	frames.add_animation("jump")
	frames.add_animation("run")
	frames.add_animation("walk")
	frames.add_animation("idle")
	sprite.sprite_frames = frames
	player.add_child(sprite)
	return player


# =============================================================================
# TileWorld Serialization Tests
# =============================================================================

func test_tile_world_tracks_modified_tiles():
	var world = TileWorld.new(42)
	# get_block only generates, doesn't mark as modified
	var _block = world.get_block(10, 20)

	var modified = world.get_modified_tiles()
	assert_eq(modified.size(), 0, "Generated tiles should not be tracked as modified")


func test_tile_world_tracks_set_block_as_modified():
	var world = TileWorld.new(42)
	world.set_block(5, 10, BlockData.BlockType.STONE)

	var modified = world.get_modified_tiles()
	assert_eq(modified.size(), 1, "set_block should track tile as modified")
	assert_true(modified.has("5,10"), "Modified tiles should use 'x,y' key format")
	assert_eq(modified["5,10"], BlockData.BlockType.STONE, "Modified tile value should match")


func test_tile_world_tracks_multiple_modifications():
	var world = TileWorld.new(42)
	world.set_block(0, 0, BlockData.BlockType.DIRT)
	world.set_block(1, 1, BlockData.BlockType.COBBLESTONE)
	world.set_block(-5, 3, BlockData.BlockType.AIR)

	var modified = world.get_modified_tiles()
	assert_eq(modified.size(), 3, "Should track all modified tiles")


func test_tile_world_overwrite_tracks_latest_value():
	var world = TileWorld.new(42)
	world.set_block(5, 5, BlockData.BlockType.STONE)
	world.set_block(5, 5, BlockData.BlockType.AIR)

	var modified = world.get_modified_tiles()
	assert_eq(modified.size(), 1, "Overwritten tile should still be one entry")
	assert_eq(modified["5,5"], BlockData.BlockType.AIR, "Should track latest value")


func test_tile_world_load_modified_tiles():
	var world = TileWorld.new(42)
	var data = {"10,20": BlockData.BlockType.DIAMOND_ORE, "-3,5": BlockData.BlockType.GOLD_ORE}

	world.load_modified_tiles(data)

	assert_eq(world.get_block(10, 20), BlockData.BlockType.DIAMOND_ORE, "Loaded tile should override generation")
	assert_eq(world.get_block(-3, 5), BlockData.BlockType.GOLD_ORE, "Loaded tile should override generation")


func test_tile_world_load_modified_tiles_roundtrip():
	var world1 = TileWorld.new(99)
	world1.set_block(0, 0, BlockData.BlockType.PLANKS)
	world1.set_block(100, -50, BlockData.BlockType.IRON_ORE)

	var saved = world1.get_modified_tiles()

	var world2 = TileWorld.new(99)
	world2.load_modified_tiles(saved)

	assert_eq(world2.get_block(0, 0), BlockData.BlockType.PLANKS, "Roundtrip should preserve block")
	assert_eq(world2.get_block(100, -50), BlockData.BlockType.IRON_ORE, "Roundtrip should preserve block")


func test_tile_world_load_ignores_malformed_keys():
	var world = TileWorld.new(42)
	var data = {"bad_key": 3, "10,20,30": 5, "": 1}

	# Should not crash
	world.load_modified_tiles(data)

	# Valid key should not be loaded since all keys are malformed
	var modified = world.get_modified_tiles()
	assert_eq(modified.size(), 0, "Malformed keys should be ignored")


func test_tile_world_serialize_includes_seed():
	var world = TileWorld.new(12345)
	var data = world.serialize()

	assert_true(data.has("seed"), "Serialized data should include seed")
	assert_eq(data["seed"], 12345, "Seed should match world seed")


func test_tile_world_serialize_includes_modified_tiles():
	var world = TileWorld.new(42)
	world.set_block(5, 10, BlockData.BlockType.STONE)

	var data = world.serialize()

	assert_true(data.has("modified_tiles"), "Serialized data should include modified_tiles")
	assert_eq(data["modified_tiles"].size(), 1, "Should have one modified tile")


func test_tile_world_serialize_empty_world():
	var world = TileWorld.new(42)
	var data = world.serialize()

	assert_eq(data["modified_tiles"].size(), 0, "Unmodified world should have no modified tiles")


func test_tile_world_deserialize_restores_seed():
	var world = TileWorld.new(999)
	world.set_block(0, 0, BlockData.BlockType.PLANKS)

	var data = world.serialize()
	var restored = TileWorld.deserialize(data)

	assert_eq(restored.world_seed, 999, "Deserialized world should have correct seed")


func test_tile_world_deserialize_restores_modified_tiles():
	var world = TileWorld.new(42)
	world.set_block(10, 20, BlockData.BlockType.DIAMOND_ORE)
	world.set_block(-5, 3, BlockData.BlockType.AIR)

	var data = world.serialize()
	var restored = TileWorld.deserialize(data)

	assert_eq(restored.get_block(10, 20), BlockData.BlockType.DIAMOND_ORE, "Should restore modified block")
	assert_eq(restored.get_block(-5, 3), BlockData.BlockType.AIR, "Should restore modified block")


func test_tile_world_deserialize_regenerates_unmodified():
	var world = TileWorld.new(42)
	# Only modify one block; others should regenerate
	world.set_block(0, 0, BlockData.BlockType.PLANKS)

	var data = world.serialize()
	var restored = TileWorld.deserialize(data)

	# Unmodified block should match procedural generation
	var expected = TileWorld.new(42)
	assert_eq(restored.get_block(100, 30), expected.get_block(100, 30),
		"Unmodified blocks should regenerate from seed")


func test_tile_world_roundtrip_preserves_generation():
	var original = TileWorld.new(42)
	var gen_block = original.get_block(50, 25)

	# Modify a different block
	original.set_block(0, 0, BlockData.BlockType.AIR)

	var data = original.serialize()
	var restored = TileWorld.deserialize(data)

	assert_eq(restored.get_block(50, 25), gen_block,
		"Procedurally generated blocks should match after roundtrip")


# =============================================================================
# Miner Serialize/Deserialize Tests
# =============================================================================

func test_miner_serialize():
	var miner = Miner.new()
	miner.position = Vector2(100.0, -200.0)
	miner.direction = Vector2i.RIGHT

	var data = miner.serialize()

	assert_eq(data["type"], "Miner", "Serialized type should be Miner")
	assert_eq(data["position"]["x"], 100.0, "Should serialize X position")
	assert_eq(data["position"]["y"], -200.0, "Should serialize Y position")
	assert_eq(data["direction"]["x"], 1, "Should serialize direction X")
	assert_eq(data["direction"]["y"], 0, "Should serialize direction Y")
	miner.free()


func test_miner_serialize_inventory():
	var miner = Miner.new()
	miner.get_inventory().add_item(ItemData.ItemType.COAL, 10)
	miner.get_inventory().add_item(ItemData.ItemType.IRON_ORE, 5)

	var data = miner.serialize()

	assert_true(data.has("inventory"), "Should include inventory")
	var inv: Array = data["inventory"]
	assert_eq(inv.size(), 2, "Sparse format should only include non-empty slots")

	# First entry should be slot 0 with coal
	assert_eq(inv[0]["slot"], 0, "First entry should be slot 0")
	assert_eq(inv[0]["item"], ItemData.ItemType.COAL, "First slot should be coal")
	assert_eq(inv[0]["count"], 10, "First slot count should be 10")

	# Second entry should be slot 1 with iron ore
	assert_eq(inv[1]["slot"], 1, "Second entry should be slot 1")
	assert_eq(inv[1]["item"], ItemData.ItemType.IRON_ORE, "Second slot should be iron ore")
	assert_eq(inv[1]["count"], 5, "Second slot count should be 5")
	miner.free()


func test_miner_serialize_state():
	var miner = Miner.new()
	miner._state = Miner.State.MINING

	var data = miner.serialize()

	assert_eq(data["state"], Miner.State.MINING, "Should serialize miner state")
	miner.free()


func test_miner_serialize_left_direction():
	var miner = Miner.new()
	miner.direction = Vector2i.LEFT

	var data = miner.serialize()

	assert_eq(data["direction"]["x"], -1, "Should serialize LEFT direction X as -1")
	assert_eq(data["direction"]["y"], 0, "Should serialize LEFT direction Y as 0")
	miner.free()


func test_miner_deserialize_restores_state():
	var miner = Miner.new()
	miner._state = Miner.State.IDLE

	miner.deserialize({"state": Miner.State.MINING, "inventory": []})

	assert_eq(miner._state, Miner.State.MINING, "Deserialize should restore state")
	miner.free()


func test_miner_deserialize_restores_inventory():
	var miner = Miner.new()

	miner.deserialize({
		"state": Miner.State.IDLE,
		"inventory": [{"slot": 0, "item": ItemData.ItemType.COAL, "count": 25}],
	})

	var slot = miner.get_inventory().get_slot(0)
	assert_eq(slot.item, ItemData.ItemType.COAL, "Deserialize should restore inventory item")
	assert_eq(slot.count, 25, "Deserialize should restore inventory count")
	miner.free()


func test_miner_serialize_roundtrip():
	var miner = Miner.new()
	miner.position = Vector2(50.0, -100.0)
	miner.direction = Vector2i.LEFT
	miner._state = Miner.State.MINING
	miner.get_inventory().add_item(ItemData.ItemType.IRON_ORE, 15)

	var data = miner.serialize()

	# Create a fresh miner and deserialize
	var restored = Miner.new()
	restored.position = Vector2(
		float(data["position"]["x"]),
		float(data["position"]["y"])
	)
	restored.direction = Vector2i(
		int(data["direction"]["x"]),
		int(data["direction"]["y"])
	)
	restored.deserialize(data)

	assert_eq(restored.position, miner.position, "Position should roundtrip")
	assert_eq(restored.direction, miner.direction, "Direction should roundtrip")
	assert_eq(restored._state, Miner.State.MINING, "State should roundtrip")
	var slot = restored.get_inventory().get_slot(0)
	assert_eq(slot.item, ItemData.ItemType.IRON_ORE, "Inventory item should roundtrip")
	assert_eq(slot.count, 15, "Inventory count should roundtrip")

	miner.free()
	restored.free()


# =============================================================================
# EntitySaver Dispatch Tests
# =============================================================================

func test_entity_saver_serialize_all_delegates_to_miner():
	# EntitySaver.serialize_all should call miner.serialize() for each miner
	var miner = Miner.new()
	miner.position = Vector2(100.0, -200.0)
	miner.direction = Vector2i.RIGHT
	add_child(miner)

	var entities = EntitySaver.serialize_all(get_tree())

	assert_eq(entities.size(), 1, "Should serialize one miner")
	assert_eq(entities[0]["type"], "Miner", "Should delegate to miner.serialize()")
	assert_eq(entities[0]["position"]["x"], 100.0, "Should have miner's position")

	miner.queue_free()


# =============================================================================
# PlayerController Serialize/Deserialize Tests
# =============================================================================

func test_player_controller_serialize():
	var player = PlayerController.new()
	player.position = Vector2(160.0, -320.0)

	var data = player.serialize()

	assert_true(data.has("position"), "Should include position")
	assert_eq(data["position"]["x"], 160.0, "Should serialize X position")
	assert_eq(data["position"]["y"], -320.0, "Should serialize Y position")
	player.free()


func test_player_controller_deserialize():
	var player = PlayerController.new()
	player.position = Vector2.ZERO

	player.deserialize({"position": {"x": 200.0, "y": -400.0}})

	assert_eq(player.position, Vector2(200.0, -400.0), "Should restore position")
	player.free()


func test_player_controller_deserialize_missing_position():
	var player = PlayerController.new()
	player.position = Vector2(100.0, 50.0)

	player.deserialize({})

	# Position should remain unchanged when no position data provided
	assert_eq(player.position, Vector2(100.0, 50.0), "Should not change position if data missing")
	player.free()


func test_player_controller_serialize_roundtrip():
	var player = PlayerController.new()
	player.position = Vector2(333.0, -666.0)

	var data = player.serialize()

	var restored = PlayerController.new()
	restored.deserialize(data)

	assert_eq(restored.position, player.position, "Position should roundtrip")
	player.free()
	restored.free()


# =============================================================================
# SaveManager Tests
# =============================================================================

func test_save_manager_class_exists():
	var manager = SaveManager.new()
	assert_not_null(manager, "SaveManager class should exist")
	manager.free()


func test_save_manager_has_save_version():
	assert_eq(SaveManager.SAVE_VERSION, "0.1.0", "Save version should be 0.1.0")


func test_save_manager_has_default_save_file():
	assert_eq(SaveManager.DEFAULT_SAVE_FILE, "save.json", "Default save file should be save.json")


func test_save_manager_auto_save_interval():
	assert_eq(SaveManager.AUTO_SAVE_INTERVAL, 300.0, "Auto-save interval should be 300 seconds")


func test_save_manager_save_fails_without_refs():
	var manager = SaveManager.new()
	add_child(manager)

	var result = manager.save_game("test_no_refs.json")
	assert_false(result, "Save should fail without game references")

	manager.queue_free()


func test_save_manager_save_and_load_roundtrip():
	var manager = SaveManager.new()
	add_child(manager)

	# Setup game state
	var world = TileWorld.new(42)
	world.set_block(5, 10, BlockData.BlockType.STONE)

	var inv = Inventory.new()
	inv.add_item(ItemData.ItemType.COAL, 20)

	var player_node = _create_test_player()
	player_node.position = Vector2(160.0, -320.0)
	add_child(player_node)

	manager.tile_world = world
	manager.player_inventory = inv
	manager.player_node = player_node
	manager.scene_tree = get_tree()

	# Save
	var save_result = manager.save_game("test_roundtrip.json")
	assert_true(save_result, "Save should succeed")

	# Verify file exists
	assert_true(manager.has_save("test_roundtrip.json"), "Save file should exist")

	# Load
	var data = manager.load_game("test_roundtrip.json")
	assert_false(data.is_empty(), "Loaded data should not be empty")
	assert_eq(data["version"], "0.1.0", "Version should match")

	# Verify world data
	assert_eq(data["world"]["seed"], 42, "World seed should be preserved")

	# Verify player data
	assert_eq(data["player"]["position"]["x"], 160.0, "Player X should be preserved")
	assert_eq(data["player"]["position"]["y"], -320.0, "Player Y should be preserved")

	# Verify inventory (sparse format - only non-empty slots)
	var inv_slots: Array = data["player"]["inventory"]
	assert_eq(inv_slots.size(), 1, "Sparse inventory should have 1 non-empty slot")
	assert_eq(inv_slots[0]["slot"], 0, "First entry should be slot 0")
	assert_eq(inv_slots[0]["item"], ItemData.ItemType.COAL, "Inventory item should be preserved")
	assert_eq(inv_slots[0]["count"], 20, "Inventory count should be preserved")

	# Cleanup
	manager.delete_save("test_roundtrip.json")
	player_node.queue_free()
	manager.queue_free()


func test_save_manager_load_nonexistent_file():
	var manager = SaveManager.new()
	add_child(manager)

	var data = manager.load_game("nonexistent_save.json")
	assert_true(data.is_empty(), "Loading nonexistent file should return empty dict")

	manager.queue_free()


func test_save_manager_has_save_returns_false_for_missing():
	var manager = SaveManager.new()
	add_child(manager)

	assert_false(manager.has_save("definitely_missing.json"), "has_save should return false for missing file")

	manager.queue_free()


func test_save_manager_delete_save():
	var manager = SaveManager.new()
	add_child(manager)

	# Setup minimal state
	var world = TileWorld.new(1)
	var inv = Inventory.new()
	var player_node = _create_test_player()
	add_child(player_node)

	manager.tile_world = world
	manager.player_inventory = inv
	manager.player_node = player_node
	manager.scene_tree = get_tree()

	# Save then delete
	manager.save_game("test_delete.json")
	assert_true(manager.has_save("test_delete.json"), "File should exist after save")

	var deleted = manager.delete_save("test_delete.json")
	assert_true(deleted, "delete_save should return true")
	assert_false(manager.has_save("test_delete.json"), "File should not exist after delete")

	player_node.queue_free()
	manager.queue_free()


func test_save_manager_save_includes_timestamp():
	var manager = SaveManager.new()
	add_child(manager)

	var world = TileWorld.new(1)
	var inv = Inventory.new()
	var player_node = _create_test_player()
	add_child(player_node)

	manager.tile_world = world
	manager.player_inventory = inv
	manager.player_node = player_node
	manager.scene_tree = get_tree()

	manager.save_game("test_timestamp.json")
	var data = manager.load_game("test_timestamp.json")

	assert_true(data.has("timestamp"), "Save data should include timestamp")
	assert_true(data["timestamp"] > 0, "Timestamp should be positive")

	manager.delete_save("test_timestamp.json")
	player_node.queue_free()
	manager.queue_free()


func test_save_manager_save_includes_entities_array():
	var manager = SaveManager.new()
	add_child(manager)

	var world = TileWorld.new(1)
	var inv = Inventory.new()
	var player_node = _create_test_player()
	add_child(player_node)

	manager.tile_world = world
	manager.player_inventory = inv
	manager.player_node = player_node
	manager.scene_tree = get_tree()

	manager.save_game("test_entities.json")
	var data = manager.load_game("test_entities.json")

	assert_true(data.has("entities"), "Save data should include entities array")
	assert_true(data["entities"] is Array, "Entities should be an array")

	manager.delete_save("test_entities.json")
	player_node.queue_free()
	manager.queue_free()


# =============================================================================
# Inventory Serialize/Deserialize Tests
# =============================================================================

func test_inventory_serialize_empty():
	var inv = Inventory.new()
	var data = inv.serialize()
	assert_eq(data.size(), 0, "Empty inventory should serialize to empty array")


func test_inventory_serialize_sparse_format():
	var inv = Inventory.new()
	inv.add_item(ItemData.ItemType.COAL, 10)

	var data = inv.serialize()
	assert_eq(data.size(), 1, "Should only include non-empty slots")
	assert_eq(data[0]["slot"], 0, "Should include slot index")
	assert_eq(data[0]["item"], ItemData.ItemType.COAL, "Should include item type")
	assert_eq(data[0]["count"], 10, "Should include count")


func test_inventory_serialize_multiple_items():
	var inv = Inventory.new()
	inv.add_item(ItemData.ItemType.COAL, 64)
	inv.add_item(ItemData.ItemType.IRON_ORE, 32)
	inv.set_slot(10, ItemData.ItemType.DIAMOND, 5)

	var data = inv.serialize()
	assert_eq(data.size(), 3, "Should have 3 non-empty slots")

	# Verify slot indices are correct
	assert_eq(data[0]["slot"], 0, "First entry at slot 0")
	assert_eq(data[1]["slot"], 1, "Second entry at slot 1")
	assert_eq(data[2]["slot"], 10, "Third entry at slot 10")


func test_inventory_deserialize_clears_existing():
	var inv = Inventory.new()
	inv.add_item(ItemData.ItemType.COAL, 50)

	# Deserialize with different data
	inv.deserialize([{"slot": 5, "item": ItemData.ItemType.DIAMOND, "count": 3}])

	# Slot 0 should be cleared
	var slot0 = inv.get_slot(0)
	assert_eq(slot0.item, Inventory.NONE, "Old data should be cleared")

	# Slot 5 should have new data
	var slot5 = inv.get_slot(5)
	assert_eq(slot5.item, ItemData.ItemType.DIAMOND, "New data should be restored")
	assert_eq(slot5.count, 3, "New count should be restored")


func test_inventory_deserialize_ignores_invalid_entries():
	var inv = Inventory.new()
	# Mix of valid and invalid entries
	inv.deserialize([
		{"slot": 0, "item": ItemData.ItemType.COAL, "count": 10},
		{"bad": "data"},
		{"slot": -1, "item": 1, "count": 5},
		{"slot": 999, "item": 1, "count": 5},
	])

	# Only slot 0 should be set
	var slot0 = inv.get_slot(0)
	assert_eq(slot0.item, ItemData.ItemType.COAL, "Valid entry should be applied")
	assert_eq(slot0.count, 10, "Valid count should be applied")

	# Others should remain empty
	var slot1 = inv.get_slot(1)
	assert_eq(slot1.item, Inventory.NONE, "Invalid entries should be ignored")


func test_inventory_deserialize_empty_array():
	var inv = Inventory.new()
	inv.add_item(ItemData.ItemType.COAL, 10)

	inv.deserialize([])

	# All slots should be cleared
	var slot0 = inv.get_slot(0)
	assert_eq(slot0.item, Inventory.NONE, "Deserializing empty array should clear inventory")


# =============================================================================
# Full Integration-style Roundtrip
# =============================================================================

func test_full_world_save_load_preserves_modifications():
	# Simulate a play session with modifications
	var world = TileWorld.new(42)

	# Mine some blocks (set to AIR)
	world.set_block(5, 30, BlockData.BlockType.AIR)
	world.set_block(6, 30, BlockData.BlockType.AIR)
	world.set_block(7, 30, BlockData.BlockType.AIR)

	# Place some blocks
	world.set_block(10, 50, BlockData.BlockType.COBBLESTONE)
	world.set_block(11, 50, BlockData.BlockType.PLANKS)

	# Serialize
	var data = world.serialize()

	# Deserialize into new world
	var restored = TileWorld.deserialize(data)

	# Verify mined blocks are still AIR
	assert_eq(restored.get_block(5, 30), BlockData.BlockType.AIR, "Mined block should stay AIR")
	assert_eq(restored.get_block(6, 30), BlockData.BlockType.AIR, "Mined block should stay AIR")
	assert_eq(restored.get_block(7, 30), BlockData.BlockType.AIR, "Mined block should stay AIR")

	# Verify placed blocks
	assert_eq(restored.get_block(10, 50), BlockData.BlockType.COBBLESTONE, "Placed block should persist")
	assert_eq(restored.get_block(11, 50), BlockData.BlockType.PLANKS, "Placed block should persist")

	# Verify unmodified terrain regenerates identically
	var fresh = TileWorld.new(42)
	for x in range(-10, 10):
		for y in range(0, 40):
			if Vector2i(x, y) not in [Vector2i(5, 30), Vector2i(6, 30), Vector2i(7, 30),
									   Vector2i(10, 50), Vector2i(11, 50)]:
				assert_eq(restored.get_block(x, y), fresh.get_block(x, y),
					"Unmodified block at (%d,%d) should match fresh generation" % [x, y])


func test_inventory_roundtrip_preserves_all_slots():
	var inv = Inventory.new()
	inv.add_item(ItemData.ItemType.COAL, 64)
	inv.add_item(ItemData.ItemType.IRON_ORE, 32)
	inv.add_item(ItemData.ItemType.DIAMOND, 1)

	# Serialize using Inventory's own method
	var data = inv.serialize()

	# Deserialize into new inventory
	var restored = Inventory.new()
	restored.deserialize(data)

	# Verify all slots match
	for i in range(inv.size):
		var original_slot = inv.get_slot(i)
		var restored_slot = restored.get_slot(i)
		assert_eq(restored_slot.item, original_slot.item,
			"Slot %d item should match after roundtrip" % i)
		assert_eq(restored_slot.count, original_slot.count,
			"Slot %d count should match after roundtrip" % i)


func test_save_data_format_matches_spec():
	# Verify the JSON structure matches the issue specification
	var manager = SaveManager.new()
	add_child(manager)

	var world = TileWorld.new(12345)
	world.set_block(0, 0, BlockData.BlockType.STONE)

	var inv = Inventory.new()
	inv.add_item(ItemData.ItemType.MINER, 1)

	var player_node = _create_test_player()
	player_node.position = Vector2(100.0, 50.0)
	add_child(player_node)

	manager.tile_world = world
	manager.player_inventory = inv
	manager.player_node = player_node
	manager.scene_tree = get_tree()

	manager.save_game("test_format.json")
	var data = manager.load_game("test_format.json")

	# Verify top-level keys per spec
	assert_true(data.has("version"), "Should have 'version' key")
	assert_true(data.has("world"), "Should have 'world' key")
	assert_true(data.has("player"), "Should have 'player' key")
	assert_true(data.has("entities"), "Should have 'entities' key")

	# Verify world structure
	assert_true(data["world"].has("seed"), "World should have 'seed'")

	# Verify player structure
	assert_true(data["player"].has("position"), "Player should have 'position'")
	assert_true(data["player"]["position"].has("x"), "Position should have 'x'")
	assert_true(data["player"]["position"].has("y"), "Position should have 'y'")
	assert_true(data["player"].has("inventory"), "Player should have 'inventory'")

	manager.delete_save("test_format.json")
	player_node.queue_free()
	manager.queue_free()
