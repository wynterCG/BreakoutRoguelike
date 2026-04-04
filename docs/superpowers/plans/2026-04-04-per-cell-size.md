# Per-Cell Size Scaling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow each formation cell to have independent width/height scale (0.5x–3.0x), with row-based auto-alignment so taller blocks push rows below them down.

**Architecture:** Add `size_scale: Vector2` to FormationCell. Block reads it to set its collision/visual size. The spawner pre-calculates row Y offsets from the tallest block per row. The formation editor gets width/height sliders in the cell inspector, and both the grid preview and arena preview reflect scaled sizes.

**Tech Stack:** Godot 4.6, GDScript, EditorPlugin

---

### Task 1: Add size_scale to FormationCell

**Files:**
- Modify: `res://scripts/data/formation_cell.gd`

- [ ] **Step 1: Add size_scale export**

```gdscript
extends Resource
class_name FormationCell

@export var grid_position: Vector2i = Vector2i.ZERO
@export var role: StringName = &"front"
@export var monster_override: MonsterData = null
@export var size_scale: Vector2 = Vector2(1.0, 1.0)
```

- [ ] **Step 2: Verify in Godot**

Open the editor, inspect any existing `.tres` formation file. Confirm `size_scale` appears in the inspector with default `(1, 1)`. Existing formations should load without errors.

- [ ] **Step 3: Commit**

```bash
git add scripts/data/formation_cell.gd
git commit -m "feat: add size_scale property to FormationCell"
```

---

### Task 2: Block reads size_scale

**Files:**
- Modify: `res://scripts/block.gd`

- [ ] **Step 1: Add size_scale export to Block**

Add the export after `max_hp`:

```gdscript
@export var max_hp: int = 1
@export var size_scale: Vector2 = Vector2(1.0, 1.0)
```

- [ ] **Step 2: Apply size_scale in _ready()**

Replace the current `_block_size` logic in `_ready()`. The `size_scale` takes priority when it's not `(1, 1)`. Change lines 35–38 from:

```gdscript
	if monster_data:
		hp = max_hp if max_hp > 1 else monster_data.hp
		block_color = monster_data.color
		_block_size = Vector2(maxf(monster_data.size.x, 10.0), maxf(monster_data.size.y, 10.0))
```

to:

```gdscript
	if monster_data:
		hp = max_hp if max_hp > 1 else monster_data.hp
		block_color = monster_data.color
		if size_scale != Vector2(1.0, 1.0):
			_block_size = Vector2(BLOCK_WIDTH * size_scale.x, BLOCK_HEIGHT * size_scale.y)
		else:
			_block_size = Vector2(maxf(monster_data.size.x, 10.0), maxf(monster_data.size.y, 10.0))
```

And add the same scale logic for the no-monster fallback. After line 41 (`block_color = _FALLBACK_COLORS[color_index]`), add:

```gdscript
		if size_scale != Vector2(1.0, 1.0):
			_block_size = Vector2(BLOCK_WIDTH * size_scale.x, BLOCK_HEIGHT * size_scale.y)
```

- [ ] **Step 3: Verify in Godot**

Run the game. Blocks should appear at normal 60x24 size (size_scale defaults to 1,1). No visual changes from the current state.

- [ ] **Step 4: Commit**

```bash
git add scripts/block.gd
git commit -m "feat: block reads size_scale for custom dimensions"
```

---

### Task 3: Row-based Y alignment in spawner

**Files:**
- Modify: `res://scripts/main.gd` — `_spawn_from_formation()` (lines 127–159)

- [ ] **Step 1: Replace _spawn_from_formation with row-based alignment**

Replace the entire function body:

