# Spec: Fix Player Interaction

## Problem

The user reports that while walking (left/right) and hotbar selection (1-9) work, other key interactions are non-functional:
- **Jump**: Space/Up does not make the player jump.
- **Inventory**: E/I/Tab does not toggle the inventory screen.
- **Mining/Placement**: "Nothing else" works, implying these might also be affected or untested.

## Root Cause Hypotheses

1.  **Missing Input Actions**: The code references input actions (e.g., `jump`, `toggle_inventory`) that are not defined in `project.godot`.
2.  **Input Manager Logic**: The `InputManager` might not be correctly delegating these specific events.
3.  **UI Focus**: The UI might be consuming input events, preventing them from reaching game logic.
4.  **Signal Disconnection**: The signals between InputManager/UI and the controllers might be missing.

## Requirements

- [ ] **Jump**: Pressing the configured jump key (default: Space) makes the player jump when on the ground.
- [ ] **Inventory Toggle**: Pressing the inventory key (default: E or Tab) opens/closes the inventory UI.
- [ ] **Mining**: Left-click mines blocks within range.
- [ ] **Placement**: Right-click places blocks within range.
- [ ] **Verify Input Map**: Ensure all required actions are present in `project.godot`.

## Success Criteria

- User verifies that Jump works.
- User verifies that Inventory Toggle works.
- User verifies that Mining/Placement works.
