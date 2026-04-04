extends CharacterBody2D
class_name Block

const DamageNumberScene: GDScript = preload("res://scripts/ui/damage_number.gd")

signal destroyed
signal projectile_spawned(projectile: Area2D, spawn_pos: Vector2)
signal killed(block_position: Vector2)

const BLOCK_WIDTH: float = 60.0
const BLOCK_HEIGHT: float = 24.0
const BAR_PADDING: float = 2.0

# static var because GDScript does not support typed array constants
static var _FALLBACK_COLORS: Array[Color] = [
	Color(0.2, 0.8, 0.2),   # 1 HP - green
	Color(0.9, 0.7, 0.1),   # 2 HP - yellow
	Color(0.9, 0.2, 0.2),   # 3 HP - red
]

@export var monster_data: MonsterData = null
@export var max_hp: int = 1
@export var size_scale: Vector2 = Vector2(1.0, 1.0)

var _total_hp: int = 1
var _block_size: Vector2 = Vector2(BLOCK_WIDTH, BLOCK_HEIGHT)
var _paddle_ref: Paddle = null
var _burn_timer: float = 0.0
var _burn_dps: float = 0.0
var _burn_accumulator: float = 0.0
var _poison_count: int = 0
var _killed_by_explosion: bool = false

@onready var _background: ColorRect = $Background
@onready var _fill_bar: ColorRect = $Background/FillBar
@onready var _hp_label: Label = $Background/HPLabel
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _health: HealthComponent = $HealthComponent
@onready var _movement: MovementComponent = $MovementComponent
@onready var _shooting: ShootingComponent = $ShootingComponent


func _ready() -> void:
	add_to_group("blocks")
	var hp: int = max_hp
	var block_color: Color = Color.WHITE

	if monster_data:
		hp = max_hp if max_hp > 1 else monster_data.hp
		block_color = monster_data.color
	else:
		var color_index: int = clampi(hp - 1, 0, _FALLBACK_COLORS.size() - 1)
		block_color = _FALLBACK_COLORS[color_index]

	_block_size = Vector2(BLOCK_WIDTH * size_scale.x, BLOCK_HEIGHT * size_scale.y)

	_total_hp = hp
	_health.initialize(hp)

	# Collision
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = _block_size
	_collision.shape = rect

	# Background (dark border/empty area)
	_background.size = _block_size
	_background.position = Vector2(-_block_size.x / 2.0, -_block_size.y / 2.0)
	_background.color = Color(0.15, 0.15, 0.15)

	# Fill bar (colored HP fill inside the block)
	_fill_bar.position = Vector2(BAR_PADDING, BAR_PADDING)
	_fill_bar.size = Vector2(_block_size.x - BAR_PADDING * 2.0, _block_size.y - BAR_PADDING * 2.0)
	_fill_bar.color = block_color

	# HP label centered on the block (relative to Background parent)
	_hp_label.position = Vector2.ZERO
	_hp_label.size = _block_size
	_hp_label.text = str(hp)
	var font_scale: float = clampf(minf(size_scale.x, size_scale.y), 0.7, 3.0)
	_hp_label.add_theme_font_size_override("font_size", int(14.0 * font_scale))
	_hp_label.add_theme_color_override("font_color", Color.WHITE)
	_hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_hp_label.add_theme_constant_override("shadow_offset_x", 1)
	_hp_label.add_theme_constant_override("shadow_offset_y", 1)

	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	set_process(false)

	# Initialize movement
	if monster_data:
		_movement.initialize(monster_data, global_position)
		var has_movement: bool = monster_data.drift_enabled or monster_data.zigzag_enabled \
			or monster_data.orbit_enabled or monster_data.charge_enabled
		if not has_movement:
			set_physics_process(false)
	else:
		set_physics_process(false)

	# Initialize shooting
	if monster_data and _paddle_ref:
		_shooting.initialize(monster_data, func() -> Vector2: return _paddle_ref.global_position)
		_shooting.projectile_spawned.connect(func(proj: Area2D, pos: Vector2) -> void: projectile_spawned.emit(proj, pos))


func set_paddle(paddle: Paddle) -> void:
	_paddle_ref = paddle


func apply_burn(dps: float, duration: float) -> void:
	_burn_dps = dps
	_burn_timer = duration
	set_process(true)


func apply_poison(stacks: int) -> void:
	_poison_count += stacks


func _process(delta: float) -> void:
	if _burn_timer <= 0.0 or not _health.is_alive():
		set_process(false)
		return
	_burn_timer -= delta
	_burn_accumulator += _burn_dps * delta
	if _burn_accumulator >= 1.0:
		var tick_damage: int = int(_burn_accumulator)
		_burn_accumulator -= float(tick_damage)
		_health.take_damage(tick_damage)
		DamageNumberScene.spawn(get_tree().root, global_position, tick_damage, Color(1.0, 0.5, 0.1))


func _physics_process(delta: float) -> void:
	var move_velocity: Vector2 = _movement.get_movement_velocity(global_position, delta)
	if move_velocity != Vector2.ZERO:
		velocity = move_velocity
		move_and_slide()
		# Clamp to arena bounds (collision_mask=0 so walls don't stop blocks)
		global_position.x = clampf(global_position.x, MovementComponent.ARENA_MIN_X, MovementComponent.ARENA_MAX_X)
		global_position.y = clampf(global_position.y, MovementComponent.ARENA_MIN_Y, MovementComponent.ARENA_MAX_Y)


func get_block_size() -> Vector2:
	return _block_size


func hit(amount: int) -> void:
	var total: int = amount + _poison_count
	_health.take_damage(total)
	# Damage number
	var dmg_color: Color = Color.WHITE
	if _poison_count > 0:
		dmg_color = Color(0.6, 1.0, 0.3)
	DamageNumberScene.spawn(get_tree().root, global_position, total, dmg_color)


func _on_health_changed(_new_hp: int, _new_max: int) -> void:
	_update_visual()


func _on_died() -> void:
	_shooting.set_physics_process(false)

	# Explosive Death (only if not killed by another explosion — prevents infinite chains)
	if UpgradeManager.explosive_death_damage > 0 and not _killed_by_explosion:
		var blocks: Array[Node] = get_tree().get_nodes_in_group("blocks")
		for block_node: Node in blocks:
			if block_node == self:
				continue
			if block_node is Node2D and block_node.has_method("hit"):
				var dist: float = (block_node as Node2D).global_position.distance_to(global_position)
				if dist <= 100.0:
					block_node._killed_by_explosion = true
					block_node.hit(UpgradeManager.explosive_death_damage)

	killed.emit(global_position)
	destroyed.emit()
	call_deferred("queue_free")


func _update_visual() -> void:
	var current_hp: int = _health.get_current_hp()
	var inner_width: float = _block_size.x - BAR_PADDING * 2.0
	var hp_ratio: float = float(current_hp) / float(_total_hp)
	_fill_bar.size.x = inner_width * hp_ratio
	_hp_label.text = str(current_hp)
