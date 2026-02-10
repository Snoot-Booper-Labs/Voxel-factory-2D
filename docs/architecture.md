# Program Builder - Architecture

## Overview

Program Builder is a 2D side-scrolling sandbox game built with Godot 4.x. The architecture combines an Entity-Component-System (ECS) pattern for game logic with Godot's native scene system for rendering.

## Core Architecture Pattern: ECS

The game uses a lightweight ECS implementation to separate data from behavior:

```
┌─────────────────────────────────────────────────────────────┐
│                        SYSTEMS                               │
│  (Process entities, contain game logic)                      │
│  WorldSystem, BeltSystem, DimensionSystem                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                       ENTITIES                               │
│  (Containers for components)                                 │
│  Miner, Conveyor                                             │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      COMPONENTS                              │
│  (Pure data, no behavior)                                    │
│  Inventory, Program, BeltNode                                │
└─────────────────────────────────────────────────────────────┘
```

### Components (`game/scripts/core/`)

Components are pure data containers that extend `RefCounted`:

- **Component** (`component.gd`) - Base class with `entity` back-reference
- **Inventory** (`inventory.gd`) - Stores items with slots, counts, max stack
- **Program** (`program.gd`) - Contains a visual programming graph
- **BeltNode** (`belt_node.gd`) - Conveyor belt position, direction, items

### Entities (`game/scripts/entities/`)

Entities are containers for components, extending `RefCounted`:

- **Entity** (`entity.gd`) - Base class with component dictionary
- **Miner** (`miner.gd`) - Mining automation entity (has Inventory + Program)
- **Conveyor** (`conveyor.gd`) - Item transport entity (has BeltNode)

### Systems (`game/scripts/world/`)

Systems contain game logic and process entities:

- **System** (`system.gd`) - Base class with `required_components` and `process_entity()`
- **WorldSystem** (`world_system.gd`) - Manages TileWorld, block get/set
- **DimensionSystem** (`dimension_system.gd`) - Multiple parallel worlds (overworld, pocket dimensions)
- **BeltSystem** (`belt_system.gd`) - Processes conveyor belt item movement

## World Generation

### TileWorld (`game/scripts/world/tile_world.gd`)

The infinite procedural world is generated lazily:

```
TileWorld
    ├── TerrainGenerator - Produces blocks based on (x, y) position
    │       ├── BiomePlanner - Determines biome at each location
    │       └── HeightNoise - Varies terrain height using Simplex noise
    │
    └── block_changed signal - Emitted when blocks are modified
```

**Coordinate System:**
- World Y-axis: Positive Y = higher altitude (up)
- Screen Y-axis: Positive Y = down (Godot standard)
- Conversion: `screen_y = -world_y`

### Block Types (`game/scripts/world/block_data.gd`)

```gdscript
enum BlockType {
    AIR = 0,      # Empty space (no collision)
    GRASS = 1,    # Surface block
    DIRT = 2,     # Subsurface
    STONE = 3,    # Underground
    WOOD = 4,     # Trees
    LEAVES = 5,   # Tree canopy
    SAND = 6,     # Desert/beach
    WATER = 7,    # Liquid (no collision)
    COAL_ORE = 8,
    IRON_ORE = 9,
    GOLD_ORE = 10,
    DIAMOND_ORE = 11,
    COBBLESTONE = 12,  # Placed/dropped stone
    PLANKS = 13,       # Crafted wood
    BEDROCK = 14       # Indestructible
}
```

### Biomes (`game/scripts/world/biome_data.gd`)

Each biome has:
- Surface block type (GRASS, SAND, etc.)
- Subsurface block type
- Height range (min/max terrain height)

```
PLAINS   - Grass/Dirt, height 20-40
FOREST   - Grass/Dirt, height 25-45
DESERT   - Sand/Sand, height 15-35
MOUNTAINS - Stone/Stone, height 50-80
OCEAN    - Sand/Stone, height 5-15
```

## Visual Programming System

### Command Blocks (`game/scripts/programming/`)

Players create automation through visual programming:

```
CommandBlock (base)
    ├── block_type: enum (MOVE, MINE, CONDITION, etc.)
    ├── parameters: Dictionary
    ├── next_block: CommandBlock (linear flow)
    └── outputs: Dictionary (branching for conditions)
```