```gdscript
func _spawn_from_formation(formation: FormationData) -> void:
	var cells: Array[FormationCell] = []

	if formation.template_index >= 0:
		cells = FormationTemplates.generate(formation.template_index, formation.grid_columns, formation.grid_rows)
	else:
		cells = formation.cells

	var block_w: float = 60.0
	var block_h: float = 24.0
	var spacing_x: float = block_w + 10.0
	var gap_y: float = 6.0

	# --- Row-based Y alignment ---
	# Find the tallest block in each row
	var row_max_h: Dictionary = {}
	for cell: FormationCell in cells:
		var row: int = cell.grid_position.y
		var cell_h: float = block_h * cell.size_scale.y
		if not row_max_h.has(row) or cell_h > row_max_h[row]:
			row_max_h[row] = cell_h

	# Build cumulative Y offsets (row index → Y position of row center)
	var row_y: Dictionary = {}
	var current_y: float = GRID_Y_OFFSET
	for row: int in range(formation.grid_rows):
		var tallest: float = row_max_h.get(row, block_h)
		row_y[row] = current_y + tallest / 2.0
		current_y += tallest + gap_y

	# --- X centering (unchanged) ---
	var total_w: float = float(formation.grid_columns) * spacing_x
	var offset_x: float = (1280.0 - total_w) / 2.0 + spacing_x / 2.0

	# --- Spawn blocks ---
	for cell: FormationCell in cells:
		var monster: MonsterData = _resolve_monster(cell, _level)
		if not monster:
			continue

		var block: Block = BLOCK_SCENE.instantiate() as Block
		block.monster_data = monster
		block.size_scale = cell.size_scale
		var base_hp: int = monster.hp
		block.max_hp = int(ceilf(float(base_hp) * (1.0 + float(_level - 1) * HP_SCALE_PER_LEVEL)))

		var pixel_pos: Vector2 = Vector2(
			offset_x + float(cell.grid_position.x) * spacing_x,
			row_y.get(cell.grid_position.y, GRID_Y_OFFSET)
		)
		block.position = pixel_pos
		block.destroyed.connect(_on_block_destroyed)
		_block_container.add_child(block)
		_blocks_remaining += 1
```

- [ ] **Step 2: Verify in Godot**

Run the game. Formations should display identically to before (all cells have default 1.0 scale). Centering, spacing, and gameplay unchanged.

- [ ] **Step 3: Commit**

```bash
git add scripts/main.gd
git commit -m "feat: row-based Y alignment in formation spawner"
```

---

### Task 4: Add size sliders to formation editor UI

**Files:**
- Modify: `res://addons/formation_editor/formation_editor_dock.tscn`

- [ ] **Step 1: Add size controls to CellInspector**

Add these nodes after `MonsterDropdown` inside `RightPanel/CellInspector`:

```
[node name="SizeSep" type="HSeparator" parent="RightPanel/CellInspector"]

[node name="WidthLabel" type="Label" parent="RightPanel/CellInspector"]
text = "Width Scale:"
theme_override_font_sizes/font_size = 10

[node name="WidthScaleBox" type="HBoxContainer" parent="RightPanel/CellInspector"]

[node name="WidthSlider" type="HSlider" parent="RightPanel/CellInspector/WidthScaleBox"]
size_flags_horizontal = 3
min_value = 0.5
max_value = 3.0
step = 0.1
value = 1.0

[node name="WidthValue" type="SpinBox" parent="RightPanel/CellInspector/WidthScaleBox"]
custom_minimum_size = Vector2(60, 0)
min_value = 0.5
max_value = 3.0
step = 0.1
value = 1.0

[node name="HeightLabel" type="Label" parent="RightPanel/CellInspector"]
text = "Height Scale:"
theme_override_font_sizes/font_size = 10

[node name="HeightScaleBox" type="HBoxContainer" parent="RightPanel/CellInspector"]

[node name="HeightSlider" type="HSlider" parent="RightPanel/CellInspector/HeightScaleBox"]
size_flags_horizontal = 3
min_value = 0.5
max_value = 3.0
step = 0.1
value = 1.0

[node name="HeightValue" type="SpinBox" parent="RightPanel/CellInspector/HeightScaleBox"]
custom_minimum_size = Vector2(60, 0)
min_value = 0.5
max_value = 3.0
step = 0.1
value = 1.0

[node name="ResetSizeButton" type="Button" parent="RightPanel/CellInspector"]
text = "Reset Size"
```

- [ ] **Step 2: Commit**

```bash
git add addons/formation_editor/formation_editor_dock.tscn
git commit -m "feat: add size scale sliders to formation editor UI"
```

---

### Task 5: Wire up size sliders in formation editor script

**Files:**
- Modify: `res://addons/formation_editor/formation_editor_dock.gd`

- [ ] **Step 1: Add @onready references**

After line 64 (`_cell_monster_dropdown`), add:

```gdscript
@onready var _width_slider: HSlider = $RightPanel/CellInspector/WidthScaleBox/WidthSlider
@onready var _width_value: SpinBox = $RightPanel/CellInspector/WidthScaleBox/WidthValue
@onready var _height_slider: HSlider = $RightPanel/CellInspector/HeightScaleBox/HeightSlider
@onready var _height_value: SpinBox = $RightPanel/CellInspector/HeightScaleBox/HeightValue
@onready var _reset_size_btn: Button = $RightPanel/CellInspector/ResetSizeButton
```

