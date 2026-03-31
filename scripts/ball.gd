extends CharacterBody2D
class_name Ball

const BASE_SPEED: float = 400.0
const MIN_VERTICAL_RATIO: float = 0.3

var _direction: Vector2 = Vector2.ZERO
var _speed: float = BASE_SPEED
var _is_launched: bool = false
var _paddle: Paddle = null

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 10.0
	_collision.shape = circle


func _physics_process(delta: float) -> void:
	if not _is_launched:
		_follow_paddle()
		if Input.is_action_just_pressed("launch_ball"):
			_launch()
		return

	velocity = _direction * _speed
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		_handle_collision(collision)


func setup(paddle: Paddle) -> void:
	_paddle = paddle
	_is_launched = false


func _follow_paddle() -> void:
	if _paddle:
		global_position = _paddle.global_position + Vector2(0.0, -40.0)


func _launch() -> void:
	_is_launched = true
	var angle: float = randf_range(-0.3, 0.3)
	_direction = Vector2(angle, -1.0).normalized()


func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider: Object = collision.get_collider()

	if collider is Paddle:
		var paddle: Paddle = collider as Paddle
		var normal: Vector2 = paddle.get_bounce_normal(collision.get_position())
		_direction = _direction.bounce(normal)
	else:
		_direction = _direction.bounce(collision.get_normal())

	# Ensure minimum vertical component to avoid horizontal loops
	if absf(_direction.y) < MIN_VERTICAL_RATIO:
		var y_sign: float = -1.0 if _direction.y >= 0.0 else 1.0
		_direction.y = MIN_VERTICAL_RATIO * y_sign
		_direction = _direction.normalized()

	# Notify blocks of hits
	if collider.has_method("hit"):
		collider.hit()


func reset_to_paddle() -> void:
	_is_launched = false
	_speed = BASE_SPEED
	_direction = Vector2.ZERO
