# Implementation Plan: Program Builder - Full ECS Foundation

> **For Claude:** REQUIRED SUB-SKILL: Invoke `Skill(skill="workflows:dev-implement")` to implement this plan.
>
> **Per-Task Ralph Loops:** Assign each task its OWN ralph loop. Do NOT combine multiple tasks into one loop.
>
> **Delegation:** Main chat orchestrates, Task agents implement. Use `Skill(skill="workflows:dev-delegate")` for subagent templates.

## Chosen Approach

**Full ECS Composition**: Maximum modularity with entity-component-system architecture adapted for Godot 4.x. This provides clean separation, excellent testability, and ideal structure for future multiplayer.

## Rationale

- User explicitly chose this approach despite higher initial complexity
- Godot's node system complements ECS - nodes as entities, Resources as components
- Signal-based systems align with Godot's observer pattern
- Clean architecture supports the educational goal (kids can understand modular systems)
- Future multiplayer requires authoritative state management that ECS provides naturally

## Architecture Overview

```
program-builder/
├── project.godot
├── addons/
│   └── gut/                     # Testing framework
├── game/
│   ├── scripts/
│   │   ├── core/                # ECS Foundation
│   │   │   ├── entity.gd        # Base entity (extends Node2D)
│   │   │   ├── component.gd     # Base component (extends Resource)
│   │   │   └── system.gd        # Base system (extends Node)
│   │   ├── components/          # Reusable components
│   │   │   ├── transform_2d.gd  # Position/rotation
│   │   │   ├── inventory.gd     # Item storage
│   │   │   ├── program.gd       # Command block graph
│   │   │   ├── machine_state.gd # State machine data
│   │   │   └── belt_node.gd     # Conveyor connection
│   │   ├── systems/             # Game systems
│   │   │   ├── world_system.gd  # Tile world management
│   │   │   ├── mining_system.gd # Process mining machines
│   │   │   ├── belt_system.gd   # Item transport
│   │   │   ├── program_system.gd # Execute command graphs
│   │   │   └── dimension_system.gd # Layer management
│   │   ├── world/               # World generation
│   │   │   ├── tile_world.gd    # TileMapLayer wrapper
│   │   │   ├── chunk_manager.gd # Streaming/loading
│   │   │   ├── terrain_generator.gd
│   │   │   ├── biome_planner.gd
│   │   │   └── biome_data.gd
│   │   ├── programming/         # Visual programming
│   │   │   ├── command_block.gd # Base command node
│   │   │   ├── blocks/          # Specific commands
│   │   │   │   ├── move_block.gd
│   │   │   │   ├── mine_block.gd
│   │   │   │   ├── condition_block.gd
│   │   │   │   └── loop_block.gd
│   │   │   └── graph_executor.gd # Tick-based interpreter
│   │   ├── entities/            # Concrete entities
│   │   │   ├── player.gd
│   │   │   ├── miner.gd
│   │   │   └── conveyor.gd
│   │   └── data/                # Static data
│   │       ├── block_data.gd
│   │       └── item_data.gd
│   ├── scenes/
│   │   ├── main.tscn
│   │   ├── player.tscn
│   │   └── ui/
│   │       └── programming_ui.tscn
│   └── resources/
│       ├── tiles/               # TileSet definitions
│       └── biomes/              # Biome curve resources
└── tests/
    ├── unit/
    │   ├── test_entity.gd
    │   ├── test_component.gd
    │   ├── test_inventory.gd
    │   ├── test_program_executor.gd
    │   └── test_terrain_generator.gd
    └── integration/
        ├── test_mining_flow.gd
        ├── test_belt_transport.gd
        └── test_world_generation.gd
```

## Key Design Patterns

### Entity-Component Pattern (Godot-Adapted)
```gdscript
# Entity: Node2D that holds components
class_name Entity extends Node2D
var components: Dictionary = {}  # type_name -> Component

func add_component(component: Component) -> void:
    components[component.get_type_name()] = component
    component.entity = self

func get_component(type_name: String) -> Component:
    return components.get(type_name)

func has_component(type_name: String) -> bool:
    return components.has(type_name)
```

### Component Pattern
```gdscript
# Component: Resource with data only
class_name Component extends Resource
var entity: Entity  # Back-reference

func get_type_name() -> String:
    return "Component"  # Override in subclasses
```

### System Pattern
```gdscript
# System: Processes entities with specific components
class_name System extends Node
var required_components: Array[String] = []

func _physics_process(delta: float) -> void:
    for entity in get_matching_entities():
        process_entity(entity, delta)

func process_entity(entity: Entity, delta: float) -> void:
    pass  # Override

func get_matching_entities() -> Array[Entity]:
    # Query world for entities with required_components
    pass
```

### Signal-Based Communication
```gdscript
# Systems communicate via signals, not direct calls
signal item_mined(entity: Entity, item_type: int, count: int)
signal program_step_completed(entity: Entity, block: CommandBlock)
signal inventory_full(entity: Entity)
```

## Files to Create

