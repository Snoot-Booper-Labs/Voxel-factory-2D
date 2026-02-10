# Program Builder - Content Creation Guide

This guide explains how to add new content to the game.

## Adding a New Block

Blocks are defined in `game/scripts/world/block_data.gd`.

1.  **Add to Enum**: Add a new entry to `BlockType` enum.
    ```gdscript
    enum BlockType {
        ...
        MY_NEW_BLOCK = 15
    }
    ```

2.  **Define Properties**: Update helper methods in `BlockData`:
    - `get_block_name()`: Display name.
    - `is_solid()`: Collision (true/false).
    - `is_destructible()`: Can be mined?
    - `get_hardness()`: Time/tool tier to mine.
    - `get_block_drops()`: What item it drops.

3.  **Add Visuals**:
    - Update `game/resources/tiles/terrain_atlas.png`.
    - Update `game/resources/tiles/terrain_tileset.tres` to map the new block enum to the atlas coordinates.

## Adding a New Item

Items are defined in `game/scripts/data/item_data.gd`.

1.  **Add to Enum**: Add a new entry to `ItemType`.
    ```gdscript
    enum ItemType {
        ...
        MY_NEW_ITEM = 100
    }
    ```

2.  **Define Properties**: Update helper methods in `ItemData`:
    - `get_item_name()`: Display name.
    - `get_max_stack()`: Stack size (usually 64 for materials, 1 for tools).
    - `is_placeable()`: Can it be placed as a block?
    - `get_block_for_item()`: If placeable, which `BlockType`?

3.  **Add Icon**:
    - Add icon to `game/assets/icons/items/`.
    - Update `ItemData.get_icon_path()` (if implemented) or UI logic.

## Adding a New Entity

Entities are in `game/scripts/entities/`.

1.  **Create Class**: Create a new file `my_entity.gd` extending `Entity`.
    ```gdscript
    class_name MyEntity extends Entity

    func _init() -> void:
        super._init()
        # Add components
        add_component(Inventory.new(10))
    ```

2.  **Define Logic**:
    - If it needs per-frame logic, create a new System in `game/scripts/world/`.
    - Or add to an existing system (e.g. `BeltSystem` for transport).

## Adding a New Component

Components are in `game/scripts/components/`.

1.  **Create Class**: Create `my_component.gd` extending `Component`.
    ```gdscript
    class_name MyComponent extends Component

    var data_value: int = 0
    ```

2.  **Use it**: Add it to entities in their `_init()` or dynamically.
