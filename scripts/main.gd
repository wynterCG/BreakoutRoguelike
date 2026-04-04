extends Node2D
class_name Main

const BLOCK_SCENE: PackedScene = preload("res://scenes/entities/block.tscn")
const BALL_SCENE: PackedScene = preload("res://scenes/entities/ball.tscn")
const MONSTERS_DIR: String = "res://data/monsters/"

const LEVEL_POOLS_DIR: String = "res://data/level_pools/"
const ARENA_HEIGHT: float = 200.0
const GRID_Y_OFFSET: float = 60.0
const PADDLE_Y: float = 640.0
const PLAYER_MAX_HP: int = 100
const HP_SCALE_PER_LEVEL: float = 0.1

const HP_BAR_WIDTH: float = 1200.0
const HP_BAR_HEIGHT: float = 20.0
const HP_BAR_Y: float = 700.0

var _level: int = 1
var _blocks_remaining: int = 0
var _current_ball: Ball = null
var _game_over: bool = false
var _monster_types: Array[MonsterData] = []
var _regen_accumulator: float = 0.0

@onready var _paddle: Paddle = $Paddle
@onready var _block_container: Node2D = $BlockContainer
@onready var _status_label: Label = $UI/StatusLabel
@onready var _hp_bar_bg: ColorRect = $UI/HPBarBackground
@onready var _hp_bar_fill: ColorRect = $UI/HPBarFill
@onready var _hp_label: Label = $UI/HPLabel
@onready var _player_health: HealthComponent = $PlayerHealth
@onready var _upgrade_selection: UpgradeSelection = $UpgradeSelection


func _ready() -> void:
	_paddle.position = Vector2(640.0, PADDLE_Y)
	_player_health.initialize(PLAYER_MAX_HP)
	_player_health.health_changed.connect(_on_player_health_changed)
	_player_health.died.connect(_on_player_died)
	_upgrade_selection.all_picks_done.connect(_on_all_picks_done)
	_paddle.hit_by_projectile.connect(_on_paddle_hit_by_projectile)
	_paddle.laser_fired.connect(_on_laser_fired)
	_load_monster_types()
	_spawn_enemies()
	_spawn_ball()
	_setup_hp_bar()


func _physics_process(delta: float) -> void:
	if _game_over:
		return
	# Regen upgrade: 1 HP every (10 / stacks) seconds
	if UpgradeManager.regen_rate > 0.0 and _player_health.get_current_hp() > 0:
		var regen_interval: float = 10.0 / UpgradeManager.regen_rate
		_regen_accumulator += delta
		if _regen_accumulator >= regen_interval:
			_regen_accumulator -= regen_interval
			_player_health.heal(1)
			_update_hp_bar()
			DamageNumber.spawn(self, Vector2(640.0, HP_BAR_Y - 15.0), 1, Color(0.4, 1.0, 0.4))


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

	_monster_types.sort_custom(func(a: MonsterData, b: MonsterData) -> bool: return a.hp > b.hp)


func _spawn_enemies() -> void:
	var pool: LevelPool = _load_level_pool(_level)
	var formation: FormationData = null

	if pool and pool.formations.size() > 0:
		formation = pool.formations[randi() % pool.formations.size()]

	if formation:
		_spawn_from_formation(formation)
	else:
		_spawn_fallback_grid()


func _load_level_pool(level: int) -> LevelPool:
	var path: String = LEVEL_POOLS_DIR + "level_%02d.tres" % level
	if ResourceLoader.exists(path):
		var res: Resource = ResourceLoader.load(path)
		if res is LevelPool:
			return res as LevelPool
	return null


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

	# Row-based Y alignment: find tallest block per row
	var row_max_h: Dictionary = {}
	for cell: FormationCell in cells:
		var row: int = cell.grid_position.y
		var cell_h: float = block_h * cell.size_scale.y
		if not row_max_h.has(row) or cell_h > row_max_h[row]:
			row_max_h[row] = cell_h

	# Build cumulative Y offsets (row index -> Y center of row)
	var row_y: Dictionary = {}
	var current_y: float = GRID_Y_OFFSET
	for row: int in range(formation.grid_rows):
		var tallest: float = row_max_h.get(row, block_h)
		row_y[row] = current_y + tallest / 2.0
		current_y += tallest + gap_y

	# X centering (unchanged)
	var total_w: float = float(formation.grid_columns) * spacing_x
	var offset_x: float = (1280.0 - total_w) / 2.0 + spacing_x / 2.0

	# Spawn blocks
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
		block.set_paddle(_paddle)
		block.position = pixel_pos
		block.destroyed.connect(_on_block_destroyed)
		block.projectile_spawned.connect(_on_projectile_spawned)
		block.killed.connect(_on_block_killed)
		_block_container.add_child(block)
		_blocks_remaining += 1


