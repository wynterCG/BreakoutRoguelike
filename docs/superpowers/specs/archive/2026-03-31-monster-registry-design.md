# Monster Registry Editor Plugin — Design Spec

## Context

Phase 2 of the Breakout Roguelike replaces static blocks with dynamic enemies (monsters). Currently, block types are hardcoded in `main.gd` with HP values assigned by grid row. We need a data-driven system to define monster types and a visual editor tool to manage them from within the Godot editor.

## MonsterData Resource

**File:** `res://scripts/data/monster_data.gd`

A custom `Resource` subclass representing a single monster type definition.

### Exported Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `monster_name` | `String` | `""` | Display name (e.g., "Grunt", "Brute") |
| `hp` | `int` | `1` | Hit points. Drives color tier (1=green, 2=yellow, 3=red) |
| `color` | `Color` | `Color(0.2, 0.8, 0.2)` | Visual color. Defaults to HP-tier color but can be overridden |
| `size` | `Vector2` | `Vector2(60, 24)` | Block dimensions in pixels |

### Storage

Each monster type is a `.tres` file in `res://data/monsters/` (e.g., `grunt.tres`, `brute.tres`, `tank.tres`).

## Editor Plugin: Monster Editor

**Plugin path:** `res://addons/monster_editor/`

### Files

- `plugin.cfg` — Plugin metadata
- `plugin.gd` — Registers/unregisters the dock
- `monster_editor_dock.gd` — Dock UI logic
- `monster_editor_dock.tscn` — Dock scene layout

### Dock UI

- **ItemList** — displays all `.tres` files found in `res://data/monsters/`, showing monster name and HP
- **Create button** — opens a dialog prompting for a name, creates a new `MonsterData` resource with defaults, saves to `.tres`
- **Delete button** — deletes the selected monster's `.tres` file after confirmation
- **Clicking an item** — selects the resource in Godot's inspector via `EditorInterface.inspect_object()`
- **Refresh** — auto-refreshes when the filesystem changes (connects to `EditorFileSystem.filesystem_changed`)

### Plugin Registration

- Extends `EditorPlugin`
- Adds the dock via `add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock_instance)`
- Removes the dock on `_exit_tree()`

## Game Integration

### Block Refactor

The existing `Block` class (`res://scripts/block.gd`) gets a new `@export var monster_data: MonsterData` field. On `_ready()`:
- If `monster_data` is set, read `hp`, `color`, and `size` from the resource
- If not set, fall back to current behavior (for backwards compatibility during transition)

### Spawn System

`main.gd`'s `_spawn_blocks()` becomes `_spawn_enemies()`:
- Loads monster resources from `res://data/monsters/`
- Assigns them to blocks during grid instantiation
- Grid layout stays the same for now (Phase 5 will handle procedural room generation)

### What Stays the Same

- `HealthComponent` — unchanged, still initialized with HP from monster data
- Ball/Paddle physics — unchanged
- Signal flow (`destroyed`, `health_changed`) — unchanged
- Color update logic in Block — now reads from `monster_data.color` instead of hardcoded array

## Verification

1. Enable the Monster Editor plugin in Project Settings > Plugins
2. Confirm the dock appears in the editor
3. Create 3 monster types: Grunt (1 HP, green), Warrior (2 HP, yellow), Brute (3 HP, red)
4. Run the game and confirm monsters spawn with correct HP, colors, and sizes
5. Edit a monster's HP in the inspector, re-run, confirm change is reflected
