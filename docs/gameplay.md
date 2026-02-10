# Program Builder - Gameplay Guide

## Game Overview

Program Builder is a 2D side-scrolling sandbox game where players explore a procedurally generated world, mine resources, and build automation systems using visual programming.

## World

### Procedural Generation

The world is procedurally generated using seeded noise functions:

- **Infinite horizontal extent** - Walk left or right forever
- **Variable terrain height** - Smooth hills and valleys
- **Biome variety** - Different regions with different resources
- **Deterministic** - Same seed always produces same world

### Biomes

| Biome | Surface | Underground | Height Range |
|-------|---------|-------------|--------------|
| Plains | Grass | Dirt/Stone | 20-40 |
| Forest | Grass | Dirt/Stone | 25-45 |
| Desert | Sand | Sand/Stone | 15-35 |
| Mountains | Stone | Stone | 50-80 |
| Ocean | Sand | Stone | 5-15 |

### Blocks

**Natural Blocks:**
- Air - Empty space, passable
- Grass - Surface layer in most biomes
- Dirt - Subsurface layer
- Stone - Underground, deep terrain
- Sand - Desert/ocean biome
- Water - Liquid, passable

**Ore Blocks:**
- Coal Ore - Common fuel source
- Iron Ore - Basic metal
- Gold Ore - Valuable metal
- Diamond Ore - Rare, valuable

**Crafted Blocks:**
- Cobblestone - Dropped when mining stone
- Planks - Processed wood

## Player Movement

The player is a platformer-style character:

- **Horizontal movement** - Move left/right with smooth acceleration
- **Gravity** - Falls when not on ground
- **Jumping** - Jump when standing on solid ground
- **Camera following** - Camera follows player position

### Movement Constants

| Property | Value |
|----------|-------|
| Move Speed | 200 px/s |
| Jump Velocity | -400 px/s |
| Gravity | 980 px/s² |

## Mining

Click on blocks to mine them:

### Mining Rules

1. **Range limit** - Can only mine blocks within 5 tiles (80 pixels)
2. **Instant break** - Blocks break immediately on click
3. **Drops to inventory** - Mined blocks go directly to inventory
4. **Different drops** - Some blocks drop different items (Stone → Cobblestone)

### Block Drops

| Block | Drops |
|-------|-------|
| Grass | Grass |
| Dirt | Dirt |
| Stone | Cobblestone |
| Wood | Wood |
| Sand | Sand |
| Coal Ore | Coal |
| Iron Ore | Iron Ore |
| Gold Ore | Gold Ore |
| Diamond Ore | Diamond |
| Leaves | Nothing |

### Unmineable Blocks

- **Bedrock** - Cannot be mined
- **Air** - Nothing to mine
- **Water** - Cannot be mined

## Placement

Place blocks from your inventory:

### Placement Rules

1. **Range limit** - Can only place within 5 tiles (80 pixels)
2. **Target must be air** - Cannot place where a block exists
3. **Consumes item** - Uses one item from selected hotbar slot
4. **Placeable items only** - Only block-type items can be placed

### Placeable Items

All basic block items can be placed:
- Dirt, Stone, Wood, Sand, Grass
- Cobblestone, Planks
- Coal Ore, Iron Ore, Gold Ore, Diamond Ore

### Non-Placeable Items

- Tools (Pickaxe, Axe, Shovel)
- Refined materials (Coal, Iron Ingot, Gold Ingot)

## Inventory

### Hotbar (9 slots)

The hotbar is always visible at the bottom of the screen:

- **Slots 1-9** - Quick access slots
- **Selection** - Currently selected slot is highlighted
- **Stack display** - Shows item count in each slot

### Full Inventory (36 slots)

The full inventory grid provides more storage:

- **4 rows × 9 columns** - 36 total slots
- **Toggle visibility** - Open/close with key
- **Same items stack** - Items of same type combine

### Item Stacking

| Item Type | Max Stack |
|-----------|-----------|
| Block items | 64 |
| Material items | 64 |
| Tools | 1 |

## Automation (Coming Soon)

### Visual Programming

Create automation using visual programming blocks:

1. **Command Blocks** - Individual instructions
2. **Graph Editor** - Connect blocks to create programs
3. **Execution** - Run programs on entities

### Entity Types

- **Miner** - Automated mining entity
- **Conveyor** - Item transport belt

### Command Block Types

- **Move** - Move entity in direction
- **Mine** - Mine block at position
- **Condition** - Branch based on condition
- **Loop** - Repeat a sequence

## Dimensions

### Overworld

The main game world:
- Infinite procedural terrain
- All biomes present
- Player spawn location

### Pocket Dimensions

Player-created isolated spaces:
- Fixed size
- Independent terrain
- Can switch between dimensions

## UI Elements

### HUD

Always visible during gameplay:

```
┌────────────────────────────────────────────┐
│                                            │
│                                            │
│              [Game World]                  │
│                                            │
│                                            │
├────────────────────────────────────────────┤
│  [1][2][3][4][5][6][7][8][9]  <- Hotbar   │
└────────────────────────────────────────────┘
```

### Inventory Screen

Opened with inventory toggle key:

```
┌────────────────────────────────────────────┐
│            INVENTORY                        │
├────────────────────────────────────────────┤
│  [□][□][□][□][□][□][□][□][□]              │
│  [□][□][□][□][□][□][□][□][□]              │
│  [□][□][□][□][□][□][□][□][□]              │
│  [□][□][□][□][□][□][□][□][□]              │
└────────────────────────────────────────────┘
```

## Game Loop

1. **Explore** - Move through the world
2. **Mine** - Gather resources
3. **Build** - Place blocks to create structures
4. **Automate** - Create programs to automate tasks
5. **Expand** - Use automation to gather more resources