func _resolve_monster(cell: FormationCell, level: int) -> MonsterData:
	if cell.monster_override:
		return cell.monster_override

	var candidates: Array[MonsterData] = []
	for monster: MonsterData in _monster_types:
		if monster.min_level <= level and monster.role == cell.role:
			candidates.append(monster)

	if candidates.is_empty():
		for monster: MonsterData in _monster_types:
			if monster.min_level <= level:
				candidates.append(monster)

	if candidates.is_empty() and _monster_types.size() > 0:
		return _monster_types[0]

	if candidates.is_empty():
		return null

	return candidates[randi() % candidates.size()]


func _spawn_fallback_grid() -> void:
	var spacing_x: float = 70.0
	var spacing_y: float = 30.0
	var total_w: float = 14.0 * spacing_x
	var offset_x: float = (1280.0 - total_w) / 2.0 + spacing_x / 2.0
	for row: int in range(5):
		for col: int in range(14):
			var block: Block = BLOCK_SCENE.instantiate() as Block
			if _monster_types.size() > 0:
				var monster: MonsterData = _monster_types[0]
				block.monster_data = monster
				block.max_hp = int(ceilf(float(monster.hp) * (1.0 + float(_level - 1) * HP_SCALE_PER_LEVEL)))
			else:
				block.max_hp = 1
			block.set_paddle(_paddle)
			block.position = Vector2(offset_x + float(col) * spacing_x, GRID_Y_OFFSET + float(row) * spacing_y)
			block.destroyed.connect(_on_block_destroyed)
			block.projectile_spawned.connect(_on_projectile_spawned)
			block.killed.connect(_on_block_killed)
			_block_container.add_child(block)
			_blocks_remaining += 1


func _spawn_ball() -> void:
	_current_ball = BALL_SCENE.instantiate() as Ball
	_current_ball.setup(_paddle)
	_current_ball.hit_back_wall.connect(_on_ball_hit_back_wall)
	_current_ball.heal_player.connect(_on_ball_heal_player)
	_current_ball.split_requested.connect(_on_ball_split_requested)
	add_child(_current_ball)


func _on_block_destroyed() -> void:
	_blocks_remaining -= 1
	if _blocks_remaining <= 0:
		_start_upgrade_selection()


func _start_upgrade_selection() -> void:
	# Destroy split balls
	for child: Node in get_children():
		if child is Ball and child != _current_ball:
			child.queue_free()

	# Destroy projectiles
	for proj: Node in get_tree().get_nodes_in_group("projectiles"):
		proj.queue_free()

	# Freeze gameplay
	if _current_ball and is_instance_valid(_current_ball):
		_current_ball.set_physics_process(false)
		_current_ball.set_process_input(false)
	_paddle.set_physics_process(false)
	_paddle.set_process_input(false)
	get_tree().paused = true
	_upgrade_selection.show_selection()


func _on_all_picks_done() -> void:
	get_tree().paused = false
	_level += 1
	_start_next_level()


func _start_next_level() -> void:
	# Clear remaining blocks
	for child: Node in _block_container.get_children():
		child.queue_free()
	_blocks_remaining = 0
	_regen_accumulator = 0.0

	# Destroy split balls
	for child: Node in get_children():
		if child is Ball and child != _current_ball:
			child.queue_free()

	# Destroy projectiles
	for proj: Node in get_tree().get_nodes_in_group("projectiles"):
		proj.queue_free()

	# Apply max HP bonus
	var total_max_hp: int = PLAYER_MAX_HP + UpgradeManager.max_hp_bonus
	if _player_health.max_hp != total_max_hp:
		var hp_gained: int = total_max_hp - _player_health.max_hp
		_player_health.max_hp = total_max_hp
		_player_health.heal(hp_gained)

	# Update paddle width
	_paddle.apply_width_upgrade()

	# Respawn blocks with scaled HP
	_spawn_enemies()

	# Unfreeze gameplay
	_paddle.set_physics_process(true)
	_paddle.set_process_input(true)

	# Reset ball to paddle
	if _current_ball and is_instance_valid(_current_ball):
		_current_ball.set_physics_process(true)
		_current_ball.set_process_input(true)
		_current_ball.reset_to_paddle()
	else:
		_spawn_ball()

	_update_hp_bar()


