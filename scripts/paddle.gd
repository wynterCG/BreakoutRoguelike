extends CharacterBody2D
class_name Paddle

const MOVE_SPEED: float = 600.0
const ARC_WIDTH: float = 200.0
const ARC_HEIGHT: float = 30.0
const ARC_SEGMENTS: int = 16
const SCREEN_MARGIN: float = 10.0
const MAX_TOUCH_SPEED: float = 3000.0

signal hit_by_projectile(damage: int)

var _screen_width: float = 0.0
var _use_touch: bool = false
var _touch_target_x: float = 640.0

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
	var arc_points: PackedVector2Array = _generate_arc_points_with_width(effective_width)
	_collision.polygon = arc_points
	_visual.polygon = arc_points
	_visual.color = Color(0.2, 0.6, 1.0)

	# Update hurt zone to match paddle width
	var hurt_rect: RectangleShape2D = RectangleShape2D.new()
	hurt_rect.size = Vector2(effective_width, ARC_HEIGHT + 10.0)
	_hurt_shape.shape = hurt_rect


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_use_touch = true
		_touch_target_x = event.position.x
	elif event is InputEventMouseButton and event.pressed:
		_use_touch = true
		_touch_target_x = event.position.x
	elif event is InputEventScreenTouch and event.pressed:
		_use_touch = true
		_touch_target_x = event.position.x
	elif event is InputEventScreenDrag:
		_use_touch = true
		_touch_target_x = event.position.x
	elif event is InputEventKey:
		_use_touch = false


func _physics_process(delta: float) -> void:
	var effective_width: float = UpgradeManager.get_effective_paddle_width(ARC_WIDTH)
	var half_width: float = effective_width / 2.0
	var min_x: float = SCREEN_MARGIN + half_width
	var max_x: float = _screen_width - SCREEN_MARGIN - half_width

	if _use_touch:
		var target_x: float = clampf(_touch_target_x, min_x, max_x)
		var diff: float = target_x - position.x
		velocity = Vector2(clampf(diff / delta, -MAX_TOUCH_SPEED, MAX_TOUCH_SPEED), 0.0)
	else:
		var direction: float = Input.get_axis("move_left", "move_right")
		velocity = Vector2(direction * MOVE_SPEED, 0.0)

	var locked_y: float = position.y
	move_and_slide()
	position.x = clampf(position.x, min_x, max_x)
	position.y = locked_y


func _generate_arc_points_with_width(width: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var half_width: float = width / 2.0
	# Top surface: the arc (concave upward — ball sits in the curve)
	for i: int in range(ARC_SEGMENTS + 1):
		var t: float = float(i) / float(ARC_SEGMENTS)
		var x: float = lerpf(-half_width, half_width, t)
		# Parabolic arc: highest (most negative y) at edges, lowest at center
		var normalized: float = (t - 0.5) * 2.0  # -1 to 1
		var y: float = -ARC_HEIGHT * (1.0 - normalized * normalized)
		points.append(Vector2(x, y))
	# Bottom edge: flat bottom to close the polygon
	points.append(Vector2(half_width, 5.0))
	points.append(Vector2(-half_width, 5.0))
	return points


func _on_hurt_zone_area_entered(area: Area2D) -> void:
	if area.is_in_group("projectiles"):
		hit_by_projectile.emit(area.damage)
		area.queue_free()
