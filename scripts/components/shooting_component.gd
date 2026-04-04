extends Node
class_name ShootingComponent

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/entities/projectile.tscn")
const BURST_DELAY: float = 0.15
const SPREAD_ANGLE: float = 15.0

signal projectile_spawned(projectile: Area2D, spawn_pos: Vector2)

var _monster_data: MonsterData = null
var _get_paddle_pos: Callable
var _has_shooting: bool = false

# Independent timers per pattern
var _straight_timer: float = 0.0
var _aimed_timer: float = 0.0
var _spread_timer: float = 0.0
var _burst_timer: float = 0.0
var _burst_remaining: int = 0
var _burst_delay_timer: float = 0.0


func initialize(data: MonsterData, paddle_pos_callable: Callable) -> void:
	_monster_data = data
	_get_paddle_pos = paddle_pos_callable
	_has_shooting = data.shoot_straight_enabled or data.shoot_aimed_enabled \
		or data.shoot_spread_enabled or data.shoot_burst_enabled

	if not _has_shooting:
		set_physics_process(false)
		return

	# Randomize initial timers to prevent synchronized volleys
	if data.shoot_straight_enabled:
		_straight_timer = data.shoot_straight_interval * randf()
	if data.shoot_aimed_enabled:
		_aimed_timer = data.shoot_aimed_interval * randf()
	if data.shoot_spread_enabled:
		_spread_timer = data.shoot_spread_interval * randf()
	if data.shoot_burst_enabled:
		_burst_timer = data.shoot_burst_interval * randf()


func _physics_process(delta: float) -> void:
	if not _monster_data or not _has_shooting:
		return

	var spawn_pos: Vector2 = (get_parent() as Node2D).global_position

	# Handle burst in progress
	if _burst_remaining > 0:
		_burst_delay_timer -= delta
		if _burst_delay_timer <= 0.0:
			_burst_delay_timer = BURST_DELAY
			_burst_remaining -= 1
			_fire_projectile(spawn_pos, Vector2.DOWN, _monster_data.shoot_burst_speed, _monster_data.shoot_burst_damage)

	# Straight
	if _monster_data.shoot_straight_enabled:
		_straight_timer -= delta
		if _straight_timer <= 0.0:
			_straight_timer = _monster_data.shoot_straight_interval
			_fire_projectile(spawn_pos, Vector2.DOWN, _monster_data.shoot_straight_speed, _monster_data.shoot_straight_damage)

	# Aimed
	if _monster_data.shoot_aimed_enabled:
		_aimed_timer -= delta
		if _aimed_timer <= 0.0:
			_aimed_timer = _monster_data.shoot_aimed_interval
			var paddle_pos: Vector2 = _get_paddle_pos.call()
			var aim_dir: Vector2 = (paddle_pos - spawn_pos).normalized()
			_fire_projectile(spawn_pos, aim_dir, _monster_data.shoot_aimed_speed, _monster_data.shoot_aimed_damage)

	# Spread
	if _monster_data.shoot_spread_enabled:
		_spread_timer -= delta
		if _spread_timer <= 0.0:
			_spread_timer = _monster_data.shoot_spread_interval
			var count: int = _monster_data.shoot_spread_count
			var total_angle: float = SPREAD_ANGLE * float(count - 1)
			var start_angle: float = -total_angle / 2.0
			for i: int in range(count):
				var angle: float = deg_to_rad(start_angle + SPREAD_ANGLE * float(i))
				var dir: Vector2 = Vector2(sin(angle), cos(angle))
				_fire_projectile(spawn_pos, dir, _monster_data.shoot_spread_speed, _monster_data.shoot_spread_damage)

	# Burst (start new burst)
	if _monster_data.shoot_burst_enabled and _burst_remaining <= 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_timer = _monster_data.shoot_burst_interval
			_burst_remaining = _monster_data.shoot_burst_count
			_burst_delay_timer = 0.0


func _fire_projectile(pos: Vector2, dir: Vector2, spd: float, dmg: int) -> void:
	var proj: Area2D = PROJECTILE_SCENE.instantiate() as Area2D
	proj.setup(dir, spd, dmg)
	proj.color = _monster_data.color
	projectile_spawned.emit(proj, pos)
