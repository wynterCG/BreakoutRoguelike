# Phase 5B: Formation Editor Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a visual Formation Editor plugin for the Godot editor — paint formations on a grid, pick from 100 templates, assign monster roles/overrides, and manage level pools.

**Architecture:** EditorPlugin adds a dock with three panels (HSplitContainer). Left panel manages formation list + level pools. Center panel renders a clickable grid with paint tools. Right panel inspects individual cells. All data saves to FormationData and LevelPool .tres resources. Follows the existing monster_editor plugin pattern.

**Tech Stack:** Godot 4.6, GDScript 2.0, @tool scripts, EditorPlugin API, Control node drawing.

---

### Task 1: Plugin Scaffold + Empty Dock

**Files:**
- Create: `res://addons/formation_editor/plugin.cfg`
- Create: `res://addons/formation_editor/plugin.gd`
- Create: `res://addons/formation_editor/formation_editor_dock.gd`
- Create: `res://addons/formation_editor/formation_editor_dock.tscn`
- Modify: `project.godot` (enable plugin)

- [ ] **Step 1: Create plugin.cfg**

```
[plugin]

name="Formation Editor"
description="Visual editor for creating and managing formation layouts"
author="Wynter"
version="1.0"
script="plugin.gd"
```

- [ ] **Step 2: Create plugin.gd**

```gdscript
@tool
extends EditorPlugin

const DOCK_SCENE_PATH: String = "res://addons/formation_editor/formation_editor_dock.tscn"

var _dock: Control = null


func _enter_tree() -> void:
	var scene: PackedScene = load(DOCK_SCENE_PATH) as PackedScene
	if scene:
		_dock = scene.instantiate()
		add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)


func _exit_tree() -> void:
	if _dock:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
```

- [ ] **Step 3: Create formation_editor_dock.gd — empty three-panel layout**

```gdscript
@tool
extends HSplitContainer

const FORMATIONS_DIR: String = "res://data/formations/"
const LEVEL_POOLS_DIR: String = "res://data/level_pools/"
const MONSTERS_DIR: String = "res://data/monsters/"

var _current_formation: FormationData = null
var _current_formation_path: String = ""
var _current_paint_role: StringName = &"front"
var _selected_cell_index: int = -1

# Left panel
@onready var _formation_list: ItemList = $LeftPanel/FormationList
@onready var _new_formation_btn: Button = $LeftPanel/ButtonBar/NewButton
@onready var _delete_formation_btn: Button = $LeftPanel/ButtonBar/DeleteButton
@onready var _create_dialog: ConfirmationDialog = $CreateDialog
@onready var _name_input: LineEdit = $CreateDialog/NameInput
@onready var _delete_dialog: ConfirmationDialog = $DeleteDialog
@onready var _pool_container: VBoxContainer = $LeftPanel/PoolContainer

# Center panel
@onready var _formation_name_input: LineEdit = $CenterPanel/Controls/NameInput
@onready var _cols_input: SpinBox = $CenterPanel/Controls/ColsInput
@onready var _rows_input: SpinBox = $CenterPanel/Controls/RowsInput
@onready var _template_dropdown: OptionButton = $CenterPanel/Controls/TemplateDropdown
@onready var _apply_template_btn: Button = $CenterPanel/Controls/ApplyButton
@onready var _grid_container: GridContainer = $CenterPanel/GridScroll/GridContainer
@onready var _paint_front_btn: Button = $CenterPanel/ToolBar/FrontButton
@onready var _paint_tank_btn: Button = $CenterPanel/ToolBar/TankButton
@onready var _paint_support_btn: Button = $CenterPanel/ToolBar/SupportButton
@onready var _paint_elite_btn: Button = $CenterPanel/ToolBar/EliteButton
@onready var _paint_erase_btn: Button = $CenterPanel/ToolBar/EraseButton
@onready var _clear_all_btn: Button = $CenterPanel/ToolBar/ClearButton
@onready var _fill_all_btn: Button = $CenterPanel/ToolBar/FillButton

# Right panel
@onready var _cell_position_label: Label = $RightPanel/CellInspector/PositionLabel
@onready var _cell_role_dropdown: OptionButton = $RightPanel/CellInspector/RoleDropdown
@onready var _cell_monster_dropdown: OptionButton = $RightPanel/CellInspector/MonsterDropdown
@onready var _stats_label: Label = $RightPanel/StatsLabel
@onready var _auto_roles_btn: Button = $RightPanel/AutoRolesButton
@onready var _save_btn: Button = $RightPanel/SaveButton


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	_setup_template_dropdown()
	_connect_signals()
	_refresh_formation_list()
	_refresh_pool_list()
```

