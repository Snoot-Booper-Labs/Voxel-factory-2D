# Program Builder - API Reference

## Core Systems

### TileWorld
**File:** `game/scripts/world/tile_world.gd`

The central manager for the voxel world.

- `get_block(x: int, y: int) -> int`: Returns `BlockType` at coordinates. Generates chunk if missing.
- `set_block(x: int, y: int, type: int) -> void`: Sets block type. Emits `block_changed`.
- `block_changed(pos: Vector2i, old_type: int, new_type: int)`: Signal emitted on modification.

### Inventory
**File:** `game/scripts/components/inventory.gd`

Component for storing items.

- `add_item(type: int, count: int) -> int`: Adds items, returns overflow (unable to fit).
- `remove_item(slot_index: int, count: int) -> bool`: Removes count from slot.
- `get_slot(index: int) -> Slot`: Returns slot data `{item, count}`.
- `inventory_updated`: Signal emitted when content changes.

### Entity
**File:** `game/scripts/core/entity.gd`

Base class for game objects.

- `add_component(component: Component) -> void`: Attaches a component.
- `get_component(type_name: String) -> Component`: Retrieves attached component.
- `has_component(type_name: String) -> bool`: Checks existence.

## Player Controllers

### PlayerController
**File:** `game/scripts/player/player_controller.gd`

Handles physics movement.

- `velocity`: Current velocity vector.
- `is_on_floor()`: Godot physics check.

### MiningController
**File:** `game/scripts/player/mining_controller.gd`

Handles breaking blocks.

- `mine_block(world_pos: Vector2)`: Attempts to mine at position. Checks range and validity.

### PlacementController
**File:** `game/scripts/player/placement_controller.gd`

Handles placing blocks.

- `place_block(world_pos: Vector2, item_type: int)`: Attempts to place block. Checks range and collision.
