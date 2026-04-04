extends CharacterBody2D
class_name Paddle

const MOVE_SPEED: float = 600.0
const ARC_WIDTH: float = 80.0
const ARC_HEIGHT: float = 15.0
const ARC_SEGMENTS: int = 16
const SCREEN_MARGIN: float = 10.0
const MAX_TOUCH_SPEED: float = 3000.0
const PADDLE_MIN_Y: float = 450.0
const PADDLE_MAX_Y: float = 680.0

signal hit_by_projectile(damage: int)
signal laser_fired(x_position: float, damage: int)
signal token_collected(amount: int)

var _screen_width: float = 0.0
var _use_touch: bool = false
var _touch_target: Vector2 = Vector2(640.0, 640.0)
var _laser_timer: float = 7.0
var _shield_timer: float = 0.0
var _shield_active: bool = true

@onready var _collision: CollisionPolygon2D = $CollisionPolygon2D
@onready var _visual: Polygon2D = $Polygon2D
@onready var _hurt_zone: Area2D = $HurtZone
@onready var _hurt_shape: CollisionShape2D = $HurtZone/HurtShape


func _ready() -> void:
	_screen_width = get_viewport_rect().size.x
	_hurt_zone.area_entered.connect(_on_hurt_zone_area_entered)
	apply_width_upgrade()


func apply_width_upgrade() -> void:
	var effective_width: float = UpgradeManager.get_effective_paddle_width(ARC_WIDTH)
	var arc_points: PackedVector2Array = _generate_arc_points(effective_width)
	_collision.polygon = arc_points
	_visual.polygon = arc_points
	_visual.color = Color(0.2, 0.6, 1.0)

	# Hurt zone matches paddle
	var hurt_rect: RectangleShape2D = RectangleShape2D.new()
	hurt_rect.size = Vector2(effective_width, ARC_HEIGHT + 10.0)
	_hurt_shape.shape = hurt_rect


func get_half_width() -> float:
	return UpgradeManager.get_effective_paddle_width(ARC_WIDTH) / 2.0


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_use_touch = true
		_touch_target = event.position
	elif event is InputEventMouseButton and event.pressed:
		_use_touch = true
		_touch_target = event.position
	elif event is InputEventScreenTouch and event.pressed:
		_use_touch = true
		_touch_target = event.position
	elif event is InputEventScreenDrag:
		_use_touch = true
		_touch_target = event.position
	elif event is InputEventKey:
		_use_touch = false


func _physics_process(delta: float) -> void:
	var half_w: float = get_half_width()
	var min_x: float = SCREEN_MARGIN + half_w
	var max_x: float = _screen_width - SCREEN_MARGIN - half_w

	if _use_touch:
		var target: Vector2 = Vector2(
			clampf(_touch_target.x, min_x, max_x),
			clampf(_touch_target.y, PADDLE_MIN_Y, PADDLE_MAX_Y)
		)
		var diff: Vector2 = target - position
		var safe_delta: float = delta if delta > 0.0001 else 0.016
		velocity = diff / safe_delta
		if velocity.length() > MAX_TOUCH_SPEED:
			velocity = velocity.normalized() * MAX_TOUCH_SPEED
	else:
		var dir_x: float = Input.get_axis("move_left", "move_right")
		var dir_y: float = Input.get_axis("move_up", "move_down")
		velocity = Vector2(dir_x, dir_y).normalized() * MOVE_SPEED

	move_and_slide()
	position.x = clampf(position.x, min_x, max_x)
	position.y = clampf(position.y, PADDLE_MIN_Y, PADDLE_MAX_Y)

	# Paddle Laser
	if UpgradeManager.laser_damage > 0:
		_laser_timer -= delta
		if _laser_timer <= 0.0:
			_laser_timer = 7.0
			laser_fired.emit(position.x, UpgradeManager.laser_damage)

	# Shield recharge
	if UpgradeManager.shield_charges > 0 and not _shield_active:
		_shield_timer -= delta
		if _shield_timer <= 0.0:
			_shield_active = true


func _generate_arc_points(width: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var half_width: float = width / 2.0
	for i: int in range(ARC_SEGMENTS + 1):
		var t: float = float(i) / float(ARC_SEGMENTS)
		var x: float = lerpf(-half_width, half_width, t)
		var normalized: float = (t - 0.5) * 2.0
		var y: float = -ARC_HEIGHT * (1.0 - normalized * normalized)
		points.append(Vector2(x, y))
	points.append(Vector2(half_width, 5.0))
	points.append(Vector2(-half_width, 5.0))
	return points


func _on_hurt_zone_area_entered(area: Area2D) -> void:
	if area.is_in_group("tokens"):
		token_collected.emit(area.value)
		area.queue_free()
		return
	if area.is_in_group("projectiles"):
		if _shield_active:
			_shield_active = false
			_shield_timer = 15.0
			area.queue_free()
			return
		hit_by_projectile.emit(area.damage)
		area.queue_free()