- [ ] **Step 4: Create formation_editor_dock.tscn via MCP**

Build the scene tree via MCP tools. Root is HSplitContainer with three panels.

- [ ] **Step 5: Enable plugin in project.godot**

Add `"res://addons/formation_editor/plugin.cfg"` to the enabled plugins array.

- [ ] **Step 6: Commit**

```
git add addons/formation_editor/ project.godot
git commit -m "feat: formation editor plugin scaffold with three-panel dock"
```

---

### Task 2: Formation List Panel (left panel)

**Files:**
- Modify: `res://addons/formation_editor/formation_editor_dock.gd`

- [ ] **Step 1: Implement formation list functions**

```gdscript
var _formation_paths: Array[String] = []


func _refresh_formation_list() -> void:
	_formation_list.clear()
	_formation_paths.clear()

	if not DirAccess.dir_exists_absolute(FORMATIONS_DIR):
		DirAccess.make_dir_recursive_absolute(FORMATIONS_DIR)
		return

	var dir: DirAccess = DirAccess.open(FORMATIONS_DIR)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = FORMATIONS_DIR + file_name
			var res: Resource = ResourceLoader.load(path)
			if res is FormationData:
				var data: FormationData = res as FormationData
				var display: String = data.formation_name if data.formation_name != "" else file_name
				display += "  (%dx%d)" % [data.grid_columns, data.grid_rows]
				_formation_list.add_item(display)
				_formation_paths.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _on_formation_selected(index: int) -> void:
	if index < 0 or index >= _formation_paths.size():
		return
	_current_formation_path = _formation_paths[index]
	_current_formation = ResourceLoader.load(_current_formation_path) as FormationData
	_load_formation_into_editor()


func _on_new_formation_pressed() -> void:
	_name_input.text = ""
	_create_dialog.popup_centered()
	_name_input.grab_focus()


func _on_new_formation_confirmed() -> void:
	var formation_name: String = _name_input.text.strip_edges()
	if formation_name == "":
		return

	var file_name: String = formation_name.to_snake_case() + ".tres"
	var path: String = FORMATIONS_DIR + file_name

	if not DirAccess.dir_exists_absolute(FORMATIONS_DIR):
		DirAccess.make_dir_recursive_absolute(FORMATIONS_DIR)

	var data: FormationData = FormationData.new()
	data.formation_name = formation_name
	ResourceSaver.save(data, path)

	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()

	_refresh_formation_list()


func _on_delete_formation_pressed() -> void:
	var selected: PackedInt32Array = _formation_list.get_selected_items()
	if selected.is_empty():
		return
	_delete_dialog.popup_centered()


func _on_delete_formation_confirmed() -> void:
	var selected: PackedInt32Array = _formation_list.get_selected_items()
	if selected.is_empty():
		return

	var index: int = selected[0]
	var path: String = _formation_paths[index]
	DirAccess.remove_absolute(path)

	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()

	_current_formation = null
	_current_formation_path = ""
	_refresh_formation_list()
	_rebuild_grid()
```

- [ ] **Step 2: Commit**

```
git add addons/formation_editor/
git commit -m "feat: formation list panel with create/delete/select"
```

---

### Task 3: Grid Rendering + Template Application

**Files:**
- Modify: `res://addons/formation_editor/formation_editor_dock.gd`

- [ ] **Step 1: Implement grid rendering and template dropdown**

