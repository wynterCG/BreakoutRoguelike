extends Label
class_name DamageNumber

const FLOAT_SPEED: float = 40.0
const DURATION: float = 0.8
const SPREAD: float = 15.0

var _timer: float = 0.0


static func spawn(parent: Node, pos: Vector2, amount: int, color: Color = Color.WHITE) -> void:
	var label: DamageNumber = DamageNumber.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos + Vector2(randf_range(-SPREAD, SPREAD), randf_range(-SPREAD, 0.0))
	label.z_index = 100
	parent.add_child(label)


func _process(delta: float) -> void:
	_timer += delta
	position.y -= FLOAT_SPEED * delta
	modulate.a = 1.0 - (_timer / DURATION)
	if _timer >= DURATION:
		queue_free()
