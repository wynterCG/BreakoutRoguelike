# Phase 5B: Formation Editor Plugin — Design Spec

## Context

Phase 5A built the formation data system: FormationCell, FormationData, LevelPool resources, 100 pattern templates, and role-based monster assignment. Currently formations are created by editing .tres files in the inspector or setting a template_index. Phase 5B adds a visual Formation Editor plugin inside the Godot editor for painting formations on a grid, assigning monsters, and managing level pools.

## Plugin Overview

An `EditorPlugin` that adds a dock panel to the Godot editor with three sections:

1. **Left panel**: Formation list + Level Pool manager
2. **Center panel**: Visual grid editor with template dropdown and paint tools
3. **Right panel**: Cell inspector + formation stats

## Plugin Files

| File | Purpose |
|---|---|
| `res://addons/formation_editor/plugin.cfg` | Plugin metadata |
| `res://addons/formation_editor/plugin.gd` | EditorPlugin — loads/unloads the dock |
| `res://addons/formation_editor/formation_editor_dock.gd` | Main dock script — three-panel layout |
| `res://addons/formation_editor/formation_editor_dock.tscn` | Dock scene |
| `res://addons/formation_editor/grid_editor.gd` | Center panel — grid rendering + painting |
| `res://addons/formation_editor/cell_inspector.gd` | Right panel — cell editing |
| `res://addons/formation_editor/formation_list.gd` | Left panel — formation list + level pools |

## Left Panel: Formation List + Level Pools

### Formation List
- Shows all FormationData `.tres` files from `res://data/formations/`
- Each item shows: name, grid size, template index
- **+ New** button: creates a new FormationData with defaults, saves to .tres
- **Delete** button: deletes selected formation .tres file
- Clicking a formation loads it into the grid editor

### Level Pool Manager
- Shows all LevelPool `.tres` files from `res://data/level_pools/`
- Each pool shows its level number and linked formations
- **+ Add Formation** button on each pool: dropdown to pick from existing formations
- **✕** button: remove formation from pool
- **+ New Level Pool**: creates a new LevelPool .tres with the next level number
- Changes auto-save to the .tres file

## Center Panel: Grid Editor

### Controls Bar (top)
- **Name**: text input for `formation_name`
- **Cols**: number input (1-20) for `grid_columns`
- **Rows**: number input (1-10) for `grid_rows`
- **Template dropdown**: lists all 100 templates by index and name from `FormationTemplates.TEMPLATE_NAMES`
- **Apply Template** button: generates cells from the selected template using current cols/rows, replaces the grid

### Paint Tool Bar
- **Role paint buttons**: Front (green), Tank (yellow), Support (red), Elite (purple)
- **Erase** button: removes a cell
- **Clear All**: removes all cells
- **Fill All**: fills every grid position with the current paint role
- Active tool is highlighted

### Grid Area
- Visual grid of cells based on `grid_columns` x `grid_rows`
- Empty cells shown as dark/transparent
- Filled cells colored by role (green/yellow/red/purple)
- **Left click**: paint cell with current tool (or erase if eraser selected)
- **Click and drag**: paint multiple cells
- **Right click**: select cell for inspector (highlighted with border)
- Cell labels show role letter (F/T/S/E) or monster name if overridden

### Behavior
- Changing cols/rows resizes the grid immediately (cells outside new bounds are removed)
- Applying a template replaces all cells
- All changes update the FormationData resource in memory
- **Save** button writes to the .tres file

## Right Panel: Cell Inspector

### Cell Details (shown when a cell is right-clicked)
- **Position**: read-only, shows (col, row)
- **Role**: dropdown — Front, Tank, Support, Elite
- **Monster Override**: dropdown — "Auto (by role)" or specific MonsterData from `res://data/monsters/`
- Changes apply immediately to the selected cell

### Formation Stats
- Total cells count
- Count per role (Front, Tank, Support, Elite)
- Count of cells with monster overrides

### Actions
- **Auto-assign roles by row**: runs `_role_for_row()` on all cells, resetting roles based on row position
- **Save Formation**: saves current FormationData to its .tres file
- **Save & Preview**: saves and runs the game scene (stretch goal)

## Grid Rendering

The grid is rendered using Godot's `Control` node drawing:
- Override `_draw()` on a custom `Control` node
- Draw cell rectangles with colors based on role
- Draw grid lines
- Draw selection highlight
- Respond to `_gui_input()` for mouse clicks and drags

Alternative: use a `GridContainer` with `ColorRect` children. Simpler but may be slower for large grids. Since max is 20x10 = 200 cells, `GridContainer` approach is fine.

## Data Flow

```
User clicks "Apply Template"
  → FormationTemplates.generate(index, cols, rows) → Array[FormationCell]
  → Formation resource's cells array updated
  → Grid redraws

User paints a cell
  → If cell exists at position: update its role (or remove if erasing)
  → If cell doesn't exist: create new FormationCell at position with current role
  → Grid redraws

User clicks "Save"
  → ResourceSaver.save(formation, path)
  → EditorInterface.get_resource_filesystem().scan()

User adds formation to level pool
  → Pool's formations array gets the FormationData reference appended
  → ResourceSaver.save(pool, path)
```

## What's New

| File | Purpose |
|---|---|
| `res://addons/formation_editor/plugin.cfg` | Plugin metadata |
| `res://addons/formation_editor/plugin.gd` | EditorPlugin loader |
| `res://addons/formation_editor/formation_editor_dock.gd` | Main dock controller |
| `res://addons/formation_editor/formation_editor_dock.tscn` | Dock scene layout |
| `res://addons/formation_editor/grid_editor.gd` | Grid painting + rendering |
| `res://addons/formation_editor/cell_inspector.gd` | Cell editing panel |
| `res://addons/formation_editor/formation_list.gd` | Formation list + level pools |

## What Changes

| File | Change |
|---|---|
| `project.godot` | Add formation_editor to enabled plugins |

## Verification

1. Enable plugin in Project Settings > Plugins
2. Dock appears in bottom-right panel
3. Create a new formation — .tres file appears in `res://data/formations/`
4. Set cols=14, rows=7, pick template "Diamond", click Apply — grid shows diamond pattern
5. Paint cells: click with Front tool = green cell, Tank = yellow, Erase = remove
6. Right-click cell — inspector shows position, role, monster override
7. Change a cell's monster override to "Brute" — cell shows "Brute" label
8. Save formation — .tres file updated
9. Create level pool — .tres file appears in `res://data/level_pools/`
10. Add formations to pool — pool .tres updated
11. Run game — level uses formation from pool