func _on_ball_hit_back_wall(ball_damage: int) -> void:
	if _game_over:
		return
	var reduced: int = maxi(int(float(ball_damage) * (1.0 - UpgradeManager.damage_reduction)), 1)
	_player_health.take_damage(reduced)
	DamageNumber.spawn(self, Vector2(640.0, HP_BAR_Y - 10.0), reduced, Color(1.0, 0.2, 0.2))

	# Thorns: damage a random block when back wall is hit
	if UpgradeManager.thorns_damage > 0:
		var blocks: Array[Node] = get_tree().get_nodes_in_group("blocks")
		if blocks.size() > 0:
			var random_block: Node = blocks[randi() % blocks.size()]
			if random_block.has_method("hit"):
				random_block.hit(UpgradeManager.thorns_damage)


func _on_paddle_hit_by_projectile(damage: int) -> void:
	if _game_over:
		return
	var reduced: int = maxi(int(float(damage) * (1.0 - UpgradeManager.damage_reduction)), 1)
	_player_health.take_damage(reduced)
	DamageNumber.spawn(self, Vector2(640.0, HP_BAR_Y - 15.0), reduced, Color(1.0, 0.3, 0.3))


func _on_projectile_spawned(projectile: Area2D, spawn_pos: Vector2) -> void:
	add_child(projectile)
	projectile.global_position = spawn_pos


func _on_block_killed(_block_position: Vector2) -> void:
	# HP on Kill
	if UpgradeManager.hp_on_kill > 0:
		_player_health.heal(UpgradeManager.hp_on_kill)
		_update_hp_bar()
		DamageNumber.spawn(self, Vector2(640.0, HP_BAR_Y - 15.0), UpgradeManager.hp_on_kill, Color(0.2, 1.0, 0.2))


func _on_laser_fired(x_pos: float, laser_damage: int) -> void:
	var blocks: Array[Node] = get_tree().get_nodes_in_group("blocks")
	var half_width: float = 15.0
	for block_node: Node in blocks:
		if block_node is Node2D and block_node.has_method("hit"):
			var bx: float = (block_node as Node2D).global_position.x
			if absf(bx - x_pos) <= half_width:
				block_node.hit(laser_damage)

	# Visual: bright vertical line from paddle to top
	var laser_line: ColorRect = ColorRect.new()
	laser_line.position = Vector2(x_pos - 2.0, 0.0)
	laser_line.size = Vector2(4.0, _paddle.position.y)
	laser_line.color = Color(0.3, 0.8, 1.0, 0.8)
	add_child(laser_line)

	# Fade out and remove after 0.15 seconds
	var tween: Tween = create_tween()
	tween.tween_property(laser_line, "color:a", 0.0, 0.15)
	tween.tween_callback(laser_line.queue_free)


func _on_ball_heal_player(amount: int) -> void:
	_player_health.heal(amount)
	_update_hp_bar()
	DamageNumber.spawn(self, Vector2(640.0, HP_BAR_Y - 15.0), amount, Color(0.2, 1.0, 0.2))


func _on_ball_split_requested(pos: Vector2, count: int) -> void:
	for i: int in range(count):
		var split_ball: Ball = BALL_SCENE.instantiate() as Ball
		var dir: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, -0.3)).normalized()
		# Offset spawn position away from block to prevent spawning inside it
		split_ball.global_position = pos + dir * 20.0
		split_ball.launch_with_direction(dir)
		split_ball.modulate = Color(0.5, 0.5, 0.5, 0.7)
		var ball_ref: Ball = split_ball
		split_ball.hit_back_wall.connect(func(ball_damage: int) -> void:
			_on_ball_hit_back_wall(ball_damage)
			if is_instance_valid(ball_ref):
				ball_ref.queue_free()
		)
		split_ball.heal_player.connect(_on_ball_heal_player)
		add_child(split_ball)

		# Despawn after 5 seconds (check validity to avoid crash on scene reload)
		var timer: SceneTreeTimer = get_tree().create_timer(5.0)
		timer.timeout.connect(func() -> void:
			if is_instance_valid(ball_ref):
				ball_ref.queue_free()
		)


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
		UpgradeManager.reset()
		get_tree().reload_current_scene()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		UpgradeManager.reset()
		get_tree().reload_current_scene()
	elif event is InputEventScreenTouch and event.pressed:
		UpgradeManager.reset()
		get_tree().reload_current_scene()
