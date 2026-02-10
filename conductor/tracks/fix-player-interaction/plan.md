# Implementation Plan: Fix Player Interaction

## Investigation

1.  **Check `project.godot`**: Verify that `jump`, `toggle_inventory`, `primary_action`, and `secondary_action` are defined in the Input Map.
2.  **Check `InputManager`**: Verify `game/scripts/player/input_manager.gd` is actually processing these inputs and calling the correct methods.
3.  **Check `PlayerController`**: Verify `jump()` logic checks `is_on_floor()` correctly (and that the player *is* on the floor).

## Proposed Tasks

| Task | Description |
|------|-------------|
| 1. Fix Input Map | Add missing actions to `project.godot` if they don't exist. |
| 2. Debug Input Flow | Add debug prints (or verify code) to ensure `InputManager` receives events. |
| 3. Verify Jump Logic | Ensure `PlayerController` physics allow jumping (gravity/floor check). |
| 4. Fix UI Interaction | Ensure `InventoryUI` is actually connected to the toggle input. |

## Execution Steps

1.  Read `project.godot` to check `[input]` section.
2.  Read `game/scripts/player/input_manager.gd`.
3.  Read `game/scripts/player/player_controller.gd`.
4.  Read `game/scripts/ui/inventory_ui.gd`.
5.  Apply fixes based on findings.
