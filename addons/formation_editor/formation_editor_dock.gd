@tool
extends HSplitContainer

const FORMATIONS_DIR: String = "res://data/formations/"
const LEVEL_POOLS_DIR: String = "res://data/level_pools/"
const MONSTERS_DIR: String = "res://data/monsters/"

const ROLE_COLORS: Dictionary = {
	&"front": Color(0.65, 0.89, 0.63),
	&"tank": Color(0.98, 0.89, 0.69),
	&"support": Color(0.95, 0.55, 0.66),
	&"elite": Color(0.80, 0.65, 0.97),
}

const CELL_SIZE: Vector2 = Vector2(34, 15)
const GAME_WIDTH: float = 1280.0
const GAME_HEIGHT: float = 720.0
const ARENA_WIDTH: float = 980.0
const ARENA_HEIGHT: float = 200.0
const GRID_OFFSET: Vector2 = Vector2(145.0, 60.0)
const PADDLE_Y: float = 640.0
const HP_BAR_Y: float = 700.0
const BACK_WALL_Y: float = 700.0
const PREVIEW_SCALE: float = 0.38

var _current_formation: FormationData = null
var _current_formation_path: String = ""
var _current_paint_role: StringName = &"front"
var _selected_cell_index: int = -1
var _formation_paths: Array[String] = []
var _level_pools: Array[LevelPool] = []
var _level_pool_paths: Array[String] = []
var _monster_data_list: Array[MonsterData] = []

# Left panel
@onready var _formation_list: ItemList = $LeftPanel/FormationList
@onready var _new_formation_btn: Button = $LeftPanel/ButtonBar/NewButton
@onready var _delete_formation_btn: Button = $LeftPanel/ButtonBar/DeleteButton
@onready var _create_dialog: ConfirmationDialog = $CreateDialog
@onready var _name_input: LineEdit = $CreateDialog/NameInput
@onready var _delete_dialog: ConfirmationDialog = $DeleteDialog
@onready var _pool_container: VBoxContainer = $LeftPanel/PoolScroll/PoolContainer
@onready var _new_pool_btn: Button = $LeftPanel/NewPoolButton

# Center panel
@onready var _formation_name_input: LineEdit = $CenterPanel/Controls/NameInput
@onready var _cols_input: SpinBox = $CenterPanel/Controls/ColsInput
@onready var _rows_input: SpinBox = $CenterPanel/Controls/RowsInput
@onready var _template_dropdown: OptionButton = $CenterPanel/Controls/TemplateDropdown
@onready var _apply_template_btn: Button = $CenterPanel/Controls/ApplyButton
@onready var _grid_container: GridContainer = $CenterPanel/SplitView/GridScroll/GridContainer
@onready var _arena_preview: Control = $CenterPanel/SplitView/ArenaPreview
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
@onready var _width_slider: HSlider = $RightPanel/CellInspector/WidthScaleBox/WidthSlider
@onready var _width_value: SpinBox = $RightPanel/CellInspector/WidthScaleBox/WidthValue
@onready var _height_slider: HSlider = $RightPanel/CellInspector/HeightScaleBox/HeightSlider
@onready var _height_value: SpinBox = $RightPanel/CellInspector/HeightScaleBox/HeightValue
@onready var _reset_size_btn: Button = $RightPanel/CellInspector/ResetSizeButton
@onready var _stats_label: Label = $RightPanel/StatsLabel
@onready var _auto_roles_btn: Button = $RightPanel/AutoRolesButton
@onready var _save_btn: Button = $RightPanel/SaveButton


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	_setup_template_dropdown()
	_setup_role_dropdown()
	_load_monsters_for_dropdown()
	_connect_signals()
	_refresh_formation_list()
	_refresh_pool_list()


# --- SIGNAL CONNECTIONS ---

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
	_width_slider.value_changed.connect(_on_width_scale_changed)
	_width_value.value_changed.connect(_on_width_scale_changed)
	_height_slider.value_changed.connect(_on_height_scale_changed)
	_height_value.value_changed.connect(_on_height_scale_changed)
	_reset_size_btn.pressed.connect(_on_reset_size)
	_cols_input.value_changed.connect(_on_grid_size_changed)
	_rows_input.value_changed.connect(_on_grid_size_changed)
	_formation_name_input.text_changed.connect(_on_name_changed)
	_new_pool_btn.pressed.connect(_on_new_pool_pressed)

	var efs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	efs.filesystem_changed.connect(_refresh_formation_list)
	efs.filesystem_changed.connect(_refresh_pool_list)