| File | Purpose |
|------|---------|
| `project.godot` | Godot project configuration |
| `game/scripts/core/entity.gd` | Base entity class |
| `game/scripts/core/component.gd` | Base component class |
| `game/scripts/core/system.gd` | Base system class |
| `game/scripts/components/inventory.gd` | Item storage component |
| `game/scripts/components/program.gd` | Command graph component |
| `game/scripts/components/machine_state.gd` | State machine component |
| `game/scripts/systems/world_system.gd` | World management |
| `game/scripts/systems/program_system.gd` | Tick-based executor |
| `game/scripts/world/tile_world.gd` | TileMapLayer wrapper |
| `game/scripts/world/terrain_generator.gd` | 2D procedural gen |
| `game/scripts/world/biome_planner.gd` | Voronoi biomes |
| `game/scripts/world/biome_data.gd` | Biome configuration |
| `game/scripts/programming/command_block.gd` | Base command |
| `game/scripts/programming/graph_executor.gd` | Graph interpreter |
| `game/scripts/data/block_data.gd` | Block definitions |
| `game/scripts/data/item_data.gd` | Item definitions |
| `tests/unit/test_entity.gd` | Entity unit tests |
| `tests/unit/test_inventory.gd` | Inventory tests |
| `tests/unit/test_program_executor.gd` | Executor tests |

## Implementation Order (with Per-Task Ralph Loops)

> **For Claude:** Each task = one ralph loop. Complete task N before starting task N+1.
>
> Pattern: `Skill(skill="workflows:dev-ralph-loop", args="Task N: [name] --max-iterations 10 --completion-promise TASKN_DONE")`

| Task | Ralph Loop | Core Test (MUST EXECUTE CODE) | Verify Command |
|------|------------|-------------------------------|----------------|
| 1. Project setup + GUT | `"Task 1: Project setup" → TASK1_DONE` | GUT runs and reports 0 tests | `godot --headless -s addons/gut/gut_cmdline.gd` |
| 2. ECS Core (Entity/Component/System) | `"Task 2: ECS Core" → TASK2_DONE` | `test_entity.gd` creates entity, adds component, retrieves it | `godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_entity.gd` |
| 3. Inventory Component | `"Task 3: Inventory" → TASK3_DONE` | `test_inventory.gd` adds/removes items, checks counts | `godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_inventory.gd` |
| 4. Block/Item Data | `"Task 4: Data definitions" → TASK4_DONE` | `test_block_data.gd` queries block properties | `godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_block_data.gd` |
| 5. Biome Planner (Voronoi) | `"Task 5: Biome planner" → TASK5_DONE` | `test_biome_planner.gd` generates same biome for same seed | `godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_biome_planner.gd` |
| 6. Terrain Generator | `"Task 6: Terrain gen" → TASK6_DONE` | `test_terrain_generator.gd` generates deterministic tiles from seed | `godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_terrain_generator.gd` |
| 7. TileWorld + WorldSystem | `"Task 7: Tile world" → TASK7_DONE` | `test_tile_world.gd` sets/gets tiles at coordinates | `godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_tile_world.gd` |
| 8. Command Block Base | `"Task 8: Command blocks" → TASK8_DONE` | `test_command_block.gd` creates block, connects outputs | `godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_command_block.gd` |
| 9. Graph Executor | `"Task 9: Graph executor" → TASK9_DONE` | `test_graph_executor.gd` executes 3-node graph, verifies order | `godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_graph_executor.gd` |
| 10. Machine Entity + Mining | `"Task 10: Miner entity" → TASK10_DONE` | `test_miner.gd` miner executes program, inventory receives items | `godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_miner.gd` |
| 11. Conveyor System | `"Task 11: Conveyors" → TASK11_DONE` | `test_conveyor.gd` item moves along belt path | `godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_conveyor.gd` |
| 12. Dimension System | `"Task 12: Dimensions" → TASK12_DONE` | `test_dimension.gd` switches layers, entities persist | `godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_dimension.gd` |
| 13. Integration: Full Mining Flow | `"Task 13: Integration" → TASK13_DONE` | Integration test: player programs miner, miner mines, items conveyed | `godot --headless -s addons/gut/gut_cmdline.gd -gdir=tests/integration/` |

### What Counts as a REAL Test

| ✅ REAL (execute + verify) | ❌ NOT A TEST (never do this) |
|----------------------------|-------------------------------|
| GUT test instantiates Entity, adds Component, asserts `has_component()` | grep for class exists |
| GUT test calls `terrain_generator.generate_chunk()`, verifies tile values | ast-grep finds generation function |
| GUT test runs graph executor for 3 ticks, checks execution order | Log says "executed" |
| Integration test programs miner, waits, checks inventory | "Code looks correct" |

**Every task MUST have a test that EXECUTES the code and VERIFIES behavior.**

## Testing Strategy

### Unit Tests (per component/system)
- Entity: add/remove/query components
- Components: data integrity, serialization
- Systems: process entities correctly
- Generator: deterministic from seed

### Integration Tests
- Full mining flow: program → execute → mine → inventory
- Belt transport: items move between machines
- World persistence: save/load preserves state

### Test Command
```bash
# Run all tests
godot --headless -s addons/gut/gut_cmdline.gd

# Run specific test file
godot --headless -s addons/gut/gut_cmdline.gd -gtest=test_entity.gd

# Run integration tests
godot --headless -s addons/gut/gut_cmdline.gd -gdir=tests/integration/
```

## Success Criteria (from SPEC.md)

- [ ] World generates deterministically from seed
- [ ] Player can mine resources and place blocks
- [ ] At least one programmable machine type works with command blocks
- [ ] Command blocks execute visually with feedback
- [ ] Save/load preserves world state and machine programs
- [ ] Architecture supports adding new machine types via data files
- [ ] Architecture supports multiple world layers (pocket dimensions)

## Dependencies

- Godot 4.x (latest stable)
- GUT addon (Godot Unit Test)
- No external dependencies

## Notes

- All components extend Resource for easy serialization
- Systems are Nodes added to main scene tree
- Entity query system uses groups or a central registry
- Signals for loose coupling between systems
- Data-driven content via static dictionaries (like Voxel-factory)
