# Program Builder - Controls & Input

## Input Overview

Program Builder uses Godot's Input Action system. All controls are configurable via the Input Map in Project Settings.

## Movement Controls

| Action | Default Binding | Description |
|--------|-----------------|-------------|
| `move_left` | A, Left Arrow | Move player left |
| `move_right` | D, Right Arrow | Move player right |
| `jump` | Space, W, Up Arrow | Jump (when on ground) |

### Movement Details

- **Horizontal movement** is smooth with instant direction changes
- **Jump** only works when `is_on_floor()` returns true
- **No air control reduction** - full movement speed in air

## Interaction Controls

| Action | Default Binding | Description |
|--------|-----------------|-------------|
| `primary_action` | Left Mouse Button | Mine block at cursor |
| `secondary_action` | Right Mouse Button | Place block at cursor |

### Mining (Primary Action)

1. Point cursor at a block
2. Click left mouse button
3. Block is mined instantly if within range (5 tiles)
4. Drops are added to inventory

### Placement (Secondary Action)

1. Select a placeable item in hotbar
2. Point cursor at empty space (air)
3. Click right mouse button
4. Block is placed if within range (5 tiles)

## Hotbar Controls

| Action | Default Binding | Description |
|--------|-----------------|-------------|
| `hotbar_1` | 1 | Select hotbar slot 1 |
| `hotbar_2` | 2 | Select hotbar slot 2 |
| `hotbar_3` | 3 | Select hotbar slot 3 |
| `hotbar_4` | 4 | Select hotbar slot 4 |
| `hotbar_5` | 5 | Select hotbar slot 5 |
| `hotbar_6` | 6 | Select hotbar slot 6 |
| `hotbar_7` | 7 | Select hotbar slot 7 |
| `hotbar_8` | 8 | Select hotbar slot 8 |
| `hotbar_9` | 9 | Select hotbar slot 9 |

### Hotbar Behavior

- Current selection is visually highlighted
- Selected slot determines what item is placed
- Numbers 1-9 map to slots 0-8 internally

## UI Controls

| Action | Default Binding | Description |
|--------|-----------------|-------------|
| `toggle_inventory` | E, I | Open/close full inventory |
| `pause` | Escape | Pause menu |

## Mouse Controls

| Input | Description |
|-------|-------------|
| Mouse Position | Determines target location for mining/placement |
| Left Click | Primary action (mine) |
| Right Click | Secondary action (place) |
| Scroll Wheel | (Future: cycle hotbar selection) |

## Input Processing

### InputManager (`game/scripts/player/input_manager.gd`)

The InputManager centralizes input handling:

```gdscript
func _process(_delta: float) -> void:
    _handle_movement()      # WASD/Arrows
    _handle_hotbar_selection()  # Number keys 1-9
```

### Controller Delegation

Input is delegated to specialized controllers:

- **PlayerController** - Receives movement direction
- **MiningController** - Receives mine requests with world position
- **PlacementController** - Receives place requests with world position
- **HotbarUI** - Receives slot selection changes
- **InventoryUI** - Receives toggle requests

## Coordinate Conversion

### Screen to World

Mouse position is in screen coordinates. Controllers convert to tile coordinates:

```gdscript
func world_to_tile(screen_pos: Vector2) -> Vector2i:
    return Vector2i(
        int(floor(screen_pos.x / TILE_SIZE)),
        int(floor(-screen_pos.y / TILE_SIZE))  # Y negated
    )
```

### Why Y is Negated

- **Godot screen**: Y increases downward
- **Game world**: Y increases upward (altitude)
- **Conversion**: `world_y = -screen_y`

## Range Checking

Both mining and placement check distance from player:

```gdscript
const MINING_RANGE: float = 80.0  # 5 tiles × 16 pixels
const PLACEMENT_RANGE: float = 80.0

func is_in_range(world_position: Vector2) -> bool:
    return player_position.distance_to(world_position) <= MINING_RANGE
```

## Input Action Setup

To add or modify controls, edit Project Settings → Input Map:

### Required Actions

```
move_left      # Player movement
move_right
jump

primary_action    # Mouse interactions
secondary_action

hotbar_1 through hotbar_9  # Slot selection

toggle_inventory  # UI toggles
pause
```

### Example: Adding Move Left

1. Open Project → Project Settings → Input Map
2. Add action named `move_left`
3. Click + to add key
4. Press A key
5. Click + again, press Left Arrow

## Debugging Input

### Checking Input State

```gdscript
# In _process or _physics_process
if Input.is_action_pressed("move_left"):
    print("Moving left")

if Input.is_action_just_pressed("jump"):
    print("Jump pressed")
```

### Input Events

```gdscript
func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            print("Left click at: ", event.position)
```

## Future Controls

Planned additions:
- Scroll wheel for hotbar cycling
- Drag and drop in inventory
- Keyboard inventory navigation
- Controller/gamepad support
