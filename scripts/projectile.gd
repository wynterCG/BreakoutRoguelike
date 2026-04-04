extends Area2D
class_name Projectile

const DESTROY_Y: float = 680.0
const DESTROY_MARGIN: float = 20.0

var _direction: Vector2 = Vector2.DOWN
var _speed: float = 150.0
var damage: int = 5
var color: Color = Color(1.0, 0.3, 0.2, 1.0)


func _ready() -> void:
	add_to_group("projectiles")
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 5.0
	$CollisionShape2D.shape = shape
	$Visual.color = color


func _physics_process(delta: float) -> void:
	# Slow Field: reduce speed near paddle
	var effective_speed: float = _speed
	if UpgradeManager.slow_field > 0.0 and global_position.y > 400.0:
		var slow_factor: float = 1.0 - UpgradeManager.slow_field
		effective_speed *= slow_factor

	global_position += _direction * effective_speed * delta

	# Destroy before ouch zone or off-screen
	if global_position.y > DESTROY_Y:
		queue_free()
	elif global_position.x < -DESTROY_MARGIN or global_position.x > 1300.0:
		queue_free()
	elif global_position.y < -DESTROY_MARGIN:
		queue_free()


func setup(dir: Vector2, spd: float, dmg: int) -> void:
	_direction = dir.normalized()
	_speed = spd
	damage = dmg
