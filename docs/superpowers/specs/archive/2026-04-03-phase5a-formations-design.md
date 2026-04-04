# Phase 5A: Room Formations + Data-Driven Enemy Progression — Design Spec

## Context

Phases 1–4 are complete. Currently every level uses the same 14x5 grid with the same 3 monster types. Phase 5A adds formation variety and data-driven enemy progression — different patterns per level, monsters that unlock at specific levels, and role-based row placement (front/tank/support/elite).

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

### Future Monsters (examples, not implemented now)

| Monster | HP | min_level | role | Notes |
|---|---|---|---|---|
| Healer | 3 | 6 | support | Would heal adjacent blocks (future mechanic) |
| Caster | 2 | 8 | support | Would shoot projectiles (future mechanic) |
| Champion | 8 | 10 | elite | Rare, high HP, placed anywhere |

Adding a new monster is: create a `.tres` file with the right `min_level` and `role`. No code changes needed.

## Role-Based Row Placement

Formations have rows assigned by role:

| Row Position | Role | Purpose |
|---|---|---|
| Back rows (top of screen, rows 0-1) | support | Hardest to reach, protected by tanks |
| Middle rows (rows 2-3) | tank | Tough, shield the support line |
| Front rows (bottom, rows 4+) | front | Closest to paddle, cannon fodder |
| Any open slot | elite | Randomly placed wherever there's space |

If no monsters exist for a role at the current level (e.g., no support before level 6), those rows are filled with the next available role (tanks fill support slots, fronts fill tank slots).

## Formation Generator

New script: `res://scripts/formation_generator.gd`

### Interface

```gdscript
static func generate(level: int, all_monsters: Array[MonsterData]) -> Array[Dictionary]
```

Returns an array of `{"position": Vector2, "monster": MonsterData}` dictionaries.

### How It Works

1. **Filter monsters**: only those with `min_level <= level`
2. **Group by role**: separate into front, tank, support, elite arrays
3. **Pick a pattern**: randomly select from 10 formation patterns
4. **Pattern generates positions**: each pattern returns positions organized by row
5. **Assign monsters to positions by role**: back rows get support, middle get tanks, front get fronts, elites scattered randomly

### 10 Formation Patterns

Each pattern is a function that returns block positions within the arena bounds (x: 120–1100, y: 50–200). Patterns define the shape; monster assignment happens after.

| # | Name | Shape Description |
|---|---|---|
| 1 | `full_grid` | Classic 14x5 dense grid |
| 2 | `diamond` | Diamond/rhombus shape centered |
| 3 | `v_shape` | V pointing down toward paddle |
| 4 | `walls` | Two vertical columns with a gap in the middle |
| 5 | `checkerboard` | Alternating filled/empty in a grid |
| 6 | `cross` | Plus sign shape |
| 7 | `scattered` | Random sparse placement (40-60% fill) |
| 8 | `corridor` | Narrow horizontal rows with gaps |
| 9 | `pyramid` | Triangle pointing up |
| 10 | `border` | Only the outer frame/outline |

### Level Scaling

Block HP still scales: `base_hp * (1 + (level - 1) * 0.2)` (from Phase 4, unchanged).

## Changes to main.gd

### `_spawn_enemies()` Refactor

Replace the hardcoded grid loop with:

```
1. Filter _monster_types by min_level <= _level
2. Call FormationGenerator.generate(_level, filtered_monsters)
3. Loop through returned array, create blocks at each position with assigned monster
```

### Remove Hardcoded Grid Constants

`GRID_COLS`, `GRID_ROWS`, `BLOCK_SPACING_X`, `BLOCK_SPACING_Y`, `GRID_OFFSET` are no longer needed — the formation generator handles all positioning.

## Changes to Monster Editor Dock

The dock already shows monsters from `res://data/monsters/`. The new `min_level` and `role` fields will automatically appear in the Inspector when clicking a monster (they're `@export` fields). No dock code changes needed.

## Update Existing .tres Files

- `grunt.tres`: add `min_level = 1`, `role = &"front"`
- `warrior.tres`: add `min_level = 3`, `role = &"tank"`
- `brute.tres`: add `min_level = 5`, `role = &"tank"`

## What's New

| File | Purpose |
|---|---|
| `res://scripts/formation_generator.gd` | Static formation pattern functions + monster assignment |

## What Changes

| File | Change |
|---|---|
| `res://scripts/data/monster_data.gd` | Add `min_level` and `role` fields |
| `res://scripts/main.gd` | Refactor `_spawn_enemies()` to use FormationGenerator |
| `res://data/monsters/*.tres` | Add min_level and role to all 3 monsters |

## Verification

1. Level 1-2: only Grunts appear, various formation patterns
2. Level 3-4: Grunts in front rows + Warriors in middle rows
3. Level 5+: Grunts in front, Warriors + Brutes in middle
4. Different formation each level (not always the same pattern)
5. HP scaling still works across levels
6. Upgrade selection still triggers after each level
7. Adding a new monster .tres with min_level=4 makes it appear at level 4+
