# Phase 5A: Formation Data System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hardcoded 14x5 grid with a data-driven formation system: FormationData resources with custom grid sizes, role-based monster assignment, LevelPool resources for per-level formation pools, and 100 pattern templates for generating formations.

**Architecture:** Three new Resource classes (FormationCell, FormationData, LevelPool) store formation data. A FormationTemplates static class provides 100 pattern generators. main.gd loads LevelPool for the current level, picks a random formation, resolves monsters by role, and spawns blocks at grid-calculated positions.

**Tech Stack:** Godot 4.6, GDScript 2.0, strict static typing, Resource pattern.

---

### Task 1: Add min_level and role to MonsterData + update .tres files

**Files:**
- Modify: `res://scripts/data/monster_data.gd`
- Modify: `res://data/monsters/grunt.tres`
- Modify: `res://data/monsters/warrior.tres`
- Modify: `res://data/monsters/brute.tres`

- [ ] **Step 1: Add fields to MonsterData**

Add to `res://scripts/data/monster_data.gd` after the `size` export:
```gdscript
@export var min_level: int = 1
@export var role: StringName = &"front"
```

- [ ] **Step 2: Update grunt.tres**

Add to the `[resource]` section:
```
min_level = 1
role = &"front"
```

- [ ] **Step 3: Update warrior.tres**

Add to the `[resource]` section:
```
min_level = 3
role = &"tank"
```

- [ ] **Step 4: Update brute.tres**

Add to the `[resource]` section:
```
min_level = 5
role = &"tank"
```

- [ ] **Step 5: Commit**

```
git add scripts/data/monster_data.gd data/monsters/
git commit -m "feat: add min_level and role to MonsterData"
```

---

### Task 2: Create FormationCell and FormationData resources

**Files:**
- Create: `res://scripts/data/formation_cell.gd`
- Create: `res://scripts/data/formation_data.gd`

- [ ] **Step 1: Create FormationCell**

```gdscript
# res://scripts/data/formation_cell.gd
extends Resource
class_name FormationCell

@export var grid_position: Vector2i = Vector2i.ZERO
@export var role: StringName = &"front"
@export var monster_override: MonsterData = null
```

- [ ] **Step 2: Create FormationData**

```gdscript
# res://scripts/data/formation_data.gd
extends Resource
class_name FormationData

@export var formation_name: String = ""
@export_range(1, 20) var grid_columns: int = 14
@export_range(1, 10) var grid_rows: int = 7
@export var cells: Array[FormationCell] = []
```

- [ ] **Step 3: Commit**

```
git add scripts/data/formation_cell.gd scripts/data/formation_data.gd
git commit -m "feat: add FormationCell and FormationData resources"
```

---

### Task 3: Create LevelPool resource

**Files:**
- Create: `res://scripts/data/level_pool.gd`

- [ ] **Step 1: Create LevelPool**

```gdscript
# res://scripts/data/level_pool.gd
extends Resource
class_name LevelPool

@export var level_number: int = 1
@export var formations: Array[FormationData] = []
```

- [ ] **Step 2: Commit**

```
git add scripts/data/level_pool.gd
git commit -m "feat: add LevelPool resource"
```

---

### Task 4: Create FormationTemplates with 100 patterns

**Files:**
- Create: `res://scripts/formation_templates.gd`

This is the largest task. The class has 100 static functions that generate `Array[FormationCell]` given a grid size. Roles are assigned by row: top rows = support, middle = tank, bottom = front.

- [ ] **Step 1: Create formation_templates.gd**

