extends StaticBody2D
class_name Block

signal destroyed

const BLOCK_WIDTH: float = 60.0
const BLOCK_HEIGHT: float = 24.0

static var _COLORS: Array[Color] = [
	Color(0.2, 0.8, 0.2),   # 1 HP - green
	Color(0.9, 0.7, 0.1),   # 2 HP - yellow
	Color(0.9, 0.2, 0.2),   # 3 HP - red
]

@export var max_hp: int = 1

@onready var _visual: ColorRect = $Visual
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _health: HealthComponent = $HealthComponent


func _ready() -> void:
	_health.initialize(max_hp)
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(BLOCK_WIDTH, BLOCK_HEIGHT)
	_collision.shape = rect
	_visual.size = Vector2(BLOCK_WIDTH, BLOCK_HEIGHT)
	_visual.position = Vector2(-BLOCK_WIDTH / 2.0, -BLOCK_HEIGHT / 2.0)
	_health.health_changed.connect(_on_health_changed)
	_health.died.connect(_on_died)
	_update_visual()


func hit() -> void:
	_health.take_damage()


func _on_health_changed(_new_hp: int, _new_max: int) -> void:
	_update_visual()


func _on_died() -> void:
	destroyed.emit()
	call_deferred("queue_free")


func _update_visual() -> void:
	var color_index: int = clampi(_health.get_current_hp() - 1, 0, _COLORS.size() - 1)
	_visual.color = _COLORS[color_index]
