---
name: roblox-studio-mcp
description: "Use when you need to leverage the built-in Roblox Studio MCP Server. Trigger this skill when the user asks to insert models, inspect the workspace, execute scripts inside the running Studio, control playtesting, or interact with instances directly through the MCP connection."
---

# Roblox Studio MCP Skill

This skill defines the workflows and best practices for utilizing the **Roblox Studio Model Context Protocol (MCP) Server**. It enables AI agents to bridge the gap between local file editing and live Studio interactions using stdio transport.

## 🚀 Core Capabilities & Tools
The server provides the following categories of tools that you can use:

### 1. Scripts
- `script_read`: Reads a scripts from the game using dot-notation paths (for example, `game.ServerScriptService.MyScript`). Supports reading entire scripts or specific line ranges.
- `multi_edit`: Applies multiple edits to a script. If the target path doesn't exist, it creates a new script.
- `script_search`: Searches for scripts by name using fuzzy matching. Returns up to 10 results.
- `script_grep`: Searches for a string pattern across all scripts in the game. Returns up to 50 matches.

### 2. Asset and Content Generation
- `generate_mesh`: Generates a textured 3D mesh.
- `generate_material`: Generates custom material or texture.
- `generate_procedural_model`: Generates custom procedural models that scale and adapt automatically.
- `insert_from_creator_store`: Inserts assets, plugins, and models from the Creator Store. (Or use equivalent `insert_model`).

### 3. Data Model Exploration
- `explore_subagent`: Investigates your place in parallel and returns a compact summary without cluttering the main conversation.
- `search_game_tree`: Explores the instance hierarchy as a flat JSON array. Supports filtering by path, instance type, and keywords.
- `inspect_instance`: Returns detailed information about a specific instance, including readable properties, custom attributes, and a summary of its children and descendants.

### 4. Luau Execution
- `execute_luau` (or `run_code`): Runs Luau code in Studio. Returns either the result or an error. Extremely useful for querying the current state of the game or manipulating properties.

### 5. Playtesting
- `start_stop_play`: Starts or stops playtesting.
- `console_output`: Retrieves output logs while the game is running.
- `screen_capture`: Captures the current Studio viewport in Play mode and returns the image data.
- `playtest_subagent`: Spawns a test character that runs through gameplay scenarios.

### 6. Player Input Simulation
- `character_navigation`: Moves the player character to a position or instance.
- `keyboard_input`: Simulates key presses, key holds, and text input.
- `mouse_input`: Simulates mouse clicks, movement, and scrolling.

### 7. Session Management
- `list_roblox_studios`: Lists all connected Studio instances, including their name, ID, and active status. This is useful when multiple Studio windows are open.
- `set_active_studio`: Sets a Studio instance as active so that all subsequent tool calls target that instance.

## ⚠️ Best Practices & Rules
1. **Never Assume the DataModel:** Always use `search_game_tree`, `inspect_instance`, or `execute_luau` to verify paths and names of objects in Studio instead of guessing.
2. **Prioritize Local Files for Logic:** For writing robust code, write to the local file system (e.g., `src/`) to let Rojo sync it. Use MCP's script editing primarily for quick prototyping or fixing isolated issues directly in Studio.
3. **Reset After Testing:** If you use `start_stop_play` to test a feature, remember to stop the playtest once debugging is complete so the user can continue building.
4. **Read Context:** Ensure you know the current Studio mode (`get_studio_mode`) before running playtest-specific commands or executing scripts that only work in Edit mode.
5. **Multiple Instances:** If tool calls fail because they target the wrong Studio session, use `list_roblox_studios` and `set_active_studio` to ensure you are talking to the correct open project.
