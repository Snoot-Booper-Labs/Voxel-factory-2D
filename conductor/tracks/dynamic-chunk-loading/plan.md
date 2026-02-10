# Implementation Plan: Dynamic Chunk Loading

## Proposed Architecture

Modify `WorldRenderer` to handle chunk management. It already has access to `TileWorld` and `TileMapLayer`.

### New Properties in `WorldRenderer`
- `chunk_size` (Vector2i): 16x16
- `render_distance` (int): 4 (chunks)
- `loaded_chunks` (Dictionary): Tracks which chunks (Vector2i coords) are currently rendered.
- `player_target` (Node2D): Reference to the player to track position.

### Logic Flow (`_process`)
1.  Get player's current chunk coordinate: `floor(player_pos / (tileSize * chunkSize))`.
2.  Calculate the set of visible chunks: `[current_chunk.x - radius` to `current_chunk.x + radius]`.
3.  Identify **new** chunks: Visible set MINUS `loaded_chunks`.
4.  Identify **old** chunks: `loaded_chunks` MINUS Visible set.
5.  Render new chunks (call `render_region` for that chunk).
6.  Unrender old chunks (clear cells in that region).
7.  Update `loaded_chunks`.

## Tasks

| Task | Description |
|------|-------------|
| 1. Update WorldRenderer | Add `_process` logic for chunk loading/unloading based on a target position. |
| 2. Connect Player | Update `Main` to pass the player node to `WorldRenderer`. |
| 3. Test Infinite Scroll | Verify the player can move continuously and seeing terrain. |

## Execution Steps

1.  Modify `game/scripts/rendering/world_renderer.gd` to implement the logic.
2.  Modify `game/scripts/main.gd` to set the tracking target.
3.  Unit test `WorldRenderer` logic (mock player position).
4.  Integration test with moving player.
