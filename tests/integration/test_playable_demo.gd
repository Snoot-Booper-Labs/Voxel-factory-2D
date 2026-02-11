extends GutTest

var tile_world: TileWorld
var inventory: Inventory
var mining_controller: MiningController
var placement_controller: PlacementController

func before_each() -> void:
    tile_world = TileWorld.new(12345)
    inventory = Inventory.new()
    mining_controller = MiningController.new()
    placement_controller = PlacementController.new()
    mining_controller.setup(tile_world, inventory)
    placement_controller.setup(tile_world, inventory)
    add_child(mining_controller)
    add_child(placement_controller)

func after_each() -> void:
    mining_controller.queue_free()
    placement_controller.queue_free()

func test_full_mining_flow() -> void:
    # Set block at world tile (5, 5)
    tile_world.set_block(5, 5, BlockData.BlockType.STONE)
    # Screen coords: X=80 -> tile X=5, Y=-80 -> tile Y=5 (negated)
    mining_controller.set_player_position(Vector2(80, -80))
    var mined = mining_controller.try_mine_at(Vector2(88, -72))
    assert_true(mined)
    assert_eq(tile_world.get_block(5, 5), BlockData.BlockType.AIR)
    assert_true(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1))

func test_full_placement_flow() -> void:
    inventory.add_item(ItemData.ItemType.DIRT, 5)
    placement_controller.set_selected_slot(0)
    placement_controller.set_player_position(Vector2(0, 0))
    # Set AIR at world tile (3, 3)
    tile_world.set_block(3, 3, BlockData.BlockType.AIR)
    # Screen coords: X=56 -> tile X=3, Y=-40 -> tile Y=3
    var placed = placement_controller.try_place_at(Vector2(56, -40))
    assert_true(placed)
    assert_eq(tile_world.get_block(3, 3), BlockData.BlockType.DIRT)
    assert_eq(inventory.get_slot(0).count, 4)

func test_mine_then_place_cycle() -> void:
    # Set block at world tile (2, 2)
    tile_world.set_block(2, 2, BlockData.BlockType.STONE)
    # Screen coords: X=32 -> tile X=2, Y=-32 -> tile Y=2 (negated)
    mining_controller.set_player_position(Vector2(32, -32))
    placement_controller.set_player_position(Vector2(32, -32))
    placement_controller.set_selected_slot(0)
    # Mine at screen (40, -24) -> tile (2, 2)
    mining_controller.try_mine_at(Vector2(40, -24))
    assert_eq(tile_world.get_block(2, 2), BlockData.BlockType.AIR)
    assert_true(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1))
    # Place at world tile (4, 4)
    tile_world.set_block(4, 4, BlockData.BlockType.AIR)
    # Screen coords: X=72 -> tile X=4, Y=-56 -> tile Y=4
    var placed = placement_controller.try_place_at(Vector2(72, -56))
    assert_true(placed)
    assert_eq(tile_world.get_block(4, 4), BlockData.BlockType.COBBLESTONE)
