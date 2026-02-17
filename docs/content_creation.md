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
    - Add icon to the item icon atlas at `game/resources/icons/items/item_icon_atlas.png`.
    - Register the icon position in `SpriteDB._icon_positions` in `game/scripts/data/sprite_db.gd`.

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

## Adding New Sprites

Sprites are managed by `SpriteDB` (`game/scripts/data/sprite_db.gd`) and stored as PNG sprite sheets in `game/resources/`.

### Zero-Code Art Swap

All sprites are designed for drop-in replacement. To swap any sprite, replace its PNG file with a same-dimension image — no code changes required.

### Item Icons

Item icons live in `game/resources/icons/items/item_icon_atlas.png` (8 columns × 4 rows, 16×16px per cell).

1. **Edit the atlas PNG**: Add your icon to an empty cell or replace an existing one.
2. **Register in SpriteDB**: Add/update the mapping in `SpriteDB._icon_positions`:
   ```gdscript
   ItemData.ItemType.MY_ITEM: Vector2i(column, row),
   ```
3. **No other changes needed** — `SpriteDB.get_item_icon()` will return the correct `AtlasTexture`.

### Entity Sprites

Entity sprite sheets are in `game/resources/sprites/entities/`:
- `miner_idle.png` — 4 frames × 16×16
- `miner_walk.png` — 4 frames × 16×16
- `conveyor.png` — 4 frames × 16×16
- `item_entity.png` — 1 frame, 16×16

To add a new entity sprite:
1. Create a horizontal strip PNG (N frames × 16px wide, 16px tall).
2. Add the path to `SpriteDB.ENTITY_SPRITES`.
3. Load it in your entity script via `SpriteDB.get_entity_sprite("key")`.

### Terrain Tiles

The terrain atlas is at `game/resources/tiles/terrain_atlas.png` (15 tiles × 16px horizontal strip). Each tile index maps to a `BlockData.BlockType` enum value. Update the atlas and tileset together.
