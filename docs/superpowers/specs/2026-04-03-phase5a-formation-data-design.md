# Phase 5A: Formation Data System — Design Spec

## Context

Currently every level uses the same hardcoded 14x5 grid. Phase 5A introduces a data-driven formation system: formations are saved as resources, each cell can have a role or a specific monster override, and level pools define which formations can appear at each level.

This spec covers the data system only. A visual Formation Editor plugin will come in a separate spec.

## MonsterData Changes

Add two new fields to `res://scripts/data/monster_data.gd`:

```gdscript
@export var min_level: int = 1
@export var role: StringName = &"front"  # "front", "tank", "support", "elite"
```

### Current Monsters Updated

| Monster | HP | min_level | role |
|---|---|---|---|
| Grunt | 1 | 1 | front |
| Warrior | 2 | 3 | tank |
| Brute | 5 | 5 | tank |

Adding new monsters later: create a .tres with the right `min_level` and `role`. They auto-appear at the correct level in formations that use role-based assignment.

## New Resources

### FormationCell (`res://scripts/data/formation_cell.gd`)

```gdscript
extends Resource
class_name FormationCell

@export var grid_position: Vector2i = Vector2i.ZERO  # (column, row)
@export var role: StringName = &"front"              # "front", "tank", "support", "elite"
@export var monster_override: MonsterData = null      # optional: force specific monster
```

- `grid_position`: column (0-13) and row (0-6) on the arena grid
- `role`: determines which monster gets assigned at runtime based on what's unlocked
- `monster_override`: if set, this exact monster is used instead of role-based selection

### FormationData (`res://scripts/data/formation_data.gd`)

```gdscript
extends Resource
class_name FormationData

@export var formation_name: String = ""
@export var grid_columns: int = 14
@export var grid_rows: int = 7
@export var cells: Array[FormationCell] = []
```

- `grid_columns` and `grid_rows`: custom grid size per formation. Defaults are 14x7 but each formation can use a different grid size (e.g., a tight 8x4 or a wide 14x8).
- The spawner uses these values for positioning instead of global constants.

Stored as `.tres` files in `res://data/formations/`.

### LevelPool (`res://scripts/data/level_pool.gd`)

```gdscript
extends Resource
class_name LevelPool

@export var level_number: int = 1
@export var formations: Array[FormationData] = []
```

Stored as `.tres` files in `res://data/level_pools/` (e.g., `level_01.tres`, `level_02.tres`).

Each level pool contains references to formations that can appear at that level. At runtime, one formation is picked randomly from the pool.

## Grid Constants

The arena grid is defined by:
- **Columns**: 0–13 (14 columns)
- **Rows**: 0–7 (up to 8 rows)
- **Spacing X**: 70px between block centers
- **Spacing Y**: 30px between block centers
- **Grid offset**: (145, 60) from top-left of arena

These remain as constants — formations reference grid positions (column, row), and the spawner converts to pixel positions.

## Role-Based Monster Selection

When spawning a cell with no `monster_override`:

1. Get all MonsterData where `min_level <= current_level`
2. Filter by `role == cell.role`
3. Pick randomly from filtered list
4. If no monsters match the role, fall back to any unlocked monster

## Runtime Flow

```
Level starts
  → Load LevelPool for current level from res://data/level_pools/
  → If no pool exists: use fallback (full_grid pattern)
  → Pick random FormationData from pool
  → For each FormationCell:
      → If monster_override: use that monster
      → Else: pick monster by role from unlocked pool
      → Scale HP: base_hp * (1 + (level - 1) * 0.2)
      → Convert grid_position to pixel position
      → Spawn block
```

## Pattern Template Generator

`res://scripts/formation_templates.gd` — static class with 100 pattern functions.

Each function takes `columns: int` and `rows: int` and returns `Array[FormationCell]` — a list of cells with grid positions and roles assigned by row (back=support, middle=tank, front=front).

These are used as **starting templates** when creating formations. You pick a template, it generates the cells, then you manually tweak (add/remove blocks, change roles, assign specific monsters) via the inspector or the future editor plugin.

### Usage Flow

1. Create new FormationData resource
2. Set `grid_columns` and `grid_rows` (or keep defaults 14x7)
3. In the future Formation Editor: pick a template from a dropdown → cells populate
4. Edit cells manually (add/remove, change roles, set monster overrides)
5. Save the .tres file

For now (without the visual editor), templates are used programmatically to generate the starter formations. The Formation Editor plugin (Phase 5B) will expose them as a dropdown.

## Pixel Position Conversion

Grid positions convert to pixel positions using per-formation grid size:

```
pixel_x = GRID_OFFSET.x + cell.grid_position.x * (ARENA_WIDTH / formation.grid_columns)
pixel_y = GRID_OFFSET.y + cell.grid_position.y * (ARENA_HEIGHT / formation.grid_rows)
```

Where `ARENA_WIDTH = 980` (playable area) and `ARENA_HEIGHT = 200` (block area height). This means a 14-column formation has tighter spacing than an 8-column one — blocks auto-space to fill the arena.

## Changes to main.gd

### Refactor `_spawn_enemies()`

Replace the hardcoded grid loop with:

1. Load `LevelPool` for `_level`
2. Pick random `FormationData` from pool
3. Read `formation.grid_columns` and `formation.grid_rows` for positioning
4. Iterate `formation.cells`
5. For each cell: resolve monster (override or role-based), create block, position it

### Remove Hardcoded Grid

Remove `GRID_COLS` and `GRID_ROWS` constants. Keep `GRID_OFFSET` as the starting position. Spacing is calculated from the formation's grid size.

### Fallback

If no LevelPool exists for the current level, spawn a full 14x7 grid using the first available monster (backward compatible).

## Starter Formations

Create 5 starter formations using templates (more will be added via the editor later):

1. **full_grid** — classic 14x5 dense grid (template #1)
2. **diamond** — diamond shape centered (template #2)
3. **v_shape** — V pointing down (template #3)
4. **checkerboard** — alternating blocks (template #5)
5. **border** — outer frame only (template #10)

Create 2 starter level pools:
- `level_01.tres` — contains full_grid, checkerboard, border (easy patterns)
- `level_02.tres` — contains diamond, v_shape (slightly harder)

Levels without a pool use the fallback full grid.

## What's New

| File | Purpose |
|---|---|
| `res://scripts/data/formation_cell.gd` | FormationCell resource class |
| `res://scripts/data/formation_data.gd` | FormationData resource class (with grid_columns, grid_rows) |
| `res://scripts/data/level_pool.gd` | LevelPool resource class |
| `res://scripts/formation_templates.gd` | 100 pattern template functions |
| `res://data/formations/*.tres` | 5 starter formation files |
| `res://data/level_pools/*.tres` | 2 starter level pool files |

## What Changes

| File | Change |
|---|---|
| `res://scripts/data/monster_data.gd` | Add `min_level` and `role` fields |
| `res://data/monsters/*.tres` | Add min_level and role to all 3 monsters |
| `res://scripts/main.gd` | Refactor `_spawn_enemies()` to use formations + level pools |

## Verification

1. Level 1: formation from level_01 pool appears (full_grid, checkerboard, or border)
2. Level 2: formation from level_02 pool appears (diamond or v_shape)
3. Level 3+: fallback full grid (no pool defined yet)
4. Formations with different grid sizes display correctly (blocks auto-space)
5. Monsters assigned by role — front in bottom rows, tank in middle
6. Level 3+: Warriors start appearing (min_level=3)
7. Level 5+: Brutes start appearing (min_level=5)
8. HP scaling works across all formations
9. Upgrade selection still works between levels
