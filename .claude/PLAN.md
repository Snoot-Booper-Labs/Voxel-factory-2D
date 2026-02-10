# Implementation Plan: Playable Demo - UI/Scene Layer

> **For Claude:** REQUIRED SUB-SKILL: Invoke `Skill(skill="workflows:dev-implement")` to implement this plan.
>
> **Per-Task Ralph Loops:** Assign each task its OWN ralph loop. Do NOT combine multiple tasks into one loop.
>
> **Delegation:** Main chat orchestrates, Task agents implement. Use `Skill(skill="workflows:dev-delegate")` for subagent templates.

## Chosen Approach

**Scene-First with ECS Bridge**: Create Godot scenes (.tscn) that bridge to existing ECS foundation via signals. This leverages Godot's built-in systems (TileMapLayer, CharacterBody2D) while keeping business logic in the tested ECS layer.

## Rationale

- User selected this approach for balance of Godot idioms + ECS integration
- Existing ECS foundation (353 tests) provides solid business logic
- Scene-first approach means faster visual results
- Signal-based bridging keeps clean separation between presentation and logic
- TileMapLayer syncs to TileWorld via `block_changed` signal
- UI syncs to Inventory via `inventory_updated` signal

## Architecture Overview

```
Godot Scenes (Visual)           ECS Foundation (Logic)
─────────────────────────────────────────────────────────
Main.tscn
├── WorldRenderer               ← TileWorld.block_changed
│   └── TileMapLayer
├── Player.tscn                 ← Entity with Inventory
│   ├── CharacterBody2D
│   └── Sprite2D
└── UI/
    ├── HotbarUI                ← Inventory.inventory_updated
    └── InventoryUI
```

## Files to Create

| File | Purpose |
|------|---------|
| `game/resources/tiles/terrain_tileset.tres` | TileSet resource with block visuals |
| `game/scripts/rendering/world_renderer.gd` | Bridges TileWorld to TileMapLayer |
| `game/scenes/main.tscn` | Main game scene |
| `game/scripts/player/player_controller.gd` | CharacterBody2D movement + gravity |
| `game/scenes/player.tscn` | Player scene with physics |
| `game/scripts/player/mining_controller.gd` | Click-to-mine interaction |
| `game/scripts/player/placement_controller.gd` | Click-to-place blocks |
| `game/scripts/ui/hotbar_ui.gd` | 9-slot hotbar display |
| `game/scenes/ui/hotbar.tscn` | Hotbar scene |
| `game/scripts/ui/inventory_ui.gd` | Full inventory grid |
| `game/scenes/ui/inventory.tscn` | Inventory panel scene |
| `game/scripts/player/input_manager.gd` | Central input handling |

## Files to Modify

| File | Change |
|------|--------|
| `project.godot` | Set main scene, input actions |

## Implementation Order (with Per-Task Ralph Loops)

> **For Claude:** Each task = one ralph loop. Complete task N before starting task N+1.
>
> Pattern: `Skill(skill="workflows:dev-ralph-loop", args="Task N: [name] --max-iterations 10 --completion-promise TASKN_DONE")`

| Task | Ralph Loop | Core Test (MUST EXECUTE CODE) | Verify Command |
|------|------------|-------------------------------|----------------|
| 1. TileSet Resource | `"Task 1: TileSet Resource" → TASK1_DONE` | Create terrain_tileset.tres with placeholder tiles for each BlockType | Manual: Open in Godot editor |
| 2. WorldRenderer + TileMapLayer | `"Task 2: WorldRenderer" → TASK2_DONE` | `test_world_renderer.gd` creates renderer, sets block, verifies tile_map updated | `godot --headless -s addons/gut/gut_cmdln.gd -gtest=test_world_renderer.gd` |
| 3. Main Scene Structure | `"Task 3: Main Scene" → TASK3_DONE` | Create main.tscn with WorldRenderer child, set as project main scene | `godot --headless --quit` (exits cleanly = scene valid) |
| 4. PlayerController Movement | `"Task 4: PlayerController" → TASK4_DONE` | `test_player_controller.gd` creates player, applies input, checks velocity/position | `godot --headless -s addons/gut/gut_cmdln.gd -gtest=test_player_controller.gd` |
| 5. Player Scene + Collision | `"Task 5: Player Scene" → TASK5_DONE` | Create player.tscn with CharacterBody2D, CollisionShape2D, Sprite2D | `godot --headless --quit` (scene loads) |
| 6. Mining Interaction | `"Task 6: Mining" → TASK6_DONE` | `test_mining.gd` simulates click on block, verifies TileWorld.get_block returns AIR and Inventory has item | `godot --headless -s addons/gut/gut_cmdln.gd -gtest=test_mining.gd` |
| 7. Block Placement | `"Task 7: Placement" → TASK7_DONE` | `test_placement.gd` places block from inventory, verifies TileWorld updated and inventory decremented | `godot --headless -s addons/gut/gut_cmdln.gd -gtest=test_placement.gd` |
| 8. HotbarUI | `"Task 8: HotbarUI" → TASK8_DONE` | `test_hotbar_ui.gd` adds item to inventory, verifies HotbarUI slot shows icon+count | `godot --headless -s addons/gut/gut_cmdln.gd -gtest=test_hotbar_ui.gd` |
| 9. InventoryUI | `"Task 9: InventoryUI" → TASK9_DONE` | `test_inventory_ui.gd` opens inventory, clicks slot, verifies selection | `godot --headless -s addons/gut/gut_cmdln.gd -gtest=test_inventory_ui.gd` |
| 10. Input Bindings + Polish | `"Task 10: Input Polish" → TASK10_DONE` | Integration test: spawn player, move, mine, place, check inventory | `godot --headless -s addons/gut/gut_cmdln.gd -gdir=tests/integration/` |