### Graph Executor (`graph_executor.gd`)

Executes the visual program:

```
GraphExecutor
    ├── state: IDLE | RUNNING | PAUSED | COMPLETED
    ├── start_block: First block to execute
    ├── current_block: Currently executing
    └── tick() -> Executes one block per call
```

## Rendering Layer

### Scene-First with ECS Bridge

The rendering uses Godot scenes that bridge to ECS data:

```
Main.tscn
    ├── WorldRenderer (TileMapLayer synced to TileWorld via signals)
    ├── Player (CharacterBody2D with PlayerController script)
    ├── InputManager (Processes input, delegates to controllers)
    ├── MiningController (Handles mine actions)
    ├── PlacementController (Handles place actions)
    └── CanvasLayer
            ├── HotbarUI (9 slots)
            └── InventoryUI (36 slots)
```

### WorldRenderer (`game/scripts/rendering/world_renderer.gd`)

Syncs TileWorld to visual TileMapLayer:

1. Connects to `TileWorld.block_changed` signal
2. On change: updates TileMapLayer cell
3. Maps `BlockType` enum values to TileSet atlas X coordinates
4. Handles Y-axis inversion (world Y → screen -Y)

## File Structure

```
program-builder/
├── game/
│   ├── scenes/
│   │   ├── main.tscn          # Main game scene
│   │   └── player.tscn        # Player prefab
│   │
│   ├── scripts/
│   │   ├── core/              # ECS base classes
│   │   │   ├── component.gd
│   │   │   ├── entity.gd
│   │   │   └── system.gd
│   │   │
│   │   ├── world/             # World generation
│   │   │   ├── tile_world.gd
│   │   │   ├── terrain_generator.gd
│   │   │   ├── biome_planner.gd
│   │   │   ├── biome_data.gd
│   │   │   ├── block_data.gd
│   │   │   ├── world_system.gd
│   │   │   └── dimension_system.gd
│   │   │
│   │   ├── entities/          # Game entities
│   │   │   ├── miner.gd
│   │   │   └── conveyor.gd
│   │   │
│   │   ├── components/        # Component data
│   │   │   ├── inventory.gd
│   │   │   ├── belt_node.gd
│   │   │   └── belt_system.gd
│   │   │
│   │   ├── programming/       # Visual programming
│   │   │   ├── command_block.gd
│   │   │   ├── mine_block.gd
│   │   │   ├── program.gd
│   │   │   └── graph_executor.gd
│   │   │
│   │   ├── player/            # Player controllers
│   │   │   ├── player_controller.gd
│   │   │   ├── mining_controller.gd
│   │   │   ├── placement_controller.gd
│   │   │   └── input_manager.gd
│   │   │
│   │   ├── ui/                # UI components
│   │   │   ├── hotbar_ui.gd
│   │   │   └── inventory_ui.gd
│   │   │
│   │   └── rendering/         # Visual rendering
│   │       └── world_renderer.gd
│   │
│   └── resources/
│       └── tiles/
│           ├── terrain_tileset.tres
│           └── terrain_atlas.png
│
├── tests/
│   ├── unit/                  # Unit tests (GUT framework)
│   └── integration/           # Integration tests
│
└── docs/                      # Documentation
```

## Key Design Decisions

### 1. Lazy World Generation

Blocks are generated on-demand when first accessed, not pre-generated. This allows infinite worlds without memory constraints.

### 2. Signal-Based UI Updates

UI components connect to `inventory_updated` signal rather than polling. This keeps UI in sync without tight coupling.

### 3. Y-Axis Inversion

World coordinates use "Y up" (higher Y = higher altitude) for intuitive terrain math, while Godot uses "Y down". The WorldRenderer and controllers handle the conversion.

### 4. Controller Separation

Input handling is separated from game logic:
- `InputManager` - Reads input, calls controller methods
- `MiningController` - Handles mining logic, range checks, inventory
- `PlacementController` - Handles placement logic, item consumption

### 5. Test-Driven Development

469 tests cover:
- ECS infrastructure
- World generation determinism
- Inventory operations
- Controller behavior
- Signal emissions
- Integration flows
