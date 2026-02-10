# Spec: Playable Demo - UI/Scene Layer

> **For Claude:** After writing this spec, use `Skill(skill="workflows:dev-explore")` for Phase 2.

## Problem

The ECS foundation (353 tests) exists but has no visual representation. Need a playable demo where players can move through the procedurally generated world, mine blocks, place blocks, and manage inventory.

## Requirements

### World Rendering
- [ ] TileMapLayer displays generated terrain from TileWorld
- [ ] Camera follows player with smooth movement
- [ ] Visible chunk loading/unloading as player moves
- [ ] Different tile visuals per block type (grass, stone, dirt, ores, etc.)

### Player
- [ ] Player entity with sprite
- [ ] WASD/arrow key movement (2D platformer or top-down TBD)
- [ ] Mining interaction (click block to mine)
- [ ] Block placement (select from hotbar, click to place)
- [ ] Collision with solid blocks

### Inventory UI
- [ ] Hotbar (9 slots) visible at bottom of screen
- [ ] Number keys 1-9 select hotbar slot
- [ ] Press key (Tab/I/E) to open full inventory grid
- [ ] Visual slots showing item icons and stack counts
- [ ] Click to select, click to place items
- [ ] Inventory integrates with existing Inventory component

### Mining/Placement
- [ ] Click on block to mine (uses TileWorld.set_block to AIR)
- [ ] Mined items go to player inventory
- [ ] Selected hotbar item can be placed
- [ ] Placement only on valid adjacent positions

## Success Criteria

- [ ] Player spawns in generated world and can see terrain
- [ ] Player can move with keyboard controls
- [ ] Player can mine a block and see it disappear
- [ ] Mined item appears in inventory
- [ ] Player can place a block from inventory
- [ ] Hotbar displays current items with counts
- [ ] Full inventory opens/closes with key press
- [ ] Camera follows player smoothly
- [ ] World generates more terrain as player explores

## Constraints

- Must use existing ECS foundation (Entity, Component, System, TileWorld, Inventory, BlockData, ItemData)
- Godot 4.x with TileMapLayer (not deprecated TileMap)
- Use free Godot asset library sprites where possible
- No multiplayer considerations yet
- Desktop only (keyboard/mouse)

## Automated Testing (MANDATORY)

> **For Claude:** Use `Skill(skill="workflows:dev-test")` for automation options.

- **Framework:** GUT (existing)
- **Command:** `../engine/Godot_v4.6-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd`
- **Core functionality to verify:**
  - Player movement updates position
  - Mining removes block from TileWorld and adds to Inventory
  - Placement adds block to TileWorld and removes from Inventory
  - Inventory UI reflects Inventory component state
  - Camera position tracks player position

### What Counts as a Real Automated Test

| REAL TEST (execute + verify) | NOT A TEST (never acceptable) |
|---------------------------------|----------------------------------|
| GUT test creates Player, calls move(), checks position changed | grep for Player class exists |
| GUT test mines block, verifies TileWorld.get_block returns AIR | Check scene has TileMapLayer |
| GUT test adds item, verifies InventoryUI slot count updates | "UI looks correct" |
| Integration test: mine → inventory → place cycle | Log says "placed block" |

## Exploration Findings

### ECS Foundation Integration Points
- `TileWorld.block_changed` signal - Connect to TileMapLayer for visual updates
- `Inventory.inventory_updated` signal - Connect to InventoryUI for slot refresh
- `BlockData.BlockType` enum - 15 block types (AIR=0 through BEDROCK=14)
- `ItemData.ItemType` enum - Block items (1-8), Materials (20-25), Tools (40-48)
- `Entity` extends Node2D - Add Player entity for scene tree integration

### Key APIs for UI
- `TileWorld.get_block(x, y)` - Query block type for rendering
- `TileWorld.set_block(x, y, type)` - Modify world (emits signal)
- `Inventory.get_slot(i)` - Returns {item: int, count: int}
- `Inventory.add_item(type, count)` - Returns overflow count
- `ItemData.get_item_name(type)` - Display name for UI labels
- `ItemData.is_placeable(type)` - Check if item can be placed
- `ItemData.get_block_for_item(type)` - Get BlockType for placement
- `BlockData.get_block_drops(type)` - Get item drops for mining

### Test Patterns
- GUT framework with `watch_signals()` and `assert_signal_emitted()`
- No scene/node testing yet - all RefCounted objects
- Test command: `../engine/Godot_v4.6-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd`

### No Existing Scenes
- `game/scenes/` directory exists but empty (only `ui/` subdirectory)
- No `.tscn` files in project yet
- No TileSet resources exist

## Clarified Requirements

### View Style
- Decision: Side-view platformer (Terraria-style)
- Implications: Gravity, jumping, CharacterBody2D for player
- Y-axis: Positive = up (surface at high Y, caves at low Y)

### Chunk Size
- Decision: 16x16 tiles per chunk
- Rationale: Standard 2D chunk size, good performance balance
- Note: Independent of BiomePlanner's 128x128 Voronoi cells

### Mining Range
- Decision: 4-5 tile radius from player
- Implementation: Calculate distance from player to clicked tile
- Edge case: Show "too far" feedback if out of range

### Mining Style
- Decision: Instant break on click (for demo), eventually to be gated behind axe tech level (e.g. steel axe needed to break bedrock+ hardness blocks)
- Rationale: Faster iteration, hardness values can be used later when tool tech is explored further
- Future: Add hold-to-mine with progress bar when polishing, add hardness and tool checks
