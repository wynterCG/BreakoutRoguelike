extends Node
class_name MovementComponent

const ARENA_MIN_X: float = 30.0
const ARENA_MAX_X: float = 1250.0
const ARENA_MIN_Y: float = 30.0
const ARENA_MAX_Y: float = 680.0
const DRIFT_BOUND: float = 120.0
const ZIGZAG_BOUND: float = 80.0
const CHARGE_HOLD_TIME: float = 0.5
const CHARGE_TARGET_OFFSET: float = 60.0
const MAX_COMBINED_SPEED: float = 200.0
const AVOIDANCE_RADIUS: float = 150.0
const AVOIDANCE_STRENGTH: float = 80.0
const AVOIDANCE_REBUILD_INTERVAL: float = 0.3

enum ChargeState { IDLE, CHARGING, HOLDING, RETURNING }

var _spawn_position: Vector2 = Vector2.ZERO
var _monster_data: MonsterData = null
var _paddle_y: float = 650.0

# Drift state
var _drift_direction: float = 1.0

# Zigzag state
var _zigzag_direction: Vector2 = Vector2(1.0, 1.0)

# Orbit state
var _orbit_angle: float = 0.0

# Charge state
var _charge_state: ChargeState = ChargeState.IDLE
var _charge_timer: float = 0.0

# Avoidance state
var _avoidance_timer: float = 0.0
var _nearby_blocks: Array[Node2D] = []
var _owner_block: Node2D = null


func initialize(data: MonsterData, spawn_pos: Vector2) -> void:
	_monster_data = data
	_spawn_position = spawn_pos
	_owner_block = get_parent() as Node2D

	# Randomize starting directions
	_drift_direction = 1.0 if randf() > 0.5 else -1.0
	var diag_x: float = 1.0 if randf() > 0.5 else -1.0
	var diag_y: float = 1.0 if randf() > 0.5 else -1.0
	_zigzag_direction = Vector2(diag_x, diag_y).normalized()
	_orbit_angle = randf() * TAU

	if data.charge_enabled:
		_charge_timer = data.charge_interval * randf()

	_avoidance_timer = AVOIDANCE_REBUILD_INTERVAL * randf()


func get_movement_velocity(current_pos: Vector2, delta: float) -> Vector2:
	if not _monster_data:
		return Vector2.ZERO

	var combined: Vector2 = Vector2.ZERO

	if _monster_data.drift_enabled:
		combined += _calc_drift(current_pos)

	if _monster_data.zigzag_enabled:
		combined += _calc_zigzag(current_pos)

	if _monster_data.orbit_enabled:
		combined += _calc_orbit(current_pos, delta)

	if _monster_data.charge_enabled:
		combined += _calc_charge(current_pos, delta)

	# Soft avoidance
	combined += _calc_avoidance(current_pos, delta)

	# Clamp combined speed
	if combined.length() > MAX_COMBINED_SPEED:
		combined = combined.normalized() * MAX_COMBINED_SPEED

	return combined


func _calc_drift(current_pos: Vector2) -> Vector2:
	var speed: float = _monster_data.drift_speed
	var drift_offset: float = current_pos.x - _spawn_position.x

	# Reverse at bounds
	if drift_offset > DRIFT_BOUND:
		_drift_direction = -1.0
	elif drift_offset < -DRIFT_BOUND:
		_drift_direction = 1.0

	# Reverse at arena walls
	if current_pos.x >= ARENA_MAX_X:
		_drift_direction = -1.0
	elif current_pos.x <= ARENA_MIN_X:
		_drift_direction = 1.0

	return Vector2(_drift_direction * speed, 0.0)


