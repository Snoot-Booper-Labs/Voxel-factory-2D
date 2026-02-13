# Agent Orientation Guide

Welcome, Agent. This file outlines the structure and context sources for the **Program Builder** project.

## 🚀 Critical Starting Point: The Conductor

The **Conductor** is the central nervous system for context-driven development in this project. You **MUST** consult this folder to understand the current state, active tasks, and development rules.

*   **[conductor/index.md](../conductor/index.md)**: The entry point for the Conductor. **Read this first.**
*   **[conductor/workflow.md](../conductor/workflow.md)**: Explains the development workflow you are expected to follow.
*   **[conductor/tracks/](../conductor/tracks/)**: Contains specific development tracks (feature branches/tasks).

## 📚 Project Documentation

The `docs/` folder contains static documentation regarding the project's design, architecture, and mechanics.

*   **[docs/README.md](../docs/README.md)**: Overview of the project documentation.
*   **[docs/architecture.md](../docs/architecture.md)**: High-level architecture and code organization.
*   **[docs/gameplay.md](../docs/gameplay.md)**: Explanation of gameplay mechanics.
*   **[docs/api_reference.md](../docs/api_reference.md)**: API reference for core systems.

## 📂 Repository Layout

*   **`game/`**: The main Godot project source code.
    *   `game/scripts/`: GDScript files.
    *   `game/scenes/`: Scene files (.tscn).
    *   `game/resources/`: Game resources (.tres).
    *   `game/tests/`: Unit and integration tests (using GUT).
*   **`.agent/`**: Agent-specific configuration, workflows, and memory.
*   **`conductor/`**: Context and task management.


## 💡 Best Practices for Agents

1.  **Context First**: Always check `conductor/` to see what is currently being worked on (`active_track`).
2.  **Follow the Ralph Loop**: Plan -> Test (Red) -> Implement (Green) -> Refactor -> Verify.
3.  **Update Documentation**: You are responsible for maintaining the `docs/` folder. As features are added or changed, the documentation **MUST** be updated to reflect the current status of the project. Obsolete documentation is technical debt.
4.  **Test Your Code**: Run tests using GUT to ensure no regressions.
5.  For Python commands, always use `uv`, for example: `uv run python script.py`

### 🧪 Testing Command (CRITICAL)

When running tests from within the game folder, strict adherence to the command format is required.

**MacOS Command:**
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_foo.gd
```

**Windows Command:** exe is located two directories up from the game folder in which the commands should be run.
```bash
..\..\engine\Godot_v4.6-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_foo.gd
```

*   **Must use `--headless`**
*   **Must use `res://` prefix for test paths** (e.g., `res://tests/unit/test_foo.gd`)