- [ ] **Step 2: Connect signals**

In `_connect_signals()`, after line 100 (`_cell_monster_dropdown.item_selected.connect`), add:

```gdscript
	_width_slider.value_changed.connect(_on_width_scale_changed)
	_width_value.value_changed.connect(_on_width_scale_changed)
	_height_slider.value_changed.connect(_on_height_scale_changed)
	_height_value.value_changed.connect(_on_height_scale_changed)
	_reset_size_btn.pressed.connect(_on_reset_size)
```

- [ ] **Step 3: Update _select_cell_for_inspector to show size values**

At the end of `_select_cell_for_inspector()`, after the monster dropdown logic (after line 576), add:

```gdscript
	_width_slider.set_value_no_signal(cell.size_scale.x)
	_width_value.set_value_no_signal(cell.size_scale.x)
	_height_slider.set_value_no_signal(cell.size_scale.y)
	_height_value.set_value_no_signal(cell.size_scale.y)
```

- [ ] **Step 4: Add size change handlers**

After `_on_cell_monster_changed()` (after line 601), add:

```gdscript
func _on_width_scale_changed(value: float) -> void:
	if _selected_cell_index < 0 or not _current_formation:
		return
	if _selected_cell_index >= _current_formation.cells.size():
		return
	_current_formation.cells[_selected_cell_index].size_scale.x = value
	_width_slider.set_value_no_signal(value)
	_width_value.set_value_no_signal(value)
	_rebuild_grid()


func _on_height_scale_changed(value: float) -> void:
	if _selected_cell_index < 0 or not _current_formation:
		return
	if _selected_cell_index >= _current_formation.cells.size():
		return
	_current_formation.cells[_selected_cell_index].size_scale.y = value
	_height_slider.set_value_no_signal(value)
	_height_value.set_value_no_signal(value)
	_rebuild_grid()


func _on_reset_size() -> void:
	if _selected_cell_index < 0 or not _current_formation:
		return
	if _selected_cell_index >= _current_formation.cells.size():
		return
	_current_formation.cells[_selected_cell_index].size_scale = Vector2(1.0, 1.0)
	_width_slider.set_value_no_signal(1.0)
	_width_value.set_value_no_signal(1.0)
	_height_slider.set_value_no_signal(1.0)
	_height_value.set_value_no_signal(1.0)
	_rebuild_grid()
```

- [ ] **Step 5: Commit**

```bash
git add addons/formation_editor/formation_editor_dock.gd
git commit -m "feat: wire size scale sliders in formation editor"
```

---

### Task 6: Grid preview shows scaled cell sizes

**Files:**
- Modify: `res://addons/formation_editor/formation_editor_dock.gd` — `_rebuild_grid()` (lines 283–336)

- [ ] **Step 1: Update grid cell sizes to reflect scale**

In `_rebuild_grid()`, change line 302 from:

```gdscript
			panel.custom_minimum_size = CELL_SIZE
```

to:

```gdscript
			if filled.has(pos):
				var cell_scale: Vector2 = filled[pos].size_scale
				panel.custom_minimum_size = Vector2(CELL_SIZE.x * cell_scale.x, CELL_SIZE.y * cell_scale.y)
			else:
				panel.custom_minimum_size = CELL_SIZE
```

This requires restructuring the code slightly. The full updated loop body at lines 297–334 becomes:

```gdscript
	for r: int in range(_current_formation.grid_rows):
		for c: int in range(_current_formation.grid_columns):
			var pos: Vector2i = Vector2i(c, r)

			var panel: PanelContainer = PanelContainer.new()

			var sb: StyleBoxFlat = StyleBoxFlat.new()
			sb.corner_radius_top_left = 2
			sb.corner_radius_top_right = 2
			sb.corner_radius_bottom_left = 2
			sb.corner_radius_bottom_right = 2

			var label: Label = Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 9)

			if filled.has(pos):
				var cell: FormationCell = filled[pos]
				panel.custom_minimum_size = Vector2(CELL_SIZE.x * cell.size_scale.x, CELL_SIZE.y * cell.size_scale.y)
				sb.bg_color = ROLE_COLORS.get(cell.role, Color.WHITE)
				var label_text: String = cell.role.left(1).to_upper()
				if cell.monster_override:
					label_text = cell.monster_override.monster_name.left(3)
				if cell.size_scale != Vector2(1.0, 1.0):
					label_text += "\n%.1fx%.1f" % [cell.size_scale.x, cell.size_scale.y]
					label.add_theme_font_size_override("font_size", 7)
				label.text = label_text
				label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
			else:
				panel.custom_minimum_size = CELL_SIZE
				sb.bg_color = Color(0.18, 0.18, 0.22)
				sb.border_color = Color(0.3, 0.3, 0.35)
				sb.border_width_top = 1
				sb.border_width_bottom = 1
				sb.border_width_left = 1
				sb.border_width_right = 1

			panel.add_theme_stylebox_override("panel", sb)
			panel.add_child(label)
			panel.gui_input.connect(_on_grid_panel_input.bind(pos))
			_grid_container.add_child(panel)
```