### What Counts as a REAL Test

| ✅ REAL (execute + verify) | ❌ NOT A TEST (never do this) |
|----------------------------|-------------------------------|
| GUT test creates WorldRenderer, calls set_block, checks TileMapLayer cell | grep for WorldRenderer class exists |
| GUT test creates Player, simulates input, checks position changed | Check player.tscn has CharacterBody2D |
| GUT test mines block, verifies TileWorld.get_block returns AIR | Log says "mined block" |
| GUT test adds item to Inventory, verifies HotbarUI slot updated | "UI looks correct" |

**Every task MUST have a test that EXECUTES the code and VERIFIES behavior.**

## Key Integration Points

### TileWorld → WorldRenderer
```gdscript
# WorldRenderer connects to TileWorld.block_changed
func _on_block_changed(pos: Vector2i, _old: int, new_type: int) -> void:
    tile_map_layer.set_cell(pos, source_id, atlas_coords_for(new_type))
```

### Inventory → HotbarUI
```gdscript
# HotbarUI connects to Inventory.inventory_updated
func _on_inventory_updated() -> void:
    for i in range(9):
        var slot = inventory.get_slot(i)
        hotbar_slots[i].update(slot.item, slot.count)
```

### Mining Flow
1. Player clicks block within range (4-5 tiles)
2. MiningController calls `tile_world.set_block(x, y, BlockData.BlockType.AIR)`
3. `block_changed` signal updates TileMapLayer
4. MiningController gets drops: `BlockData.get_block_drops(old_type)`
5. Add to inventory: `inventory.add_item(drop_type, 1)`
6. `inventory_updated` signal updates HotbarUI

### Placement Flow
1. Player clicks empty position with placeable item selected
2. PlacementController checks `ItemData.is_placeable(selected_item)`
3. Gets block type: `ItemData.get_block_for_item(selected_item)`
4. Sets block: `tile_world.set_block(x, y, block_type)`
5. Removes from inventory: `inventory.remove_item(hotbar_index, 1)`

## Testing Strategy

### Unit Tests (per component)
- WorldRenderer: block_changed → tile updated
- PlayerController: input → velocity → position
- MiningController: click → world update → inventory update
- HotbarUI: inventory signal → slot display

### Integration Tests
- Full mining flow: click block → disappears → in inventory
- Full placement flow: select item → click → placed → inventory decremented
- Movement + world: player moves → new chunks render

### Test Command
```bash
# Run all tests
/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd

# Run specific test file
/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd -gtest=test_world_renderer.gd

# Run integration tests
/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd -gdir=tests/integration/
```

## Success Criteria (from SPEC.md)

- [ ] Player spawns in generated world and can see terrain
- [ ] Player can move with keyboard controls
- [ ] Player can mine a block and see it disappear
- [ ] Mined item appears in inventory
- [ ] Player can place a block from inventory
- [ ] Hotbar displays current items with counts
- [ ] Full inventory opens/closes with key press
- [ ] Camera follows player smoothly
- [ ] World generates more terrain as player explores

## Dependencies

- Godot 4.x (latest stable)
- GUT addon (existing)
- Existing ECS foundation (353 tests passing)

## Notes

- Side-view platformer with gravity (Terraria-style)
- Y-axis: Positive = up (surface at high Y, caves at low Y)
- 16x16 tile chunks for TileMapLayer rendering
- 4-5 tile mining range from player
- Instant break on click (no hold-to-mine for demo)
- Use placeholder sprites initially, asset library later
- Use uv to run python, e.g. `.venv/bin/python [file]`
