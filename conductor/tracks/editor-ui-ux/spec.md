# Specification: Editor UI UX Improvements

## Goal
Make the main game scene more visual and interactive in the Godot Editor. Currently, nodes are blank/invisible and difficult to work with.

## Requirements

### Player Entity
- **Visibility**: The Player node must be visible in the editor with a sprite/texture, not just a placeholder.
- **Editability**: Developers should be able to change the sprite/texture and animations directly from the inspector on the main scene instance.
- **Default State**: The player should have a default appearance in the editor.

### UI Components (Hotbar & Inventory)
- **Editor Rendering**: The `HotbarUI` and `InventoryUI` must be rendered in the editor using `@tool`.
- **Interactivity**: Developers should be able to see the layout and potentially tweak properties (like slot size, spacing) and see updates in real-time.
- **Visuals**: Drawn boxes/panels should be visible to represent the UI structure.

## Technical Approach
- Add `@tool` to `HotbarUI`, `InventoryUI`, and possibly `PlayerController` or related scripts.
- Implement `_ready()` or `_draw()` logic that runs in the editor (`Engine.is_editor_hint()`).
- Use `notify_property_list_changed()` or setters to refresh in editor when properties change.