```gdscript
const ROLE_COLORS: Dictionary = {
	&"front": Color(0.65, 0.89, 0.63),
	&"tank": Color(0.98, 0.89, 0.69),
	&"support": Color(0.95, 0.55, 0.66),
	&"elite": Color(0.80, 0.65, 0.97),
}

const CELL_SIZE: Vector2 = Vector2(48, 20)


func _setup_template_dropdown() -> void:
	_template_dropdown.clear()
	for i: int in range(FormationTemplates.get_template_count()):
		_template_dropdown.add_item("%d — %s" % [i, FormationTemplates.get_template_name(i)], i)


func _load_formation_into_editor() -> void:
	if not _current_formation:
		return
	_formation_name_input.text = _current_formation.formation_name
	_cols_input.value = _current_formation.grid_columns
	_rows_input.value = _current_formation.grid_rows
	if _current_formation.template_index >= 0:
		_template_dropdown.selected = _current_formation.template_index
	_selected_cell_index = -1
	_rebuild_grid()
	_update_stats()


func _rebuild_grid() -> void:
	# Clear existing grid
	for child: Node in _grid_container.get_children():
		child.queue_free()

	if not _current_formation:
		return

	_grid_container.columns = _current_formation.grid_columns

	# Get cells (from template or stored)
	var cells: Array[FormationCell] = _get_current_cells()

	# Build lookup for filled positions
	var filled: Dictionary = {}  # Vector2i -> FormationCell
	for cell: FormationCell in cells:
		filled[cell.grid_position] = cell

	# Create grid buttons
	for r: int in range(_current_formation.grid_rows):
		for c: int in range(_current_formation.grid_columns):
			var btn: Button = Button.new()
			btn.custom_minimum_size = CELL_SIZE
			btn.flat = true
			var pos: Vector2i = Vector2i(c, r)

			if filled.has(pos):
				var cell: FormationCell = filled[pos]
				var color: Color = ROLE_COLORS.get(cell.role, Color.WHITE)
				var stylebox: StyleBoxFlat = StyleBoxFlat.new()
				stylebox.bg_color = color
				stylebox.corner_radius_top_left = 2
				stylebox.corner_radius_top_right = 2
				stylebox.corner_radius_bottom_left = 2
				stylebox.corner_radius_bottom_right = 2
				btn.add_theme_stylebox_override("normal", stylebox)
				btn.add_theme_stylebox_override("hover", stylebox)
				btn.add_theme_stylebox_override("pressed", stylebox)
				btn.text = cell.role.left(1).to_upper()
				btn.add_theme_font_size_override("font_size", 9)
				btn.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
			else:
				var stylebox: StyleBoxFlat = StyleBoxFlat.new()
				stylebox.bg_color = Color(0.15, 0.15, 0.2)
				stylebox.border_color = Color(0.3, 0.3, 0.35)
				stylebox.border_width_top = 1
				stylebox.border_width_bottom = 1
				stylebox.border_width_left = 1
				stylebox.border_width_right = 1
				btn.add_theme_stylebox_override("normal", stylebox)
				btn.add_theme_stylebox_override("hover", stylebox)

			btn.pressed.connect(_on_grid_cell_pressed.bind(pos))
			_grid_container.add_child(btn)


func _get_current_cells() -> Array[FormationCell]:
	if not _current_formation:
		return []
	if _current_formation.template_index >= 0 and _current_formation.cells.is_empty():
		return FormationTemplates.generate(
			_current_formation.template_index,
			_current_formation.grid_columns,
			_current_formation.grid_rows
		)
	return _current_formation.cells


func _on_apply_template_pressed() -> void:
	if not _current_formation:
		return
	var index: int = _template_dropdown.get_selected_id()
	_current_formation.template_index = index
	_current_formation.grid_columns = int(_cols_input.value)
	_current_formation.grid_rows = int(_rows_input.value)
	_current_formation.cells = FormationTemplates.generate(
		index, _current_formation.grid_columns, _current_formation.grid_rows
	)
	_current_formation.template_index = -1  # Now using explicit cells
	_rebuild_grid()
	_update_stats()
```

- [ ] **Step 2: Commit**

```
git add addons/formation_editor/
git commit -m "feat: grid rendering with template dropdown and application"
```

---

### Task 4: Paint Tools + Grid Clicking

**Files:**
- Modify: `res://addons/formation_editor/formation_editor_dock.gd`

- [ ] **Step 1: Implement paint tools and grid cell interaction**

