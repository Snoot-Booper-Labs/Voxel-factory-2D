extends GutTest
## Integration Tests for Full Mining Flow
## Tests that all systems work together: world generation, mining, inventory, and belt transport

# =============================================================================
# Test 1: Full Mining Flow
# Create world, miner, program - execute mining - verify inventory has mined items
# =============================================================================

func test_full_mining_flow_basic():
	# Setup dimension system and world
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(12345)
	var world := dimension_system.get_active_dimension()

	# Set up a known block to mine underground
	var mine_x := 100
	var mine_y := 10
	world.set_block(mine_x, mine_y, BlockData.BlockType.STONE)

	# Create miner entity
	var miner := Miner.new()

	# Create mining program: START -> MINE -> END
	var start := CommandBlock.new(CommandBlock.BlockType.START)
	var mine := MineBlock.new()
	mine.set_parameter("x", mine_x)
	mine.set_parameter("y", mine_y)
	var end := CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(mine)
	mine.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(world)

	# Execute program until complete
	while miner.tick():
		pass

	# Verify block was mined (replaced with AIR)
	assert_eq(world.get_block(mine_x, mine_y), BlockData.BlockType.AIR,
		"Block should be mined to AIR")

	# Verify miner has item in inventory (stone drops cobblestone)
	var inventory := miner.get_inventory()
	assert_true(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Miner should have cobblestone after mining stone")

	# Cleanup
	miner.free()
	dimension_system.free()


func test_full_mining_flow_dirt():
	# Test mining dirt which drops dirt
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(99999)
	var world := dimension_system.get_active_dimension()

	var mine_x := 50
	var mine_y := 20
	world.set_block(mine_x, mine_y, BlockData.BlockType.DIRT)

	var miner := Miner.new()

	var start := CommandBlock.new(CommandBlock.BlockType.START)
	var mine := MineBlock.new()
	mine.set_parameter("x", mine_x)
	mine.set_parameter("y", mine_y)
	var end := CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(mine)
	mine.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(world)

	while miner.tick():
		pass

	assert_eq(world.get_block(mine_x, mine_y), BlockData.BlockType.AIR,
		"Dirt block should be mined to AIR")
	assert_true(miner.get_inventory().has_item(ItemData.ItemType.DIRT, 1),
		"Miner should have dirt after mining dirt block")

	miner.free()
	dimension_system.free()


func test_full_mining_flow_multiple_blocks():
	# Mine multiple blocks in sequence
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(54321)
	var world := dimension_system.get_active_dimension()

	# Set up multiple blocks
	world.set_block(10, 10, BlockData.BlockType.STONE)
	world.set_block(11, 10, BlockData.BlockType.DIRT)
	world.set_block(12, 10, BlockData.BlockType.SAND)

	var miner := Miner.new()

	# Create program to mine all three blocks
	var start := CommandBlock.new(CommandBlock.BlockType.START)
	var mine1 := MineBlock.new()
	mine1.set_parameter("x", 10)
	mine1.set_parameter("y", 10)
	var mine2 := MineBlock.new()
	mine2.set_parameter("x", 11)
	mine2.set_parameter("y", 10)
	var mine3 := MineBlock.new()
	mine3.set_parameter("x", 12)
	mine3.set_parameter("y", 10)
	var end := CommandBlock.new(CommandBlock.BlockType.END)

	start.connect_next(mine1)
	mine1.connect_next(mine2)
	mine2.connect_next(mine3)
	mine3.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(world)

	while miner.tick():
		pass

	# Verify all blocks mined
	assert_eq(world.get_block(10, 10), BlockData.BlockType.AIR, "First block should be AIR")
	assert_eq(world.get_block(11, 10), BlockData.BlockType.AIR, "Second block should be AIR")
	assert_eq(world.get_block(12, 10), BlockData.BlockType.AIR, "Third block should be AIR")

	# Verify inventory has all items
	var inventory := miner.get_inventory()
	assert_true(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1), "Should have cobblestone from stone")
	assert_true(inventory.has_item(ItemData.ItemType.DIRT, 1), "Should have dirt from dirt block")
	assert_true(inventory.has_item(ItemData.ItemType.SAND, 1), "Should have sand from sand block")

	miner.free()
	dimension_system.free()


