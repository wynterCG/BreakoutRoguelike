extends CharacterBody2D
class_name Ball

signal hit_back_wall(ball_damage: int)
signal heal_player(amount: int)
signal split_requested(pos: Vector2, count: int)

const BASE_SPEED: float = 400.0
const MIN_VERTICAL_RATIO: float = 0.3
const PADDLE_FOLLOW_OFFSET_Y: float = -40.0
const POST_BOUNCE_CLEARANCE_Y: float = -12.0
const AOE_RADIUS: float = 80.0

@export var damage: int = 5

var _direction: Vector2 = Vector2.ZERO
var _speed: float = BASE_SPEED
var _is_launched: bool = false
var _paddle: Paddle = null
var _piercing_remaining: int = 0

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 10.0
	_collision.shape = circle


func _input(event: InputEvent) -> void:
	if _is_launched:
		return
	if event.is_action_pressed("launch_ball"):
		_launch()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_launch()
	elif event is InputEventScreenTouch and event.pressed:
		_launch()


func _physics_process(delta: float) -> void:
	if not _is_launched:
		_follow_paddle()
		return

	var effective_speed: float = UpgradeManager.get_effective_ball_speed(_speed)
	var motion: Vector2 = _direction * effective_speed * delta
	var collision: KinematicCollision2D = move_and_collide(motion)
	if collision:
		_handle_collision(collision)


func setup(paddle: Paddle) -> void:
	_paddle = paddle
	_is_launched = false


func _follow_paddle() -> void:
	if _paddle:
		global_position = _paddle.global_position + Vector2(0.0, PADDLE_FOLLOW_OFFSET_Y)


func _launch() -> void:
	if _is_launched:
		return
	_is_launched = true
	var angle: float = randf_range(-0.3, 0.3)
	_direction = Vector2(angle, -1.0).normalized()


func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider: Object = collision.get_collider()

	if collider is Paddle:
		_handle_paddle_bounce(collider as Paddle, collision)
		_piercing_remaining = UpgradeManager.piercing_count
	else:
		# Check piercing: if we have charges and hit a block, pass through
		var is_block: bool = collider.has_method("hit")
		if is_block and _piercing_remaining > 0:
			_piercing_remaining -= 1
			# Don't bounce — ball passes through
		else:
			# Axis-based reflection: determine which side was hit and flip that axis
			_axis_reflect(collision)
			# Reset piercing charges after bouncing
			_piercing_remaining = UpgradeManager.piercing_count

	# Ensure minimum vertical component to avoid horizontal loops
	if absf(_direction.y) < MIN_VERTICAL_RATIO:
		var y_sign: float = -1.0 if _direction.y >= 0.0 else 1.0
		_direction.y = MIN_VERTICAL_RATIO * y_sign
		_direction = _direction.normalized()

	# Handle block hits (damage, crit, lifesteal, AoE, split)
	if collider is not Paddle and collider.has_method("hit"):
		var effective_damage: int = UpgradeManager.get_effective_ball_damage(damage)

		# Critical hit (monsters only)
		var is_crit: bool = UpgradeManager.crit_chance > 0.0 and randf() < UpgradeManager.crit_chance
		if is_crit:
			effective_damage *= 2

		collider.hit(effective_damage)

		# Lifesteal
		if UpgradeManager.lifesteal_percent > 0.0:
			var heal_amount: int = maxi(int(float(effective_damage) * UpgradeManager.lifesteal_percent), 1)
			heal_player.emit(heal_amount)

		# AoE Blast
		if UpgradeManager.aoe_damage > 0 and collider is Node2D:
			var hit_position: Vector2 = (collider as Node2D).global_position
			var blocks: Array[Node] = get_tree().get_nodes_in_group("blocks")
			for block_node: Node in blocks:
				if block_node == collider:
					continue
				if block_node is Node2D and block_node.has_method("hit"):
					var dist: float = (block_node as Node2D).global_position.distance_to(hit_position)
					if dist <= AOE_RADIUS:
						(block_node as Node2D).hit(UpgradeManager.aoe_damage)

		# Split Shot
		if UpgradeManager.split_count > 0:
			split_requested.emit(global_position, UpgradeManager.split_count)

	# Detect back wall hit for player damage
	if collider is Node and (collider as Node).is_in_group("back_wall"):
		var effective_damage: int = UpgradeManager.get_effective_ball_damage(damage)
		hit_back_wall.emit(effective_damage)


func _handle_paddle_bounce(paddle: Paddle, collision: KinematicCollision2D) -> void:
	var diff: Vector2 = global_position - paddle.global_position

	if diff.y > 0.0:
		# Ball is below paddle — force it upward
		_direction.y = -absf(_direction.y)
		_direction = _direction.normalized()
		return

	# Ball hit from above — use arc-based angle calculation
	var local_pos: Vector2 = paddle.to_local(global_position)
	var effective_width: float = UpgradeManager.get_effective_paddle_width(Paddle.ARC_WIDTH)
	var half_width: float = effective_width / 2.0
	var t: float = clampf((local_pos.x + half_width) / effective_width, 0.0, 1.0)

	# Map t to an angle: left edge = -70deg, center = straight up, right edge = +70deg
	var max_angle: float = deg_to_rad(70.0)
	var angle: float = lerpf(-max_angle, max_angle, t)

	# Always points upward — guaranteed by -cos which is always negative
	_direction = Vector2(sin(angle), -cos(angle)).normalized()

	# Place ball above the paddle to prevent re-collision
	global_position.y = paddle.global_position.y - Paddle.ARC_HEIGHT + POST_BOUNCE_CLEARANCE_Y


func _axis_reflect(collision: KinematicCollision2D) -> void:
	var collider: Object = collision.get_collider()

	# For walls: use the collision normal to determine axis
	# Walls have clean normals (they're simple rectangles aligned to axes)
	if collider is Node2D and (collider as Node2D).is_in_group("back_wall"):
		# Back wall — always flip Y upward
		_direction.y = -absf(_direction.y)
		return

	# For blocks: determine which side was hit using ball position vs block center
	if collider is Node2D and collider.has_method("hit"):
		var collider_pos: Vector2 = (collider as Node2D).global_position
		var diff: Vector2 = global_position - collider_pos

		# Block is wider than tall (60x24), so scale Y by aspect ratio
		var scaled_dx: float = absf(diff.x) / 60.0
		var scaled_dy: float = absf(diff.y) / 24.0

		if scaled_dx > scaled_dy:
			# Side hit — flip X, ensure ball moves away from block
			_direction.x = signf(diff.x) * absf(_direction.x)
		else:
			# Top/bottom hit — flip Y, ensure ball moves away from block
			_direction.y = signf(diff.y) * absf(_direction.y)

		_direction = _direction.normalized()
		return

	# For walls (top, left, right): use the normal which is reliable for axis-aligned rects
	var normal: Vector2 = collision.get_normal()
	if absf(normal.x) > absf(normal.y):
		# Horizontal normal — side wall, flip X and ensure moving away
		_direction.x = signf(normal.x) * absf(_direction.x)
	else:
		# Vertical normal — top/bottom wall, flip Y and ensure moving away
		_direction.y = signf(normal.y) * absf(_direction.y)

	_direction = _direction.normalized()


func reset_to_paddle() -> void:
	_is_launched = false
	_speed = BASE_SPEED
	_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	_follow_paddle()