```gdscript
func _connect_signals() -> void:
	_formation_list.item_selected.connect(_on_formation_selected)
	_new_formation_btn.pressed.connect(_on_new_formation_pressed)
	_delete_formation_btn.pressed.connect(_on_delete_formation_pressed)
	_create_dialog.confirmed.connect(_on_new_formation_confirmed)
	_delete_dialog.confirmed.connect(_on_delete_formation_confirmed)
	_apply_template_btn.pressed.connect(_on_apply_template_pressed)
	_paint_front_btn.pressed.connect(_set_paint_role.bind(&"front"))
	_paint_tank_btn.pressed.connect(_set_paint_role.bind(&"tank"))
	_paint_support_btn.pressed.connect(_set_paint_role.bind(&"support"))
	_paint_elite_btn.pressed.connect(_set_paint_role.bind(&"elite"))
	_paint_erase_btn.pressed.connect(_set_paint_role.bind(&"erase"))
	_clear_all_btn.pressed.connect(_on_clear_all)
	_fill_all_btn.pressed.connect(_on_fill_all)
	_auto_roles_btn.pressed.connect(_on_auto_roles)
	_save_btn.pressed.connect(_on_save)
	_cell_role_dropdown.item_selected.connect(_on_cell_role_changed)
	_cell_monster_dropdown.item_selected.connect(_on_cell_monster_changed)
	_cols_input.value_changed.connect(_on_grid_size_changed)
	_rows_input.value_changed.connect(_on_grid_size_changed)
	_formation_name_input.text_changed.connect(_on_name_changed)

	if Engine.is_editor_hint():
		var efs: EditorFileSystem = EditorInterface.get_resource_filesystem()
		efs.filesystem_changed.connect(_refresh_formation_list)
		efs.filesystem_changed.connect(_refresh_pool_list)


func _set_paint_role(role: StringName) -> void:
	_current_paint_role = role


func _on_grid_cell_pressed(pos: Vector2i) -> void:
	if not _current_formation:
		return

	# Ensure cells array is populated (not relying on template_index)
	if _current_formation.cells.is_empty() and _current_formation.template_index >= 0:
		_current_formation.cells = FormationTemplates.generate(
			_current_formation.template_index,
			_current_formation.grid_columns,
			_current_formation.grid_rows
		)
		_current_formation.template_index = -1

	if _current_paint_role == &"erase":
		# Remove cell at position
		for i: int in range(_current_formation.cells.size() - 1, -1, -1):
			if _current_formation.cells[i].grid_position == pos:
				_current_formation.cells.remove_at(i)
	else:
		# Find existing cell or create new
		var found: bool = false
		for cell: FormationCell in _current_formation.cells:
			if cell.grid_position == pos:
				cell.role = _current_paint_role
				found = true
				break
		if not found:
			var cell: FormationCell = FormationCell.new()
			cell.grid_position = pos
			cell.role = _current_paint_role
			_current_formation.cells.append(cell)

	_rebuild_grid()
	_update_stats()


func _on_clear_all() -> void:
	if not _current_formation:
		return
	_current_formation.cells.clear()
	_current_formation.template_index = -1
	_rebuild_grid()
	_update_stats()


func _on_fill_all() -> void:
	if not _current_formation:
		return
	_current_formation.cells.clear()
	_current_formation.template_index = -1
	for r: int in range(_current_formation.grid_rows):
		for c: int in range(_current_formation.grid_columns):
			var cell: FormationCell = FormationCell.new()
			cell.grid_position = Vector2i(c, r)
			cell.role = _current_paint_role
			_current_formation.cells.append(cell)
	_rebuild_grid()
	_update_stats()


func _on_auto_roles() -> void:
	if not _current_formation:
		return
	for cell: FormationCell in _current_formation.cells:
		cell.role = FormationTemplates._role_for_row(cell.grid_position.y, _current_formation.grid_rows)
	_rebuild_grid()
	_update_stats()


func _on_grid_size_changed(_value: float) -> void:
	if not _current_formation:
		return
	_current_formation.grid_columns = int(_cols_input.value)
	_current_formation.grid_rows = int(_rows_input.value)
	# Remove cells outside new bounds
	for i: int in range(_current_formation.cells.size() - 1, -1, -1):
		var pos: Vector2i = _current_formation.cells[i].grid_position
		if pos.x >= _current_formation.grid_columns or pos.y >= _current_formation.grid_rows:
			_current_formation.cells.remove_at(i)
	_rebuild_grid()
	_update_stats()


func _on_name_changed(new_name: String) -> void:
	if _current_formation:
		_current_formation.formation_name = new_name
```

