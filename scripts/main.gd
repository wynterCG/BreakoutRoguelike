extends Node2D
class_name Main

const BLOCK_SCENE: PackedScene = preload("res://scenes/entities/block.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/entities/ball.tscn")
const MONSTERS_DIR: String = "res://data/monsters/"

const GRID_COLS: int = 14
const GRID_ROWS: int = 5
const BLOCK_SPACING_X: float = 70.0
const BLOCK_SPACING_Y: float = 30.0
const GRID_OFFSET: Vector2 = Vector2(145.0, 60.0)
const PADDLE_Y: float = 650.0

var _lives: int = 3
var _blocks_remaining: int = 0
var _current_ball: Ball = null
var _game_over: bool = false
var _monster_types: Array[MonsterData] = []

@onready var _paddle: Paddle = $Paddle
@onready var _arena: Node2D = $Arena
@onready var _block_container: Node2D = $BlockContainer
@onready var _lives_label: Label = $UI/LivesLabel
@onready var _status_label: Label = $UI/StatusLabel


func _ready() -> void:
	_paddle.position = Vector2(640.0, PADDLE_Y)
	_load_monster_types()
	_spawn_enemies()
	_spawn_ball()
	_update_ui()
	var kill_zone: Area2D = _arena.get_node("BottomKillZone")
	kill_zone.body_entered.connect(_on_kill_zone_body_entered)


func _load_monster_types() -> void:
	_monster_types.clear()
	if not DirAccess.dir_exists_absolute(MONSTERS_DIR):
		return

	var dir: DirAccess = DirAccess.open(MONSTERS_DIR)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: Resource = ResourceLoader.load(MONSTERS_DIR + file_name)
			if res is MonsterData:
				_monster_types.append(res as MonsterData)
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort by HP so lower HP monsters appear in lower rows (closer to paddle)
	_monster_types.sort_custom(func(a: MonsterData, b: MonsterData) -> bool: return a.hp > b.hp)


func _spawn_enemies() -> void:
	for row: int in range(GRID_ROWS):
		for col: int in range(GRID_COLS):
			var block: Block = BLOCK_SCENE.instantiate() as Block

			if _monster_types.size() > 0:
				# Assign monster type by row, cycling through available types
				var type_index: int = clampi(row, 0, _monster_types.size() - 1)
				block.monster_data = _monster_types[type_index]
			else:
				# Fallback: no monster resources found, use legacy HP-by-row
				block.max_hp = clampi(GRID_ROWS - row, 1, 3)

			block.position = GRID_OFFSET + Vector2(col * BLOCK_SPACING_X, row * BLOCK_SPACING_Y)
			block.destroyed.connect(_on_block_destroyed)
			_block_container.add_child(block)
			_blocks_remaining += 1


func _spawn_ball() -> void:
	_current_ball = BALL_SCENE.instantiate() as Ball
	_current_ball.setup(_paddle)
	add_child(_current_ball)


func _on_block_destroyed() -> void:
	_blocks_remaining -= 1
	if _blocks_remaining <= 0:
		_end_game("YOU WIN!")


func _on_kill_zone_body_entered(body: Node2D) -> void:
	if _game_over:
		return
	if body is Ball:
		_lives -= 1
		_update_ui()
		if _lives <= 0:
			_end_game("GAME OVER")
			body.queue_free()
			_current_ball = null
		else:
			(body as Ball).reset_to_paddle()


func _end_game(text: String) -> void:
	_game_over = true
	_status_label.text = text
	_status_label.visible = true
	_paddle.set_physics_process(false)
	_paddle.set_process_input(false)
	if _current_ball and is_instance_valid(_current_ball):
		_current_ball.set_physics_process(false)


func _update_ui() -> void:
	_lives_label.text = "Lives: " + str(_lives)


func _input(event: InputEvent) -> void:
	if not _game_over:
		return
	if event.is_action_pressed("launch_ball"):
		get_tree().reload_current_scene()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().reload_current_scene()
	elif event is InputEventScreenTouch and event.pressed:
		get_tree().reload_current_scene()
