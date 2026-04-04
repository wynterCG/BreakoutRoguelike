extends Resource
class_name MonsterData

@export var monster_name: String = ""
@export_range(1, 100) var hp: int = 1
@export var color: Color = Color(0.2, 0.8, 0.2)
@export var min_level: int = 1
@export_enum("front", "tank", "support", "elite") var role: String = "front"

@export_group("Movement")
@export var drift_enabled: bool = false
@export var drift_speed: float = 30.0
@export var zigzag_enabled: bool = false
@export var zigzag_speed: float = 40.0
@export var orbit_enabled: bool = false
@export var orbit_speed: float = 50.0
@export var orbit_radius: float = 30.0
@export var charge_enabled: bool = false
@export var charge_speed: float = 100.0
@export var charge_interval: float = 3.0