- [ ] **Step 2: Verify in Godot**

Open the formation editor. Select a cell, change its width to 2.0. The grid cell should appear wider. Change height to 1.5 — cell appears taller. The scale values display inside the cell.

- [ ] **Step 3: Commit**

```bash
git add addons/formation_editor/formation_editor_dock.gd
git commit -m "feat: grid preview reflects cell size scale"
```

---

### Task 7: Arena preview shows scaled block sizes

**Files:**
- Modify: `res://addons/formation_editor/formation_editor_dock.gd` — `_update_arena_preview()` (lines 344–406)

- [ ] **Step 1: Update arena preview with row-based alignment and scaled sizes**

Replace the block-drawing section (lines 391–405) with row-based Y alignment matching `main.gd`:

```gdscript
	# Blocks from formation (row-based alignment matching main.gd)
	var cells: Array[FormationCell] = _get_current_cells()
	var block_w: float = 60.0
	var block_h: float = 24.0
	var spacing_x: float = block_w + 10.0
	var gap_y: float = 6.0
	var total_w: float = float(_current_formation.grid_columns) * spacing_x
	var offset_x: float = (GAME_WIDTH - total_w) / 2.0 + spacing_x / 2.0
	var grid_y: float = 60.0

	# Calculate row heights
	var row_max_h: Dictionary = {}
	for cell: FormationCell in cells:
		var row: int = cell.grid_position.y
		var cell_h: float = block_h * cell.size_scale.y
		if not row_max_h.has(row) or cell_h > row_max_h[row]:
			row_max_h[row] = cell_h

	# Build cumulative Y offsets
	var row_y: Dictionary = {}
	var current_y: float = grid_y
	for row: int in range(_current_formation.grid_rows):
		var tallest: float = row_max_h.get(row, block_h)
		row_y[row] = current_y + tallest / 2.0
		current_y += tallest + gap_y

	# Draw blocks
	for cell: FormationCell in cells:
		var scaled_w: float = block_w * cell.size_scale.x
		var scaled_h: float = block_h * cell.size_scale.y
		var px: float = offset_x + float(cell.grid_position.x) * spacing_x - scaled_w / 2.0
		var py: float = row_y.get(cell.grid_position.y, grid_y) - scaled_h / 2.0
		var color: Color = ROLE_COLORS.get(cell.role, Color.WHITE)
		_draw_preview_rect(Vector2(px, py), Vector2(scaled_w, scaled_h), color)
```

- [ ] **Step 2: Verify in Godot**

In the formation editor, set a cell to 2.0x width. The arena preview should show that block wider than others. Set a cell to 2.0x height — rows below it should shift down in the preview.

- [ ] **Step 3: Commit**

```bash
git add addons/formation_editor/formation_editor_dock.gd
git commit -m "feat: arena preview shows scaled blocks with row-based alignment"
```

---

### Task 8: End-to-end verification

- [ ] **Step 1: Create a test formation**

In the formation editor:
1. Create a new formation "size_test"
2. Paint a 5x3 grid of front-role cells
3. Select center cell, set size to 2.0x width, 1.5x height
4. Select a corner cell, set size to 0.5x, 0.5x
5. Verify grid preview shows scaled sizes
6. Verify arena preview shows correct layout with row alignment
7. Save the formation

- [ ] **Step 2: Play-test the formation**

1. Add the formation to a level pool
2. Run the game
3. Confirm: center block is 120x36, corner block is 30x12
4. Confirm: rows below the tall block are shifted down
5. Confirm: ball bounces correctly off different-sized blocks
6. Confirm: HP bars scale with block size

- [ ] **Step 3: Test backward compatibility**

1. Load an existing formation that was created before this feature
2. Confirm it loads without errors and displays at normal size
3. Run the game with that formation — identical behavior to before

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: per-cell size scaling for formations — complete"
```