- [ ] **Step 2: Commit**

```
git add addons/formation_editor/
git commit -m "feat: paint tools, grid clicking, clear/fill/auto-roles"
```

---

### Task 5: Cell Inspector (right panel)

**Files:**
- Modify: `res://addons/formation_editor/formation_editor_dock.gd`

- [ ] **Step 1: Implement cell inspector and stats**

```gdscript
var _monster_data_list: Array[MonsterData] = []
var _monster_paths_list: Array[String] = []


func _load_monsters_for_dropdown() -> void:
	_monster_data_list.clear()
	_monster_paths_list.clear()
	_cell_monster_dropdown.clear()
	_cell_monster_dropdown.add_item("— Auto (by role) —", 0)

	if not DirAccess.dir_exists_absolute(MONSTERS_DIR):
		return

	var dir: DirAccess = DirAccess.open(MONSTERS_DIR)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	var idx: int = 1
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = MONSTERS_DIR + file_name
			var res: Resource = ResourceLoader.load(path)
			if res is MonsterData:
				var data: MonsterData = res as MonsterData
				_monster_data_list.append(data)
				_monster_paths_list.append(path)
				_cell_monster_dropdown.add_item(data.monster_name + " (%d HP)" % data.hp, idx)
				idx += 1
		file_name = dir.get_next()
	dir.list_dir_end()

	# Setup role dropdown
	_cell_role_dropdown.clear()
	_cell_role_dropdown.add_item("Front", 0)
	_cell_role_dropdown.add_item("Tank", 1)
	_cell_role_dropdown.add_item("Support", 2)
	_cell_role_dropdown.add_item("Elite", 3)


func _select_cell_for_inspector(pos: Vector2i) -> void:
	if not _current_formation:
		return

	var cells: Array[FormationCell] = _get_current_cells()
	_selected_cell_index = -1

	for i: int in range(cells.size()):
		if cells[i].grid_position == pos:
			_selected_cell_index = i
			break

	if _selected_cell_index < 0:
		_cell_position_label.text = "No cell selected"
		return

	var cell: FormationCell = cells[_selected_cell_index]
	_cell_position_label.text = "(%d, %d)" % [cell.grid_position.x, cell.grid_position.y]

	# Set role dropdown
	match cell.role:
		&"front": _cell_role_dropdown.selected = 0
		&"tank": _cell_role_dropdown.selected = 1
		&"support": _cell_role_dropdown.selected = 2
		&"elite": _cell_role_dropdown.selected = 3

	# Set monster dropdown
	if cell.monster_override:
		var found: bool = false
		for i: int in range(_monster_data_list.size()):
			if _monster_data_list[i].monster_name == cell.monster_override.monster_name:
				_cell_monster_dropdown.selected = i + 1
				found = true
				break
		if not found:
			_cell_monster_dropdown.selected = 0
	else:
		_cell_monster_dropdown.selected = 0


func _on_cell_role_changed(index: int) -> void:
	if _selected_cell_index < 0 or not _current_formation:
		return
	var roles: Array[StringName] = [&"front", &"tank", &"support", &"elite"]
	if index >= 0 and index < roles.size():
		_current_formation.cells[_selected_cell_index].role = roles[index]
		_rebuild_grid()
		_update_stats()


func _on_cell_monster_changed(index: int) -> void:
	if _selected_cell_index < 0 or not _current_formation:
		return
	if index == 0:
		_current_formation.cells[_selected_cell_index].monster_override = null
	elif index - 1 < _monster_data_list.size():
		_current_formation.cells[_selected_cell_index].monster_override = _monster_data_list[index - 1]
	_rebuild_grid()


func _update_stats() -> void:
	var cells: Array[FormationCell] = _get_current_cells()
	var counts: Dictionary = {&"front": 0, &"tank": 0, &"support": 0, &"elite": 0}
	var overrides: int = 0
	for cell: FormationCell in cells:
		if counts.has(cell.role):
			counts[cell.role] += 1
		if cell.monster_override:
			overrides += 1
	_stats_label.text = "Total: %d\nFront: %d\nTank: %d\nSupport: %d\nElite: %d\nOverrides: %d" % [
		cells.size(), counts[&"front"], counts[&"tank"], counts[&"support"], counts[&"elite"], overrides
	]
```

