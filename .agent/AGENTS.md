# Agent Orientation Guide — Program Builder (Voxel Factory 2D)

2D side-scrolling sandbox automation game (Factorio-like) built in **Godot 4.6** with **GDScript**.
Lightweight ECS architecture integrated with Godot's scene system.

## Conductor System (Read First)

The `conductor/` folder is the central context source. Check it before starting work.

- `conductor/index.md` — entry point, project state overview
- `conductor/workflow.md` — development workflow and merge policy
- `conductor/tracks/` — active feature tracks with specs and plans
- `conductor/tech-stack.md` — engine and framework versions

## Repository Layout

```
game/                    # Godot project root (open this in Godot Editor)
  scripts/
    core/                # ECS base classes: entity.gd, component.gd, system.gd
    components/          # Component implementations (inventory, belt_node, program)
    entities/            # Entity implementations (miner, conveyor)
    systems/             # System implementations (world_system, belt_system)
    world/               # World generation (tile_world, terrain_generator, biome)
    data/                # Static data classes (block_data, item_data, miner_data)
    programming/         # Visual programming (command_block, graph_executor)
    player/              # Player systems (controller, input, mining, placement)
    ui/                  # UI scripts (inventory_ui, hotbar_ui)
    rendering/           # Rendering (world_renderer)
    save/                # Save system (save_manager, entity_saver)
    main.gd              # Game entry point
  scenes/                # .tscn scene files
  resources/             # .tres resources (biomes, sprites, tiles)
  tests/
    unit/                # 19 unit test files (~460+ tests)
    integration/         # 2 integration test files
  addons/gut/            # GUT testing framework
conductor/               # Context and task management
docs/                    # Architecture, gameplay, API reference docs
.agent/                  # Agent configuration
```

## Build & Run

No build step required. Open `game/` in Godot Editor and press F5.
For Python commands, always use `uv` (e.g., `uv run python script.py`).

## Testing (GUT Framework)

Test config: `game/.gutconfig.json`. Tests live in `game/tests/unit/` and `game/tests/integration/`.

**All test commands must be run from the `game/` directory.**

### Run all tests
```bash
# macOS
/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd

# Windows
..\..\engine\Godot_v4.6-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd
```

### Run a single test file
```bash
# macOS
/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_inventory.gd

# Windows
..\..\engine\Godot_v4.6-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_inventory.gd
```

### Run a test directory
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit/
```

### Critical rules
- **Must use `--headless`** flag
- **Must use `res://` prefix** for all test paths (not filesystem paths)
- Working directory must be `game/`

## Development Workflow (The Ralph Loop)

1. **Plan** — define the task in a Track Plan
2. **Test** — write a failing test (Red)
3. **Implement** — write code to pass the test (Green)
4. **Refactor** — clean up
5. **Verify** — run the full test suite

Before merging to `main`: all tests pass, human manually verifies, explicit approval received.

## Code Style

### File Structure
```gdscript
## Doc comment describing the class
class_name ClassName
extends ParentClass

# =============================================================================
# Constants
# =============================================================================
const MAX_VALUE = 100

# =============================================================================
# Signals
# =============================================================================
signal something_happened

# =============================================================================
# Properties
# =============================================================================
@export var public_prop: int = 0
var _private_var: String = ""

# =============================================================================
# Lifecycle
# =============================================================================
func _ready() -> void:
    pass

# =============================================================================
# Public API
# =============================================================================
func do_thing(param: int) -> bool:
    return true
```

### Naming Conventions
| Element       | Convention          | Example                          |
|---------------|---------------------|----------------------------------|
| Classes       | `PascalCase`        | `TileWorld`, `MiningController`  |
| Functions     | `snake_case`        | `get_block`, `add_item`          |
| Variables     | `snake_case`        | `tile_world`, `block_type`       |
| Private       | `_prefix`           | `_slots`, `_state`, `_tiles`     |
| Constants     | `UPPER_SNAKE_CASE`  | `TILE_SIZE`, `MAX_STACK`         |
| Enums         | `PascalCase.UPPER`  | `BlockType.AIR`, `State.IDLE`    |
| Signals       | `snake_case`        | `inventory_updated`, `block_mined` |

### Type Annotations
- Always annotate return types: `func get_block(x: int, y: int) -> int:`
- Always annotate parameters: `func setup(world: TileWorld, inv: Inventory) -> void:`
- Use `:=` for type inference on locals: `var pos := Vector2i(x, y)`
- Use `@export` for editor-exposed properties, `@onready` for node references

### Documentation
- `##` for GDScript doc comments (renders in Godot docs panel)
- `#` for inline implementation notes
- `# =============================================================================` section banners to organize code

### Error Handling
- GDScript has no exceptions. Use return values for error states.
- Null-check before use: `if tile_world == null: return`
- Bounds-check array access before indexing
- Return empty/default values on invalid input: `{item = NONE, count = 0}`

### Architecture Patterns
- **ECS**: Entity (Node2D) -> Component (Resource) -> System (Node)
- Components identified by `get_type_name() -> String`
- Entities grouped via `add_to_group("miners")` for efficient queries
- Signal-based UI updates (e.g., `inventory_updated` -> UI refresh)
- Serialize/deserialize pattern on entities and components for save/load
- Controllers separate from input handling (InputManager -> specific controllers)
- Static data classes with static dictionaries and static functions (BlockData, ItemData)
- `@tool` annotation on classes that need editor preview

### Test Style
```gdscript
extends GutTest
## Description of what this test file covers

func before_each() -> void:
    # setup

func test_descriptive_name():
    var obj = MyClass.new()
    assert_eq(obj.value, expected, "Descriptive failure message")
```

- Test files: `test_` prefix, extend `GutTest`
- Test functions: `test_` prefix
- Setup/teardown: `before_each()` / `after_each()`
- Assertions: `assert_eq`, `assert_true`, `assert_false`, `assert_not_null`, `assert_null`
- Signals: call `watch_signals(obj)` before `assert_signal_emitted` / `assert_signal_not_emitted`
- Always include a descriptive message as the last parameter to assertions
- Node-based objects: call `add_child()` if scene tree access needed, `free()` / `queue_free()` to prevent leaks
- Organize tests with `# =============` section banners matching the source file's API sections

### Formatting
- Indentation: tabs (Godot default)
- Line endings: LF (`* text=auto eol=lf` in .gitattributes)
- Charset: UTF-8
- No configured linter or formatter — follow existing code patterns
