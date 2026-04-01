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
const PLAYER_MAX_HP: int = 100

const HP_BAR_WIDTH: float = 1200.0
const HP_BAR_HEIGHT: float = 20.0
const HP_BAR_Y: float = 700.0

var _blocks_remaining: int = 0
var _current_ball: Ball = null
var _game_over: bool = false
var _monster_types: Array[MonsterData] = []

@onready var _paddle: Paddle = $Paddle
@onready var _block_container: Node2D = $BlockContainer
@onready var _status_label: Label = $UI/StatusLabel
@onready var _hp_bar_bg: ColorRect = $UI/HPBarBackground
@onready var _hp_bar_fill: ColorRect = $UI/HPBarFill
@onready var _hp_label: Label = $UI/HPLabel
@onready var _player_health: HealthComponent = $PlayerHealth


func _ready() -> void:
	_paddle.position = Vector2(640.0, PADDLE_Y)
	_player_health.initialize(PLAYER_MAX_HP)
	_player_health.health_changed.connect(_on_player_health_changed)
	_player_health.died.connect(_on_player_died)
	_load_monster_types()
	_spawn_enemies()
	_spawn_ball()
	_setup_hp_bar()


func _setup_hp_bar() -> void:
	var bar_x: float = (1280.0 - HP_BAR_WIDTH) / 2.0
	_hp_bar_bg.position = Vector2(bar_x, HP_BAR_Y)
	_hp_bar_bg.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	_hp_bar_bg.color = Color(0.15, 0.15, 0.15)

	_hp_bar_fill.position = Vector2(bar_x + 2.0, HP_BAR_Y + 2.0)
	_hp_bar_fill.size = Vector2(HP_BAR_WIDTH - 4.0, HP_BAR_HEIGHT - 4.0)
	_hp_bar_fill.color = Color(0.85, 0.15, 0.15)

	_hp_label.position = Vector2(bar_x, HP_BAR_Y)
	_hp_label.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_label.add_theme_font_size_override("font_size", 12)
	_hp_label.add_theme_color_override("font_color", Color.WHITE)
	_hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_hp_label.add_theme_constant_override("shadow_offset_x", 1)
	_hp_label.add_theme_constant_override("shadow_offset_y", 1)
	_update_hp_bar()


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
	_current_ball.hit_back_wall.connect(_on_ball_hit_back_wall)
	add_child(_current_ball)


func _on_block_destroyed() -> void:
	_blocks_remaining -= 1
	if _blocks_remaining <= 0:
		_end_game("YOU WIN!")


func _on_ball_hit_back_wall(ball_damage: int) -> void:
	if _game_over:
		return
	_player_health.take_damage(ball_damage)


func _on_player_health_changed(_current_hp: int, _max_hp: int) -> void:
	_update_hp_bar()


func _on_player_died() -> void:
	_end_game("GAME OVER")


func _end_game(text: String) -> void:
	_game_over = true
	_status_label.text = text
	_status_label.add_theme_font_size_override("font_size", 32)
	_status_label.visible = true
	_paddle.set_physics_process(false)
	_paddle.set_process_input(false)
	if _current_ball and is_instance_valid(_current_ball):
		_current_ball.set_physics_process(false)
		_current_ball.set_process_input(false)


func _update_hp_bar() -> void:
	var current_hp: int = _player_health.get_current_hp()
	var max_hp: int = _player_health.max_hp
	var hp_ratio: float = float(current_hp) / float(max_hp)
	_hp_bar_fill.size.x = (HP_BAR_WIDTH - 4.0) * hp_ratio
	_hp_label.text = "HP: " + str(current_hp) + " / " + str(max_hp)


func _input(event: InputEvent) -> void:
	if not _game_over:
		return
	if event.is_action_pressed("launch_ball"):
		get_tree().reload_current_scene()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_tree().reload_current_scene()
	elif event is InputEventScreenTouch and event.pressed:
		get_tree().reload_current_scene()
