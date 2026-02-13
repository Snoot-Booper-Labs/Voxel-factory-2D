# Specification: Miner Inventory Access Interface

## Goal
Allow the player to access the miner's inventory using a dedicated UI window.

## Requirements

### Interaction
- **Trigger**: The interface should be opened/closed by pressing the 'E' interact key.
- **Context**: Interaction should happen when the player is within range of a specific miner entity.
- **Binding**: Use the existing input map for 'E'.

### UI Layout
- **Position**: The miner inventory window must anchor directly above the existing player inventory window.
- **Existing Inventory**: anchored to the bottom of the screen.
- **Visibility**: The UI nodes must be present and visible in the `main.tscn` scene tree (Godot GUI).

### Technical Implementation
- **Scene Structure**: Add the new UI nodes to `main.tscn` under the main CanvasLayer.
- **Scripting**:
    - Implement a controller/manager to handle the 'E' key toggle.
    - Connect the miner entity's inventory data to the UI.
