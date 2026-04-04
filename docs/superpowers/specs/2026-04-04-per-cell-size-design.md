# Per-Cell Size Scaling for Formations

## Goal

Allow each cell in a formation to have an independent size scale (width and height), so blocks can be bigger or smaller than the default 60x24. The rest of the formation auto-aligns using row-based layout: each row's vertical position adjusts based on the tallest block in the row above.

## Architecture

Size scale is a property of **FormationCell**, independent from role and monster override. A tiny elite boss surrounded by massive front-line grunts is a valid configuration. The scale affects both visuals (collision shape, HP bar) and gameplay (bigger blocks are easier to hit).

## Data Model

**FormationCell** (`res://scripts/data/formation_cell.gd`) — add one property:

- `size_scale: Vector2 = Vector2(1.0, 1.0)` — width and height multipliers
- Range: 0.5 to 3.0 per axis
- Default: `(1.0, 1.0)` — standard 60x24 block
- Examples: `(2.0, 1.5)` = 120x36 block, `(0.5, 0.5)` = 30x12 block

No changes to FormationData, MonsterData, or LevelPool.

## Spawning Logic

**main.gd** `_spawn_from_formation()` changes:

### Row-based Y alignment

Before placing blocks, pre-calculate row heights:

1. Scan all cells, group by `grid_position.y` (row index)
2. For each row, find the tallest block: `max(base_height * cell.size_scale.y)` across all cells in that row
3. Build a cumulative Y offset array: `row_y[r] = row_y[r-1] + tallest_in_row[r-1] + vertical_spacing`

### X positioning

Keep grid-based X positioning (centered on grid slot). Wider blocks extend beyond their cell. The user leaves empty neighbor cells in the editor to prevent overlap.

### Block size

Pass `base_size * cell.size_scale` to the block. Block already supports custom sizes via `_block_size` (set in `_ready()` from `monster_data.size` or constants). The cell scale overrides this: `_block_size = Vector2(BLOCK_WIDTH * scale.x, BLOCK_HEIGHT * scale.y)`.

### Centering

Horizontal centering uses the same formula but X spacing stays uniform (base grid spacing). The formation width stays grid-based so centering isn't affected by individual cell widths.

## Block Changes

**block.gd** — add a `size_scale` property:

- `@export var size_scale: Vector2 = Vector2(1.0, 1.0)`
- In `_ready()`, apply scale: `_block_size = Vector2(BLOCK_WIDTH * size_scale.x, BLOCK_HEIGHT * size_scale.y)`
- This takes priority over `monster_data.size` when `size_scale != (1.0, 1.0)`
- Collision shape, background, fill bar, and label all use `_block_size` already, so they auto-adjust

## Formation Editor Changes

**formation_editor_dock.gd** — cell inspector additions:

### UI Controls (right panel, below monster dropdown)

- **Width Scale** — HSlider, range 0.5 to 3.0, step 0.1, default 1.0, with SpinBox showing the value
- **Height Scale** — HSlider, range 0.5 to 3.0, step 0.1, default 1.0, with SpinBox showing the value
- **Reset Size** button — snaps both back to 1.0

### Grid Preview

Grid cells reflect scaled sizes visually. A 2x wide cell appears wider in the grid paint view. This helps the user see which cells need empty neighbors to avoid overlap.

### Arena Preview

The arena preview already renders blocks at actual size, so scaled blocks will display correctly with no additional work — the preview reads block size from the spawned block's `_block_size`.

## Formation Templates

Templates generate cells with default `size_scale = (1.0, 1.0)`. The user can then select individual cells in the editor and adjust their scale. Template-generated cells are editable after generation.

## Backward Compatibility

Existing `.tres` formation files have no `size_scale` property. Godot's Resource system defaults missing exported properties, so `size_scale` will be `Vector2(1.0, 1.0)` — no migration needed. Existing formations behave identically.

## Files Modified

| File | Change |
|---|---|
| `res://scripts/data/formation_cell.gd` | Add `size_scale: Vector2` export |
| `res://scripts/block.gd` | Add `size_scale` export, apply in `_ready()` |
| `res://scripts/main.gd` | Row-based Y alignment in `_spawn_from_formation()` |
| `res://addons/formation_editor/formation_editor_dock.gd` | Width/Height sliders in inspector, scaled grid preview |

## Verification

1. Open formation editor, select a cell, adjust width to 2.0 — cell appears wider in grid
2. Adjust height to 1.5 — cell appears taller in grid
3. Click Reset Size — both go back to 1.0
4. Save formation, run game — scaled blocks appear at correct size
5. Place a 2x tall block in row 1 — row 2 blocks shift down to accommodate
6. Existing formations without size_scale load and play normally (backward compat)
7. Mix sizes: tiny elite surrounded by large front-line — all render correctly