# =============================================================================
# Test 2: Mining to Conveyor Flow
# Mine block, transfer to belt, verify belt transport works
# =============================================================================

func test_mining_to_conveyor_basic():
	# Setup world and mine a block
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(11111)
	var world := dimension_system.get_active_dimension()

	world.set_block(50, 15, BlockData.BlockType.STONE)

	# Create miner and execute mining program
	var miner := Miner.new()

	var start := CommandBlock.new(CommandBlock.BlockType.START)
	var mine := MineBlock.new()
	mine.set_parameter("x", 50)
	mine.set_parameter("y", 15)
	var end := CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(mine)
	mine.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(world)

	while miner.tick():
		pass

	# Verify miner has cobblestone
	var inventory := miner.get_inventory()
	assert_true(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Miner should have cobblestone after mining")

	# Create conveyor belt system
	var belt_system := BeltSystem.new()
	var belt_a := Conveyor.new(Vector2i(0, 0), BeltNode.Direction.RIGHT)
	var belt_b := Conveyor.new(Vector2i(1, 0), BeltNode.Direction.RIGHT)

	belt_a.get_belt().connect_to(belt_b.get_belt())
	belt_system.register_belt(belt_a.get_belt())
	belt_system.register_belt(belt_b.get_belt())

	# Transfer item from miner inventory to first belt
	var slot := inventory.get_slot(0)
	belt_a.add_item(slot["item"])
	inventory.remove_item(0, 1)

	# Verify transfer worked
	assert_true(belt_a.get_belt().has_items(), "Belt A should have item after transfer")
	assert_false(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Miner inventory should be empty after transfer")

	# Process belt - item moves to belt_b
	belt_system.process_belts(1.0)  # 1 second at 1 item/sec

	# Item should be on belt_b now
	assert_false(belt_a.get_belt().has_items(), "Belt A should be empty after processing")
	assert_true(belt_b.get_belt().has_items(), "Belt B should have item after processing")
	assert_eq(belt_b.get_belt().get_items()[0]["item_type"], ItemData.ItemType.COBBLESTONE,
		"Belt B should have cobblestone")

	# Cleanup
	miner.free()
	belt_a.free()
	belt_b.free()
	belt_system.free()
	dimension_system.free()


func test_mining_to_conveyor_chain():
	# Mine multiple items and transport through longer belt chain
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(22222)
	var world := dimension_system.get_active_dimension()

	world.set_block(100, 20, BlockData.BlockType.COAL_ORE)

	var miner := Miner.new()

	var start := CommandBlock.new(CommandBlock.BlockType.START)
	var mine := MineBlock.new()
	mine.set_parameter("x", 100)
	mine.set_parameter("y", 20)
	var end := CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(mine)
	mine.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(world)

	while miner.tick():
		pass

	# Verify coal was mined
	assert_true(miner.get_inventory().has_item(ItemData.ItemType.COAL, 1),
		"Should have coal from coal ore")

	# Create 3-belt chain
	var belt_system := BeltSystem.new()
	var belt_a := Conveyor.new(Vector2i(0, 0), BeltNode.Direction.RIGHT)
	var belt_b := Conveyor.new(Vector2i(1, 0), BeltNode.Direction.RIGHT)
	var belt_c := Conveyor.new(Vector2i(2, 0), BeltNode.Direction.RIGHT)

	belt_a.get_belt().connect_to(belt_b.get_belt())
	belt_b.get_belt().connect_to(belt_c.get_belt())
	belt_system.register_belt(belt_a.get_belt())
	belt_system.register_belt(belt_b.get_belt())
	belt_system.register_belt(belt_c.get_belt())

	# Transfer from miner to belt_a
	var slot := miner.get_inventory().get_slot(0)
	belt_a.add_item(slot["item"])
	miner.get_inventory().remove_item(0, 1)

	# Process twice to move through chain
	belt_system.process_belts(1.0)  # A -> B
	assert_true(belt_b.get_belt().has_items(), "Belt B should have item after first tick")

	belt_system.process_belts(1.0)  # B -> C
	assert_true(belt_c.get_belt().has_items(), "Belt C should have item after second tick")
	assert_false(belt_b.get_belt().has_items(), "Belt B should be empty after second tick")

	# Cleanup
	miner.free()
	belt_a.free()
	belt_b.free()
	belt_c.free()
	belt_system.free()
	dimension_system.free()


# =============================================================================
# Test 3: Multi-Dimension Mining
# Create overworld and pocket dimension, mine in both, verify items in each context
# =============================================================================

func test_multi_dimension_mining_overworld():
	# Mine in overworld
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(33333)

	var overworld := dimension_system.get_active_dimension()
	overworld.set_block(25, 25, BlockData.BlockType.IRON_ORE)

	var miner := Miner.new()

	var start := CommandBlock.new(CommandBlock.BlockType.START)
	var mine := MineBlock.new()
	mine.set_parameter("x", 25)
	mine.set_parameter("y", 25)
	var end := CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(mine)
	mine.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(overworld)

	while miner.tick():
		pass

	assert_true(miner.get_inventory().has_item(ItemData.ItemType.IRON_ORE, 1),
		"Should have iron ore from mining in overworld")
	assert_eq(overworld.get_block(25, 25), BlockData.BlockType.AIR,
		"Overworld block should be AIR after mining")

	miner.free()
	dimension_system.free()


func test_multi_dimension_mining_pocket():
	# Mine in pocket dimension
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(44444)

	var pocket_id := dimension_system.create_pocket_dimension()
	dimension_system.set_active_dimension(pocket_id)
	var pocket := dimension_system.get_active_dimension()

	pocket.set_block(30, 30, BlockData.BlockType.GOLD_ORE)

	var miner := Miner.new()

	var start := CommandBlock.new(CommandBlock.BlockType.START)
	var mine := MineBlock.new()
	mine.set_parameter("x", 30)
	mine.set_parameter("y", 30)
	var end := CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(mine)
	mine.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(pocket)

	while miner.tick():
		pass

	assert_true(miner.get_inventory().has_item(ItemData.ItemType.GOLD_ORE, 1),
		"Should have gold ore from mining in pocket dimension")
	assert_eq(pocket.get_block(30, 30), BlockData.BlockType.AIR,
		"Pocket dimension block should be AIR after mining")

	miner.free()
	dimension_system.free()


func test_multi_dimension_mining_both_dimensions():
	# Mine in both overworld and pocket dimension
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(55555)

	var overworld := dimension_system.get_active_dimension()
	overworld.set_block(40, 40, BlockData.BlockType.STONE)

	var pocket_id := dimension_system.create_pocket_dimension()
	var pocket := dimension_system.get_dimension(pocket_id)
	pocket.set_block(40, 40, BlockData.BlockType.DIAMOND_ORE)

	# Create two miners - one for each dimension
	var miner_overworld := Miner.new()
	var miner_pocket := Miner.new()

	# Program for overworld miner
	var start1 := CommandBlock.new(CommandBlock.BlockType.START)
	var mine1 := MineBlock.new()
	mine1.set_parameter("x", 40)
	mine1.set_parameter("y", 40)
	var end1 := CommandBlock.new(CommandBlock.BlockType.END)
	start1.connect_next(mine1)
	mine1.connect_next(end1)

	# Program for pocket miner
	var start2 := CommandBlock.new(CommandBlock.BlockType.START)
	var mine2 := MineBlock.new()
	mine2.set_parameter("x", 40)
	mine2.set_parameter("y", 40)
	var end2 := CommandBlock.new(CommandBlock.BlockType.END)
	start2.connect_next(mine2)
	mine2.connect_next(end2)

	# Execute overworld mining
	miner_overworld.set_mining_program(start1)
	miner_overworld.start_mining(overworld)
	while miner_overworld.tick():
		pass

	# Execute pocket dimension mining
	miner_pocket.set_mining_program(start2)
	miner_pocket.start_mining(pocket)
	while miner_pocket.tick():
		pass

	# Verify each miner has items from their respective dimension
	assert_true(miner_overworld.get_inventory().has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Overworld miner should have cobblestone from stone")
	assert_true(miner_pocket.get_inventory().has_item(ItemData.ItemType.DIAMOND, 1),
		"Pocket miner should have diamond from diamond ore")

	# Verify blocks are independent
	assert_eq(overworld.get_block(40, 40), BlockData.BlockType.AIR,
		"Overworld block should be AIR")
	assert_eq(pocket.get_block(40, 40), BlockData.BlockType.AIR,
		"Pocket block should be AIR")

	# Cleanup
	miner_overworld.free()
	miner_pocket.free()
	dimension_system.free()


func test_miner_persists_inventory_across_dimension_switch():
	# Miner keeps inventory when dimension changes
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(66666)

	var overworld := dimension_system.get_active_dimension()
	overworld.set_block(60, 60, BlockData.BlockType.COAL_ORE)

	var miner := Miner.new()

	var start := CommandBlock.new(CommandBlock.BlockType.START)
	var mine := MineBlock.new()
	mine.set_parameter("x", 60)
	mine.set_parameter("y", 60)
	var end := CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(mine)
	mine.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(overworld)

	while miner.tick():
		pass

	assert_true(miner.get_inventory().has_item(ItemData.ItemType.COAL, 1),
		"Miner should have coal before dimension switch")

	# Switch to pocket dimension
	var pocket_id := dimension_system.create_pocket_dimension()
	dimension_system.set_active_dimension(pocket_id)

	# Miner inventory should persist
	assert_true(miner.get_inventory().has_item(ItemData.ItemType.COAL, 1),
		"Miner should still have coal after dimension switch")

	# Switch back to overworld
	dimension_system.set_active_dimension(DimensionSystem.OVERWORLD)

	# Inventory still persists
	assert_true(miner.get_inventory().has_item(ItemData.ItemType.COAL, 1),
		"Miner should still have coal after switching back")

	miner.free()
	dimension_system.free()


# =============================================================================
# Test 4: Deterministic World Generation
# Same seed produces same blocks, different seeds produce different blocks
# =============================================================================

func test_deterministic_same_seed_same_blocks():
	# Two worlds with same seed should have identical blocks
	var world1 := TileWorld.new(12345)
	var world2 := TileWorld.new(12345)

	# Check multiple positions
	var positions := [
		Vector2i(0, 30),
		Vector2i(50, 25),
		Vector2i(100, 20),
		Vector2i(-50, 35),
		Vector2i(200, 15)
	]

	for pos in positions:
		assert_eq(world1.get_block(pos.x, pos.y), world2.get_block(pos.x, pos.y),
			"Same seed should produce same block at position %s" % str(pos))


func test_deterministic_different_seed_different_blocks():
	# Two worlds with different seeds should have different terrain
	var world1 := TileWorld.new(12345)
	var world2 := TileWorld.new(54321)

	var different_count := 0
	var total_checks := 20

	# Check multiple positions at surface level where terrain varies
	for i in range(total_checks):
		var x := i * 25
		var y := 30  # Surface area where terrain varies
		if world1.get_block(x, y) != world2.get_block(x, y):
			different_count += 1

	# Most blocks should be different (allow some same due to randomness)
	assert_gt(different_count, 0,
		"Different seeds should produce at least some different blocks")


func test_deterministic_dimension_system_seeds():
	# DimensionSystem should produce deterministic dimensions
	var system1 := DimensionSystem.new()
	var system2 := DimensionSystem.new()
	system1.setup(99999)
	system2.setup(99999)

	var world1 := system1.get_active_dimension()
	var world2 := system2.get_active_dimension()

	# Check multiple positions
	var positions := [
		Vector2i(0, 25),
		Vector2i(75, 30),
		Vector2i(150, 20)
	]

	for pos in positions:
		assert_eq(world1.get_block(pos.x, pos.y), world2.get_block(pos.x, pos.y),
			"Same seed dimension systems should produce same blocks at %s" % str(pos))

	system1.free()
	system2.free()


func test_deterministic_pocket_dimension_seeds():
	# Pocket dimensions should also be deterministic
	var system1 := DimensionSystem.new()
	var system2 := DimensionSystem.new()
	system1.setup(88888)
	system2.setup(88888)

	var pocket_id1 := system1.create_pocket_dimension()
	var pocket_id2 := system2.create_pocket_dimension()

	var pocket1 := system1.get_dimension(pocket_id1)
	var pocket2 := system2.get_dimension(pocket_id2)

	# Check multiple positions
	var positions := [
		Vector2i(10, 30),
		Vector2i(50, 25),
		Vector2i(100, 20)
	]

	for pos in positions:
		assert_eq(pocket1.get_block(pos.x, pos.y), pocket2.get_block(pos.x, pos.y),
			"Same seed pocket dimensions should produce same blocks at %s" % str(pos))

	system1.free()
	system2.free()


# =============================================================================
# Test 5: Full System Integration
# DimensionSystem + WorldSystem + Miner + Conveyor all working together
# =============================================================================

func test_full_system_integration():
	# Complete integration: dimension -> world -> miner mines -> belt transports
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(77777)

	var world := dimension_system.get_active_dimension()

	# Verify world was generated with terrain
	var surface_y := 30
	var has_terrain := false
	for x in range(0, 100, 10):
		var block := world.get_block(x, surface_y)
		if block != BlockData.BlockType.AIR:
			has_terrain = true
			break
	assert_true(has_terrain, "World should have generated terrain")

	# Set up a known block to mine
	world.set_block(75, 25, BlockData.BlockType.STONE)

	# Create miner
	var miner := Miner.new()
	assert_true(miner.has_component("Inventory"), "Miner should have Inventory")
	assert_true(miner.has_component("Program"), "Miner should have Program")

	# Create mining program
	var start := CommandBlock.new(CommandBlock.BlockType.START)
	var mine := MineBlock.new()
	mine.set_parameter("x", 75)
	mine.set_parameter("y", 25)
	var end := CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(mine)
	mine.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(world)

	# Execute program
	var tick_count := 0
	while miner.tick():
		tick_count += 1
		assert_lt(tick_count, 100, "Program should complete in reasonable ticks")

	# Verify mining worked
	assert_eq(world.get_block(75, 25), BlockData.BlockType.AIR,
		"Block should be mined")
	assert_true(miner.get_inventory().has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Miner should have mined item")

	# Create belt system
	var belt_system := BeltSystem.new()
	var belt_a := Conveyor.new(Vector2i(0, 0), BeltNode.Direction.RIGHT)
	var belt_b := Conveyor.new(Vector2i(1, 0), BeltNode.Direction.RIGHT)
	var belt_c := Conveyor.new(Vector2i(2, 0), BeltNode.Direction.RIGHT)

	belt_a.get_belt().connect_to(belt_b.get_belt())
	belt_b.get_belt().connect_to(belt_c.get_belt())
	belt_system.register_belt(belt_a.get_belt())
	belt_system.register_belt(belt_b.get_belt())
	belt_system.register_belt(belt_c.get_belt())

	# Transfer from miner to belt
	var slot := miner.get_inventory().get_slot(0)
	belt_a.add_item(slot["item"])
	miner.get_inventory().remove_item(0, 1)

	# Verify belt has item
	assert_true(belt_a.get_belt().has_items(), "Belt A should have item")

	# Process through belt chain
	belt_system.process_belts(1.0)
	assert_true(belt_b.get_belt().has_items(), "Item should move to Belt B")

	belt_system.process_belts(1.0)
	assert_true(belt_c.get_belt().has_items(), "Item should move to Belt C")
	assert_eq(belt_c.get_belt().get_items()[0]["item_type"], ItemData.ItemType.COBBLESTONE,
		"Final belt should have cobblestone")

	# Cleanup
	miner.free()
	belt_a.free()
	belt_b.free()
	belt_c.free()
	belt_system.free()
	dimension_system.free()


func test_full_integration_with_pocket_dimension():
	# Full integration spanning multiple dimensions
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(88888)

	# Create pocket dimension
	var pocket_id := dimension_system.create_pocket_dimension()
	assert_true(dimension_system.has_dimension(pocket_id),
		"Pocket dimension should exist")

	# Set up blocks in both dimensions
	var overworld := dimension_system.get_dimension(DimensionSystem.OVERWORLD)
	var pocket := dimension_system.get_dimension(pocket_id)

	overworld.set_block(80, 30, BlockData.BlockType.IRON_ORE)
	pocket.set_block(80, 30, BlockData.BlockType.DIAMOND_ORE)

	# Create belt system with two belts (MAX_ITEMS=1 per belt)
	var belt_system := BeltSystem.new()
	var belt_a := Conveyor.new(Vector2i(0, 0), BeltNode.Direction.RIGHT)
	var belt_b := Conveyor.new(Vector2i(1, 0), BeltNode.Direction.RIGHT)
	belt_a.get_belt().connect_to(belt_b.get_belt())
	belt_system.register_belt(belt_a.get_belt())
	belt_system.register_belt(belt_b.get_belt())

	# Mine in overworld
	var miner := Miner.new()
	var start1 := CommandBlock.new(CommandBlock.BlockType.START)
	var mine1 := MineBlock.new()
	mine1.set_parameter("x", 80)
	mine1.set_parameter("y", 30)
	var end1 := CommandBlock.new(CommandBlock.BlockType.END)
	start1.connect_next(mine1)
	mine1.connect_next(end1)

	miner.set_mining_program(start1)
	miner.start_mining(overworld)
	while miner.tick():
		pass

	# Transfer overworld item to belt_a
	var slot1 := miner.get_inventory().get_slot(0)
	belt_a.add_item(slot1["item"])
	miner.get_inventory().remove_item(0, 1)

	# Process so item moves from belt_a to belt_b, freeing belt_a
	belt_system.process_belts(1.0)
	assert_true(belt_b.get_belt().has_items(), "Belt B should have overworld item")
	assert_false(belt_a.get_belt().has_items(), "Belt A should be free after transfer")

	# Switch to pocket dimension
	dimension_system.set_active_dimension(pocket_id)
	assert_eq(dimension_system.active_dimension, pocket_id,
		"Should be in pocket dimension")

	# Mine in pocket dimension
	var start2 := CommandBlock.new(CommandBlock.BlockType.START)
	var mine2 := MineBlock.new()
	mine2.set_parameter("x", 80)
	mine2.set_parameter("y", 30)
	var end2 := CommandBlock.new(CommandBlock.BlockType.END)
	start2.connect_next(mine2)
	mine2.connect_next(end2)

	miner.set_mining_program(start2)
	miner.start_mining(pocket)
	while miner.tick():
		pass

	# Transfer pocket item to belt_a (now empty)
	var slot2 := miner.get_inventory().get_slot(0)
	belt_a.add_item(slot2["item"])
	miner.get_inventory().remove_item(0, 1)

	# Each belt should have one item from each dimension
	assert_true(belt_a.get_belt().has_items(), "Belt A should have pocket item")
	assert_true(belt_b.get_belt().has_items(), "Belt B should have overworld item")

	var item_a = belt_a.get_belt().get_items()[0]["item_type"]
	var item_b = belt_b.get_belt().get_items()[0]["item_type"]

	# belt_b got the overworld item (iron ore), belt_a has the pocket item (diamond)
	assert_eq(item_b, ItemData.ItemType.IRON_ORE, "Belt B should have iron ore from overworld")
	assert_eq(item_a, ItemData.ItemType.DIAMOND, "Belt A should have diamond from pocket dimension")

	# Cleanup
	miner.free()
	belt_a.free()
	belt_b.free()
	belt_system.free()
	dimension_system.free()


func test_multiple_miners_concurrent():
	# Multiple miners operating on same world
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(12321)
	var world := dimension_system.get_active_dimension()

	# Set up blocks for each miner
	world.set_block(10, 10, BlockData.BlockType.STONE)
	world.set_block(20, 10, BlockData.BlockType.DIRT)
	world.set_block(30, 10, BlockData.BlockType.SAND)

	# Create 3 miners
	var miner1 := Miner.new()
	var miner2 := Miner.new()
	var miner3 := Miner.new()

	# Create programs for each
	var start1 := CommandBlock.new(CommandBlock.BlockType.START)
	var mine1 := MineBlock.new()
	mine1.set_parameter("x", 10)
	mine1.set_parameter("y", 10)
	var end1 := CommandBlock.new(CommandBlock.BlockType.END)
	start1.connect_next(mine1)
	mine1.connect_next(end1)

	var start2 := CommandBlock.new(CommandBlock.BlockType.START)
	var mine2 := MineBlock.new()
	mine2.set_parameter("x", 20)
	mine2.set_parameter("y", 10)
	var end2 := CommandBlock.new(CommandBlock.BlockType.END)
	start2.connect_next(mine2)
	mine2.connect_next(end2)

	var start3 := CommandBlock.new(CommandBlock.BlockType.START)
	var mine3 := MineBlock.new()
	mine3.set_parameter("x", 30)
	mine3.set_parameter("y", 10)
	var end3 := CommandBlock.new(CommandBlock.BlockType.END)
	start3.connect_next(mine3)
	mine3.connect_next(end3)

	# Start all miners
	miner1.set_mining_program(start1)
	miner1.start_mining(world)
	miner2.set_mining_program(start2)
	miner2.start_mining(world)
	miner3.set_mining_program(start3)
	miner3.start_mining(world)

	# Execute all in parallel (simulated by interleaving ticks)
	var all_done := false
	var max_ticks := 100
	var tick := 0
	while not all_done and tick < max_ticks:
		var m1_running := miner1.tick()
		var m2_running := miner2.tick()
		var m3_running := miner3.tick()
		all_done = not (m1_running or m2_running or m3_running)
		tick += 1

	# Verify all blocks mined
	assert_eq(world.get_block(10, 10), BlockData.BlockType.AIR, "Block 1 should be mined")
	assert_eq(world.get_block(20, 10), BlockData.BlockType.AIR, "Block 2 should be mined")
	assert_eq(world.get_block(30, 10), BlockData.BlockType.AIR, "Block 3 should be mined")

	# Verify each miner has their respective item
	assert_true(miner1.get_inventory().has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Miner 1 should have cobblestone")
	assert_true(miner2.get_inventory().has_item(ItemData.ItemType.DIRT, 1),
		"Miner 2 should have dirt")
	assert_true(miner3.get_inventory().has_item(ItemData.ItemType.SAND, 1),
		"Miner 3 should have sand")

	# Cleanup
	miner1.free()
	miner2.free()
	miner3.free()
	dimension_system.free()


# =============================================================================
# Edge Cases and Error Handling
# =============================================================================

func test_mining_air_does_nothing():
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(10101)
	var world := dimension_system.get_active_dimension()

	# Explicitly set to AIR
	world.set_block(50, 100, BlockData.BlockType.AIR)

	var miner := Miner.new()

	var start := CommandBlock.new(CommandBlock.BlockType.START)
	var mine := MineBlock.new()
	mine.set_parameter("x", 50)
	mine.set_parameter("y", 100)
	var end := CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(mine)
	mine.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(world)

	while miner.tick():
		pass

	# Inventory should be empty
	assert_false(miner.get_inventory().has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Should not get items from mining air")
	assert_false(miner.get_inventory().has_item(ItemData.ItemType.DIRT, 1),
		"Should not get items from mining air")

	miner.free()
	dimension_system.free()


func test_belt_item_falls_off_end():
	# Item reaches end of belt chain with no next belt
	var belt_system := BeltSystem.new()
	var belt := Conveyor.new(Vector2i(0, 0), BeltNode.Direction.RIGHT)
	belt_system.register_belt(belt.get_belt())

	belt.add_item(ItemData.ItemType.COAL)
	assert_true(belt.get_belt().has_items(), "Belt should have item initially")

	belt_system.process_belts(1.0)

	assert_false(belt.get_belt().has_items(),
		"Item should fall off belt with no next connection")

	belt.free()
	belt_system.free()


func test_empty_program_completes_immediately():
	# Program with only START -> END completes without error
	var dimension_system := DimensionSystem.new()
	dimension_system.setup(20202)
	var world := dimension_system.get_active_dimension()

	var miner := Miner.new()

	var start := CommandBlock.new(CommandBlock.BlockType.START)
	var end := CommandBlock.new(CommandBlock.BlockType.END)
	start.connect_next(end)

	miner.set_mining_program(start)
	miner.start_mining(world)

	var tick_count := 0
	while miner.tick():
		tick_count += 1

	# Should complete in just 2 ticks (START, END)
	assert_lt(tick_count, 5, "Empty program should complete quickly")
	assert_false(miner.get_inventory().has_item(ItemData.ItemType.COBBLESTONE, 1),
		"Empty program should not mine anything")

	miner.free()
	dimension_system.free()
