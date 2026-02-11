# Workflow

## Conductor Plugin
The **Conductor Plugin** (located at `~\.gemini\extensions\conductor`) MUST always be used for all project management, planning, and implementation tasks. 

- Use `/conductor:newTrack` for any new feature or bug fix.
- Use `/conductor:implement` to execute approved track plans.
- Refer to `conductor/tracks.md` for the current project status.
- Follow the **Context -> Spec & Plan -> Implement** lifecycle for every task.


## Development Loop (The Ralph Loop)

1.  **Plan**: Define the task in a Track Plan.
2.  **Test**: Write a failing test (Red).
3.  **Implement**: Write code to pass the test (Green).
4.  **Refactor**: Clean up the code (Refactor).
5.  **Verify**: Run the full suite.

## Track Completion & Merging

**CRITICAL: Human in the Loop (HITL) Policy**
Before merging any feature branch into `main`:

1.  **Automated Tests**: All automated tests (unit + integration) must pass.
2.  **Manual Verification**: Ask the HUMAN user to manually test the feature in the game.
3.  **Approval**: WAIT for explicit user confirmation that the feature works as intended.
    - If issues are found, return to the Development Loop.
    - Only after explicit approval, merge the branch.

## Testing

### Command Format
Always use the headless command.
**CRITICAL**: When specifying a test file or directory, you **MUST** use the `res://` prefix.

**Correct:**
Windows: `..\engine\Godot_v4.6-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_foo.gd`

MacOS: `/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_foo.gd`

**Incorrect:**
`..\engine\Godot_v4.6-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gtest=tests/unit/test_foo.gd`

### Command Components
- **Executable**: `..\engine\Godot_v4.6-stable_win64_console.exe`
- **Headless flag**: `--headless`
- **Script flag**: `-s addons/gut/gut_cmdln.gd`
- **Test filter**:
    - Specific file: `-gtest=res://tests/unit/test_name.gd`
    - Directory: `-gdir=res://tests/unit/`
