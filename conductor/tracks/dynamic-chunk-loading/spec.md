# Spec: Dynamic Chunk Loading

## Problem

Currently, the game only renders a fixed initial region (centered at 0,0) on startup. As the player moves beyond this region, new terrain is not generated or rendered, resulting in a void.

## Requirements

1.  **Chunk-Based Rendering**: Divide the world into logical chunks (e.g., 16x16 tiles).
2.  **Dynamic Loading**: Automatically load and render chunks within a specified radius around the player.
3.  **Dynamic Unloading**: (Optional for now) Unload chunks that are far away to save memory/performance.
4.  **Performance**: Spread loading over frames or use threading if necessary (though simple single-thread usually fine for 2D).
5.  **Integration**: Ensure `WorldRenderer` handles this logic or delegates to a new manager.

## Technical Details

- **Chunk Size**: 16x16 tiles (matches `TileMapLayer` efficiency).
- **Render Distance**: ~4 chunks radius (64 tiles) horizontally and vertically from player.
- **Update Frequency**: Check player position every frame or periodically.

## Success Criteria

- User can travel infinitely in any direction and see continuous terrain.
- No visible gaps or "pop-in" within the immediate view.
