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
    tile_world.set_block(5, 5, BlockData.BlockType.STONE)
    mining_controller.set_player_position(Vector2(80, 80))
    var mined = mining_controller.try_mine_at(Vector2(88, 88))
    assert_true(mined)
    assert_eq(tile_world.get_block(5, 5), BlockData.BlockType.AIR)
    assert_true(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1))

func test_full_placement_flow() -> void:
    inventory.add_item(ItemData.ItemType.DIRT, 5)
    placement_controller.set_selected_slot(0)
    placement_controller.set_player_position(Vector2(0, 0))
    tile_world.set_block(3, 3, BlockData.BlockType.AIR)
    var placed = placement_controller.try_place_at(Vector2(56, 56))
    assert_true(placed)
    assert_eq(tile_world.get_block(3, 3), BlockData.BlockType.DIRT)
    assert_eq(inventory.get_slot(0).count, 4)

func test_mine_then_place_cycle() -> void:
    tile_world.set_block(2, 2, BlockData.BlockType.STONE)
    mining_controller.set_player_position(Vector2(32, 32))
    placement_controller.set_player_position(Vector2(32, 32))
    placement_controller.set_selected_slot(0)
    mining_controller.try_mine_at(Vector2(40, 40))
    assert_eq(tile_world.get_block(2, 2), BlockData.BlockType.AIR)
    assert_true(inventory.has_item(ItemData.ItemType.COBBLESTONE, 1))
    tile_world.set_block(4, 4, BlockData.BlockType.AIR)
    var placed = placement_controller.try_place_at(Vector2(72, 72))
    assert_true(placed)
    assert_eq(tile_world.get_block(4, 4), BlockData.BlockType.COBBLESTONE)
