# Spec: 2D Factory Builder - "Program Builder"

> **For Claude:** After writing this spec, use `Skill(skill="workflows:dev-explore")` for Phase 2.

## Problem

Create a 2D factory-building game (Terraria-style) that teaches programming concepts subconsciously to children through gameplay. Players start with manual resource gathering, then progressively automate their factories using drag-and-drop command blocks, learning programming fundamentals (sequences, conditionals, loops, functions) without explicit instruction.

## Vision

A 2D companion/adaptation of Voxel-factory with:
- Terraria-style procedurally generated world (surface, caves, depths, structures)
- Factory automation that mirrors programming concepts
- Progressive complexity unlocking as players advance
- Educational stealth - kids learn programming by playing, not studying

## Requirements

### Core Gameplay
- [ ] Seed-based procedural world generation with distinct layers (surface, underground, deep)
- [ ] Resource gathering (mining, harvesting) with tools
- [ ] Tile-based world with destructible/placeable blocks
- [ ] Inventory and crafting system
- [ ] Machine placement and interaction

### Automation/Programming System
- [ ] Scratch-like drag-and-drop command blocks for machine programming
- [ ] Simple chains initially (sequential execution)
- [ ] Unlockable complexity: conditionals → loops → variables → functions
- [ ] Visual feedback showing program execution
- [ ] Miners and other machines that execute player-defined programs

### World Generation
- [ ] Deterministic generation from seed
- [ ] Horizontal biomes with vertical layer progression
- [ ] Ore deposits and resource nodes at appropriate depths
- [ ] Generated structures (ruins, puzzle rooms, dungeons)
- [ ] Support for "pocket dimensions" and multiple map layers

### Architecture Requirements
- [ ] Modular, composition-based design (no deep inheritance)
- [ ] Data-driven content (JSON/resources for items, recipes, blocks)
- [ ] Prepared for future multiplayer (authoritative game state)
- [ ] Multi-layer world support (main world, pocket dimensions, space)
- [ ] Teleportation and cross-layer resource sharing capability

### Platform
- Desktop only (PC/Mac)
- Godot 4.x engine
- Keyboard/mouse controls

## Success Criteria

- [ ] World generates deterministically from seed
- [ ] Player can mine resources and place blocks
- [ ] At least one programmable machine type works with command blocks
- [ ] Command blocks execute visually with feedback
- [ ] Save/load preserves world state and machine programs
- [ ] Architecture supports adding new machine types via data files
- [ ] Architecture supports multiple world layers (pocket dimensions)

## Constraints

- Must use Godot 4.x (aligns with Voxel-factory)
- Architecture must be extensible without code changes for new content
- Performance: handle large worlds with many active machines
- Single-player first, but state management must allow future multiplayer
- No educational "branding" - learning should feel like natural gameplay

## Automated Testing (MANDATORY)

> **For Claude:** Use `Skill(skill="workflows:dev-test")` for automation options.

- **Framework:** GUT (Godot Unit Test) + integration tests
- **Command:** `godot --headless -s addons/gut/gut_cmdline.gd`
- **Core functionality to verify:**
  - World generation produces consistent output from seed
  - Command block execution follows correct sequence
  - Save/load preserves machine state and programs
  - Resource system correctly tracks inventory

### What Counts as a Real Automated Test

| ✅ REAL TEST (execute + verify) | ❌ NOT A TEST (never acceptable) |
|---------------------------------|----------------------------------|
| GUT test runs world gen, verifies tile at coordinates | grep finds WorldGenerator class |
| Integration test executes command blocks, checks machine state | Check logs say "executed" |
| Save/load test verifies data integrity | Read save file structure |

## Exploration Findings (from Voxel-factory Analysis)

### Machine/Automation Architecture
- **Miner class** (`miner.gd`): State machine pattern with `MiningPhase` enum (DESCENDING → HORIZONTAL)
- **Composition**: Miner owns `Inventory` component, not inherited
- **Signal-based communication**: `mining_completed`, `depth_changed`, `active_changed`, `inventory_full`
- **Configuration methods**: `set_target_depth()`, `set_horizontal_direction()` - program-like instructions
- **No visual programming yet**: Current machines execute hardcoded algorithms, extensible via method calls

### World Generation Patterns
- **VoxelWorld** wraps godot_voxel module with `VoxelStreamRegionFiles` for persistence
- **TerrainGenerator** uses Voronoi-based biome system via `BiomePlanner`
- **Seed-based**: All `FastNoiseLite` generators seeded from `world_seed`
- **Lazy generation**: Biomes only generated when player approaches (3x3 cell radius)
- **Curve resources**: Per-biome height shaping via `.tres` Curve files

### Data-Driven Patterns
- **BlockData/ItemData**: Static dictionaries with enum keys
- **BiomeData**: Static `biome_params` dictionary with complete biome config
- **VoxelBlockyLibrary**: External `.tres` resource for block meshes/materials
- **CraftingSystem**: Static `recipes` array of dictionary patterns

### Composition Patterns
- **Main.gd**: Dictionary-based registry (`miners: Dictionary = {}`) keyed by position
- **Inventory**: `extends Resource` - reusable component owned by Player or Miner
- **Signal connections**: All set up in `_ready()` for loose coupling
- **No deep inheritance**: Classes extend Node3D/Resource directly

### Test Infrastructure
- **GUT framework** (Godot Unit Test) with `.gutconfig.json`
- **Tests in**: `tests/unit/` and `tests/integration/`
- **Mock pattern**: `MockVoxelWorld` with dictionary-based block storage
- **Lifecycle hooks**: `before_all`, `after_each`, `autofree()` for cleanup

## Clarified Requirements

### 2D World Rendering
- **Decision**: TileMapLayer (native Godot)
- **Rationale**: Auto-culling, built-in collision, matches Terraria style
- **Implementation**: Single TileMapLayer for main terrain, additional layers for pocket dimensions

### Command Block Programming Model
- **Decision**: Flowchart/node graph (visual connections)
- **Rationale**: Teaches data flow, more expressive than linear sequences
- **Implementation**: Drag-and-drop nodes with visual wires connecting outputs to inputs

### Program Execution
- **Decision**: Tick-based execution (one command per game tick)
- **Rationale**: Kids see each step execute, easier to debug, teaches sequential thinking
- **Implementation**: Machine's `_process()` executes one node per tick, visual highlight on active node

### Biome Generation Architecture
- **Decision**: Modular biome functions with shared noise core
- **Rationale**: Easy biome-specific customization while maintaining consistency
- **Implementation**:
  - Shared: `_generate_base_terrain(x, y, params)` - noise-based height/density
  - Per-biome: `generate_forest()`, `generate_desert()` - calls shared, adds macro features (temples, ice spikes)
  - Biomes configured via data dictionaries like Voxel-factory's BiomeData

### Pocket Dimensions
- **Decision**: TileMapLayers (same scene, different layers)
- **Rationale**: Simpler architecture, all layers share coordinates, no loading screens
- **Implementation**: `DimensionManager` toggles layer visibility, each layer can have different tile sources

### Machine Item Transfer
- **Decision**: Conveyor belts (Factorio-style)
- **Rationale**: Visual item flow teaches logistics, kids see resources moving
- **Implementation**: Belt tiles with direction, items as sprites moving along belt path

## Open Questions (Remaining)

- [ ] Chunk size for TileMapLayer streaming (16x16 recommended for 2D)
- [ ] Node graph UI library (custom vs existing addon)