- [ ] **Step 2: Commit**

```
git add addons/formation_editor/
git commit -m "feat: cell inspector with role/monster editing and stats"
```

---

### Task 6: Level Pool Manager (left panel)

**Files:**
- Modify: `res://addons/formation_editor/formation_editor_dock.gd`

- [ ] **Step 1: Implement level pool list and management**

```gdscript
var _level_pools: Array[LevelPool] = []
var _level_pool_paths: Array[String] = []


func _refresh_pool_list() -> void:
	_level_pools.clear()
	_level_pool_paths.clear()

	# Clear pool container UI
	for child: Node in _pool_container.get_children():
		child.queue_free()

	if not DirAccess.dir_exists_absolute(LEVEL_POOLS_DIR):
		DirAccess.make_dir_recursive_absolute(LEVEL_POOLS_DIR)
		return

	var dir: DirAccess = DirAccess.open(LEVEL_POOLS_DIR)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = LEVEL_POOLS_DIR + file_name
			var res: Resource = ResourceLoader.load(path)
			if res is LevelPool:
				_level_pools.append(res as LevelPool)
				_level_pool_paths.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort by level number
	# Build pool UI for each
	for i: int in range(_level_pools.size()):
		var pool: LevelPool = _level_pools[i]
		var pool_path: String = _level_pool_paths[i]
		_build_pool_ui(pool, pool_path)


func _build_pool_ui(pool: LevelPool, pool_path: String) -> void:
	var section: VBoxContainer = VBoxContainer.new()

	var header: Label = Label.new()
	header.text = "Level %d" % pool.level_number
	header.add_theme_font_size_override("font_size", 12)
	section.add_child(header)

	for j: int in range(pool.formations.size()):
		var formation: FormationData = pool.formations[j]
		var row: HBoxContainer = HBoxContainer.new()
		var label: Label = Label.new()
		label.text = formation.formation_name if formation.formation_name != "" else "Unnamed"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 11)
		row.add_child(label)

		var remove_btn: Button = Button.new()
		remove_btn.text = "X"
		remove_btn.flat = true
		remove_btn.add_theme_font_size_override("font_size", 10)
		remove_btn.pressed.connect(_remove_from_pool.bind(pool, j, pool_path))
		row.add_child(remove_btn)

		section.add_child(row)

	var add_btn: Button = Button.new()
	add_btn.text = "+ Add Formation"
	add_btn.add_theme_font_size_override("font_size", 11)
	add_btn.pressed.connect(_add_to_pool.bind(pool, pool_path))
	section.add_child(add_btn)

	_pool_container.add_child(section)


func _add_to_pool(pool: LevelPool, pool_path: String) -> void:
	if _current_formation and _current_formation_path != "":
		pool.formations.append(_current_formation)
		ResourceSaver.save(pool, pool_path)
		if Engine.is_editor_hint():
			EditorInterface.get_resource_filesystem().scan()
		_refresh_pool_list()


func _remove_from_pool(pool: LevelPool, index: int, pool_path: String) -> void:
	if index >= 0 and index < pool.formations.size():
		pool.formations.remove_at(index)
		ResourceSaver.save(pool, pool_path)
		if Engine.is_editor_hint():
			EditorInterface.get_resource_filesystem().scan()
		_refresh_pool_list()


func _on_new_pool_pressed() -> void:
	var next_level: int = 1
	for pool: LevelPool in _level_pools:
		if pool.level_number >= next_level:
			next_level = pool.level_number + 1

	if not DirAccess.dir_exists_absolute(LEVEL_POOLS_DIR):
		DirAccess.make_dir_recursive_absolute(LEVEL_POOLS_DIR)

	var pool: LevelPool = LevelPool.new()
	pool.level_number = next_level
	var path: String = LEVEL_POOLS_DIR + "level_%02d.tres" % next_level
	ResourceSaver.save(pool, path)

	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()

	_refresh_pool_list()
```

