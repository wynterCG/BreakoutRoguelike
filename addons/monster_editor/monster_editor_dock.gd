@tool
extends VBoxContainer

const MONSTERS_DIR: String = "res://data/monsters/"

var _monster_paths: Array[String] = []

@onready var _monster_list: ItemList = $MonsterList
@onready var _create_button: Button = $ButtonBar/CreateButton
@onready var _delete_button: Button = $ButtonBar/DeleteButton
@onready var _create_dialog: ConfirmationDialog = $CreateDialog
@onready var _delete_dialog: ConfirmationDialog = $DeleteDialog
@onready var _name_input: LineEdit = $CreateDialog/NameInput


func _ready() -> void:
	_create_button.pressed.connect(_on_create_pressed)
	_delete_button.pressed.connect(_on_delete_pressed)
	_create_dialog.confirmed.connect(_on_create_confirmed)
	_delete_dialog.confirmed.connect(_on_delete_confirmed)
	_monster_list.item_selected.connect(_on_item_selected)

	if Engine.is_editor_hint():
		var efs: EditorFileSystem = EditorInterface.get_resource_filesystem()
		efs.filesystem_changed.connect(_refresh_list)

	_refresh_list()


func _refresh_list() -> void:
	_monster_list.clear()
	_monster_paths.clear()

	if not DirAccess.dir_exists_absolute(MONSTERS_DIR):
		DirAccess.make_dir_recursive_absolute(MONSTERS_DIR)
		return

	var dir: DirAccess = DirAccess.open(MONSTERS_DIR)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = MONSTERS_DIR + file_name
			var res: Resource = ResourceLoader.load(path)
			if res is MonsterData:
				var data: MonsterData = res as MonsterData
				var display: String = data.monster_name if data.monster_name != "" else file_name
				display += "  (HP: " + str(data.hp) + ")"
				_monster_list.add_item(display)
				_monster_paths.append(path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _on_create_pressed() -> void:
	_name_input.text = ""
	_create_dialog.popup_centered()
	_name_input.grab_focus()


func _on_create_confirmed() -> void:
	var monster_name: String = _name_input.text.strip_edges()
	if monster_name == "":
		return

	var file_name: String = monster_name.to_snake_case() + ".tres"
	var path: String = MONSTERS_DIR + file_name

	if not DirAccess.dir_exists_absolute(MONSTERS_DIR):
		DirAccess.make_dir_recursive_absolute(MONSTERS_DIR)

	var data: MonsterData = MonsterData.new()
	data.monster_name = monster_name
	ResourceSaver.save(data, path)

	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()

	_refresh_list()


func _on_delete_pressed() -> void:
	var selected: PackedInt32Array = _monster_list.get_selected_items()
	if selected.is_empty():
		return
	_delete_dialog.popup_centered()


func _on_delete_confirmed() -> void:
	var selected: PackedInt32Array = _monster_list.get_selected_items()
	if selected.is_empty():
		return

	var index: int = selected[0]
	var path: String = _monster_paths[index]
	DirAccess.remove_absolute(path)

	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()

	_refresh_list()


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _monster_paths.size():
		return

	var path: String = _monster_paths[index]
	var res: Resource = ResourceLoader.load(path)
	if res and Engine.is_editor_hint():
		EditorInterface.inspect_object(res)
