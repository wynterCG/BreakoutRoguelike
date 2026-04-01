extends StaticBody2D
class_name Block

signal destroyed

const BLOCK_WIDTH: float = 60.0
const BLOCK_HEIGHT: float = 24.0
const BAR_PADDING: float = 2.0

# static var because GDScript does not support typed array constants
static var _FALLBACK_COLORS: Array[Color] = [
	Color(0.2, 0.8, 0.2),   # 1 HP - green
	Color(0.9, 0.7, 0.1),   # 2 HP - yellow
	Color(0.9, 0.2, 0.2),   # 3 HP - red
]

@export var monster_data: MonsterData = null
@export var max_hp: int = 1

var _total_hp: int = 1
var _block_size: Vector2 = Vector2(BLOCK_WIDTH, BLOCK_HEIGHT)

@onready var _background: ColorRect = $Background
@onready var _fill_bar: ColorRect = $Background/FillBar
@onready var _hp_label: Label = $Background/HPLabel
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _health: HealthComponent = $HealthComponent


func _ready() -> void:
	var hp: int = max_hp
	var block_color: Color = Color.WHITE

	if monster_data:
		hp = monster_data.hp
		block_color = monster_data.color
		_block_size = Vector2(maxf(monster_data.size.x, 10.0), maxf(monster_data.size.y, 10.0))
	else:
		var color_index: int = clampi(hp - 1, 0, _FALLBACK_COLORS.size() - 1)
		block_color = _FALLBACK_COLORS[color_index]

	_total_hp = hp
	_health.initialize(hp)

	# Collision
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = _block_size
	_collision.shape = rect

	# Background (dark border/empty area)
	_background.size = _block_size
	_background.position = Vector2(-_block_size.x / 2.0, -_block_size.y / 2.0)
	_background.color = Color(0.15, 0.15, 0.15)

	# Fill bar (colored HP fill inside the block)
	_fill_bar.position = Vector2(BAR_PADDING, BAR_PADDING)
	_fill_bar.size = Vector2(_block_size.x - BAR_PADDING * 2.0, _block_size.y - BAR_PADDING * 2.0)
	_fill_bar.color = block_color

	# HP label centered on the block
	_hp_label.position = Vector2.ZERO
	_hp_label.size = _block_size
	_hp_label.text = str(hp)
	_hp_label.add_theme_font_size_override("font_size", 14)
	_hp_label.add_theme_color_override("font_color", Color.WHITE)
	_hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_hp_label.add_theme_constant_override("shadow_offset_x", 1)
	_hp_label.add_theme_constant_override("shadow_offset_y", 1)

	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)


func hit() -> void:
	_health.take_damage()


func _on_health_changed(_new_hp: int, _new_max: int) -> void:
	_update_visual()


func _on_died() -> void:
	destroyed.emit()
	call_deferred("queue_free")


func _update_visual() -> void:
	var current_hp: int = _health.get_current_hp()
	var inner_width: float = _block_size.x - BAR_PADDING * 2.0
	var hp_ratio: float = float(current_hp) / float(_total_hp)
	_fill_bar.size.x = inner_width * hp_ratio
	_hp_label.text = str(current_hp)