```gdscript
# res://scripts/formation_templates.gd
class_name FormationTemplates

const TEMPLATE_NAMES: PackedStringArray = [
    "Full Grid", "Diamond", "V-Shape", "Walls", "Checkerboard",
    "Cross", "Scattered", "Corridor", "Pyramid", "Border",
    "Inverted V", "Zigzag", "Heart", "Spiral", "Arrows",
    "Clusters", "Diagonal Left", "Diagonal Right", "X-Shape", "Fortress",
    "Hourglass", "Teeth", "Ring", "Bullseye", "Staircase",
    "Waves", "Split Grid", "Dense Core", "Triple Line", "Random Heavy",
    "Double Diamond", "Hexagon", "Star", "Parallel Lines", "Grid Holes",
    "Crown", "Lightning", "Hashtag", "Bowtie", "Window",
    "Blob Left", "Blob Right", "Two Blobs", "Crescent", "Mushroom",
    "Amoeba", "Tree", "Skull", "Infinity", "Cloud",
    "Mirror V", "Concentric Sq", "Pinwheel", "DNA Helix", "Butterfly",
    "Snowflake", "Dominos", "Lattice", "Target", "Maze Walls",
    "Shield Wall", "Ambush", "Phalanx", "Scatter Guard", "Citadel",
    "Flanking", "Wedge", "Echelon", "Pocket", "Encircle",
    "Castle", "Bridge", "Tunnel", "Islands", "Columns",
    "Dam", "Skyline", "Tetris L", "Tetris T", "Barricade",
    "Quilt", "Sparse Diag", "Thick X", "Broken Grid", "Fence",
    "Ricochet", "Gauntlet", "Chessboard K", "Gradient", "Inv Gradient",
    "Plus Array", "Donut", "Arrow Up", "Three Rows", "Diagonal Fill",
    "Inv Diag Fill", "Center Line", "Sparse Ring", "Full Chaos", "The Gauntlet",
]


static func get_template_count() -> int:
    return TEMPLATE_NAMES.size()


static func get_template_name(index: int) -> String:
    if index >= 0 and index < TEMPLATE_NAMES.size():
        return TEMPLATE_NAMES[index]
    return "Unknown"


static func generate(index: int, columns: int, rows: int) -> Array[FormationCell]:
    # Dispatch to the correct pattern function
    match index:
        0: return _full_grid(columns, rows)
        1: return _diamond(columns, rows)
        2: return _v_shape(columns, rows)
        3: return _walls(columns, rows)
        4: return _checkerboard(columns, rows)
        5: return _cross(columns, rows)
        6: return _scattered(columns, rows, 42)
        7: return _corridor(columns, rows)
        8: return _pyramid(columns, rows)
        9: return _border(columns, rows)
        # ... patterns 10-99 follow same dispatch
        _: return _full_grid(columns, rows)
    # NOTE: Full 100-pattern match statement will be implemented
    # with all patterns from the HTML preview


static func _role_for_row(row: int, total_rows: int) -> StringName:
    var ratio: float = float(row) / float(total_rows)
    if ratio < 0.25:
        return &"support"
    if ratio < 0.55:
        return &"tank"
    return &"front"


static func _make_cell(col: int, row: int, total_rows: int) -> FormationCell:
    var cell: FormationCell = FormationCell.new()
    cell.grid_position = Vector2i(col, row)
    cell.role = _role_for_row(row, total_rows)
    return cell


static func _full_grid(columns: int, rows: int) -> Array[FormationCell]:
    var cells: Array[FormationCell] = []
    for r: int in range(rows):
        for c: int in range(columns):
            cells.append(_make_cell(c, r, rows))
    return cells


static func _diamond(columns: int, rows: int) -> Array[FormationCell]:
    var cells: Array[FormationCell] = []
    var cx: int = columns / 2
    var cy: int = rows / 2
    var size_val: int = mini(cx, cy)
    for r: int in range(-size_val, size_val + 1):
        var width: int = size_val - absi(r)
        for c: int in range(-width, width + 1):
            var col: int = cx + c
            var row: int = cy + r
            if col >= 0 and col < columns and row >= 0 and row < rows:
                cells.append(_make_cell(col, row, rows))
    return cells


# ... all 100 pattern functions follow the same structure:
# take (columns, rows), return Array[FormationCell]
# use _make_cell() which auto-assigns role by row position
```

The full implementation will port all 100 patterns from the HTML preview into GDScript static functions. Each pattern adapts to the given `columns` and `rows` parameters.

- [ ] **Step 2: Commit**

```
git add scripts/formation_templates.gd
git commit -m "feat: add FormationTemplates with 100 pattern generators"
```

---

### Task 5: Create starter .tres formation files + level pools

**Files:**
- Create: `res://data/formations/full_grid.tres`
- Create: `res://data/formations/diamond.tres`
- Create: `res://data/formations/v_shape.tres`
- Create: `res://data/formations/checkerboard.tres`
- Create: `res://data/formations/border.tres`
- Create: `res://data/level_pools/level_01.tres`
- Create: `res://data/level_pools/level_02.tres`

- [ ] **Step 1: Create 5 formation .tres files programmatically**

Use `FormationTemplates.generate()` to create each formation's cells, then save as .tres via a one-time editor script or manually. Each formation file follows this structure:

```
[gd_resource type="Resource" script_class="FormationData" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/data/formation_data.gd" id="1"]
[resource]
script = ExtResource("1")
formation_name = "Full Grid"
grid_columns = 14
grid_rows = 5
cells = []  # populated by template generator
```

Since FormationCell arrays are complex to write manually as .tres, use an editor script or create them in code at startup for the prototype. Alternative: create a helper function in main.gd that generates formations from templates on first run and saves them.

**Practical approach for prototype:** Instead of hand-writing .tres files with dozens of sub-resources, the `_spawn_enemies()` function will call `FormationTemplates.generate()` directly when a LevelPool references a template index rather than embedded cells. Add a field to FormationData:

```gdscript
@export var template_index: int = -1  # -1 = use cells array, 0-99 = generate from template
```

This way formations can either use hand-crafted cells OR reference a template by index. The editor plugin (Phase 5B) will handle creating cell-based formations.

- [ ] **Step 2: Create level pool .tres files**

`res://data/level_pools/level_01.tres`:
```
[gd_resource type="Resource" script_class="LevelPool" load_steps=4 format=3]
[ext_resource type="Script" path="res://scripts/data/level_pool.gd" id="1"]
[ext_resource type="Resource" path="res://data/formations/full_grid.tres" id="2"]
[ext_resource type="Resource" path="res://data/formations/checkerboard.tres" id="3"]
[ext_resource type="Resource" path="res://data/formations/border.tres" id="4"]
[resource]
script = ExtResource("1")
level_number = 1
formations = [ExtResource("2"), ExtResource("3"), ExtResource("4")]
```