func _calc_zigzag(current_pos: Vector2) -> Vector2:
	var speed: float = _monster_data.zigzag_speed
	var offset: Vector2 = current_pos - _spawn_position

	# Bounce at bounding box
	if absf(offset.x) > ZIGZAG_BOUND:
		_zigzag_direction.x = -signf(offset.x)
	if absf(offset.y) > ZIGZAG_BOUND:
		_zigzag_direction.y = -signf(offset.y)

	# Bounce at arena walls (absf pattern prevents oscillation)
	if current_pos.x >= ARENA_MAX_X:
		_zigzag_direction.x = -absf(_zigzag_direction.x)
	elif current_pos.x <= ARENA_MIN_X:
		_zigzag_direction.x = absf(_zigzag_direction.x)
	if current_pos.y >= ARENA_MAX_Y:
		_zigzag_direction.y = -absf(_zigzag_direction.y)
	elif current_pos.y <= ARENA_MIN_Y:
		_zigzag_direction.y = absf(_zigzag_direction.y)

	return _zigzag_direction.normalized() * speed


func _calc_orbit(current_pos: Vector2, delta: float) -> Vector2:
	var angular_speed: float = _monster_data.orbit_speed / _monster_data.orbit_radius
	_orbit_angle += angular_speed * delta
	if _orbit_angle > TAU:
		_orbit_angle -= TAU

	var target: Vector2 = _spawn_position + Vector2(
		cos(_orbit_angle) * _monster_data.orbit_radius,
		sin(_orbit_angle) * _monster_data.orbit_radius
	)
	target.x = clampf(target.x, ARENA_MIN_X, ARENA_MAX_X)
	target.y = clampf(target.y, ARENA_MIN_Y, ARENA_MAX_Y)

	var diff: Vector2 = target - current_pos
	if diff.length() < 1.0:
		return Vector2.ZERO
	return diff.normalized() * _monster_data.orbit_speed


func _calc_charge(current_pos: Vector2, delta: float) -> Vector2:
	var speed: float = _monster_data.charge_speed

	match _charge_state:
		ChargeState.IDLE:
			_charge_timer -= delta
			if _charge_timer <= 0.0:
				_charge_state = ChargeState.CHARGING
			return Vector2.ZERO

		ChargeState.CHARGING:
			var target_y: float = _paddle_y - CHARGE_TARGET_OFFSET
			if current_pos.y >= target_y:
				_charge_state = ChargeState.HOLDING
				_charge_timer = CHARGE_HOLD_TIME
				return Vector2.ZERO
			return Vector2(0.0, speed)

		ChargeState.HOLDING:
			_charge_timer -= delta
			if _charge_timer <= 0.0:
				_charge_state = ChargeState.RETURNING
			return Vector2.ZERO

		ChargeState.RETURNING:
			var diff_y: float = _spawn_position.y - current_pos.y
			if absf(diff_y) < 2.0:
				_charge_state = ChargeState.IDLE
				_charge_timer = _monster_data.charge_interval
				return Vector2.ZERO
			return Vector2(0.0, signf(diff_y) * speed * 0.5)

	return Vector2.ZERO


func _calc_avoidance(current_pos: Vector2, delta: float) -> Vector2:
	# Rebuild neighbor list periodically
	_avoidance_timer -= delta
	if _avoidance_timer <= 0.0:
		_avoidance_timer = AVOIDANCE_REBUILD_INTERVAL
		_rebuild_nearby_blocks(current_pos)

	# Push away from nearby blocks
	var repulsion: Vector2 = Vector2.ZERO
	for block: Node2D in _nearby_blocks:
		if not is_instance_valid(block):
			continue
		var diff: Vector2 = current_pos - block.global_position
		var dist: float = diff.length()
		if dist < 1.0:
			repulsion += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * AVOIDANCE_STRENGTH
		elif dist < AVOIDANCE_RADIUS:
			var strength: float = AVOIDANCE_STRENGTH * (1.0 - dist / AVOIDANCE_RADIUS)
			repulsion += diff.normalized() * strength

	return repulsion


func _rebuild_nearby_blocks(current_pos: Vector2) -> void:
	_nearby_blocks.clear()
	if not _owner_block or not is_instance_valid(_owner_block):
		return
	var all_blocks: Array[Node] = _owner_block.get_tree().get_nodes_in_group("blocks")
	for block_node: Node in all_blocks:
		if block_node == _owner_block:
			continue
		if block_node is Node2D:
			var dist: float = current_pos.distance_to((block_node as Node2D).global_position)
			if dist < AVOIDANCE_RADIUS:
				_nearby_blocks.append(block_node as Node2D)