- [ ] **Step 2: Commit**

```
git add addons/formation_editor/
git commit -m "feat: level pool manager with add/remove/create"
```

---

### Task 7: Save Functionality + Scene Building

**Files:**
- Modify: `res://addons/formation_editor/formation_editor_dock.gd`
- Create: `res://addons/formation_editor/formation_editor_dock.tscn` (if not already built)

- [ ] **Step 1: Implement save and final wiring**

```gdscript
func _on_save() -> void:
	if not _current_formation or _current_formation_path == "":
		return
	_current_formation.formation_name = _formation_name_input.text
	ResourceSaver.save(_current_formation, _current_formation_path)
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()
	_refresh_formation_list()
```

- [ ] **Step 2: Build the full .tscn scene file**

The scene tree for the dock:

```
HSplitContainer (formation_editor_dock)
├── LeftPanel (VBoxContainer)
│   ├── Label "Formations"
│   ├── ButtonBar (HBoxContainer)
│   │   ├── NewButton (Button) "New"
│   │   └── DeleteButton (Button) "Delete"
│   ├── FormationList (ItemList)
│   ├── HSeparator
│   ├── Label "Level Pools"
│   ├── PoolContainer (VBoxContainer)
│   └── NewPoolButton (Button) "+ New Level Pool"
├── CenterPanel (VBoxContainer)
│   ├── Controls (HBoxContainer)
│   │   ├── Label "Name:"
│   │   ├── NameInput (LineEdit)
│   │   ├── Label "Cols:"
│   │   ├── ColsInput (SpinBox) min=1 max=20 value=14
│   │   ├── Label "Rows:"
│   │   ├── RowsInput (SpinBox) min=1 max=10 value=7
│   │   ├── TemplateDropdown (OptionButton)
│   │   └── ApplyButton (Button) "Apply Template"
│   ├── ToolBar (HBoxContainer)
│   │   ├── FrontButton (Button) "Front"
│   │   ├── TankButton (Button) "Tank"
│   │   ├── SupportButton (Button) "Support"
│   │   ├── EliteButton (Button) "Elite"
│   │   ├── EraseButton (Button) "Erase"
│   │   ├── ClearButton (Button) "Clear"
│   │   └── FillButton (Button) "Fill"
│   └── GridScroll (ScrollContainer)
│       └── GridContainer (GridContainer)
├── RightPanel (VBoxContainer)
│   ├── Label "Cell Inspector"
│   ├── CellInspector (VBoxContainer)
│   │   ├── PositionLabel (Label)
│   │   ├── Label "Role:"
│   │   ├── RoleDropdown (OptionButton)
│   │   ├── Label "Monster Override:"
│   │   └── MonsterDropdown (OptionButton)
│   ├── HSeparator
│   ├── Label "Stats"
│   ├── StatsLabel (Label)
│   ├── HSeparator
│   ├── AutoRolesButton (Button) "Auto-assign Roles"
│   └── SaveButton (Button) "Save Formation"
├── CreateDialog (ConfirmationDialog)
│   └── NameInput (LineEdit)
└── DeleteDialog (ConfirmationDialog)
```

Build this via MCP tools (open scene, add nodes) or write as .tscn file directly.

- [ ] **Step 3: Commit**

```
git add addons/formation_editor/
git commit -m "feat: complete formation editor dock scene and save functionality"
```

---

### Task 8: Final Integration + Testing

- [ ] **Step 1: Enable plugin and test**

1. Enable Formation Editor plugin in Project Settings > Plugins
2. Dock appears with three panels
3. Create new formation — .tres file created
4. Apply Diamond template — grid shows diamond pattern
5. Paint cells with different roles — colors change
6. Click cell to inspect — role/monster dropdowns work
7. Clear All / Fill All work
8. Auto-assign roles — top rows become support, middle tank, bottom front
9. Change grid size — grid resizes, out-of-bounds cells removed
10. Save formation — .tres file updated
11. Create level pool — pool .tres created
12. Add formation to pool — pool updated
13. Run game — formations load from pools

- [ ] **Step 2: Code review + commit**

```
git add -A
git commit -m "phase5b_00: Formation Editor plugin with grid painting and level pools"
git push
```