- [ ] **Step 3: Commit**

```
git add data/formations/ data/level_pools/ scripts/data/formation_data.gd
git commit -m "feat: add starter formations and level pools"
```

---

### Task 6: Refactor main.gd to use formations + level pools

**Files:**
- Modify: `res://scripts/main.gd`

- [ ] **Step 1: Add level pool loading and formation-based spawning**

Replace constants and `_spawn_enemies()` in main.gd:

Remove: `GRID_COLS`, `GRID_ROWS`, `BLOCK_SPACING_X`, `BLOCK_SPACING_Y`

Add constants:
```gdscript
const LEVEL_POOLS_DIR: String = "res://data/level_pools/"
const ARENA_WIDTH: float = 980.0
const ARENA_HEIGHT: float = 200.0
```

Add new function to load level pool:
```gdscript
func _load_level_pool(level: int) -> LevelPool:
    var path: String = LEVEL_POOLS_DIR + "level_%02d.tres" % level
    if ResourceLoader.exists(path):
        var res: Resource = ResourceLoader.load(path)
        if res is LevelPool:
            return res as LevelPool
    return null
```

Add monster-by-role resolver:
```gdscript
func _resolve_monster(cell: FormationCell, level: int) -> MonsterData:
    if cell.monster_override:
        return cell.monster_override

    var candidates: Array[MonsterData] = []
    for monster: MonsterData in _monster_types:
        if monster.min_level <= level and monster.role == cell.role:
            candidates.append(monster)

    if candidates.is_empty():
        # Fallback: any unlocked monster
        for monster: MonsterData in _monster_types:
            if monster.min_level <= level:
                candidates.append(monster)

    if candidates.is_empty() and _monster_types.size() > 0:
        return _monster_types[0]

    return candidates[randi() % candidates.size()]
```

Replace `_spawn_enemies()`:
```gdscript
func _spawn_enemies() -> void:
    var pool: LevelPool = _load_level_pool(_level)
    var formation: FormationData = null

    if pool and pool.formations.size() > 0:
        formation = pool.formations[randi() % pool.formations.size()]

    if formation:
        _spawn_from_formation(formation)
    else:
        _spawn_fallback_grid()


func _spawn_from_formation(formation: FormationData) -> void:
    var cells: Array[FormationCell] = []

    if formation.template_index >= 0:
        cells = FormationTemplates.generate(formation.template_index, formation.grid_columns, formation.grid_rows)
    else:
        cells = formation.cells

    var col_spacing: float = ARENA_WIDTH / float(formation.grid_columns)
    var row_spacing: float = ARENA_HEIGHT / float(formation.grid_rows)

    for cell: FormationCell in cells:
        var monster: MonsterData = _resolve_monster(cell, _level)
        if not monster:
            continue

        var block: Block = BLOCK_SCENE.instantiate() as Block
        block.monster_data = monster
        var base_hp: int = monster.hp
        block.max_hp = int(ceilf(float(base_hp) * (1.0 + float(_level - 1) * HP_SCALE_PER_LEVEL)))

        var pixel_pos: Vector2 = GRID_OFFSET + Vector2(
            float(cell.grid_position.x) * col_spacing,
            float(cell.grid_position.y) * row_spacing
        )
        block.position = pixel_pos
        block.destroyed.connect(_on_block_destroyed)
        _block_container.add_child(block)
        _blocks_remaining += 1


func _spawn_fallback_grid() -> void:
    var col_spacing: float = ARENA_WIDTH / 14.0
    var row_spacing: float = ARENA_HEIGHT / 5.0
    for row: int in range(5):
        for col: int in range(14):
            var block: Block = BLOCK_SCENE.instantiate() as Block
            if _monster_types.size() > 0:
                var monster: MonsterData = _monster_types[0]
                block.monster_data = monster
                block.max_hp = int(ceilf(float(monster.hp) * (1.0 + float(_level - 1) * HP_SCALE_PER_LEVEL)))
            else:
                block.max_hp = 1
            block.position = GRID_OFFSET + Vector2(float(col) * col_spacing, float(row) * row_spacing)
            block.destroyed.connect(_on_block_destroyed)
            _block_container.add_child(block)
            _blocks_remaining += 1
```

- [ ] **Step 2: Commit**

```
git add scripts/main.gd
git commit -m "feat: refactor spawn_enemies to use formations and level pools"
```

---

### Task 7: Test and verify

- [ ] **Step 1: Run the game and verify**

1. Level 1: formation from level_01 pool appears (full_grid, checkerboard, or border)
2. Level 2: formation from level_02 pool appears (diamond or v_shape)
3. Level 3+: fallback full grid
4. Blocks auto-space correctly based on formation grid size
5. Monsters assigned by role (if Warriors/Brutes exist at current level)
6. HP scaling still works
7. Upgrade selection still works between levels
8. Game over and restart still work

- [ ] **Step 2: Code review + commit**

```
git add -A
git commit -m "phase5a_00: formation data system with templates and level pools"
git push
```
