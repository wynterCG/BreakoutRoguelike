extends Area2D
class_name TokenPickup

const GRAVITY: float = 120.0
const DESTROY_Y: float = 720.0
const TOKEN_SIZE: float = 8.0

var value: int = 1
var _velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("tokens")
	collision_layer = 32
	collision_mask = 0

	# Collision shape
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = TOKEN_SIZE
	var col: CollisionShape2D = CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	# Visual — small golden diamond
	var visual: Polygon2D = Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(0, -TOKEN_SIZE),
		Vector2(TOKEN_SIZE, 0),
		Vector2(0, TOKEN_SIZE),
		Vector2(-TOKEN_SIZE, 0),
	])
	visual.color = Color(1.0, 0.85, 0.2)
	add_child(visual)

	# Value label
	if value > 1:
		var label: Label = Label.new()
		label.text = str(value)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-10, -20)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		add_child(label)

	# Small random horizontal kick on spawn
	_velocity = Vector2(randf_range(-30.0, 30.0), randf_range(-50.0, -20.0))


func _physics_process(delta: float) -> void:
	_velocity.y += GRAVITY * delta
	global_position += _velocity * delta

	if global_position.y > DESTROY_Y:
		queue_free()