# --- SETUP ---

func _setup_template_dropdown() -> void:
	_template_dropdown.clear()
	for i: int in range(FormationTemplates.get_template_count()):
		_template_dropdown.add_item("%d - %s" % [i, FormationTemplates.get_template_name(i)], i)


func _setup_role_dropdown() -> void:
	_cell_role_dropdown.clear()
	_cell_role_dropdown.add_item("Front", 0)
	_cell_role_dropdown.add_item("Tank", 1)
	_cell_role_dropdown.add_item("Support", 2)
	_cell_role_dropdown.add_item("Elite", 3)


func _load_monsters_for_dropdown() -> void:
	_monster_data_list.clear()
	_cell_monster_dropdown.clear()
	_cell_monster_dropdown.add_item("-- Auto (by role) --", 0)

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
				_cell_monster_dropdown.add_item(data.monster_name + " (%d HP)" % data.hp, idx)
				idx += 1
		file_name = dir.get_next()
	dir.list_dir_end()


# --- FORMATION LIST ---

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
	var loaded: Resource = ResourceLoader.load(_current_formation_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not loaded is FormationData:
		return
	# Create a fresh FormationData with writable arrays
	_current_formation = FormationData.new()
	_current_formation.formation_name = loaded.formation_name
	_current_formation.grid_columns = loaded.grid_columns
	_current_formation.grid_rows = loaded.grid_rows
	_current_formation.template_index = loaded.template_index
	for cell: FormationCell in loaded.cells:
		var new_cell: FormationCell = FormationCell.new()
		new_cell.grid_position = cell.grid_position
		new_cell.role = cell.role
		new_cell.monster_override = cell.monster_override
		new_cell.size_scale = cell.size_scale
		_current_formation.cells.append(new_cell)
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

	_current_formation = null
	_current_formation_path = ""
	EditorInterface.get_resource_filesystem().scan()
	_refresh_formation_list()
	_rebuild_grid()


# --- GRID EDITOR ---

func _load_formation_into_editor() -> void:
	if not _current_formation:
		return
	_formation_name_input.text = _current_formation.formation_name
	_cols_input.value = _current_formation.grid_columns
	_rows_input.value = _current_formation.grid_rows
	if _current_formation.template_index >= 0 and _current_formation.template_index < _template_dropdown.item_count:
		_template_dropdown.selected = _current_formation.template_index
	_selected_cell_index = -1
	_cell_position_label.text = "No cell selected"
	_rebuild_grid()
	_update_stats()


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


func _rebuild_grid() -> void:
	for child: Node in _grid_container.get_children():
		child.queue_free()

	if not _current_formation:
		return

	_grid_container.columns = _current_formation.grid_columns

	var cells: Array[FormationCell] = _get_current_cells()
	var filled: Dictionary = {}
	for cell: FormationCell in cells:
		filled[cell.grid_position] = cell

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

	_update_arena_preview()


func _on_grid_panel_input(event: InputEvent, pos: Vector2i) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_grid_cell_clicked(pos)


func _update_arena_preview() -> void:
	# Clear previous preview
	for child: Node in _arena_preview.get_children():
		child.queue_free()

	if not _current_formation:
		return

	var preview_w: float = GAME_WIDTH * PREVIEW_SCALE
	var preview_h: float = GAME_HEIGHT * PREVIEW_SCALE
	_arena_preview.custom_minimum_size = Vector2(preview_w, preview_h)

	# Background (game area)
	var bg: ColorRect = ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(preview_w, preview_h)
	bg.color = Color(0.3, 0.3, 0.3)
	_arena_preview.add_child(bg)

	# Walls
	var wall_color: Color = Color(0.45, 0.45, 0.45)
	_draw_preview_rect(Vector2(0, 0), Vector2(GAME_WIDTH, 20), wall_color)       # top
	_draw_preview_rect(Vector2(0, 0), Vector2(20, GAME_HEIGHT), wall_color)       # left
	_draw_preview_rect(Vector2(GAME_WIDTH - 20, 0), Vector2(20, GAME_HEIGHT), wall_color) # right

	# Paddle (circle)
	var paddle_r: float = 30.0 * PREVIEW_SCALE
	var paddle_center: Vector2 = Vector2(GAME_WIDTH / 2.0 * PREVIEW_SCALE, PADDLE_Y * PREVIEW_SCALE)
	var paddle_circle: Polygon2D = Polygon2D.new()
	var paddle_points: PackedVector2Array = PackedVector2Array()
	for i: int in range(16):
		var angle: float = TAU * float(i) / 16.0
		paddle_points.append(paddle_center + Vector2(cos(angle) * paddle_r, sin(angle) * paddle_r))
	paddle_circle.polygon = paddle_points
	paddle_circle.color = Color(0.2, 0.6, 1.0)
	_arena_preview.add_child(paddle_circle)

	# HP bar
	_draw_preview_rect(
		Vector2(40, HP_BAR_Y),
		Vector2(GAME_WIDTH - 80, 20),
		Color(0.85, 0.15, 0.15)
	)

	# Back wall (thin line)
	_draw_preview_rect(
		Vector2(0, BACK_WALL_Y),
		Vector2(GAME_WIDTH, 4),
		Color(0.5, 0.5, 0.5)
	)

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


func _draw_preview_rect(game_pos: Vector2, game_size: Vector2, color: Color) -> void:
	var rect: ColorRect = ColorRect.new()
	rect.position = game_pos * PREVIEW_SCALE
	rect.size = game_size * PREVIEW_SCALE
	rect.color = color
	_arena_preview.add_child(rect)


func _set_cells(new_cells: Array[FormationCell]) -> void:
	_current_formation.cells.clear()
	for cell: FormationCell in new_cells:
		_current_formation.cells.append(cell)


func _ensure_cells_populated() -> void:
	if not _current_formation:
		return
	if _current_formation.cells.is_empty() and _current_formation.template_index >= 0:
		var generated: Array[FormationCell] = FormationTemplates.generate(
			_current_formation.template_index,
			_current_formation.grid_columns,
			_current_formation.grid_rows
		)
		_set_cells(generated)
		_current_formation.template_index = -1


# --- PAINT TOOLS ---

func _set_paint_role(role: StringName) -> void:
	_current_paint_role = role


func _on_grid_cell_clicked(pos: Vector2i) -> void:
	if not _current_formation:
		return

	_ensure_cells_populated()

	if _current_paint_role == &"erase":
		for i: int in range(_current_formation.cells.size() - 1, -1, -1):
			if _current_formation.cells[i].grid_position == pos:
				_current_formation.cells.remove_at(i)
	else:
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

	# Select cell for inspector
	_select_cell_for_inspector(pos)

	_rebuild_grid()
	_update_stats()


func _on_apply_template_pressed() -> void:
	if not _current_formation:
		return
	var index: int = _template_dropdown.get_selected_id()
	_current_formation.grid_columns = int(_cols_input.value)
	_current_formation.grid_rows = int(_rows_input.value)
	var generated: Array[FormationCell] = FormationTemplates.generate(
		index, _current_formation.grid_columns, _current_formation.grid_rows
	)
	_set_cells(generated)
	_current_formation.template_index = -1
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
	_ensure_cells_populated()
	for cell: FormationCell in _current_formation.cells:
		cell.role = FormationTemplates.role_for_row(cell.grid_position.y, _current_formation.grid_rows)
	_rebuild_grid()
	_update_stats()


func _on_grid_size_changed(_value: float) -> void:
	if not _current_formation:
		return
	_current_formation.grid_columns = int(_cols_input.value)
	_current_formation.grid_rows = int(_rows_input.value)
	_ensure_cells_populated()
	for i: int in range(_current_formation.cells.size() - 1, -1, -1):
		var pos: Vector2i = _current_formation.cells[i].grid_position
		if pos.x >= _current_formation.grid_columns or pos.y >= _current_formation.grid_rows:
			_current_formation.cells.remove_at(i)
	_rebuild_grid()
	_update_stats()


func _on_name_changed(new_name: String) -> void:
	if _current_formation:
		_current_formation.formation_name = new_name


# --- CELL INSPECTOR ---

func _select_cell_for_inspector(pos: Vector2i) -> void:
	if not _current_formation:
		return

	var cells: Array[FormationCell] = _current_formation.cells
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

	match cell.role:
		&"front": _cell_role_dropdown.selected = 0
		&"tank": _cell_role_dropdown.selected = 1
		&"support": _cell_role_dropdown.selected = 2
		&"elite": _cell_role_dropdown.selected = 3

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

	_width_slider.set_value_no_signal(cell.size_scale.x)
	_width_value.set_value_no_signal(cell.size_scale.x)
	_height_slider.set_value_no_signal(cell.size_scale.y)
	_height_value.set_value_no_signal(cell.size_scale.y)


func _on_cell_role_changed(index: int) -> void:
	if _selected_cell_index < 0 or not _current_formation:
		return
	if _selected_cell_index >= _current_formation.cells.size():
		return
	var roles: Array[StringName] = [&"front", &"tank", &"support", &"elite"]
	if index >= 0 and index < roles.size():
		_current_formation.cells[_selected_cell_index].role = roles[index]
		_rebuild_grid()
		_update_stats()


func _on_cell_monster_changed(index: int) -> void:
	if _selected_cell_index < 0 or not _current_formation:
		return
	if _selected_cell_index >= _current_formation.cells.size():
		return
	if index == 0:
		_current_formation.cells[_selected_cell_index].monster_override = null
	elif index - 1 < _monster_data_list.size():
		_current_formation.cells[_selected_cell_index].monster_override = _monster_data_list[index - 1]
	_rebuild_grid()


func _on_width_scale_changed(value: float) -> void:
	if _selected_cell_index < 0 or not _current_formation:
		return
	if _selected_cell_index >= _current_formation.cells.size():
		return
	if is_equal_approx(_current_formation.cells[_selected_cell_index].size_scale.x, value):
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
	if is_equal_approx(_current_formation.cells[_selected_cell_index].size_scale.y, value):
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


# --- LEVEL POOLS ---

func _refresh_pool_list() -> void:
	_level_pools.clear()
	_level_pool_paths.clear()

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
			var loaded: LevelPool = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as LevelPool
			if loaded:
				var pool: LevelPool = LevelPool.new()
				pool.level_number = loaded.level_number
				for f: FormationData in loaded.formations:
					pool.formations.append(f)
				_level_pools.append(pool)
				_level_pool_paths.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort pools and paths together by level number
	var paired: Array[Array] = []
	for i: int in range(_level_pools.size()):
		paired.append([_level_pools[i], _level_pool_paths[i]])
	paired.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as LevelPool).level_number < (b[0] as LevelPool).level_number)
	_level_pools.clear()
	_level_pool_paths.clear()
	for pair: Array in paired:
		_level_pools.append(pair[0] as LevelPool)
		_level_pool_paths.append(pair[1] as String)

	for i: int in range(_level_pools.size()):
		_build_pool_ui(_level_pools[i], _level_pool_paths[i])


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
	add_btn.text = "+ Add Selected"
	add_btn.add_theme_font_size_override("font_size", 11)
	add_btn.pressed.connect(_add_to_pool.bind(pool, pool_path))
	section.add_child(add_btn)

	var sep: HSeparator = HSeparator.new()
	section.add_child(sep)

	_pool_container.add_child(section)


func _add_to_pool(pool: LevelPool, pool_path: String) -> void:
	if _current_formation and _current_formation_path != "":
		pool.formations.append(_current_formation)
		ResourceSaver.save(pool, pool_path)
		EditorInterface.get_resource_filesystem().scan()
		_refresh_pool_list()


func _remove_from_pool(pool: LevelPool, index: int, pool_path: String) -> void:
	if index >= 0 and index < pool.formations.size():
		pool.formations.remove_at(index)
		ResourceSaver.save(pool, pool_path)
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

	EditorInterface.get_resource_filesystem().scan()
	_refresh_pool_list()


# --- SAVE ---

func _on_save() -> void:
	if not _current_formation or _current_formation_path == "":
		return
	_current_formation.formation_name = _formation_name_input.text
	_ensure_cells_populated()
	ResourceSaver.save(_current_formation, _current_formation_path)
	EditorInterface.get_resource_filesystem().scan()
	_refresh_formation_list()
