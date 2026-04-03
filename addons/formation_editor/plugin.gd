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
