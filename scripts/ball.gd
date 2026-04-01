extends CharacterBody2D
class_name Ball

signal hit_back_wall(ball_damage: int)

const BASE_SPEED: float = 400.0
const MIN_VERTICAL_RATIO: float = 0.3
const PADDLE_FOLLOW_OFFSET_Y: float = -40.0
const POST_BOUNCE_CLEARANCE_Y: float = -12.0

@export var damage: int = 5

var _direction: Vector2 = Vector2.ZERO
var _speed: float = BASE_SPEED
var _is_launched: bool = false
var _paddle: Paddle = null

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

	var motion: Vector2 = _direction * _speed * delta
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
	else:
		# Walls and blocks: simple reflection
		_direction = _direction.bounce(collision.get_normal())

	# Ensure minimum vertical component to avoid horizontal loops
	if absf(_direction.y) < MIN_VERTICAL_RATIO:
		var y_sign: float = -1.0 if _direction.y >= 0.0 else 1.0
		_direction.y = MIN_VERTICAL_RATIO * y_sign
		_direction = _direction.normalized()

	# Notify blocks of hits (exclude paddle to prevent future damage conflicts)
	if collider is not Paddle and collider.has_method("hit"):
		collider.hit(damage)

	# Detect back wall hit for player damage
	if collider is Node and (collider as Node).is_in_group("back_wall"):
		hit_back_wall.emit(damage)


func _handle_paddle_bounce(paddle: Paddle, collision: KinematicCollision2D) -> void:
	# If ball is coming from below the paddle, just reflect normally
	if _direction.y < 0.0:
		_direction = _direction.bounce(collision.get_normal())
		return

	# Ball hit from above — use arc-based angle calculation
	var hit_pos: Vector2 = collision.get_position()
	var local_pos: Vector2 = paddle.to_local(hit_pos)
	var half_width: float = Paddle.ARC_WIDTH / 2.0
	var t: float = clampf((local_pos.x + half_width) / Paddle.ARC_WIDTH, 0.0, 1.0)

	# Map t to an angle: left edge = -70deg, center = straight up, right edge = +70deg
	var max_angle: float = deg_to_rad(70.0)
	var angle: float = lerpf(-max_angle, max_angle, t)

	# Always points upward
	_direction = Vector2(sin(angle), -cos(angle)).normalized()

	# Place ball above the paddle to prevent re-collision
	global_position.y = paddle.global_position.y - Paddle.ARC_HEIGHT + POST_BOUNCE_CLEARANCE_Y


func reset_to_paddle() -> void:
	_is_launched = false
	_speed = BASE_SPEED
	_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	_follow_paddle()
