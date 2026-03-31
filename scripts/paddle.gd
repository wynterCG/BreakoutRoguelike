extends CharacterBody2D
class_name Paddle

const MOVE_SPEED: float = 600.0
const ARC_WIDTH: float = 200.0
const ARC_HEIGHT: float = 30.0
const ARC_SEGMENTS: int = 16
const SCREEN_MARGIN: float = 10.0

var _screen_width: float = 0.0

@onready var _collision: CollisionPolygon2D = $CollisionPolygon2D
@onready var _visual: Polygon2D = $Polygon2D


func _ready() -> void:
	_screen_width = get_viewport_rect().size.x
	var arc_points: PackedVector2Array = _generate_arc_points()
	_collision.polygon = arc_points
	_visual.polygon = arc_points
	_visual.color = Color(0.2, 0.6, 1.0)


func _physics_process(_delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	velocity = Vector2(direction * MOVE_SPEED, 0.0)
	move_and_slide()
	# Clamp to screen bounds
	var half_width: float = ARC_WIDTH / 2.0
	position.x = clampf(position.x, SCREEN_MARGIN + half_width, _screen_width - SCREEN_MARGIN - half_width)


func _generate_arc_points() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var half_width: float = ARC_WIDTH / 2.0
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


func get_bounce_normal(hit_position: Vector2) -> Vector2:
	## Returns the surface normal at a given hit position on the arc.
	## Used by the ball to calculate reflection direction.
	var local_pos: Vector2 = to_local(hit_position)
	var half_width: float = ARC_WIDTH / 2.0
	var t: float = clampf((local_pos.x + half_width) / ARC_WIDTH, 0.0, 1.0)
	# Derivative of the arc: y = -ARC_HEIGHT * (1 - (2t-1)^2)
	# dy/dt = -ARC_HEIGHT * -2 * (2t-1) * 2 = 4 * ARC_HEIGHT * (2t - 1)
	var normalized: float = 2.0 * t - 1.0
	var slope: float = 4.0 * ARC_HEIGHT * normalized / ARC_WIDTH
	# Tangent vector along the arc surface
	var tangent: Vector2 = Vector2(1.0, slope).normalized()
	# Normal is perpendicular to tangent, pointing upward
	var normal: Vector2 = Vector2(-tangent.y, tangent.x)
	if normal.y > 0.0:
		normal = -normal
	return normal.normalized()
